part of '../../main.dart';

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

/// This is the main Business Logic Component (BLoC) of this sensing app.
/// It holds references to the sensing layer, the current study, deployment
/// mode, etc. It also provides methods to initialize the sensing,
/// add a study, connect to devices, and start/pause/resume sensing.
class SensingBLoC {
  /// The [Sensing] layer used in the app.
  Sensing get sensing => Sensing();

  /// What kind of deployment are we running? Default is local.
  DeploymentMode deploymentMode = DeploymentMode.local;

  /// The study running on this phone.
  SmartphoneStudy? get study => sensing.study;

  /// Initialize the BLoC.
  Future<void> initialize({
    DeploymentMode deploymentMode = DeploymentMode.local,
  }) async {
    Settings().debugLevel = DebugLevel.debug;
    await Settings().init();
    this.deploymentMode = deploymentMode;
    info('$runtimeType initialized');
  }

  /// Add a study to the app based on the current [deploymentMode].
  /// If in local mode, the study protocol is loaded from the local study protocol
  /// manager. If in CAWS mode, the study invitation is retrieved from CAWS.
  Future<void> addStudy(BuildContext context) async {
    SmartphoneStudy? study;
    switch (bloc.deploymentMode) {
      case DeploymentMode.local:
        // Get the protocol from the local study protocol manager.
        // Note that the study id is not used.
        StudyProtocol protocol = await LocalStudyProtocolManager()
            .getStudyProtocol('');

        // Deploy this protocol using the on-phone deployment service.
        var status = await sensing.deploymentService.createStudyDeployment(
          protocol,
        );

        // Create the study using the deployment information.
        study = SmartphoneStudy(
          studyDeploymentId: status.studyDeploymentId,
          deviceRoleName: protocol.primaryDevice.roleName,
        );
        break;
      case DeploymentMode.production:
      case DeploymentMode.test:
      case DeploymentMode.dev:
        // Get the study invitation from CAWS.
        study = await CarpBackend().getStudyInvitation(context);
        break;
    }
    // Now add the study to the sensing client.
    if (study != null) sensing.client.addStudy(study);
  }

  /// Run (start, resume, pause) [study] based on its current state.
  void runStudy() {
    if (study == null) return;

    debug(
      '$runtimeType - Running study - isDeployed: ${study!.isDeployed}, '
      'isSampling: ${study!.isSampling}',
    );

    // If the study has not been started (and deployed) yet, do this before
    // resuming or pausing.
    !study!.isDeployed
        ? sensing.client.start()
        : study!.isSampling
        ? sensing.client.pause()
        : sensing.client.resume();
  }
}
