/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of 'carp_core_client.dart';

/// Manage data collection for a [study] linking a specific [deployment] on a
/// primary device
class StudyRuntime<TRegistration extends DeviceRegistration> {
  Study? _study;
  TRegistration? _deviceRegistration;
  final DeviceDataCollectorFactory _deviceRegistry;
  final StreamController<StudyStatus> _statusEventsController =
      StreamController.broadcast();

  /// The study for this study runtime. Set in the [addStudy] method.
  /// `null` if no study has been added yet.
  Study? get study => _study;

  /// The unique device registration for this device.
  /// Set in the [addStudy] method.
  TRegistration? get deviceRegistration => _deviceRegistration;

  /// The study deployment id for the [study] of this study runtime.
  String? get studyDeploymentId => _study?.studyDeploymentId;

  /// The latest known deployment status retrieved from the deployment service.
  /// Null if not know.
  StudyDeploymentStatus? get deploymentStatus => _study?.deploymentStatus;

  /// The primary device deployment for this study runtime.
  ///
  /// Is null if the deployment is not ready.
  /// Use the [tryDeployment] method to retrieve the study deployment from
  /// the deployment service.
  PrimaryDeviceDeployment? deployment;

  /// The device registry that handles the devices used in this runtime.
  DeviceDataCollectorFactory get deviceRegistry => _deviceRegistry;

  /// The deployment service to use to retrieve and manage the study deployment.
  final DeploymentService _deploymentService;

  /// The stream of [StudyStatus] events for this study runtime.
  Stream<StudyStatus> get statusEvents => _statusEventsController.stream;

  /// The status of the [study] running on this study runtime.
  StudyStatus get status => _study?.status ?? StudyStatus.DeploymentNotStarted;

  /// Has this [StudyRuntime] been initialized?
  bool get isInitialized => (study != null);

  /// Has the device deployment been completed successfully?
  bool get isDeployed => (status.index >= StudyStatus.Deployed.index);

  /// Is the study and data collection running?
  bool get isRunning => (status == StudyStatus.Running);

  /// Has the study and data collection been stopped?
  bool get isStopped => (status == StudyStatus.Stopped);

  /// The list of all devices - both primary and connected devices - that remain
  /// to be registered before all devices in this [study] are registered.
  ///
  /// Returns null if the deployment status is not available.
  List<DeviceConfiguration>? get remainingDevicesToRegister =>
      (deploymentStatus == null)
      ? null
      : deploymentStatus!.deviceStatusList
            .where(
              (deviceStatus) =>
                  deviceStatus.status ==
                  DeviceDeploymentStatusTypes.Unregistered,
            )
            .map((deviceStatus) => deviceStatus.device)
            .toList();

  /// Create a new study runtime to manage a study deployment.
  ///
  /// This constructor requires a [DeploymentService] to use to retrieve a study
  /// deployment and a [DeviceDataCollectorFactory] to use as device registry to
  /// handle the devices used for data collection.
  StudyRuntime(this._deploymentService, this._deviceRegistry);

  /// Adds [study] to this study runtime.
  /// The [deviceRegistration] is used in the [tryDeployment] method to register
  /// the device for the study deployment in the deployment service.
  ///
  /// Call [tryDeployment] to subsequently deploy the study.
  Future<void> addStudy(Study study, TRegistration deviceRegistration) async {
    _study = study;
    status = StudyStatus.DeploymentNotStarted;
    _deviceRegistration = deviceRegistration;
  }

  /// Get the deployment status for the [study] from the deployment service.
  /// This updates the [deploymentStatus] and sets the study [status] accordingly.
  ///
  /// Returns null if no [study] has been added yet via the [addStudy] method,
  /// or if the deployment status could not be retrieved from the
  /// deployment service.
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus() async {
    if (study == null) return null;

    // try to get the deployment status from the deployment service
    try {
      deploymentStatus = await _deploymentService.getStudyDeploymentStatus(
        study!.studyDeploymentId,
      );
    } catch (error) {
      print(
        "$runtimeType - Could not get deployment with id '${study!.studyDeploymentId}' "
        "from the deployment service: $_deploymentService."
        "\nError: $error",
      );
      status = StudyStatus.DeploymentNotAvailable;
      deploymentStatus = null;
    }

    return deploymentStatus;
  }

  /// The [DeviceDeploymentStatus] for the primary device of this [study]
  /// (typically this phone).
  ///
  /// Returns null if no study has been added yet, or if no deployment status
  /// is available yet. Call [getStudyDeploymentStatus] to retrieve the
  /// deployment status from the deployment service.
  DeviceDeploymentStatus? get primaryDeviceStatus => (study == null)
      ? null
      : deploymentStatus?.getDeviceStatusByRoleName(study!.deviceRoleName);

