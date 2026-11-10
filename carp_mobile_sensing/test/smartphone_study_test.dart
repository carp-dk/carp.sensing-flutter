import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';

void main() {
  // A deployment service like CAWS returns a plain PrimaryDeviceDeployment.
  test('a plain device deployment is received as a SmartphoneDeployment', () {
    final phone = Smartphone();
    final Study study = SmartphoneStudy(studyDeploymentId: '1234', deviceRoleName: phone.roleName, studyId: 'abc')
      ..deploymentStatusReceived(StudyDeploymentStatus(studyDeploymentId: '1234'));

    study.deviceDeploymentReceived(
      PrimaryDeviceDeployment(deviceConfiguration: phone, registration: DefaultDeviceRegistration()),
    );

    expect(study.deployment, isA<SmartphoneDeployment>());
    expect((study.deployment as SmartphoneDeployment).studyDeploymentId, '1234');
    expect(study.studyId, 'abc');
  });

  // carp_core is pure Dart, so CAMS makes its study and deployment usable in a ListenableBuilder.
  test('a smartphone study and deployment are Flutter Listenables', () {
    expect(SmartphoneStudy(studyDeploymentId: '1234', deviceRoleName: 'phone'), isA<Listenable>());
    expect(
      SmartphoneDeployment(deviceConfiguration: Smartphone(), registration: DeviceRegistration()),
      isA<Listenable>(),
    );
  });
}
