import 'dart:io';
import 'dart:convert';

// import 'package:cognition_package/cognition_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:research_package/research_package.dart';
import 'package:carp_apps_package/apps.dart';
// import 'package:carp_communication_package/communication.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_audio_package/media.dart';
import 'package:carp_esense_package/esense.dart';
import 'package:carp_polar_package/carp_polar_package.dart';
import 'package:carp_survey_package/survey.dart';
import 'package:carp_health_package/health_package.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Initialization of libraries
    CarpMobileSensing.ensureInitialized();
    ResearchPackage.ensureInitialized();
    // CognitionPackage.ensureInitialized();

    // register the sampling packages
    SamplingPackageRegistry().register(AppsSamplingPackage());
    // SamplingPackageRegistry().register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    SamplingPackageRegistry().register(ESenseSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
    SamplingPackageRegistry().register(SurveySamplingPackage());
    SamplingPackageRegistry().register(HealthSamplingPackage());
  });

  group("parsing resources", () {
    test('consent', () async {
      String consentPath = 'carp/resources/consent.json';
      String consentJson = File(consentPath).readAsStringSync();
      RPOrderedTask.fromJson(json.decode(consentJson) as Map<String, dynamic>);
    });

    test('protocol', () async {
      String protocolPath = 'carp/resources/protocol.json';
      String protocolJson = File(protocolPath).readAsStringSync();
      StudyProtocol.fromJson(json.decode(protocolJson) as Map<String, dynamic>);
    });
  });
}
