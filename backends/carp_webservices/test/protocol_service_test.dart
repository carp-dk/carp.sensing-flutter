import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_carp_properties.dart';
import '_credentials.dart';

void main() {
  CarpUser? user;
  String? ownerId;
  late StudyProtocol protocol;

  setUpAll(() async {
    Settings().debugLevel = DebugLevel.debug;
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    CarpMobileSensing.ensureInitialized();

    await CarpAuthService().configure(CarpProperties().authProperties);
    CarpService().configure(CarpProperties().app, CarpProperties().study);

    user = await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );
    CarpProtocolService().configureFrom(CarpService());
    ownerId = CarpAuthService().currentUser.id;

    var phone = Smartphone(roleName: testPhoneRoleName);
    phone.defaultSamplingConfiguration?.addAll({
      CarpDataTypes.GEOLOCATION: BatteryAwareSamplingConfiguration(
        normal: GranularitySamplingConfiguration(Granularity.Detailed),
        low: GranularitySamplingConfiguration(Granularity.Coarse),
      ),
    });

    final bike = AltBeacon(roleName: testBikeRoleName);

    // a study protocol mimicking the protocol from core
    protocol =
        StudyProtocol(
            ownerId: ownerId!,
            name: 'Non-motorized transport study',
            description:
                'Track how much non-motorized movement participants perform.',
          )
          ..addPrimaryDevice(phone)
          ..addConnectedDevice(bike, phone);

    var trigger = ElapsedTimeTrigger(elapsedTime: const Duration(hours: 1));

    protocol
      ..addTaskControl(
        trigger,
        BackgroundTask(
          name: 'Monitor movement',
          description: 'Track step count and geolocation for one week.',
          duration: const Duration(hours: 1),
          measures: [
            Measure(type: CarpDataTypes.GEOLOCATION)
              ..overrideSamplingConfiguration =
                  BatteryAwareSamplingConfiguration(
                    normal: GranularitySamplingConfiguration(
                      Granularity.Detailed,
                    ),
                    low: GranularitySamplingConfiguration(Granularity.Balanced),
                  ),
            Measure(type: CarpDataTypes.STEP_COUNT),
            // the following measures are not part of carp-core, but should still be accepted.
            Measure(type: DeviceSamplingPackage.APP_LIFECYCLE_EVENT),
            Measure(type: DeviceSamplingPackage.BATTERY_STATE),
          ],
        ),
        phone,
      )
      ..addTaskControl(
        trigger,
        BackgroundTask(
          name: 'Bike proximity',
          description: 'Monitor proximity to bike',
          duration: const Duration(hours: 1),
          measures: [Measure(type: CarpDataTypes.SIGNAL_STRENGTH)],
        ),
        bike,
      );

    protocol.addParticipantRole(ParticipantRole('Participant'));

    protocol.addExpectedParticipantData(
      ExpectedParticipantData(
        attribute: ParticipantAttribute(
          inputDataType: 'dk.cachet.carp.input.sex',
        ),
        assignedTo: AssignedTo(roleNames: {'Participant'}),
      ),
    );

    protocol.applicationData = {'uiTheme': 'black'};
  });

  /// Runs once after all tests.
  tearDownAll(() {});

  group("Base services", () {
    test('- authentication', () async {
      debugPrint('CarpService : ${CarpService().app}');
      debugPrint(" - signed in as: $user");
    });
  });

  /// To test the Protocol Service you must be authenticated as a RESEARCHER
  group("Protocol", () {
    test('- define', () async {
      debugPrint(toJsonString(protocol));
    });

    test('- add', () async {
      await CarpProtocolService().add(protocol);
    });

    test('- addVersion', () async {
      protocol.id = testProtocolId;
      await CarpProtocolService().addVersion(protocol, testProtocolVersion);
    });

    test('- getBy', () async {
      var p = await CarpProtocolService().getBy(testProtocolId);
      debugPrint(toJsonString(p));
    });

    test('- getAllFor', () async {
      debugPrint('Getting protocols for owner id: $ownerId');
      List<StudyProtocol> protocols = await CarpProtocolService()
          .getAllForOwner(ownerId!);
      debugPrint(toJsonString(protocols));
    });

    test('- getVersionHistoryFor', () async {
      List<ProtocolVersion> versions = await CarpProtocolService()
          .getVersionHistoryFor(testProtocolId);
      debugPrint(toJsonString(versions));
    });

    test('- updateParticipantDataConfiguration', () async {
      var p = await CarpProtocolService().updateParticipantDataConfiguration(
        testProtocolId,
        testProtocolVersion,
        [
          ExpectedParticipantData(
            attribute: ParticipantAttribute(
              inputDataType: 'dk.cachet.carp.input.sex',
            ),
            // assignedTo: AssignedTo(roleNames: {'Participant'}),
          ),
        ],
      );
      debugPrint(toJsonString(p));
    });

    test('- createCustomProtocol', skip: true, () async {
      StudyProtocol protocol = await CarpProtocolService().createCustomProtocol(
        ownerId!,
        'Custom Protocol Unit Test',
        'Made from Dart unit test.',
        '{"version":1}',
      );

      debugPrint(toJsonString(protocol));
    });
  });
}
