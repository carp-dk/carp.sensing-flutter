part of '../../main.dart';

/// This class implements the sensing layer.
///
/// Call [initialize] to setup a deployment, either locally or using a CAWS
/// deployment.
///
/// Once initialized, the runtime [controller] can be used to
/// control the study execution (e.g., start and stop).
///
/// Collected data is available in the [measurements] stream.
///
/// Works as a singleton, and can be accessed by `Sensing()`.
class Sensing {
  static final Sensing _instance = Sensing._();
  factory Sensing() => _instance;

  Sensing._() : super() {
    CarpMobileSensing.ensureInitialized();

    // Create and register external sampling packages
    SamplingPackageRegistry().register(ConnectivitySamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    SamplingPackageRegistry().register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(AppsSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
    SamplingPackageRegistry().register(ESenseSamplingPackage());
    SamplingPackageRegistry().register(MovisensSamplingPackage());
    SamplingPackageRegistry().register(HealthSamplingPackage());
    // SamplingPackageRegistry().register(MovesenseSamplingPackage());
    // SamplingPackageRegistry().register(CortriumSamplingPackage());

    // Register the CARP data manager for uploading data back to CAWS.
    // This is needed in both LOCAL and CAWS deployments, since a local study
    // protocol may still upload to CAWS
    DataManagerRegistry().register(CarpDataManagerFactory());
  }

  StudyDeploymentStatus? _status;

  DeploymentService? deploymentService;

  /// The study running on this phone.
  Study? study;

  /// The deployment running on this phone.
  /// Only available after [addStudy] is called.
  SmartphoneDeployment? get deployment => controller?.deployment;

  /// Get the latest status of the study deployment.
  StudyDeploymentStatus? get status => _status;

  /// The role name of this device in the deployed study
  String? get deviceRoleName => _status?.primaryDeviceStatus?.device.roleName;

  /// The study runtime controller for this deployment
  SmartphoneDeploymentController? get controller => (study != null)
      ? SmartPhoneClientManager().getStudyRuntime(study!.studyDeploymentId)
      : null;

  /// The stream of all sampled measurements.
  Stream<Measurement> get measurements =>
      controller?.measurements ?? Stream.empty();

  /// the list of running - i.e. used - probes in this study.
  List<Probe> get runningProbes =>
      (controller != null) ? controller!.executor.probes : [];

  /// The list of available devices.
  List<DeviceManager> get availableDevices =>
      SmartPhoneClientManager().deviceController.devices.values.toList();

  /// The list of connected devices.
  List<DeviceManager> get connectedDevices =>
      SmartPhoneClientManager().deviceController.connectedDevices.toList();

  /// The list of devices in the current deployment.
  List<DeviceManager>? get deployedDevices => deployment != null
      ? SmartPhoneClientManager()
          .deviceController
          .devices
          .values
          .where((manager) => deployment!.devices
              .any((registration) => registration.type == manager.type))
          .toList()
      : [];

  /// Initialize and set up sensing.
  Future<void> initialize() async {
    info('Initializing $runtimeType - mode: ${bloc.deploymentMode}');

    switch (bloc.deploymentMode) {
      case DeploymentMode.local:
        // Use the local, phone-based deployment service.
        deploymentService = SmartphoneDeploymentService();

        // Get the protocol from the local study protocol manager.
        // Note that the study id is not used.
        StudyProtocol protocol =
            await LocalStudyProtocolManager().getStudyProtocol('');

        // Deploy this protocol using the on-phone deployment service.
        // Reuse the study deployment id, if this is stored on the phone.
        _status = await SmartphoneDeploymentService().createStudyDeployment(
          protocol,
        );

        // Save the study on the phone for later use.
        bloc.study = SmartphoneStudy(
          studyDeploymentId: _status!.studyDeploymentId,
          deviceRoleName: _status!.primaryDeviceStatus!.device.roleName,
        );

        break;
      case DeploymentMode.production:
      case DeploymentMode.test:
      case DeploymentMode.dev:
        // Use the CARP deployment service which can download a protocol from CAWS
        CarpDeploymentService().configureFrom(CarpService());
        deploymentService = CarpDeploymentService();

        break;
    }

    // Configure the client manager with the deployment service selected above
    // (local or CAWS), add the study, and deploy it.
    await SmartPhoneClientManager().configure(
      deploymentService: deploymentService,
      askForPermissions: true, // Allow the system to request permissions as needed
    );

    study = await SmartPhoneClientManager().addStudy(bloc.study!);
    
    await controller?.tryDeployment(useCached: bloc.useCachedStudyDeployment);
    
    try {
      await controller?.configure().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('Sensing.initialize() - WARNING: Configure timed out after 30 seconds');
          print('Sensing.initialize() - Continuing anyway...');
        },
      );
    } catch (error) {
      print('Sensing.initialize() - ERROR during configure: $error');
    }

    // Listen on the measurements stream and print them as json.
    SmartPhoneClientManager()
        .measurements
        .listen((measurement) => print(toJsonString(measurement)));

    info('$runtimeType initialized');
  }
}
