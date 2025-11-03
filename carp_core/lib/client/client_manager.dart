/*
 * Copyright 2021-2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_core_client.dart';

/// Allows managing studies on a client device.
///
/// It holds a list of [studies] added to this client and holds a [repository]
/// of corresponding [StudyRuntime] for executing a study.
abstract class ClientManager<
  TPrimaryDevice extends PrimaryDeviceConfiguration<TRegistration>,
  TRegistration extends DeviceRegistration
> {
  DeploymentService? _deploymentService;
  DeviceDataCollectorFactory? _deviceController;

  /// All studies added to this client mapped to the study deployment ID.
  Map<String, Study> studies = {};

  /// Repository of [StudyRuntime] mapped to the study deployment ID.
  Map<String, StudyRuntime> repository = {};

  /// The registration of this client.
  TRegistration? registration;

  /// The application service through which study deployments, to be run on
  /// this client, can be managed and retrieved.
  DeploymentService? get deploymentService => _deploymentService;

  /// The controller of connected devices used to collect data locally on
  /// this primary device. Also works as a factory which is used to create
  /// [DeviceDataCollector] instances for connected devices.
  DeviceDataCollectorFactory? get deviceController => _deviceController;

  /// Get the [StudyRuntime] for a [studyDeploymentId].
  StudyRuntime? getStudyRuntime(String studyDeploymentId) =>
      repository[studyDeploymentId];

  /// Determines whether a [DeviceRegistration] has been configured for this client,
  /// which is necessary to start adding [StudyRuntime]s.
  bool get isConfigured =>
      (deploymentService != null) &&
      (deviceController != null) &&
      (registration != null);

  /// Configure this [ClientManager] by specifying:
  ///  * [deploymentService] - where to get study deployments
  ///  * [deviceController] that handles devices connected to this client
  ///  * [registration] - a unique device registration for this client device
  @mustCallSuper
  Future<void> configure({
    required DeploymentService deploymentService,
    required DeviceDataCollectorFactory deviceController,
    TRegistration? registration,
  }) async {
    _deploymentService = deploymentService;
    _deviceController = deviceController;
    this.registration = registration;
  }

  /// Get the status for the studies which run on this client device.
  List<StudyStatus> getStudyStatusList() =>
      repository.values.map((study) => study.status) as List<StudyStatus>;

  /// Add a study which needs to be executed on this client.
  /// This involves registering this device for the specified study deployment.
  ///
  /// A [Study] specifies:
  ///
  ///  * [studyDeploymentId] - The ID of a study which has been deployed already
  ///    and for which to collect data.
  ///  * [deviceRoleName] - The role which the client device this runtime is
  ///    intended for plays as part of the deployment identified by [studyDeploymentId].
  ///
  /// Returns the added study.
  @mustCallSuper
  Future<Study> addStudy(Study study) async {
    assert(
      isConfigured,
      'The client manager has not been configured yet. Call configure() first.',
    );
    assert(
      !repository.containsKey(study.studyDeploymentId),
      'A study with the same study deployment ID and device role name has already been added.',
    );
    studies[study.studyDeploymentId] = study;

    return study;
  }

  /// Verifies whether the device is ready for deployment of the study runtime
  /// identified by [study], and in case it is, deploys.
  /// In case already deployed, nothing happens and the status of the deployment
  /// is returned.
  @mustCallSuper
  Future<StudyStatus> tryDeployment(String studyDeploymentId) async {
    StudyRuntime? runtime = repository[studyDeploymentId];
    assert(
      runtime != null && runtime.study != null,
      'No runtime for this study found. Has this study been added using the addStudy method?',
    );

    // Early out in case this runtime has already received and validated deployment information.
    if (runtime!.status.index >= StudyStatus.Deployed.index) {
      return runtime.status;
    }

    return await runtime.tryDeployment();
  }

  /// Remove the study with [studyDeploymentId] from this client manager.
  ///
  /// Note that by removing a study, the deployment is not marked as stopped
  /// permanently in the deployment service.
  /// Hence, the study can later be added and deployed again using the [addStudy]
  /// and [tryDeployment] methods.
  ///
  /// If a study deployment is to be permanently stopped, use the [stopStudy] method.
  @mustCallSuper
  Future<void> removeStudy(String studyDeploymentId) async {
    var runtime = repository[studyDeploymentId];
    repository.remove(studyDeploymentId);
    if (runtime != null) await runtime.remove();
  }

  /// Permanently stop collecting data for [study] and mark it as stopped.
  ///
  /// Once a study is stopped it cannot be deployed anymore since it will
  /// be marked as permanently stopped in the [DeploymentService].
  ///
  /// If you only want to remove the study from this client and be able to
  /// redeploy it later, use the [removeStudy] method instead.
  @mustCallSuper
  Future<void> stopStudy(String studyDeploymentId) async {
    var runtime = repository[studyDeploymentId];

    if (runtime != null) {
      await runtime.stop();
      await removeStudy(studyDeploymentId);

      // Permanently stop this study deployment on the deployment service.
      await deploymentService?.stop(studyDeploymentId);
    }
  }
}

/// Allows managing studies on a smartphone.
class SmartphoneClient extends ClientManager<Smartphone, DeviceRegistration> {
  SmartphoneClient();
}
