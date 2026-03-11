/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */
part of '../runtime.dart';

/// Controls the runtime execution of a [SmartphoneStudy].
///
/// A [SmartphoneStudyController] is responsible for:
///  * Orchestrating the lifecycle of a [SmartphoneDeploymentExecutor]
///  * Configuring the [DataManager] based on the study's [DataEndPoint]
///  * Requesting OS permissions needed for sampling
///  * Transforming collected [Measurement]s using the privacy schema and
///    preferred data format specified in the deployment
///
/// Access via [SmartPhoneClientManager.getStudyController].
class SmartphoneStudyController {
  final SmartphoneStudy _study;
  DataManager? _dataManager;
  final SmartphoneDeploymentExecutor _executor = SmartphoneDeploymentExecutor();
  Map<Permission, PermissionStatus>? _permissions;

  /// Create a new [SmartphoneStudyController] to control the runtime behavior
  /// of a [study].
  SmartphoneStudyController(SmartphoneStudy study) : _study = study {
    // listen to study events and handle deployment updates
    study.events.listen((event) {
      switch (event.event) {
        case StudyStatusEventTypes.DeploymentStatusReceived:
          _deploymentStatusReceived();
          break;
        case StudyStatusEventTypes.DeviceDeploymentReceived:
          _deviceDeploymentReceived();
          break;
        default:
          break;
      }
    });

    // Keep the sampling state updated.
    executor.stateEvents.listen(
      (state) => study.samplingState = executor.samplingState,
    );
  }

  /// The study that this [SmartphoneStudyController] controls
  SmartphoneStudy get study => _study;

  /// The deployment associated with this [study].
  SmartphoneDeployment? get deployment => study.deployment;

  /// The list of all devices - both primary and connected devices - that remain
  /// to be registered before all devices in this [study] are registered.
  ///
  /// Returns an empty list if the deployment status is not available yet.
  List<DeviceConfiguration> get remainingDevicesToRegister =>
      (study.deploymentStatus == null)
      ? []
      : study.deploymentStatus!.deviceStatusList
            .where(
              (deviceStatus) =>
                  deviceStatus.status ==
                  DeviceDeploymentStatusTypes.Unregistered,
            )
            .map((deviceStatus) => deviceStatus.device)
            .toList();

  DeviceController get _deviceController =>
      SmartPhoneClientManager().deviceController;

  DeploymentService get _deploymentService =>
      SmartPhoneClientManager().deploymentService;

  /// The permissions granted to this client from the OS.
  Map<Permission, PermissionStatus> get permissions => _permissions ?? {};

  /// The executor executing the [deployment].
  SmartphoneDeploymentExecutor get executor => _executor;

  /// The configuration of the data endpoint, i.e. how data is saved or uploaded.
  /// Can be null, in which case data is still sampled and can be used in the app,
  /// but is not saved.
  DataEndPoint? get dataEndPoint => deployment?.dataEndPoint;

  /// The data manager responsible for handling the data collected by this controller.
  DataManager? get dataManager => _dataManager;

  /// The privacy schema used to encrypt data before upload.
  String get privacySchemaName =>
      deployment?.privacySchemaName ?? NameSpace.CARP;

  /// The stream of all sampled measurements.
  ///
  /// Data in the [measurements] stream are transformed in the following order:
  ///   1. privacy schema as specified in the [privacySchemaName]
  ///   2. preferred data format as specified by [DataEndPoint.dataFormat] in the
  ///      original protocol.
  ///
  /// This is a broadcast stream and supports multiple subscribers.
  Stream<Measurement> get measurements => _executor.measurements.distinct().map(
    (measurement) => measurement
      ..data = DataTransformerSchemaRegistry()
          .lookup(deployment?.dataEndPoint?.dataFormat ?? NameSpace.CARP)!
          .transform(
            DataTransformerSchemaRegistry()
                .lookup(privacySchemaName)!
                .transform(measurement.data),
          ),
  );

  /// A stream of all [measurements] of a specific data [type].
  Stream<Measurement> measurementsByType(String type) => measurements.where(
    (measurement) => measurement.data.dataType.toString() == type,
  );

  /// Handles updates of the [deployment] status.
  Future<void> _deploymentStatusReceived() async {}

