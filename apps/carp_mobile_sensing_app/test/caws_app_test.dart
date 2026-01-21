// import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';
import 'package:flutter/cupertino.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_connectivity_package/connectivity.dart';
import 'package:carp_esense_package/esense.dart';
import 'package:carp_polar_package/carp_polar_package.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_audio_package/media.dart';
// import 'package:carp_communication_package/communication.dart';
import 'package:carp_apps_package/apps.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'credentials.dart';

void main() {
  Settings().debugLevel = DebugLevel.debug;
  SharedPreferences.setMockInitialValues({});
  WidgetsFlutterBinding.ensureInitialized();
  // TestWidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();

  // CarpApp app;
  late CarpUser user;

  setUp(() async {
    Settings().debugLevel = DebugLevel.debug;

    // register the different sampling package since we're using measures from them
    SamplingPackageRegistry().register(ConnectivitySamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    // SamplingPackageRegistry().register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(AppsSamplingPackage());
    SamplingPackageRegistry().register(ESenseSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
    SamplingPackageRegistry().register(MovesenseSamplingPackage());
    SamplingPackageRegistry().register(HealthSamplingPackage());

    // create a data manager in order to register the json functions
    CarpDataManager();

    /// The URI of the CAWS server
    final uri = Uri(scheme: 'https', host: 'dev.carp.dk');

    /// The CAWS app configuration.
    final app = CarpApp(name: "CAWS @ DTU", uri: uri);

    /// The authentication configuration
    CarpAuthProperties authProperties = CarpAuthProperties(
      authURL: uri,
      clientId: 'studies-app',
      redirectURI: Uri.parse('carp-studies-auth://auth'),
      // For authentication at CAWS the path is '/auth/realms/Carp'
      discoveryURL: uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
    );

    await CarpAuthService().configure(authProperties);
    CarpService().configure(app);

    user = await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );

    CarpParticipationService().configureFrom(CarpService());
    CarpDeploymentService().configureFrom(CarpService());
  });

  group("CARP Deployment Service", () {
    setUp(() async {});

    test('- authentication', () async {
      print('CarpService : ${CarpService().app}');
      print(" - signed in as: $user");
    });

    test('- get study deployment status', () async {
      final status = await CarpDeploymentService().getStudyDeploymentStatus(
        testDeploymentId,
      );
      print(toJsonString(status));
    });

    test("- register Primary Phone", () async {
      final status = await CarpDeploymentService().registerDevice(
        testDeploymentId,
        "Primary Phone",
        DefaultDeviceRegistration(deviceDisplayName: 'Samsung A10'),
      );
      print(toJsonString(status));
    });
    test("- register Father's device", () async {
      final status = await CarpDeploymentService().registerDevice(
        testDeploymentId,
        "Father's Phone",
        DefaultDeviceRegistration(deviceDisplayName: 'Samsung A10'),
      );
      print(toJsonString(status));
    });

    test("- register Mother's device", () async {
      final status = await CarpDeploymentService().registerDevice(
        testDeploymentId,
        "Mother's Phone",
        DefaultDeviceRegistration(deviceDisplayName: 'Samsung A20'),
      );
      print(toJsonString(status));
    });

    test('- get study deployment ', () async {
      final status = await CarpDeploymentService().getStudyDeploymentStatus(
        testDeploymentId,
      );

      final study = await CarpDeploymentService().getDeviceDeploymentFor(
        status.studyDeploymentId,
        "Primary Phone",
      );
      print(toJsonString(study));
    });
  });

  group("CARP Participation Service", () {
    test('- get invitations', () async {
      List<ActiveParticipationInvitation> invitations =
          await CarpParticipationService().getActiveParticipationInvitations();

      for (var invitation in invitations) {
        print(toJsonString(invitation));
      }
    });

    test('- set participant data - SEX', () async {
      var participation = CarpParticipationService().participation();

      var data = await participation.setParticipantData({
        InputType.SEX: SexInput(value: Sex.Male),
      });

      print(toJsonString(data));
    });

    test('- set participant data - NAME', () async {
      var data = await CarpParticipationService()
          .setParticipantData(testDeploymentId, {
            InputType.FULL_NAME: FullNameInput(
              firstName: 'Eva',
              middleName: 'G.',
              lastName: 'Olsen',
            ),
          }, "Mother");
      print(toJsonString(data));
    });

    test('- set informed consent', () async {
      var participation = CarpParticipationService().participation();

      await participation.setInformedConsent(
        InformedConsentInput(
          userId: 'jakba@dtu.dk',
          name: 'JEB',
          consent: 'I agree',
          signatureImage: 'blob',
        ),
        '',
      );
    });

    test('- get ALL participant data', () async {
      var participation = CarpParticipationService().participation();
      var data = await participation.getParticipantData();

      print(toJsonString(data));
    });
  });
}
