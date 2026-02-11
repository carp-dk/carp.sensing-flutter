import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_credentials.dart';
import '_carp_properties.dart';

/// This test suite tests how to set and get expected participation data.
///
/// The main focus is to test
///  - creating a protocol with expected participation data
///  - setting & getting participation data for different participant roles
///
/// A special protocol for a 3-person family is used for testing expected
/// participation data for each family member.
void main() {
  const father = 'Father';
  const mother = 'Mother';
  const child = 'Child';
  const fatherDeviceRoleName = "$father's Phone";

  CarpUser? user;
  String? ownerId;

  Settings().debugLevel = DebugLevel.debug;
  SharedPreferences.setMockInitialValues({});
  WidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();

  /// Configure CARP and authenticate.
  setUpAll(() async {
    await CarpAuthService().configure(CarpProperties().authProperties);

    // configure the service with both an app and the family study, using the same
    // study for all tests

    SmartphoneStudy familyStudy = SmartphoneStudy(
      studyId: familyStudyId,
      studyDeploymentId: familyDeploymentId,
      deviceRoleName: fatherDeviceRoleName,
      participantId: '',
      participantRoleName: father,
    );

    CarpService().configure(CarpProperties().app, familyStudy);
    CarpParticipationService().configureFrom(CarpService());
    CarpDeploymentService().configureFrom(CarpService());

    user = await CarpAuthService().authenticateWithUsernamePassword(
      // username: fatherUsername,
      // password: fatherPassword,
      username: username,
      password: password,
    );
  });

  tearDownAll(() {});

  group("Base Services", () {
    test('- authentication', () async {
      debugPrint('CarpService : ${CarpService().app}');
      debugPrint(" - signed in as: $user");
    });

    test('- get invitations for this user', () async {
      List<ActiveParticipationInvitation> invitations =
          await CarpParticipationService().getActiveParticipationInvitations();

      expect(invitations, isNotNull);
      debugPrint(toJsonString(invitations));
    }, skip: false);
  });

  group("Define Protocol", () {
    test('- define', () async {
      ownerId = CarpAuthService().currentUser.id;

      // a study protocol testing misc input data types for a family
      StudyProtocol protocol = StudyProtocol(
        ownerId: ownerId!,
        name: 'Input Data Types',
        description: 'Collect mics. input from study participants.',
      );

      // add participant roles
      protocol
        ..addParticipantRole(ParticipantRole(father))
        ..addParticipantRole(ParticipantRole(mother))
        ..addParticipantRole(ParticipantRole(child));

      // define and assign the primary devices for each family member
      final fatherPhone = Smartphone(roleName: "$father's Phone");
      final motherPhone = Smartphone(roleName: "$mother's Phone");
      final childPhone = Smartphone(roleName: "$child's Phone");
      protocol
        ..addPrimaryDevice(fatherPhone)
        ..addPrimaryDevice(motherPhone)
        ..addPrimaryDevice(childPhone);

      protocol
        ..changeDeviceAssignment(fatherPhone, AssignedTo(roleNames: {father}))
        ..changeDeviceAssignment(motherPhone, AssignedTo(roleNames: {mother}))
        ..changeDeviceAssignment(childPhone, AssignedTo(roleNames: {child}));

      // add expected participant data which can be set by ALL participants
      protocol.addExpectedParticipantData(
        ExpectedParticipantData(
          attribute: ParticipantAttribute(inputDataType: InputType.ADDRESS),
        ),
      );

      // add expected participant data for specific participants
      protocol
        ..addExpectedParticipantData(
          ExpectedParticipantData(
            attribute: ParticipantAttribute(inputDataType: InputType.FULL_NAME),
            assignedTo: AssignedTo(roleNames: {father, mother, child}),
          ),
        )
        ..addExpectedParticipantData(
          ExpectedParticipantData(
            attribute: ParticipantAttribute(inputDataType: InputType.SEX),
            assignedTo: AssignedTo(roleNames: {father, mother, child}),
          ),
        )
        ..addExpectedParticipantData(
          ExpectedParticipantData(
            attribute: ParticipantAttribute(
              inputDataType: InputType.INFORMED_CONSENT,
            ),
            assignedTo: AssignedTo(roleNames: {father, mother}),
          ),
        );

      // add measures (not really used in this test)
      protocol
        ..addTaskControl(
          ImmediateTrigger(),
          BackgroundTask(
            measures: [
              Measure(type: SensorSamplingPackage.STEP_EVENT),
              Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
            ],
          ),
          fatherPhone,
        )
        ..addTaskControl(
          ImmediateTrigger(),
          BackgroundTask(
            measures: [
              Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
              Measure(type: DeviceSamplingPackage.FREE_MEMORY),
            ],
          ),
          motherPhone,
        )
        ..addTaskControl(
          ImmediateTrigger(),
          BackgroundTask(
            measures: [
              Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
              Measure(type: DeviceSamplingPackage.BATTERY_STATE),
            ],
          ),
          childPhone,
        );
      debugPrint(toJsonString(protocol));
    });
  });

  group("Deployment", () {
    test('- get deployment status', () async {
      final status = await CarpDeploymentService().deployment().getStatus();
      debugPrint(toJsonString(status));
      expect(status.studyDeploymentId, familyDeploymentId);
    });

    test('- register device', () async {
      final reference = CarpDeploymentService().deployment();
      var status = await reference.getStatus();
      debugPrint('$status');

      expect(status.deviceStatusList.first.device, isNotNull);
      debugPrint('${status.deviceStatusList.first.device}');
      var newStatus = await reference.registerDevice();
      debugPrint('$newStatus');
      expect(newStatus.studyDeploymentId, familyDeploymentId);
    });

    test('- get primary device deployment', () async {
      final reference = CarpDeploymentService().deployment();
      final status = await reference.getStatus();
      debugPrint('$status');
      expect(status.deviceStatusList.first.device, isNotNull);
      debugPrint('${status.deviceStatusList.first.device}');

      // getting the deployment for the father we expect to throw an exception
      // since the rest of the family hasn't registered their devices yet...
      expect(
        () async => await reference.get(),
        throwsA(TypeMatcher<CarpServiceException>()),
      );
    });

    test('- unregister device', () async {
      final reference = CarpDeploymentService().deployment();
      var status = await reference.getStatus();
      debugPrint('$status');

      expect(status.deviceStatusList.first.device, isNotNull);
      debugPrint('${status.deviceStatusList.first.device}');
      var newStatus = await reference.unRegisterDevice();
      debugPrint('$newStatus');
      expect(newStatus.studyDeploymentId, familyDeploymentId);
    });
  });

  group("Participant Data", () {
    test('- get all', () async {
      ParticipationReference participation = CarpParticipationService()
          .participation();

      ParticipantData data = await participation.getParticipantData();
      debugPrint(toJsonString(data));

      // data.roles.forEach(
      //     (data) => debugPrint('${data.roleName} : ${data.data.keys}'));
    });

    test('- set common data (Sex)', () async {
      final participation = CarpParticipationService().participation();

      ParticipantData data = await participation.setParticipantData({
        InputType.SEX: SexInput(value: Sex.Male),
      });
      debugPrint(toJsonString(data));

      expect(data.common[InputType.SEX], isA<SexInput>());
      expect((data.common[InputType.SEX] as SexInput).value, Sex.Male);
    });

    test('- set role-specific data (Name of Mother)', () async {
      final participation = CarpParticipationService().participation();

      final data = await participation.setParticipantData({
        InputType.FULL_NAME: FullNameInput(
          firstName: 'Anna',
          middleName: 'K.',
          lastName: 'Doe',
        ),
      }, mother);
      debugPrint(toJsonString(data));

      final sex = data.roles
          .firstWhere((role) => role.roleName == mother)
          .data[InputType.SEX];

      expect(sex, isA<SexInput>());
      expect((sex as SexInput).value, Sex.Male);
    });

    test('- set role-specific data (Sex of Mother)', () async {
      final participation = CarpParticipationService().participation();

      final data = await participation.setParticipantData({
        InputType.SEX: SexInput(value: Sex.Female),
      }, mother);
      debugPrint(toJsonString(data));

      final sex = data.roles
          .firstWhere((role) => role.roleName == mother)
          .data[InputType.SEX];

      expect(sex, isA<SexInput>());
      expect((sex as SexInput).value, Sex.Female);
    });

    test('- set role-specific data (Informed Consent for Father)', () async {
      final participation = CarpParticipationService().participation();

      final data = await participation.setParticipantData({
        InputType.INFORMED_CONSENT: InformedConsentInput(
          userId: 'ec44c84d-3acd-45d5-83ef-1511e0c39e48',
          name: father,
          consent: 'I agree!',
          signatureImage: 'blob',
        ),
      }, father);
      debugPrint(toJsonString(data));

      final consent = data.roles
          .firstWhere((role) => role.roleName == father)
          .data[InputType.INFORMED_CONSENT];

      expect(consent, isA<InformedConsentInput>());
      expect((consent as InformedConsentInput).name, father);
    });

    test('- set role-specific data (Full Name of Father)', () async {
      final participation = CarpParticipationService().participation();

      final data = await participation.setParticipantData({
        InputType.FULL_NAME: FullNameInput(
          firstName: 'Jakob',
          middleName: 'E.',
          lastName: 'Bardram',
        ),
      }, father);
      debugPrint(toJsonString(data));

      final name = data.roles
          .firstWhere((role) => role.roleName == father)
          .data[InputType.FULL_NAME];

      expect(name, isA<FullNameInput>());
      expect((name as FullNameInput).firstName, 'Jakob');
    });

    test('- get Informed Consent', () async {
      final participation = CarpParticipationService().participation();

      Map<String, InformedConsentInput?> consent = await participation
          .getInformedConsent();
      debugPrint(toJsonString(consent));

      expect(consent[father], isA<InformedConsentInput>());
      expect(consent[father]?.name, father);
      expect(consent[mother], isNull);
      expect(consent[child], isNull);
    });

    test('- get Informed Consent by Role', () async {
      final participation = CarpParticipationService().participation();

      InformedConsentInput? consent = await participation
          .getInformedConsentByRole();
      debugPrint(toJsonString(consent));

      expect(consent, isA<InformedConsentInput>());
      // expect(consent[father]?.name, father);
      // expect(consent[mother], isNull);
      // expect(consent[child], isNull);
    });

    test('- set Informed Consent', () async {
      final participation = CarpParticipationService().participation();

      await participation.setInformedConsent(
        InformedConsentInput(
          userId: 'ec44c84d-3acd-45d5-83ef-1511e0c39e48',
          name: father,
          consent: 'I agree!',
          signatureImage: 'blob',
        ),
        father,
      );

      final consent = await participation.getInformedConsent();
      debugPrint(toJsonString(consent));

      expect(consent[father], isA<InformedConsentInput>());
      expect(consent[father]?.name, father);
      expect(consent[mother], isNull);
      expect(consent[child], isNull);
    });

    test('- remove Informed Consent', () async {
      final participation = CarpParticipationService().participation();

      await participation.removeInformedConsent(father);

      final consent = await participation.getInformedConsent();
      debugPrint(toJsonString(consent));

      expect(consent[father], isNull);
      expect(consent[mother], isNull);
      expect(consent[child], isNull);
    });
  });
}