  /// Handles the reception of a new or updated [deployment].
  ///
  /// This entails configuring devices, data manager, and executor to get
  /// ready to handle sampling of data. Data sampling is started if the
  /// [SmartphoneStudy.samplingState] is in a resumed state.
  Future<void> _deviceDeploymentReceived() async {
    debug(
      '$runtimeType - Received device deployment: ${deployment?.studyDeploymentId}',
    );
    // fast out if study has been stopped
    if (study.status == StudyStatus.Stopped) {
      info('$runtimeType - Study has been stopped and cannot be started.');
      return;
    }

    // fast out if no deployment information yet
    if (deployment == null) {
      info('$runtimeType - No deployment information available yet.');
      return;
    }

    info('$runtimeType - Configuring based on new deployment information...');

    // Try to register the remaining connected devices with the deployment service.
    // Note that we allow this to run asynchronously, since this is not critical to
    // deploying this study.
    tryRegisterRemainingDevicesToRegister();

    // Initialize the data manager
    if (dataEndPoint != null) {
      _dataManager = DataManagerRegistry().create(dataEndPoint!.type);
    }

    if (_dataManager == null) {
      warning(
        "No data manager for the specified data endpoint found: '$dataEndPoint'. "
        "Data sampling will still start, but no data will be saved.",
      );
    }

    await _dataManager?.configure(
      dataEndPoint: dataEndPoint!,
      deployment: deployment!,
      measurements: measurements,
    );

    // Initialize all devices from the deployment, incl. this smartphone.
    _configureAllDevices();

    // Initialize the executor, which recursively initializes all executors and probes.
    // But before doing this, save any existing sampling status which might have
    // been loaded, so that we can properly resume sampling.
    var existingSamplingStatus = study.samplingState;
    _executor.initialize(deployment!, deployment!);
    _executor.setSamplingState(existingSamplingStatus);

    // Connect to all connectable devices, incl. this phone.
    // (Re-)connecting a device will trigger that sampling is (re)started
    await _connectAllConnectableDevices();

    // start the study and restart data sampling
    study.samplingState = existingSamplingStatus;
    start();

    var statusMsg =
        '===============================================================\n'
        '  CARP Mobile Sensing (CAMS) - $runtimeType\n'
        '===============================================================\n'
        '  study status : ${study.status.name}\n'
        ' deployment id : ${deployment?.studyDeploymentId}\n'
        ' deployed time : ${deployment?.deployed}\n'
        '     role name : ${deployment?.deviceConfiguration.roleName}\n'
        '      platform : ${DeviceInfoService().platform.toString()}\n'
        '     device ID : ${DeviceInfoService().deviceID.toString()}\n'
        ' data endpoint : ${dataEndPoint?.type}\n'
        '  data manager : $_dataManager\n'
        '===============================================================\n';
    debugPrint(statusMsg);
  }

  /// Tries to register the connected [device] with the deployment service.
  /// The [device] must be available in the device controller.
  Future<void> tryRegisterConnectedDevice(DeviceConfiguration device) async {
    final deviceType = device.type;
    final deviceRoleName = device.roleName;

    info(
      "$runtimeType - Trying to register device with role name "
      "'$deviceRoleName' for study deployment '${study.studyDeploymentId}'.",
    );

    // Check if this phone has this type of device.
    if (_deviceController.hasDevice(deviceType)) {
      DeviceManager deviceManager = _deviceController.getDeviceManager(
        deviceType,
      )!;

      DeviceRegistration registration = deviceManager.createRegistration();

      try {
        final deploymentStatus = await _deploymentService.registerDevice(
          study.studyDeploymentId,
          deviceRoleName,
          registration,
        );

        // Also update local deployment information about the connected device registrations,
        // so that it is in sync with the deployment service.
        if (device is! PrimaryDeviceConfiguration) {
          deployment?.connectedDeviceRegistrations[deviceRoleName] =
              registration;
        }
        study.deploymentStatusReceived(deploymentStatus);
      } catch (error) {
        warning(
          "$runtimeType - Failed to register device with role name "
          "'$deviceRoleName' for study deployment '${study.studyDeploymentId}' "
          "at deployment service '$_deploymentService'.\n"
          "Error: $error\n"
          "Continuing without registration.",
        );
      }
    } else {
      warning(
        "$runtimeType - Trying to register device of type '$deviceType' playing the role "
        "'$deviceRoleName' for study deployment '${study.studyDeploymentId}'. "
        "But this smartphone does not have such a type of device."
        "Continuing without registration.",
      );
    }
  }

