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
  bool failRegistration = false;

  @override
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus(String id) async =>
      status;

  @override
  Future<StudyDeploymentStatus> registerDevice(
    String id,
    String roleName,
    DeviceRegistration registration,
  ) async {
    registerDeviceCalls++;
    if (failRegistration) throw Exception('registration failed');
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
  test('returns without registering when the deployment is running', () async {
    final service = _DeploymentService();
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(
      service,
    ).tryDeployment(study, DefaultDeviceRegistration());

    expect(study.deployment, isNull);
    expect(service.registerDeviceCalls, 0);
    expect(service.deviceDeployedCalls, 0);
  });

  test('continues deployment when registration fails', () async {
    final service = _DeploymentService()
      ..failRegistration = true
      ..status.status = StudyDeploymentStatusTypes.DeployingDevices;
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(
      service,
    ).tryDeployment(study, DefaultDeviceRegistration());

    expect(service.registerDeviceCalls, 1);
    expect(study.deployment, same(service.deployment));
    expect(service.deviceDeployedCalls, 1);
  });

  test('registers and acknowledges an unregistered device', () async {
    final service = _DeploymentService();
    service.status.status = StudyDeploymentStatusTypes.DeployingDevices;
    service.deviceStatus.status = DeviceDeploymentStatusTypes.Unregistered;
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(
      service,
    ).tryDeployment(study, DefaultDeviceRegistration());

    expect(service.registerDeviceCalls, 1);
    expect(service.deviceDeployedCalls, 1);
  });
}
