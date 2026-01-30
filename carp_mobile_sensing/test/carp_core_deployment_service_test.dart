import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_serializable/carp_serializable.dart';

void main() {
  setUp(() {
    // make sure that the json functions are loaded
    CarpMobileSensing();
  });

  test('JSON File -> StudyProtocol', () async {
    // Read the study protocol from json file
    String plainJson = File('test/json/study_protocol.json').readAsStringSync();

    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol.fromJson(
      json.decode(plainJson) as Map<String, dynamic>,
    );

    expect(protocol.ownerId, 'user@dtu.dk');
    expect(
      protocol.primaryDevices.first.roleName,
      SmartphoneDeploymentService().thisPhone.roleName,
    );
    print(toJsonString(protocol));
  });

  test('Deploy protocol -> CAMSDeploymentService()', () async {
    // Read the study protocol from json file
    String plainJson = File('test/json/study_protocol.json').readAsStringSync();

    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol.fromJson(
      json.decode(plainJson) as Map<String, dynamic>,
    );

    expect(protocol.ownerId, 'user@dtu.dk');
    expect(
      protocol.primaryDevices.first.roleName,
      SmartphoneDeploymentService().thisPhone.roleName,
    );

    StudyDeploymentStatus status = await SmartphoneDeploymentService()
        .createStudyDeployment(protocol);
    print(toJsonString(status));
  });

  test('Get deployment <- CAMSDeploymentService()', () async {
    // Read the study protocol from json file
    String plainJson = File('test/json/study_protocol.json').readAsStringSync();

    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol.fromJson(
      json.decode(plainJson) as Map<String, dynamic>,
    );

    StudyDeploymentStatus status = await SmartphoneDeploymentService()
        .createStudyDeployment(protocol);
    SmartphoneDeployment? deployment = await SmartphoneDeploymentService()
        .getDeviceDeployment(status.studyDeploymentId);

    expect(status.studyDeploymentId, deployment?.studyDeploymentId);
    print(toJsonString(deployment));
  });
}
