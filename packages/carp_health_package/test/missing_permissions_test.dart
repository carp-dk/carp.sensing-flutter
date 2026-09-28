import 'package:carp_health_package/health_package.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Fake Health Connect: only STEPS and HEART_RATE are granted.
  const granted = {'STEPS', 'HEART_RATE'};
  setUp(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_health'), (call) async {
        final types = (call.arguments['types'] as List).cast<String>();
        return types.every(granted.contains);
      }));

  test('missingHealthPermissions names the types that are not granted', () async {
    final manager = HealthServiceManager(HealthService())
      ..addTypes([HealthDataType.STEPS, HealthDataType.WEIGHT, HealthDataType.HEART_RATE, HealthDataType.HEIGHT]);

    expect(await manager.onHasPermissions(), isFalse);
    expect(await manager.missingHealthPermissions(manager.types), [HealthDataType.WEIGHT, HealthDataType.HEIGHT]);
  });

  test('missingHealthPermissions is empty when all types are granted', () async {
    final manager = HealthServiceManager(HealthService())..addTypes([HealthDataType.STEPS]);

    expect(await manager.onHasPermissions(), isTrue);
    expect(await manager.missingHealthPermissions(manager.types), isEmpty);
  });
}
