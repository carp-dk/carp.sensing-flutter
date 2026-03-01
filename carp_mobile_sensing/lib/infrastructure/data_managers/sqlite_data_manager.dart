/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

class SQLiteDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.SQLITE;

  @override
  DataManager create() => SQLiteDataManager();
}

/// Stores all collected [Measurement] json objects in an SQLite database on
/// the device's local storage media.
/// Measurements are stored in the `measurements` table.
///
/// The path and filename format is `~/carp-data.db`, where `~` is the folder
/// where SQLite places it database files.
///
/// On iOS, this is the `NSDocumentsDirectory` and the files can be accessed via
/// the MacOS Finder.
///
/// On Android, Flutter files are stored in the `databases` directory, which is
/// located in the `data/data/<package_name>/databases/` folder.
/// Files can be accessed via AndroidStudio.
class SQLiteDataManager extends AbstractDataManager {
  static const String DATABASE_NAME = 'carp-data';

  static const String MEASUREMENT_TABLE_NAME = 'measurements';
  static const String ID_COLUMN = 'id';
  static const String UPLOADED_COLUMN = 'uploaded';
  static const String DEPLOYMENT_ID_COLUMN = 'deployment_id';
  static const String TRIGGER_ID_COLUMN = 'trigger_id';
  static const String DEVICE_ROLE_NAME_COLUMN = 'device_role_name';
  static const String DATATYPE_COLUMN = 'data_type';
  static const String MEASUREMENT_COLUMN = 'measurement';

  String? _databasePath;

  /// Full path and name of the database.
  String get databaseName => '$_databasePath/$DATABASE_NAME.db';

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
    await super.configure(
      dataEndPoint: dataEndPoint,
      deployment: deployment,
      measurements: measurements,
    );

    info('Initializing $runtimeType...');

    _databasePath ??= await getDatabasesPath();

    // Open the database - make sure to use the same database across app (re)start
    database = await openDatabase(
      databaseName,
      version: 1,
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
          '$MEASUREMENT_COLUMN TEXT)',
        );

        debug("$runtimeType - '$databaseName' DB created");
      },
    );
  }

  @override
  Future<void> onMeasurement(Measurement measurement) async {
    // If the database hasn't been created yet, wait for 3 secs
    if (database == null) {
      return Future.delayed(
        const Duration(seconds: 3),
        () => onMeasurement(measurement),
      );
    }

    final Map<String, dynamic> map = {
      UPLOADED_COLUMN: 0,
      DEPLOYMENT_ID_COLUMN: deployment.studyDeploymentId,
      TRIGGER_ID_COLUMN: measurement.taskControl?.triggerId ?? 0,
      DEVICE_ROLE_NAME_COLUMN:
          measurement.taskControl?.destinationDeviceRoleName ??
          deployment.deviceConfiguration.roleName,
      DATATYPE_COLUMN: measurement.dataType.toString(),
      MEASUREMENT_COLUMN: jsonEncode(measurement),
    };

    // Fast out if DB has been closed.
    // This may happen when the data manager is closed while some probes are still
    // running and sampling measurements.
    if (!database!.isOpen) return;

    try {
      int? id = await database?.insert(
        MEASUREMENT_TABLE_NAME,
        map,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      debug(
        '$runtimeType - wrote measurement to SQLite - '
        'id: $id, type: ${map[DATATYPE_COLUMN]}, '
        'device role name: ${map[DEVICE_ROLE_NAME_COLUMN]}.',
      );
    } catch (error) {
      warning('$runtimeType - Error writing measurement to database - $error');
    }
  }
}
