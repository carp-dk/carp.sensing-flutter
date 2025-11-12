part of '../../main.dart';

/// This is the main Business Logic Component (BLoC) of this sensing app.
class SensingBLoC {
  static const String STUDY_KEY = 'study';

  SmartphoneStudy? _study;
  bool _useCached = true;
  bool _resumeSensingOnStartup = false;

  /// The [Sensing] layer used in the app.
  Sensing get sensing => Sensing();

  /// What kind of deployment are we running? Default is local.
  DeploymentMode deploymentMode = DeploymentMode.local;

  /// The study for the currently running study deployment.
  /// The study is cached locally on the phone.
  /// Returns `null` if no study is deployed (yet).
  SmartphoneStudy? get study {
    if (_study != null) return _study;
    var jsonString = Settings().preferences?.getString(STUDY_KEY);
    return _study = (jsonString == null)
        ? null
        : _$SmartphoneStudyFromJson(
            json.decode(jsonString) as Map<String, dynamic>);
  }

  set study(SmartphoneStudy? study) {
    assert(
        study != null,
        'Cannot set the study to null in Settings. '
        "Use the 'eraseStudyDeployment()' method to erase study deployment information.");
    _study = study;
    Settings().preferences?.setString(
          STUDY_KEY,
          json.encode(_$SmartphoneStudyToJson(study!)),
        );
  }

  /// Erase all study deployment information cached locally on this phone.
  Future<void> eraseStudyDeployment() async {
    _study = null;
    await Settings().preferences!.remove(STUDY_KEY);
  }

  // Need to create our own JSON serializers here, since SmartphoneStudy is not made serializable
  Map<String, dynamic> _$SmartphoneStudyToJson(SmartphoneStudy study) =>
      <String, dynamic>{
        'studyId': study.studyId,
        'studyDeploymentId': study.studyDeploymentId,
        'deviceRoleName': study.deviceRoleName,
        'participantId': study.participantId,
        'participantRoleName': study.participantRoleName,
      };

  SmartphoneStudy _$SmartphoneStudyFromJson(Map<String, dynamic> json) =>
      SmartphoneStudy(
        studyId: json['studyId'] as String?,
        studyDeploymentId: json['studyDeploymentId'] as String,
        deviceRoleName: json['deviceRoleName'] as String,
        participantId: json['participantId'] as String?,
        participantRoleName: json['participantRoleName'] as String?,
      );

  /// Use the cached study deployment?
  bool get useCachedStudyDeployment => _useCached;

  /// Should sensing be automatically resumed on app startup?
  bool get resumeSensingOnStartup => _resumeSensingOnStartup;

  /// The [SmartphoneDeployment] deployed on this phone.
  SmartphoneDeployment? get deployment => sensing.controller?.deployment;

  /// The preferred format of the data to be uploaded according to
  /// [NameSpace]. Default using the [NameSpace.CARP].
  String dataFormat = NameSpace.CARP;

  StudyDeploymentViewModel? _model;

  /// Get the view model for this study [deployment].
  StudyDeploymentViewModel get studyDeploymentViewModel =>
      _model ??= StudyDeploymentViewModel(deployment!);

  /// Get a list of view models for the running probes.
  Iterable<ProbeViewModel> get runningProbes => bloc.sensing.runningProbes
      .toSet() // only unique probes
      .where((probe) => probe is! StubProbe) // remove stub probes
      .map((probe) => ProbeViewModel(probe));

  /// Get a list of view models for the available devices.
  Iterable<DeviceViewModel> get availableDevices =>
      bloc.sensing.availableDevices.map((device) => DeviceViewModel(device));

  /// Get a list of view models for connected devices.
  Iterable<DeviceViewModel> get connectedDevices =>
      bloc.sensing.connectedDevices.map((device) => DeviceViewModel(device));

  /// The list of all devices in this deployment.
  Iterable<DeviceViewModel> get deployedDevices =>
      bloc.sensing.deployedDevices!.map((device) => DeviceViewModel(device));

  /// Initialize the BLoC.
  Future<void> initialize({
    DeploymentMode deploymentMode = DeploymentMode.local,
    String dataFormat = NameSpace.CARP,
    bool useCachedStudyDeployment = true,
    bool resumeSensingOnStartup = false,
  }) async {
    Settings().debugLevel = DebugLevel.debug;
    await Settings().init();
    this.deploymentMode = deploymentMode;
    this.dataFormat = dataFormat;
    _resumeSensingOnStartup = resumeSensingOnStartup;
    _useCached = useCachedStudyDeployment;

    info('$runtimeType initialized');
  }

  /// Connect to a [device] which is part of the [deployment].
  void connectToDevice(DeviceViewModel device) => SmartPhoneClientManager()
      .deviceController
      .devices[device.type!]!
      .connect();

  void start() {
    SmartPhoneClientManager().notificationController?.createNotification(
          title: 'Sensing Started',
          body:
              'Data sampling is now running in the background. Click the STOP button to stop sampling again.',
        );
    Sensing().controller?.start();
  }

  void stop() {
    SmartPhoneClientManager().notificationController?.createNotification(
          title: 'Sensing Stopped',
          body:
              'Sampling is stopped and no is being collected. Click the START button to restart sampling.',
        );
    Sensing().controller?.executor.stop();
  }

  void dispose() => SmartPhoneClientManager().dispose();

  /// Is sensing running, i.e. has the study executor been started?
  bool get isRunning =>
      Sensing().controller?.executor.state == ExecutorState.started;
}

/// How to deploy a study.
enum DeploymentMode {
  /// Use a local study protocol & deployment and store data locally on the phone.
  local,

  /// Use the CAWS production server to get the study deployment and store data.
  production,

  /// Use the CAWS test server to get the study deployment and store data.
  test,

  /// Use the CAWS development server to get the study deployment and store data.
  dev,
}
