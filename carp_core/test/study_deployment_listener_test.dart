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
}
