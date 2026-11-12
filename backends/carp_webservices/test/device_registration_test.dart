import 'dart:convert';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// What [CarpDeploymentService] sends and returns - without CAMS as a dependency.
void main() {
  final requests = <Map<String, dynamic>>[];
  late Map<String, dynamic> reply;

  setUpAll(() {
    CarpMobileSensing.ensureInitialized();
    CarpDeploymentService().configure(CarpApp(name: 'test', uri: Uri.parse('https://caws.test')));
    CarpAuthService().currentUser = CarpUser(
      username: 'test',
      id: 'test',
      token: OAuthToken('access', 'refresh', 'bearer', DateTime.now().add(const Duration(hours: 1)), [], 'id'),
    );
  });

  Future<T> withCaws<T>(Future<T> Function() body) => http.runWithClient(
    body,
    () => MockClient((request) async {
      requests.add(json.decode(request.body) as Map<String, dynamic>);
      return http.Response(json.encode(reply), 200);
    }),
  );

  // CAWS takes custom registrations since CARP Core 1.3 (issue #561).
  test('a CAMS registration is sent as is', () async {
    reply = (StudyDeploymentStatus(studyDeploymentId: '1234')..createdOn = DateTime.now()).toJson();
    final cams = SmartphoneRegistration(deviceId: 'abc', deviceDisplayName: 'my phone', platform: 'Android');

    await withCaws(() => CarpDeploymentService().registerDevice('1234', 'phone', cams));

    final sent = requests.last['registration'] as Map<String, dynamic>;
    expect(sent[Serializable.CLASS_IDENTIFIER], cams.jsonType);
    expect(sent['deviceId'], 'abc');
    expect(sent['platform'], 'Android');
    expect(sent['registrationCreatedOn'], isNotNull);

    // the deployment reference takes the same path
    await withCaws(() => CarpDeploymentService().deployment('1234', 'phone').registerDevice(cams));
    expect((requests.last['registration'] as Map)[Serializable.CLASS_IDENTIFIER], cams.jsonType);
  });

  test('a CARP Core registration is sent as is', () async {
    reply = (StudyDeploymentStatus(studyDeploymentId: '1234')..createdOn = DateTime.now()).toJson();
    final core = MACAddressDeviceRegistration(macAddress: '00:11:22:33:44:55');

    await withCaws(() => CarpDeploymentService().registerDevice('1234', 'phone', core));

    expect((requests.last['registration'] as Map)[Serializable.CLASS_IDENTIFIER], core.jsonType);
  });

  test('the deployment reference registers a default registration if none is given', () async {
    reply = (StudyDeploymentStatus(studyDeploymentId: '1234')..createdOn = DateTime.now()).toJson();

    await withCaws(() => CarpDeploymentService().deployment('1234', 'phone').registerDevice());

    final sent = requests.last['registration'] as Map<String, dynamic>;
    expect(sent[Serializable.CLASS_IDENTIFIER], DefaultDeviceRegistration().jsonType);
    expect(sent['deviceId'], isNotEmpty);
  });

  test('the deployment from CAWS becomes a SmartphoneDeployment in a SmartphoneStudy', () async {
    final phone = Smartphone();
    reply = PrimaryDeviceDeployment(deviceConfiguration: phone, registration: DefaultDeviceRegistration()).toJson();

    final deployment = await withCaws(() => CarpDeploymentService().getDeviceDeploymentFor('1234', phone.roleName));
    final study = SmartphoneStudy(studyDeploymentId: '1234', deviceRoleName: phone.roleName)
      ..deploymentStatusReceived(StudyDeploymentStatus(studyDeploymentId: '1234'))
      ..deviceDeploymentReceived(deployment);

    expect(study.deployment, isA<SmartphoneDeployment>());
    expect(study.deployment!.studyDeploymentId, '1234');
  });
}
