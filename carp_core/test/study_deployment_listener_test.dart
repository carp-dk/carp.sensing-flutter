import 'package:carp_core/carp_core.dart';
import 'package:test/test.dart';

void main() {
  test('a restored deployment is listened to', () async {
    final deployment = PrimaryDeviceDeployment(
      deviceConfiguration: Smartphone(roleName: 'phone'),
      registration: DeviceRegistration(),
    );

    final study = Study<PrimaryDeviceDeployment>(
      'deployment-id',
      'phone',
      null,
      StudyDeploymentStatus(studyDeploymentId: 'deployment-id'),
      deployment,
    );

    final events = <StudyStatusEvent>[];
    study.events.listen(events.add);

    study.deviceDeploymentReceived();

    deployment.hasBeenUpdated();
    await Future.delayed(Duration.zero);

    expect(
      events.map((event) => event.event),
      contains(StudyStatusEventTypes.DeploymentUpdated),
      reason: 'updating the deployment should be reported, so it gets saved',
    );
  });

  test('a deployment is reported once per update', () async {
    final deployment = PrimaryDeviceDeployment(
      deviceConfiguration: Smartphone(roleName: 'phone'),
      registration: DeviceRegistration(),
    );

    final study = Study<PrimaryDeviceDeployment>(
      'deployment-id',
      'phone',
      null,
      StudyDeploymentStatus(studyDeploymentId: 'deployment-id'),
    );

    final events = <StudyStatusEvent>[];
    study.events.listen(events.add);

    study.deviceDeploymentReceived(deployment);
    study.deviceDeploymentReceived();

    deployment.hasBeenUpdated();
    await Future.delayed(Duration.zero);

    expect(
      events
          .where(
            (event) => event.event == StudyStatusEventTypes.DeploymentUpdated,
          )
          .length,
      1,
      reason: 'a measurement should not be saved once per received deployment',
    );
  });
}
