import 'dart:async';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

/// When a new deployment arrives, [SmartphoneStudyController] closes the
/// existing data manager before replacing it. If closing does not actually
/// cancel the measurement subscription, the replaced manager keeps writing and
/// one measurement ends up stored twice - see issue #598.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() => CarpMobileSensing.ensureInitialized());

  test('a closed data manager stops writing measurements', () async {
    final deployment = SmartphoneDeployment(
      deviceConfiguration: Smartphone(roleName: 'phone'),
      registration: DeviceRegistration(),
    );
    final measurements = StreamController<Measurement>.broadcast();
    await deleteDatabase(
      '${await getDatabasesPath()}/${SQLiteDataManager.DATABASE_NAME}.db',
    );

    Future<void> configure(SQLiteDataManager manager) => manager.configure(
      dataEndPoint: SQLiteDataEndPoint(),
      deployment: deployment,
      measurements: measurements.stream,
    );

    final replaced = SQLiteDataManager();
    await configure(replaced);

    // The deployment update: close before replacing, as the controller does.
    await replaced.close();
    final replacement = SQLiteDataManager();
    await configure(replacement);

    measurements.add(Measurement.fromData(Error(message: 'once')));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // One measurement must yield one row - not one per manager.
    expect(
      (await replacement.database!.query(
        SQLiteDataManager.MEASUREMENT_TABLE_NAME,
      )).length,
      1,
    );

    await measurements.close();
    await replacement.database?.close();
  });
}
