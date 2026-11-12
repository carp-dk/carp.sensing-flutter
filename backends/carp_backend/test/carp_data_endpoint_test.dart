import 'package:carp_backend/carp_backend.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(CarpDataManager.ensureInitialized);

  test('the removed datapoint upload method in old protocols is read as stream', () {
    final endPoint = CarpDataEndPoint().toJson()..['uploadMethod'] = 'datapoint';
    expect(CarpDataEndPoint.fromJson(endPoint).uploadMethod, CarpUploadMethod.stream);
  });

  test('every CAMS debug level has a CAWS log level', () {
    for (final level in DebugLevel.values) {
      expect(CarpLogLevel.values.byName(level.name).name, level.name);
    }
  });
}
