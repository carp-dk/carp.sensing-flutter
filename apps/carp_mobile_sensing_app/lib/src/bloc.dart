part of '../main.dart';

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
  /// Create the BLoC, optionally specifying the [deploymentMode], [debugLevel],
  /// and [primaryDeviceType].
  SensingBLoC({
    this.deploymentMode = DeploymentMode.local,
    DebugLevel debugLevel = DebugLevel.warning,
  }) {
    Settings().debugLevel = debugLevel;
  }

  /// The [Sensing] layer used in the app.
  Sensing get sensing => Sensing();

  /// What kind of deployment are we running? Default is local.
  DeploymentMode deploymentMode = DeploymentMode.local;

  /// The study running on this phone.
  SmartphoneStudy? get study => sensing.study;

  /// Is sampling running, i.e. has the study executor been started?
  bool get isSampling =>
      sensing.controller?.executor.state == ExecutorState.Resumed;

  /// Add a study to the app based on the current [deploymentMode].
  /// If in local mode, the study protocol is loaded from the local study protocol
  /// manager. If in CAWS mode, the study invitation is retrieved from CAWS.
  Future<void> addStudy(BuildContext context) async {
    switch (deploymentMode) {
      case DeploymentMode.local:
        // Get the protocol from the local study protocol manager.
        // Note that the study id is not used.
        StudyProtocol protocol = await LocalStudyProtocolManager()
            .getStudyProtocol('');

        // Add the study from the protocol to the sensing client.
        await sensing.client.addStudyFromProtocol(protocol);

        break;
      case DeploymentMode.production:
      case DeploymentMode.test:
      case DeploymentMode.dev:
        // Get the study invitation from CAWS.
        var invitation = await CarpBackend().getStudyInvitation(context);
        debug('$runtimeType >> Study invitation: ${invitation?.toJson()}');
        if (invitation != null) {
          await sensing.client.addStudyFromInvitation(invitation);
        }

        break;
    }
  }

  /// Run (start, resume, pause) [study] based on its current state.
  void runStudy() {
    if (study == null) return;

    // If the study has not been deployed yet, do this before
    // resuming or pausing.
    !study!.isDeployed
        ? sensing.deploy()
        : isSampling
        ? sensing.pause()
        : sensing.resume();
  }
}
