import 'package:carp_core/carp_core.dart';
import 'package:test/test.dart';

class _DeploymentService implements DeploymentService {
  final device = Smartphone(roleName: 'phone');
  late final deviceStatus = DeviceDeploymentStatus(device: device)..status = DeviceDeploymentStatusTypes.Deployed;
  late final status = StudyDeploymentStatus(studyDeploymentId: 'deployment', deviceStatusList: [deviceStatus])
    ..status = StudyDeploymentStatusTypes.Running;
  late final deployment = PrimaryDeviceDeployment(
    deviceConfiguration: device,
    registration: DefaultDeviceRegistration(),
  );
  int registerDeviceCalls = 0;
  DeviceRegistration? registered;
  int deviceDeployedCalls = 0;
  bool failRegistration = false;

  @override
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus(String id) async => status;

  @override
  Future<StudyDeploymentStatus?> registerDevice(String id, String roleName, DeviceRegistration registration) async {
    registerDeviceCalls++;
    registered = registration;
    if (failRegistration) throw Exception('registration failed');
    deviceStatus.status = DeviceDeploymentStatusTypes.Registered;
    return status;
  }

  @override
  Future<PrimaryDeviceDeployment?> getDeviceDeploymentFor(String id, String roleName) async => deployment;

  @override
  Future<StudyDeploymentStatus?> deviceDeployed(String id, String roleName, DateTime updatedOn) async {
    deviceDeployedCalls++;
    return status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('fetches the device deployment when running but not yet held locally '
      '(e.g. after reinstallation)', () async {
    final service = _DeploymentService();
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(service).tryDeployment(study, DefaultDeviceRegistration());

    expect(study.deployment, same(service.deployment));
    expect(service.registerDeviceCalls, 0);
    expect(service.deviceDeployedCalls, 0);
  });

  test('does nothing when running and the deployment is already held locally', () async {
    final service = _DeploymentService();
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone')
      ..deploymentStatusReceived(service.status)
      ..deviceDeploymentReceived(service.deployment);

    await StudyDeploymentProxy(service).tryDeployment(study, DefaultDeviceRegistration());

    expect(service.registerDeviceCalls, 0);
    expect(service.deviceDeployedCalls, 0);
  });

  test('a later status replaces the one held locally, e.g. when stopped', () async {
    final service = _DeploymentService();
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone')..deploymentStatusReceived(service.status);
    final stopped = StudyDeploymentStatus(studyDeploymentId: 'deployment')..status = StudyDeploymentStatusTypes.Stopped;

    study.deploymentStatusReceived(stopped);
    expect(study.status, StudyStatus.Stopped);

    study.deploymentStatusReceived();
    expect(study.status, StudyStatus.Stopped);
  });

  test('continues deployment when registration fails', () async {
    final service = _DeploymentService()
      ..failRegistration = true
      ..status.status = StudyDeploymentStatusTypes.DeployingDevices
      ..deviceStatus.status = DeviceDeploymentStatusTypes.Registered;
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(service).tryDeployment(study, DefaultDeviceRegistration());

    expect(service.registerDeviceCalls, 1);
    expect(study.deployment, same(service.deployment));
    expect(service.deviceDeployedCalls, 1);
  });

  test('registers and acknowledges an unregistered device', () async {
    final service = _DeploymentService();
    service.status.status = StudyDeploymentStatusTypes.DeployingDevices;
    service.deviceStatus.status = DeviceDeploymentStatusTypes.Unregistered;
    final study = Study<PrimaryDeviceDeployment>('deployment', 'phone');

    await StudyDeploymentProxy(service).tryDeployment(study, DefaultDeviceRegistration());

    expect(service.registerDeviceCalls, 1);
    expect(service.deviceDeployedCalls, 1);
  });

  test('sends the registration the device in the deployment accepts', () async {
    final service = _DeploymentService();
    service.status.status = StudyDeploymentStatusTypes.DeployingDevices;
    service.deviceStatus.status = DeviceDeploymentStatusTypes.Unregistered;
    final custom = MACAddressDeviceRegistration(macAddress: '00:11:22:33:44:55');

    await StudyDeploymentProxy(service).tryDeployment(Study<PrimaryDeviceDeployment>('deployment', 'phone'), custom);

    // a CARP Core Smartphone only takes a DefaultDeviceRegistration
    expect(service.registered, isA<DefaultDeviceRegistration>());
    expect(service.registered!.deviceId, custom.deviceId);
    expect(service.registered!.registrationCreatedOn, custom.registrationCreatedOn);
  });

  test('acceptedRegistration only converts for CARP Core devices taking a default registration', () {
    final custom = MACAddressDeviceRegistration(macAddress: '00:11:22:33:44:55');
    final plain = DefaultDeviceRegistration();

    expect(Smartphone().acceptedRegistration(custom), isA<DefaultDeviceRegistration>());
    expect(CustomProtocolDevice().acceptedRegistration(custom), isA<DefaultDeviceRegistration>());
    expect(Smartphone().acceptedRegistration(plain), same(plain));
    expect(BLEHeartRateDevice(roleName: 'hr').acceptedRegistration(custom), same(custom));
    // a device type which is not CARP Core, e.g. a CAMS device
    expect((Smartphone()..$type = 'dk.carp.cams.devices.Smartphone').acceptedRegistration(custom), same(custom));
  });
}
