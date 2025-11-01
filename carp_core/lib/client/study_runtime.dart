/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_core_client.dart';

/// Manage data collection for a specific primary device [deployment] on a
/// client device.
class StudyRuntime<TRegistration extends DeviceRegistration> {
  final List<DeviceConfiguration> _remainingDevicesToRegister = [];
  Study? _study;
  TRegistration? _deviceRegistration;
  final DeviceDataCollectorFactory _deviceRegistry;
  final StreamController<StudyStatus> _statusEventsController =
      StreamController();

  /// The study for this study runtime. Set in the [addStudy] method.
  /// `null` if no study has been added yet.
  Study? get study => _study;

  /// The unique device registration for this device.
  /// Set in the [addStudy] method.
  TRegistration? get deviceRegistration => _deviceRegistration;

  /// The study deployment id for the [study] of this study runtime.
  String? get studyDeploymentId => _study?.studyDeploymentId;

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

  /// The latest known deployment status retrieved from the deployment service.
  /// Null if not know.
  StudyDeploymentStatus? deploymentStatus;

  /// The stream of [StudyStatus] events for this study runtime.
  Stream<StudyStatus> get statusEvents => _statusEventsController.stream;

  /// The status of the [study] running on this study runtime.
  StudyStatus get status => _study?.status ?? StudyStatus.DeploymentNotStarted;
  set status(StudyStatus newStatus) {
    _study?.status = newStatus;
    _statusEventsController.add(newStatus);
  }

  /// Has this [StudyRuntime] been initialized?
  bool get isInitialized => (study != null);

  /// Has the device deployment been completed successfully?
  bool get isDeployed => (status.index >= StudyStatus.Deployed.index);

  /// Is the study and data collection running?
  bool get isRunning => (status == StudyStatus.Running);

  /// Has the study and data collection been stopped?
  bool get isStopped => (status == StudyStatus.Stopped);

  /// The list of devices that still remain to be registered before all devices
  /// in this study runtime is registered.
  List<DeviceConfiguration> get remainingDevicesToRegister =>
      _remainingDevicesToRegister;

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
      status = StudyStatus.DeploymentStatusAvailable;
    } catch (error) {
      print(
        "$runtimeType - Could not get deployment with id '${study!.studyDeploymentId}' "
        "from the deployment service: $_deploymentService."
        "\nError: $error",
      );
      status = StudyStatus.DeploymentNotAvailable;
      return deploymentStatus = null;
    }

    // update the status based on the deployment status
    if (deploymentStatus != null) {
      if (deploymentStatus!.isDeploying) {
        status = StudyStatus.Deploying;
      } else if (deploymentStatus!.isAwaitingDeviceRegistrations) {
        status = StudyStatus.AwaitingOtherDeviceRegistrations;
      } else if (deploymentStatus!.isAwaitingDeviceDeployment) {
        status = StudyStatus.AwaitingDeviceDeployment;
      } else if (deploymentStatus!.isRegisteringDevices) {
        status = StudyStatus.RegisteringDevices;
      } else if (deploymentStatus!.isAwaitingOtherDeviceDeployments) {
        status = StudyStatus.AwaitingOtherDeviceDeployments;
      } else if (deploymentStatus!.isDeployed) {
        status = StudyStatus.Deployed;
      }
    }

    return deploymentStatus;
  }

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

    // early out if already deployed.
    if (status.index >= StudyStatus.Deployed.index) return status;

    // check the status of this deployment.
    if (await getStudyDeploymentStatus() == null) return status;

    status = StudyStatus.Deploying;

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

    // get the deployment from the deployment service
    deployment = await _deploymentService.getDeviceDeploymentFor(
      study!.studyDeploymentId,
      study!.deviceRoleName,
    );
    status = StudyStatus.DeviceDeploymentReceived;

    // check for devices that still need to be registered
    if (deploymentStatus != null) {
      for (var deviceStatus in deploymentStatus!.deviceStatusList) {
        if (deviceStatus.status == DeviceDeploymentStatusTypes.Unregistered) {
          _remainingDevicesToRegister.add(deviceStatus.device);
        }
      }
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
  /// in the [_deploymentService].
  ///
  /// This is a convenient method for synchronizing the devices needed for a
  /// deployment and the available devices on this phone.
  Future<void> tryRegisterRemainingDevicesToRegister() async {
    for (var device in remainingDevicesToRegister) {
      await tryRegisterConnectedDevice(device);
    }
  }

  /// Start collecting data for this [StudyRuntime].
  @mustCallSuper
  void start() => status = StudyStatus.Running;

  /// Called when this [StudyRuntime] is disposed.
  /// This entails stopping and disposing all data sampling and storage.
  @mustCallSuper
  void dispose() {}

  /// Called when this [StudyRuntime] is removed from a [ClientManager].
  @mustCallSuper
  Future<void> remove() async {}

  /// Stop collecting data for this [StudyRuntime].
  @mustCallSuper
  Future<void> stop() async => status = StudyStatus.Stopped;
}
