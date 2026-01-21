import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_credentials.dart';
import '_carp_properties.dart';

/// This test suite tests the [CarpParticipationService].
///
/// The main focus is to test
///  - getting the participation invitations
///  - setting & getting expected participation data
void main() {
  CarpUser? user;

  Settings().debugLevel = DebugLevel.debug;
  SharedPreferences.setMockInitialValues({});
  WidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();

  /// Configure the [CarpAuthService] and authenticate,
  /// and configure the [CarpParticipationService].
  setUpAll(() async {
    await CarpAuthService().configure(CarpProperties().authProperties);
    CarpParticipationService().configure(
      CarpProperties().app,
      CarpProperties().study,
    );

    user = await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );
  });

  tearDownAll(() {});

  group("Base services", () {
    test('- authentication', () async {
      debugPrint(
        'CarpParticipationService : ${CarpParticipationService().app}',
      );
      debugPrint(" - signed in as: $user");
    }, skip: false);
  });

  group("Participation Service", () {
    test('- get invitations for this user', () async {
      final invitations = await CarpParticipationService()
          .getActiveParticipationInvitations();

      debugPrint(toJsonString(invitations));
      expect(invitations, isNotNull);

      var invitation = invitations.firstWhere(
        (invitation) => invitation.studyDeploymentId == testDeploymentId,
      );
      expect(invitation, isNotNull);
      expect(invitation.studyId, testStudyId);
      expect(invitation.studyDeploymentId, testDeploymentId);

      debugPrint(toJsonString(invitation));
      debugPrint(invitation.studyId);
    }, skip: false);

    test('- get participant data - single deployment', () async {
      final data = await CarpParticipationService().getParticipantData(
        testDeploymentId,
      );
      debugPrint(toJsonString(data));
    }, skip: false);

    test('- get participant data - multiple deployments', () async {
      final data = await CarpParticipationService().getParticipantDataList([
        testDeploymentId,
        anotherTestDeploymentId,
      ]);
      debugPrint(toJsonString(data));
    }, skip: false);

    test('- set participant data - common', () async {
      // this is a pretty bad example - setting sex as a common participant data....
      // but this is what is in the protocol
      final data = await CarpParticipationService().setParticipantData(
        testDeploymentId,
        {InputType.SEX: SexInput(value: Sex.Male)},
      );
      debugPrint(toJsonString(data));

      expect(data.common[InputType.SEX], isA<SexInput>());
      expect((data.common[InputType.SEX] as SexInput).value, Sex.Male);
    }, skip: false);
  });

  group("Participation Reference", () {
    test('- get participant data', () async {
      final participation = CarpParticipationService().participation();

      ParticipantData data = await participation.getParticipantData();
      debugPrint(toJsonString(data));
    }, skip: false);

    test('- set common participant data', () async {
      final participation = CarpParticipationService().participation();

      ParticipantData data = await participation.setParticipantData({
        InputType.ADDRESS: AddressInput(address1: 'Test Address'),
      });
      debugPrint(toJsonString(data));

      expect(data.common[InputType.ADDRESS], isA<AddressInput>());
      expect(
        (data.common[InputType.ADDRESS] as AddressInput).address1,
        'Test Address',
      );
    }, skip: false);

    test('- set Informed Consent', () async {
      final participation = CarpParticipationService().participation();

      await participation.setInformedConsent(
        InformedConsentInput(
          userId: 'ec44c84d-3acd-45d5-83ef-1511e0c39e48',
          name: 'John Doe',
          consent: 'I agree!',
          signatureImage: 'blob',
        ),
        testParticipantRoleName,
      );

      final consent = await participation.getInformedConsent();
      debugPrint(toJsonString(consent));

      expect(consent[testParticipantRoleName], isA<InformedConsentInput>());
      expect(consent[testParticipantRoleName]?.name, 'John Doe');
      expect(consent['mother'], isNull);
      expect(consent['child'], isNull);
    });

    test('- get informed consent document', () async {
      final participation = CarpParticipationService().participation();
      final consent = await participation.getInformedConsentByRole();
      debugPrint(toJsonString(consent));
      expect(consent, isNotNull);
    });
  });
}