  /// Tries to register the connected devices which still need to be registered
  /// in the deployment service.
  ///
  /// This is a convenient method for synchronizing the devices needed for a
  /// deployment and the available devices on this phone.
  Future<void> tryRegisterRemainingDevicesToRegister() async =>
      remainingDevicesToRegister.forEach((device) async {
        await tryRegisterConnectedDevice(device);
      });

  /// Tries to unregister the disconnected [device] with the deployment service.
  Future<void> tryUnregisterDisconnectedDevice(
    DeviceConfiguration device,
  ) async {
    final deviceRoleName = device.roleName;

    info(
      "$runtimeType - Trying to unregister device with role name "
      "'$deviceRoleName' for study deployment '${study.studyDeploymentId}'.",
    );

    try {
      final deploymentStatus = await _deploymentService.unregisterDevice(
        study.studyDeploymentId,
        deviceRoleName,
      );

      // Also update local deployment information about the connected device registrations,
      // so that it is in sync with the deployment service.
      if (device is! PrimaryDeviceConfiguration) {
        deployment?.connectedDeviceRegistrations.remove(deviceRoleName);
      }
      study.deploymentStatusReceived(deploymentStatus);
    } catch (error) {
      warning(
        "$runtimeType - Failed to unregister device with role name "
        "'$deviceRoleName' for study deployment '${study.studyDeploymentId}' "
        "at deployment service '$_deploymentService'.\n"
        "Error: $error\n"
        "Continuing without un-registration.",
      );
    }
  }

  /// Tries to re-register the [device] with the deployment service.
  /// This entails trying to unregister the device and then trying to register
  /// it again.
  Future<void> tryReregisterDevice(DeviceConfiguration device) async {
    await tryUnregisterDisconnectedDevice(device);
    // Wait for a few seconds before trying to register the device again,
    // to give the deployment service some time to process the un-registration.
    Future.delayed(
      Duration(seconds: 5),
      () async => await tryRegisterConnectedDevice(device),
    );
  }

  /// Asking for permissions for all the measures included in this
  /// [study].
  ///
  /// Since we only ask for permission relevant to the deployment, this method
  /// should be called after deployment has taken place but before this controller
  /// is started.
  ///
  /// This method is only relevant on Android, and does nothing on iOS.
  /// iOS automatically asks for permissions when a resource is accessed.
  Future<void> _askForAllPermissions() async {
    if (deployment == null) {
      warning(
        '$runtimeType - No deployment available. Skipping requesting permissions.',
      );
      return;
    }
    if (Platform.isIOS) {
      warning(
        '$runtimeType - Requesting all permissions at once is not feasible on iOS. Skipping this.',
      );
      return;
    }

    Set<Permission> permissions = {};

    for (var measure in deployment?.measures ?? <Measure>[]) {
      var schema = SamplingPackageRegistry().samplingSchemes[measure.type];
      if (schema != null && schema.dataType is CamsDataTypeMetaData) {
        permissions.addAll(
          (schema.dataType as CamsDataTypeMetaData).permissions,
        );
      }
    }

    debug(
      '$runtimeType - Required permissions for this deployment: $permissions',
    );

    if (permissions.isNotEmpty) {
      // Never ask for location permissions.
      // Will mess it up when requesting multiple permissions at once.
      permissions
        ..remove(Permission.location)
        ..remove(Permission.locationWhenInUse)
        ..remove(Permission.locationAlways);

      try {
        info(
          '$runtimeType - Asking for permissions for all measures in this deployment - status:',
        );
        _permissions = await permissions.toList().request();

        _permissions?.forEach(
          (permission, status) => info(
            ' - ${permission.toString().split('.').last} : ${status.name}',
          ),
        );
      } catch (error) {
        warning('$runtimeType - Error requesting permissions - error: $error');
      }
    }
  }

  /// Configure all devices in this [deployment].
  void _configureAllDevices() {
    assert(deployment != null, 'Deployment is null.');

    for (var configuration in deployment!.devices) {
      _configureDevice(configuration);
    }
  }

