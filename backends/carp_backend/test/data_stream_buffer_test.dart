import 'dart:async';

import 'package:carp_backend/carp_backend.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

/// [CarpDataManager.onMeasurement] is a no-op - measurements are written to
/// SQLite by the [DataStreamBuffer]'s own subscription. So a replaced manager
/// must detach from the buffer, or it keeps writing. The buffer is a singleton
/// backed by one app-wide `carp-data.db`, so it must be detached from, never
/// closed. See issue #598.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() => CarpMobileSensing.ensureInitialized());

  test('detach stops buffering but keeps the database open', () async {
    final buffer = DataStreamBuffer();
    final deployment = SmartphoneDeployment(
      deviceConfiguration: Smartphone(roleName: 'phone'),
      registration: DeviceRegistration(),
    );
    final measurements = StreamController<Measurement>.broadcast();
    await deleteDatabase(
      '${await getDatabasesPath()}/${SQLiteDataManager.DATABASE_NAME}.db',
    );

    await buffer.initialize(deployment, measurements.stream);

    measurements.add(Measurement.fromData(Error(message: 'buffered')));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await _rowCount(buffer), 1);

    await buffer.detach();

    // No further writes from the detached deployment...
    measurements.add(Measurement.fromData(Error(message: 'after detach')));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await _rowCount(buffer), 1);

    // ...but the database stays open so a replacement manager can use it,
    // and the un-uploaded row is still there.
    expect(buffer.database!.isOpen, isTrue);

    await measurements.close();
  });
}

Future<int> _rowCount(DataStreamBuffer buffer) async =>
    (await buffer.database!.query(SQLiteDataManager.MEASUREMENT_TABLE_NAME))
        .length;
