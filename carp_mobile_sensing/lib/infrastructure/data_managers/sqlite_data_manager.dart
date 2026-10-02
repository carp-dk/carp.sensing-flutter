/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// Creates a [SQLiteDataManager] for data endpoints of type
/// [DataEndPointTypes.SQLITE].
///
/// Registered in the [DataManagerRegistry] by
/// [SmartPhoneClientManager.configure].
class SQLiteDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.SQLITE;

  @override
  DataManager create() => SQLiteDataManager();
}

/// A data manager that stores [Measurement]s as JSON in a local SQLite database.
///
/// Used when the protocol's data endpoint is a [SQLiteDataEndPoint], which is
/// the default for a [SmartphoneStudyProtocol]. Backends (e.g. `carp_backend`)
/// read from this database and upload rows marked as not uploaded.
///
/// Key points:
///  * One database file is shared by all deployments in the app. Rows are keyed
///    by deployment ID, device role name and the measurement's record ID.
///  * Duplicates (same deployment, device role name and record ID) are ignored.
///  * Inserts are batched: rows are buffered and written in one transaction
///    every 500 ms. [close] writes any remaining rows.
///  * Write errors are logged and the batch is dropped.
///
/// Measurements are stored in the [MEASUREMENT_TABLE_NAME] table.
///
/// The path and filename format is `~/carp-data.db`, where `~` is the folder
/// where SQLite places its database files.
///
/// On iOS, this is the `NSDocumentsDirectory` and the files can be accessed via
/// the MacOS Finder.
///
/// On Android, Flutter files are stored in the `databases` directory, which is
/// located in the `data/data/<package_name>/databases/` folder.
/// Files can be accessed via AndroidStudio.
class SQLiteDataManager extends AbstractDataManager {
  /// Name of the database file, without the `.db` extension.
  static const String DATABASE_NAME = 'carp-data';

  /// Name of the table holding the measurements.

  static const String MEASUREMENT_TABLE_NAME = 'measurements';
  static const String ID_COLUMN = 'id';

  /// Upload flag column: `0` when stored. An uploader that keeps rows after
  /// upload sets it to `1`.
  static const String UPLOADED_COLUMN = 'uploaded';
  static const String DEPLOYMENT_ID_COLUMN = 'deployment_id';

  /// ID of the trigger that collected the measurement, or `0` if unknown.
  static const String TRIGGER_ID_COLUMN = 'trigger_id';
  static const String DEVICE_ROLE_NAME_COLUMN = 'device_role_name';
  static const String DATATYPE_COLUMN = 'data_type';

  /// The [Data.recordId] of the measurement, used to drop duplicates.
  static const String RECORD_ID_COLUMN = 'record_id';

  /// The JSON-encoded [Measurement].
  static const String MEASUREMENT_COLUMN = 'measurement';

  String? _databasePath;

  /// Full path and name of the database.
  String get databaseName => '$_databasePath/$DATABASE_NAME.db';

  /// The open database, or `null` until [configure] has been called.
  Database? database;

  @override
  String get type => DataEndPointTypes.SQLITE;

  @override
  Future<void> configure({
    required DataEndPoint dataEndPoint,
    required SmartphoneDeployment deployment,
    required Stream<Measurement> measurements,
  }) async {
    assert(dataEndPoint is SQLiteDataEndPoint);
    await super.configure(dataEndPoint: dataEndPoint, deployment: deployment, measurements: measurements);

    info('Initializing $runtimeType...');

    _databasePath ??= await getDatabasesPath();

    // Open the database - make sure to use the same database across app (re)start
    database = await openDatabase(
      databaseName,
      version: 2,
      singleInstance: true,
      onCreate: (Database db, int version) async {
        // when creating the database, create the measurements table
        debug("$runtimeType - Creating '$MEASUREMENT_TABLE_NAME' table");
        await db.execute(
          'CREATE TABLE $MEASUREMENT_TABLE_NAME ('
          '$ID_COLUMN INTEGER PRIMARY KEY AUTOINCREMENT, '
          // SQLite does not have a separate Boolean storage class. Instead,
          // boolean values are stored as integers 0 (false) and 1 (true).
          '$UPLOADED_COLUMN INTEGER, '
          '$DEPLOYMENT_ID_COLUMN TEXT, '
          '$TRIGGER_ID_COLUMN INTEGER, '
          '$DEVICE_ROLE_NAME_COLUMN TEXT, '
          '$DATATYPE_COLUMN TEXT, '
          '$RECORD_ID_COLUMN TEXT, '
          '$MEASUREMENT_COLUMN TEXT, '
          'UNIQUE($DEPLOYMENT_ID_COLUMN, $DEVICE_ROLE_NAME_COLUMN, '
          '$RECORD_ID_COLUMN))',
        );

        debug("$runtimeType - '$databaseName' DB created");
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // The column/index may already exist, so guard both statements
          // instead of crashing the upgrade on "already exists".
          final columns = await db.rawQuery('PRAGMA table_info($MEASUREMENT_TABLE_NAME)');
          final hasRecordIdColumn = columns.any((column) => column['name'] == RECORD_ID_COLUMN);
          if (!hasRecordIdColumn) {
            await db.execute(
              'ALTER TABLE $MEASUREMENT_TABLE_NAME '
              'ADD COLUMN $RECORD_ID_COLUMN TEXT',
            );
          }
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS measurements_record_id '
            'ON $MEASUREMENT_TABLE_NAME('
            '$DEPLOYMENT_ID_COLUMN, $DEVICE_ROLE_NAME_COLUMN, '
            '$RECORD_ID_COLUMN)',
          );
        }
      },
    );
  }

  @override
  Future<void> onMeasurement(Measurement measurement) async {
    // If the database hasn't been created yet, wait for 3 secs
    if (database == null) {
      return Future.delayed(const Duration(seconds: 3), () => onMeasurement(measurement));
    }

    final Map<String, dynamic> map = {
      UPLOADED_COLUMN: 0,
      DEPLOYMENT_ID_COLUMN: deployment.studyDeploymentId,
      TRIGGER_ID_COLUMN: measurement.taskControl?.triggerId ?? 0,
      DEVICE_ROLE_NAME_COLUMN:
          measurement.taskControl?.destinationDeviceRoleName ?? deployment.deviceConfiguration.roleName,
      DATATYPE_COLUMN: measurement.dataType.toString(),
      RECORD_ID_COLUMN: measurement.data.recordId,
      MEASUREMENT_COLUMN: jsonEncode(measurement),
    };

    // Fast out if DB has been closed.
    // This may happen when the data manager is closed while some probes are still
    // running and sampling measurements.
    if (!database!.isOpen) return;

    // One transaction per burst: a transaction per row caps out at a few
    // hundred inserts/s, which is too slow for e.g. health data catch-up.
    _rows.add(map);
    _flushTimer ??= Timer(const Duration(milliseconds: 500), _flush);
  }

  final List<Map<String, dynamic>> _rows = [];
  Timer? _flushTimer;

  Future<void> _flush() async {
    _flushTimer = null;
    if (_rows.isEmpty || database?.isOpen != true) return;
    final batch = database!.batch();
    for (final row in _rows) {
      batch.insert(MEASUREMENT_TABLE_NAME, row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    final count = _rows.length;
    _rows.clear();

    try {
      await batch.commit(noResult: true);
      debug('$runtimeType - wrote $count measurements to SQLite.');
    } catch (error) {
      warning('$runtimeType - Error writing measurements to database - $error');
    }
  }

  @override
  Future<void> close() async {
    _flushTimer?.cancel();
    await _flush();
    await super.close();
  }
}
