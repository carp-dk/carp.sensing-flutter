/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../client.dart';

/// Allows managing studies on a client device.
abstract class ClientManager<
  TPrimaryDevice extends PrimaryDeviceConfiguration<TRegistration>,
  TRegistration extends DeviceRegistration,
  TStudy extends Study
> {
  final ClientRepository<TStudy>? _repository;
  DeploymentService? _deploymentService;
  DeviceDataCollectorFactory? _dataCollectorFactory;
  TRegistration? _registration;
  StudyDeploymentProxy? proxy;

  /// Create a new [ClientManager].
  ///
  /// [repository] is used to persist the state of this client.
  /// [deploymentService] is used to manage study deployments.
  /// [dataCollectorFactory] determines which [DeviceDataCollector] to use
  /// to collect data locally on this primary device and is used to create
  /// [ConnectedDeviceDataCollector] instances for connected devices.
  ClientManager({
    ClientRepository<TStudy>? repository,
    DeploymentService? deploymentService,
    DeviceDataCollectorFactory? dataCollectorFactory,
  }) : _repository = repository,
       _deploymentService = deploymentService,
       _dataCollectorFactory = dataCollectorFactory;

  /// Repository within which the state of this client is stored.
  ClientRepository<TStudy> get repository =>
      _repository ??
      (throw NotConfiguredException(
        'ClientManager has not been configured yet. Call configure() first.',
      ));

  /// Get the studies running on this client device.
  List<TStudy> get studies => repository.getStudyList();

  /// The application service through which study deployments, to be run on
  /// this client, can be managed and retrieved.
  DeploymentService get deploymentService =>
      _deploymentService ??
      (throw NotConfiguredException(
        'ClientManager has not been configured yet. Call configure() first.',
      ));

  /// Determines which [DeviceDataCollector] to use to collect data locally on
  /// this primary device and this factory is used to create
  /// [ConnectedDeviceDataCollector] instances for connected devices.
  DeviceDataCollectorFactory? get dataCollectorFactory => _dataCollectorFactory;

  /// The registration of this client.
  TRegistration get registration =>
      _registration ??
      (throw NotConfiguredException(
        'ClientManager has not been configured yet. Call configure() first.',
      ));

  /// Determines whether a [DeviceRegistration] has been configured for this client,
  /// which is necessary to start adding studies.
  bool get isConfigured => repository.deviceRegistration != null;

  /// Makes a check if this client manager is ready for requests.
  void _checkConfiguration() {
    if (!isConfigured) {
      throw NotConfiguredException(
        'ClientManager has not been configured yet. Call configure() first.',
      );
    }
  }

  /// Configure this [ClientManager] by specifying a [registration] for
  /// this client device.
  ///
  /// Optionally, you can specify or override:
  ///  * [deploymentService] - where to get study deployments
  ///  * [dataCollectorFactory] - the factory for creating data collectors
  ///
  /// Throws an [AssertionError] if this client manager has already been configured.
  /// Throws [NotConfiguredException] if after configuration either
  /// [deploymentService] or [dataCollectorFactory] is not set.
  @mustCallSuper
  Future<void> configure({
    required TRegistration registration,
    DeploymentService? deploymentService,
    DeviceDataCollectorFactory? dataCollectorFactory,
  }) async {
    assert(
      !isConfigured,
      'The client manager has already been configured. '
      'Reconfiguring clients is not supported.',
    );

    _registration = registration;
    repository.deviceRegistration = registration;

    // override if specified and not null
    _deploymentService = deploymentService ?? _deploymentService;
    _dataCollectorFactory = dataCollectorFactory ?? _dataCollectorFactory;

    if (_deploymentService == null || _dataCollectorFactory == null) {
      throw NotConfiguredException(
        'Both deploymentService and dataCollectorFactory must be specified '
        'either during construction of the ClientManager or during configure().',
      );
    }

    proxy = StudyDeploymentProxy(this.deploymentService);
  }

  /// Get the status for the studies which run on this client device.
  /// Note that is the current status, and reflects the latest known status.
  /// If you want an updated status from the deployment service, use
  /// [getStudyDeploymentStatus] for each study.
  List<StudyStatus> getStudyStatusList() =>
      studies.map((study) => study.status).toList();

  /// Get the study with [studyDeploymentId] and [deviceRoleName] from this client
  /// manager.
  /// Returns null if no such study has been added.
  TStudy? getStudy(String studyDeploymentId, String deviceRoleName) =>
      repository.getStudy(studyDeploymentId, deviceRoleName);

  /// Add a [study] which needs to be executed on this client.
  /// No deployment is attempted yet.
  ///
  /// If a study with the same deployment id and device role name has already
  /// been added to this client, nothing happens and this study is returned.
  ///
  /// Throws NotConfiguredException if the client has not yet been configured.
  /// Return the study successfully added to this client manager or the existing
  /// study if it was already added.
  @mustCallSuper
  Future<TStudy> addStudy(TStudy study) async {
    _checkConfiguration();
    if (!repository.hasStudy(study)) {
      repository.addStudy(study);

      // Update study status based on deployment status
      await proxy?.getStudyDeploymentStatus(study);
    }
    return study;
  }

  /// Get the deployment status for the [study] from the deployment service.
  /// This updates the study's deployment status and sets the study's status
  /// accordingly.
  /// Returns null if the deployment status could not be retrieved from the
  /// deployment service or if the study has not been added to this client manager.
  @mustCallSuper
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus(TStudy study) async {
    _checkConfiguration();
    if (repository.hasStudy(study)) {
      return await proxy?.getStudyDeploymentStatus(study);
    }
    return null;
  }

  /// Verifies whether the device is ready for deployment of the study runtime
  /// identified by [studyDeploymentId] and [deviceRoleName], and in case it is,
  /// deploys.
  /// In case already deployed, nothing happens and the status of the deployment
  /// is returned.
  ///
  /// Throws NotConfiguredException if the client has not yet been configured.
  /// Throws IllegalArgumentException if a study with the given [studyDeploymentId]
  /// and [deviceRoleName] does not exist or if deployment failed because of unexpected
  /// study deployment ID, device role name, or device registration.
  @mustCallSuper
  Future<StudyStatus> tryDeployment(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    _checkConfiguration();

    var study = getStudy(studyDeploymentId, deviceRoleName);

    if (study == null) {
      throw IllegalArgumentException(
        "A study with the study deployment ID '$studyDeploymentId' "
        "and device role name '$deviceRoleName' was not found. "
        "Has this study been added using the addStudy method?",
      );
    }
    var status = study.status;

    // Early out in case this study has already received and validated
    // deployment information and is running.
    // if (study.status == StudyStatus.Running) return study.status;
    // TODO: Should not check for this? Allow for re-deployment?
    // if (study.isDeployed) return study.status;

    // Try to deploy the study.
    await proxy?.tryDeployment(study, registration);

    var newStatus = study.status;
    if (status != newStatus) repository.updateStudy(study);
    return newStatus;
  }

  /// Remove the study with [studyDeploymentId] and [deviceRoleName] from this
  /// client manager.
  ///
  /// Note that by removing a study, the deployment is not marked as stopped
  /// permanently in the deployment service.
  /// Hence, the study can later be added and deployed again using the [addStudy]
  /// and [tryDeployment] methods.
  ///
  /// If a study deployment is to be permanently stopped, use the [stopStudy] method.
  @mustCallSuper
  Future<void> removeStudy(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    _checkConfiguration();

    var study = getStudy(studyDeploymentId, deviceRoleName);
    if (study != null) {
      repository.removeStudy(study);
    }
  }

  /// Permanently stop collecting data for the study with id [studyDeploymentId]
  /// and mark it as stopped.
  ///
  /// Once a study is stopped it cannot be deployed anymore since it will
  /// be marked as permanently stopped in the deployment service.
  ///
  /// If you want to remove the study from this client and be able to
  /// redeploy it later, use the [removeStudy] method instead.
  /// Note that stopping a study does not remove it from this client manager.
  @mustCallSuper
  Future<StudyStatus> stopStudy(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    _checkConfiguration();

    var study = getStudy(studyDeploymentId, deviceRoleName);

    if (study == null) {
      throw IllegalArgumentException(
        "A study with the study deployment ID '$studyDeploymentId' "
        "and device role name '$deviceRoleName' was not found. "
        "Has this study been added using the addStudy method?",
      );
    }
    var status = study.status;
    await proxy?.stop(study);
    var newStatus = study.status;
    if (status != newStatus) repository.updateStudy(study);

    return newStatus;
  }
}

/// Allows managing studies on a smartphone.
class SmartphoneClient
    extends ClientManager<Smartphone, DeviceRegistration, Study> {
  SmartphoneClient({
    super.repository,
    super.deploymentService,
    super.dataCollectorFactory,
  });
}
