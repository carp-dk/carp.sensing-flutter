import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() => CarpMobileSensing.ensureInitialized());

  test('ignores duplicate source records', () async {
    final manager = await _manager();

    await manager.onMeasurement(
      Measurement.fromData(_IdentifiedData('record-1', 'original')),
    );
    await manager.onMeasurement(
      Measurement.fromData(
        _IdentifiedData(
          'record-1',
          'duplicate',
          jsonType: 'dk.cachet.carp.health.sleep',
        ),
      ),
    );

    final rows = await manager.database!.query(
      SQLiteDataManager.MEASUREMENT_TABLE_NAME,
    );
    expect(rows, hasLength(1));
    expect(
      rows.single[SQLiteDataManager.MEASUREMENT_COLUMN],
      contains('original'),
    );

    await manager.database?.close();
  });

  test('appends records without a source identifier', () async {
    final manager = await _manager();

    await manager.onMeasurement(Measurement.fromData(Error(message: 'first')));
    await manager.onMeasurement(Measurement.fromData(Error(message: 'second')));

    expect(
      await manager.database!.query(SQLiteDataManager.MEASUREMENT_TABLE_NAME),
      hasLength(2),
    );

    await manager.database?.close();
  });

  test('upgrades existing databases', () async {
    final path = await _databasePath();
    await deleteDatabase(path);
    final legacy = await openDatabase(
      path,
      version: 1,
      onCreate: (database, _) => database.execute(
        'CREATE TABLE ${SQLiteDataManager.MEASUREMENT_TABLE_NAME} ('
        '${SQLiteDataManager.ID_COLUMN} INTEGER PRIMARY KEY, '
        '${SQLiteDataManager.DEPLOYMENT_ID_COLUMN} TEXT, '
        '${SQLiteDataManager.DEVICE_ROLE_NAME_COLUMN} TEXT, '
        '${SQLiteDataManager.DATATYPE_COLUMN} TEXT)',
      ),
    );
    await legacy.insert(SQLiteDataManager.MEASUREMENT_TABLE_NAME, {
      SQLiteDataManager.DEPLOYMENT_ID_COLUMN: 'study-a',
    });
    await legacy.close();

    final manager = await _manager(reset: false);
    final columns = await manager.database!.rawQuery(
      'PRAGMA table_info(${SQLiteDataManager.MEASUREMENT_TABLE_NAME})',
    );
    expect(
      columns.map((column) => column['name']),
      contains(SQLiteDataManager.RECORD_ID_COLUMN),
    );
    expect(
      await manager.database!.query(SQLiteDataManager.MEASUREMENT_TABLE_NAME),
      hasLength(1),
    );

    await manager.database?.close();
  });

  test('re-upgrades a database stuck with the column but no version bump', () async {
    // A v1 database that already has the record_id column used to crash the
    // upgrade with "duplicate column name: record_id".
    final path = await _databasePath();
    await deleteDatabase(path);
    final legacy = await openDatabase(
      path,
      version: 1,
      onCreate: (database, _) => database.execute(
        'CREATE TABLE ${SQLiteDataManager.MEASUREMENT_TABLE_NAME} ('
        '${SQLiteDataManager.ID_COLUMN} INTEGER PRIMARY KEY, '
        '${SQLiteDataManager.DEPLOYMENT_ID_COLUMN} TEXT, '
        '${SQLiteDataManager.DEVICE_ROLE_NAME_COLUMN} TEXT, '
        '${SQLiteDataManager.DATATYPE_COLUMN} TEXT)',
      ),
    );
    await legacy.execute(
      'ALTER TABLE ${SQLiteDataManager.MEASUREMENT_TABLE_NAME} '
      'ADD COLUMN ${SQLiteDataManager.RECORD_ID_COLUMN} TEXT',
    );
    await legacy.insert(SQLiteDataManager.MEASUREMENT_TABLE_NAME, {
      SQLiteDataManager.DEPLOYMENT_ID_COLUMN: 'study-a',
    });
    await legacy.close();

    final manager = await _manager(reset: false);
    expect(
      await manager.database!.query(SQLiteDataManager.MEASUREMENT_TABLE_NAME),
      hasLength(1),
    );

    await manager.database?.close();
  });
}

Future<SQLiteDataManager> _manager({bool reset = true}) async {
  if (reset) await deleteDatabase(await _databasePath());
  final manager = SQLiteDataManager();
  await manager.configure(
    dataEndPoint: SQLiteDataEndPoint(),
    deployment: SmartphoneDeployment(
      studyDeploymentId: 'study-a',
      deviceConfiguration: Smartphone(roleName: 'phone'),
      registration: DeviceRegistration(),
    ),
    measurements: const Stream.empty(),
  );
  return manager;
}

Future<String> _databasePath() async =>
    '${await getDatabasesPath()}/${SQLiteDataManager.DATABASE_NAME}.db';

class _IdentifiedData extends Error {
  @override
  final String recordId;
  final String? _jsonType;

  _IdentifiedData(this.recordId, String message, {String? jsonType})
    : _jsonType = jsonType,
      super(message: message);

  @override
  String get jsonType => _jsonType ?? super.jsonType;
}
