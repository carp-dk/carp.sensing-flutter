import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    CarpMobileSensing.ensureInitialized();
  });

  group('Sampling Configurations', () {
    test('Sampling Packages.', () {
      var schemes = DeviceSamplingPackage().samplingSchemes;
      expect(
        schemes.configurations.length,
        DeviceSamplingPackage().samplingSchemes.dataTypes.length,
      );

      schemes.addSamplingSchema(MonitoringSamplingPackage().samplingSchemes);
      expect(
        schemes.configurations.length,
        DeviceSamplingPackage().samplingSchemes.dataTypes.length +
            MonitoringSamplingPackage().samplingSchemes.dataTypes.length,
      );

      schemes.addSamplingSchema(SensorSamplingPackage().samplingSchemes);
      expect(
        schemes.configurations.length,
        DeviceSamplingPackage().samplingSchemes.dataTypes.length +
            MonitoringSamplingPackage().samplingSchemes.dataTypes.length +
            SensorSamplingPackage().samplingSchemes.dataTypes.length,
      );

      print(schemes.types);
    });
  });
}