  /// Tries to deploy the [study] if it's ready to be deployed by registering
  /// the client device using [deviceRegistration] and verifying the study is
  /// supported on this device.
  ///
  /// Deployment entails trying to retrieve the [deployment] from the [_deploymentService],
  /// based on the [studyDeploymentId].
  ///
  /// In case already deployed, nothing happens.
  Future<StudyStatus> tryDeployment() async {
    assert(
      study != null,
      'Cannot deploy without a valid study deployment id and device role name. '
      "Call 'configure()' first.",
    );

    // check the status of this deployment - early out if no status is available
    if (await getStudyDeploymentStatus() == null) return status;

    // early out if already deployed, running or stopped.
    if (status.index >= StudyStatus.Deployed.index) return status;

    // register the primary device for the given study deployment
    try {
      deploymentStatus = await _deploymentService.registerDevice(
        study!.studyDeploymentId,
        study!.deviceRoleName,
        deviceRegistration!,
      );
    } catch (error) {
      // we only print a warning - this device may already be registered
      print(
        "$runtimeType - Error registering '${study!.deviceRoleName}' as primary device.\n$error",
      );
    }

    // check if the primary device is ready for deployment - early out if not
    if (!(primaryDeviceStatus?.isReadyForDeployment ?? false)) return status;

    print("$runtimeType - Trying to get deployment...");

    // get the deployment from the deployment service
    deployment = await _deploymentService.getDeviceDeploymentFor(
      study!.studyDeploymentId,
      study!.deviceRoleName,
    );

    print("$runtimeType - DEPLOYMENT RECEIVED:\n$deployment");

    if (deployment == null) {
      print(
        "$runtimeType - Deployment for device role name '${study!.deviceRoleName}' "
        "in study deployment '${study!.studyDeploymentId}' is not available.",
      );
      return status = StudyStatus.DeploymentNotAvailable;
    }

    // mark this deployment as successful
    try {
      await _deploymentService.deviceDeployed(
        study!.studyDeploymentId,
        study!.deviceRoleName,
        deployment?.lastUpdatedOn ?? DateTime.now(),
      );
    } catch (error) {
      // we only print a warning
      // see issue #50 - there is a bug in CAWS
      print(
        "$runtimeType - Error marking deployment '${study!.studyDeploymentId}' as deployed.\n$error",
      );
    }
    print(
      "$runtimeType - Study deployment '${study!.studyDeploymentId}' successfully deployed.",
    );

    return status = StudyStatus.Deployed;
  }

  /// Tries to register the connected [device] with the deployment service.
  /// The [device] must be available in this device's device registry.
  Future<void> tryRegisterConnectedDevice(DeviceConfiguration device) async {
    assert(
      study != null,
      "Cannot register a device without a valid study deployment. "
      "Call 'configure()' first.",
    );

    String deviceType = device.type;
    String? deviceRoleName = device.roleName;

    if (_deviceRegistry.hasDevice(deviceType)) {
      DeviceDataCollector deviceManager = _deviceRegistry.getDevice(
        deviceType,
      )!;

      // create a registration based on the device manager's unique id and name of the device
      var registration = deviceManager.configuration?.createRegistration(
        deviceId: deviceManager.id,
        deviceDisplayName: deviceManager.displayName,
      );

      if (registration != null) {
        try {
          deploymentStatus = (await _deploymentService.registerDevice(
            study!.studyDeploymentId,
            deviceRoleName,
            registration,
          ));
        } catch (error) {
          print(
            "$runtimeType - failed to register device with role name "
            "'$deviceRoleName' for study deployment '${study!.studyDeploymentId}' "
            "at deployment service '$_deploymentService'.\n"
            "Error: $error\n"
            "Continuing without registration.",
          );
        }
      }
    }
  }

  /// Tries to register the connected devices which still need to be registered
  /// in the deployment service.
  ///
  /// This is a convenient method for synchronizing the devices needed for a
  /// deployment and the available devices on this phone.
  Future<void> tryRegisterRemainingDevicesToRegister() async =>
      remainingDevicesToRegister?.forEach((device) async {
        await tryRegisterConnectedDevice(device);
      });

  /// Start this [study].
  @mustCallSuper
  void start() => status = StudyStatus.Running;

  /// Called when this [StudyRuntime] is disposed.
  /// This entails stopping and disposing all data sampling and storage.
  @mustCallSuper
  void dispose() {}

  /// Called when this [StudyRuntime] is removed from a [ClientManager].
  @mustCallSuper
  Future<void> remove() async {}

  /// Permanently stop this [study].
  ///
  /// Note that will mark the study as stopped in the deployment service.
  /// Once stopped, a study cannot be restarted.
  @mustCallSuper
  Future<void> stop() async {
    // Early out in case study has already been stopped.
    if (deploymentStatus?.status == StudyDeploymentStatusTypes.Stopped) return;

    try {
      deploymentStatus = (await _deploymentService.stop(
        study!.studyDeploymentId,
      ));
    } catch (error) {
      print(
        "$runtimeType - failed to stop study for study deployment '${study!.studyDeploymentId}' "
        "at deployment service '$_deploymentService'.\n"
        "Stopping the study locally only.\n"
        "Error: $error",
      );
    }

    status = StudyStatus.Stopped;
  }
}