  /// Configure the device specified in [configuration].
  void _configureDevice(DeviceConfiguration configuration) {
    // Fast out if this device is not available on this phone.
    if (!_deviceController.hasDevice(configuration.type)) {
      warning(
        "$runtimeType - A device of type '${configuration.type}' is not available on this device. "
        "This may be because this device is not available on this operating system. "
        "Or it may be because the sampling package containing this device has not been "
        "registered in the SamplingPackageRegistry.",
      );
      return;
    }

    var manager = _deviceController.devices[configuration.type];

    // Listen to status events for this device manager and try to re-register
    // the device with the deployment service when a real device is connected.
    manager?.statusEvents
        .where((status) => status == DeviceStatus.connected)
        .listen((_) => tryReregisterDevice(configuration));

    // Now configure the device incl. any pre-registration information from the deployment
    var registration =
        deployment?.connectedDeviceRegistrations[configuration.roleName];
    manager?.configure(configuration, registration);
  }

  /// Start connecting all connectable devices to be used in the [deployment]
  /// and which are available on this phone.
  ///
  /// Connecting a device will trigger that sampling is (re)started.
  /// Note that this method is called in the [_deviceDeploymentReceived] method,
  /// which is called when a new deployment is received.
  Future<void> _connectAllConnectableDevices() async {
    assert(deployment != null, 'Deployment is null.');

    debug('$runtimeType - Trying to connect to all connectable devices.');

    // connect all the connected devices and the primary device (i.e. this phone)
    for (var configuration in deployment?.devices ?? <DeviceConfiguration>[]) {
      var device = _deviceController.getDeviceManager(configuration.type);
      debug(
        '$runtimeType - Checking to connect to device $device with canConnect '
        "'${device?.canConnect}' and shouldConnect '${device?.shouldConnect}'...",
      );
      if (device != null && device.canConnect && device.shouldConnect) {
        await device.connect();
      }
    }
  }

  /// Start data collection using this controller.
  ///
  /// Will attempt to deploy this [study] if not already done.
  ///
  /// Will resume data collection if the [study]'s samplingStatus is `Resumed`.
  /// If not, sampling can be started later by calling the [resume] method.
  Future<void> start() async {
    if (study.status == StudyStatus.Stopped) {
      warning(
        '$runtimeType - Study has been stopped. Will not start data sampling.',
      );
      return;
    }

    info(
      '$runtimeType - Starting data sampling for study deployment: ${study.studyDeploymentId}',
    );

    // If this study has not yet been deployed, do this first.
    if (!study.isDeployed) {
      debug('$runtimeType - Study not yet deployed - trying to deploy...');
      await SmartPhoneClientManager().tryDeployment(
        study.studyDeploymentId,
        study.deviceRoleName,
      );
    }

    // Ask for permissions for all measures in this deployment
    if (SmartPhoneClientManager().askForPermissions) {
      await _askForAllPermissions();
    }

    // TODO - why this model? The AppTaskController should be responsible for restoring itself... - just like sampling state
    // Restore the app task controller state for this study.
    await AppTaskController()._restoreQueue(study);

    // Finally, resume/pause data sampling based on the current sampling state of this study.
    if (study.samplingState?.state == ExecutorState.Resumed) {
      debug('$runtimeType - Restarting sampling in 15 seconds...');
      Future.delayed(Duration(seconds: 15), () => resume());
    } else if (study.samplingState?.state == ExecutorState.Paused) {
      pause();
    }
  }

  // Restart data sampling, ignoring any previously stored sampling state.
  void restart() => executor
    ..clearSamplingStatus()
    ..resume();

  /// Resume data sampling for the [study] controlled by this controller.
  /// Will resume data sampling based on the current sampling state of this study.
  /// If you want to restart sampling and ignore any previously stored sampling state,
  /// call the [restart] method instead.
  void resume() => executor.resume();

  /// Pause data sampling.
  void pause() => executor.pause();

  /// Called when this controller is disposed.
  ///
  /// This entails:
  ///   * pausing data sampling
  ///   * closing the data manager (e.g., flushing data to a file)
  ///
  /// Note that all cached deployment information and any data sampled
  /// from this deployment will remain on the phone.
  ///
  /// When this method is called, the controller is never used again. It is an error
  /// to call any of the [start] or [stop] methods at this point.
  @mustCallSuper
  void dispose() {
    info('$runtimeType - Disposing study from this smartphone...');
    pause();
    dataManager?.close();
  }
}
