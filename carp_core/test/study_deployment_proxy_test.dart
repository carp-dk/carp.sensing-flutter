import 'package:carp_core/carp_core.dart';
import 'package:test/test.dart';

class _DeploymentService implements DeploymentService {
  final device = Smartphone(roleName: 'phone');
  late final deviceStatus = DeviceDeploymentStatus(device: device)
    ..status = DeviceDeploymentStatusTypes.Deployed;
  late final status = StudyDeploymentStatus(
    studyDeploymentId: 'deployment',
    deviceStatusList: [deviceStatus],
  )..status = StudyDeploymentStatusTypes.Running;
  late final deployment = PrimaryDeviceDeployment(
    deviceConfiguration: device,
    registration: DefaultDeviceRegistration(),
  );
  int registerDeviceCalls = 0;
  int deviceDeployedCalls = 0;

  @override
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus(String id) async =>
      status;

  @override
  Future<StudyDeploymentStatus?> registerDevice(
    String id,
    String roleName,
    DeviceRegistration registration,
  ) async {
    registerDeviceCalls++;
    deviceStatus.status = DeviceDeploymentStatusTypes.Registered;
    return status;
  }

  @override
  Future<PrimaryDeviceDeployment?> getDeviceDeploymentFor(
    String id,
    String roleName,
  ) async => deployment;

  @override
  Future<StudyDeploymentStatus?> deviceDeployed(
    String id,
    String roleName,
    DateTime updatedOn,
  ) async {
    deviceDeployedCalls++;
    return status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('refreshes an already deployed device without re-registering or '
      're-acknowledging it', () async {
    final service = _DeploymentService();
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(
      service,
    ).tryDeployment(study, DefaultDeviceRegistration());

    // The deployment is still refreshed, but neither request is repeated -
    // CAWS rejects both for an already deployed device.
    expect(study.deployment, same(service.deployment));
    expect(service.registerDeviceCalls, 0);
    expect(service.deviceDeployedCalls, 0);
  });

  test('registers and acknowledges an unregistered device', () async {
    final service = _DeploymentService();
    service.deviceStatus.status = DeviceDeploymentStatusTypes.Unregistered;
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(
      service,
    ).tryDeployment(study, DefaultDeviceRegistration());

    expect(service.registerDeviceCalls, 1);
    expect(service.deviceDeployedCalls, 1);
  });
}
