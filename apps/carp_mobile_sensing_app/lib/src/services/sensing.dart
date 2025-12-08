part of '../../main.dart';

/// This class handles the sensing in the CARP Mobile Sensing framework.
///
/// This class provides easy access to different part of the sensing framework,
/// to be used in the views and view models of the app.
///
/// Works as a singleton, and can be accessed by `Sensing()`.
class Sensing {
  static final Sensing _instance = Sensing._();

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
    SamplingPackageRegistry().register(MovesenseSamplingPackage());
    // SamplingPackageRegistry().register(CortriumSamplingPackage());

    // Register the CARP data manager for uploading data back to CAWS.
    // This is needed in both LOCAL and CAWS deployments, since a local study
    // protocol may still upload to CAWS
    DataManagerRegistry().register(CarpDataManagerFactory());
  }

  factory Sensing() => _instance;

  /// The client manager running on this smartphone.
  SmartPhoneClientManager client = SmartPhoneClientManager();

  /// The study for the currently running study deployment.
  /// Returns `null` if no study is deployed (yet).
  /// If multiple studies are deployed, returns the first one (this app only
  /// supports a single study at a time).
  SmartphoneStudy? get study =>
      client.studies.isEmpty ? null : client.studies.first;

  /// The deployment service used to deploy studies.
  /// If in local deployment mode, this is a [SmartphoneDeploymentService],
  /// otherwise a [CarpDeploymentService].
  DeploymentService get deploymentService =>
      bloc.deploymentMode == DeploymentMode.local
      ? SmartphoneDeploymentService()
      : CarpDeploymentService();

  /// The deployment running on this phone, if the study is deployed.
  SmartphoneDeployment? get deployment => study?.deployment;

  /// The study runtime controller for this [study], if deployed.
  SmartphoneStudyController? get controller =>
      (study != null) ? client.getStudyController(study!) : null;

  /// The total number of measurements sampled so far.
  int samplingSize = 0;

  /// The list of running - i.e. used - probes in this study.
  List<Probe> get runningProbes =>
      (controller != null) ? controller!.executor.probes : [];

  /// The list of devices in the current deployment.
  List<DeviceManager>? get deployedDevices => deployment != null
      ? client.deviceController.devices.values
            .where(
              (manager) => deployment!.devices.any(
                (registration) => registration.type == manager.deviceType,
              ),
            )
            .toList()
      : [];

  /// Initialize and set up sensing.
  Future<void> initialize() async {
    info('Initializing $runtimeType - mode: ${bloc.deploymentMode}');

    // Configure the client manager with the deployment service selected above
    // (local or CAWS).
    await client.configure(
      deploymentService: deploymentService,
      askForPermissions: true,
    );

    // Listen on the measurements stream and count measurements
    // .. and print them as json.
    client.measurements.listen((measurement) {
      samplingSize++;
      print(toJsonString(measurement));
    });

    info('$runtimeType initialized');
  }
}
