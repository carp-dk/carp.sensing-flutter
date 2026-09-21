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

  test('cleanup only removes the rows of the given data stream', () async {
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

    measurements.add(Measurement.fromData(Error(message: 'error')));
    measurements.add(Measurement.fromData(StepCount(steps: 1)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await _rowCount(buffer), 2);

    final batches = await Future.wait(
      [CarpDataTypes.ERROR, CarpDataTypes.STEP_COUNT].map(
        (type) => buffer.getDataStreamBatch(
          ExpectedDataStream(dataType: type, deviceRoleName: 'phone'),
        ),
      ),
    );
    expect(batches.map((b) => b!.measurements.length), [1, 1]);

    // Simulate the error stream being uploaded, but the step count rejected.
    await buffer.cleanup(batches[0]!.dataStream);
    await buffer.discard(batches[1]!.dataStream);
    expect(await _rowCount(buffer), 1);
    // The rejected row stays for debugging but is never batched again.
    expect(
      await buffer.getDataStreamBatch(
        ExpectedDataStream(
          dataType: CarpDataTypes.STEP_COUNT,
          deviceRoleName: 'phone',
        ),
      ),
      isNull,
    );

    await buffer.detach();
    await measurements.close();
  });
}

Future<int> _rowCount(DataStreamBuffer buffer) async =>
    (await buffer.database!.query(
      SQLiteDataManager.MEASUREMENT_TABLE_NAME,
    )).length;
