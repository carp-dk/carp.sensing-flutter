import 'package:test/test.dart';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_polar_package/carp_polar_package.dart';

/// Tests that protocols created with CAMS 1.x (protocol API level < 2.0) -
/// where the Polar device used the carp_core device namespace and had no
/// BLE scan configuration - still can be deserialized into the CAMS 2.x class.
void main() {
  setUp(() {
    CarpMobileSensing.ensureInitialized();
    SamplingPackageRegistry().register(PolarSamplingPackage());
  });

  group('API Level 1.x Backwards Compatibility', () {
    test(' - 1.x Polar device', () {
      final device = DeviceConfiguration.fromJson({
        '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.PolarDevice',
        'roleName': 'Polar HR Sensor',
        'isOptional': true,
        'defaultSamplingConfiguration': <String, dynamic>{},
      });

      expect(device, isA<PolarDevice>());
      final polar = device as PolarDevice;
      expect(polar.type, PolarDevice.DEVICE_TYPE);
      expect(polar.roleName, 'Polar HR Sensor');
      expect(polar.serviceUuids, isEmpty);
      expect(polar.namePrefix, 'Polar');
      expect(polar.allowDuplicates, true);
    });
  });
}
