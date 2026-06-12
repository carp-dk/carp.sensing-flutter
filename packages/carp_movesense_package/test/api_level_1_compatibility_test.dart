import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';

/// Tests that protocols created with CAMS 1.x (protocol API level < 2.0) -
/// where the Movesense device used the carp_core device namespace and had a
/// (now removed) deviceType property - still can be deserialized into the
/// CAMS 2.x class.
void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    CarpMobileSensing.ensureInitialized();
    SamplingPackageRegistry().register(MovesenseSamplingPackage());
  });

  group('API Level 1.x Backwards Compatibility', () {
    test(' - 1.x Movesense device', () {
      final device = DeviceConfiguration.fromJson({
        '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.MovesenseDevice',
        'roleName': 'Movesense ECG Device',
        'isOptional': true,
        'defaultSamplingConfiguration': <String, dynamic>{},
        'deviceType': 'UNKNOWN',
      });

      expect(device, isA<MovesenseDevice>());
      final movesense = device as MovesenseDevice;
      expect(movesense.type, MovesenseDevice.DEVICE_TYPE);
      expect(movesense.roleName, 'Movesense ECG Device');
      expect(movesense.serviceUuids, isEmpty);
      expect(movesense.allowDuplicates, true);
    });
  });
}
