import 'package:test/test.dart';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_context_package/carp_context_package.dart';

/// Tests that protocols created with CAMS 1.x (protocol API level < 2.0) -
/// where the context services used the carp_core device namespace - still
/// can be deserialized into the CAMS 2.x classes.
void main() {
  setUp(() {
    CarpMobileSensing.ensureInitialized();
    SamplingPackageRegistry().register(ContextSamplingPackage());
  });

  group('API Level 1.x Backwards Compatibility', () {
    test(' - 1.x location service', () {
      final device = DeviceConfiguration.fromJson({
        '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.LocationService',
        'roleName': 'Location Service',
        'isOptional': true,
        'defaultSamplingConfiguration': <String, dynamic>{},
        'accuracy': 'balanced',
        'distance': 10.0,
        'interval': 60000000,
        'notificationOnTapBringToFront': false,
      });

      expect(device, isA<LocationService>());
      final service = device as LocationService;
      expect(service.type, LocationService.DEVICE_TYPE);
      expect(service.accuracy, GeolocationAccuracy.balanced);
      expect(service.distance, 10.0);
      expect(service.interval, const Duration(minutes: 1));
    });

    test(' - 1.x weather service', () {
      final device = DeviceConfiguration.fromJson({
        '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.WeatherService',
        'roleName': 'Weather Service',
        'isOptional': true,
        'defaultSamplingConfiguration': <String, dynamic>{},
        'apiKey': '12b6e28582eb9298577c734a31ba9f4f',
      });

      expect(device, isA<WeatherService>());
      final service = device as WeatherService;
      expect(service.type, WeatherService.DEVICE_TYPE);
      expect(service.apiKey, '12b6e28582eb9298577c734a31ba9f4f');
    });

    test(' - 1.x air quality service', () {
      final device = DeviceConfiguration.fromJson({
        '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.AirQualityService',
        'roleName': 'Air Quality Service',
        'isOptional': true,
        'defaultSamplingConfiguration': <String, dynamic>{},
        'apiKey': '9e538456b2b85c92647d8b65090e29f957638c77',
      });

      expect(device, isA<AirQualityService>());
      final service = device as AirQualityService;
      expect(service.type, AirQualityService.DEVICE_TYPE);
      expect(service.apiKey, '9e538456b2b85c92647d8b65090e29f957638c77');
    });
  });
}
