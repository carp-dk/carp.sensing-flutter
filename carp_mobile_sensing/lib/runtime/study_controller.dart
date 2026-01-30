/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */
part of '../runtime.dart';

/// A [SmartphoneStudyController] controls the execution of a [SmartphoneStudy].
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
      debug('$runtimeType >> event: ${event.event}');
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

    // Keep the sampling status updated.
    executor.stateEvents.listen((state) => study.samplingStatus = state);
    debug(
      '$runtimeType created for study deployment: ${study.deployment?.studyDeploymentId}',
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

  /// The transformer used to transform data before upload.
  ///
  /// The [transformer] is a generic [DataTransformer] function which transform
  /// each collected measurement. If not specified, a 1:1 mapping is done,
  /// i.e. no transformation.
  DataTransformer get transformer => ((data) => data);

  // TODO - create a new transformer configuration model
  // _transformer = transformer ?? ((data) => data);

  /// The stream of all sampled measurements.
  ///
  /// Data in the [measurements] stream are transformed in the following order:
  ///   1. privacy schema as specified in the [privacySchemaName]
  ///   2. preferred data format as specified by [dataFormat] in the
  ///      [SmartphoneDeployment.dataEndPoint]
  ///   3. any custom [transformer] provided in the [configure] method when
  ///      configuring this controller
  ///
  /// This is a broadcast stream and supports multiple subscribers.
  Stream<Measurement> get measurements => _executor.measurements.distinct().map(
    (measurement) => measurement
      ..data = transformer(
        DataTransformerSchemaRegistry()
            .lookup(deployment?.dataEndPoint?.dataFormat ?? NameSpace.CARP)!
            .transform(
              DataTransformerSchemaRegistry()
                  .lookup(privacySchemaName)!
                  .transform(measurement.data),
            ),
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
  /// [SmartphoneStudy.samplingStatus] is in a resumed state.
  Future<void> _deviceDeploymentReceived() async {
    debug(
      '$runtimeType >> Received device deployment: ${deployment?.studyDeploymentId}',
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

    await _dataManager?.initialize(
      deployment!.dataEndPoint!,
      deployment!,
      measurements,
    );

    // Initialize all devices from the deployment, incl. this smartphone.
    _initializeDevices();

    // Initialize the executor, which recursively initializes all executors and probes.
    // But before doing this, save any existing sampling status which might have
    // been loaded, so that we can properly resume sampling.
    var existingSamplingStatus = study.samplingStatus;
    _executor.initialize(deployment!, deployment!);

    // Connect to all connectable devices, incl. this phone.
    // (Re-)connecting a device will trigger that sampling is (re)started
    await connectAllConnectableDevices();

    // start heartbeat monitoring
    if (SmartPhoneClientManager().heartbeat) _startHeartbeatMonitoring();

    // debug print all measurements - TODO: remove this later
    measurements.listen(
      (measurement) =>
          debugPrint('>> ${study.studyDeploymentId} - ${measurement.dataType}'),
    );

    // start data sampling
    study.samplingStatus = existingSamplingStatus;
    start();

    var statusMsg =
        '===============================================================\n'
        '  CARP Mobile Sensing (CAMS) - $runtimeType\n'
        '===============================================================\n'
        '  study status : ${study.status.name}\n'
        ' deployment id : ${deployment?.studyDeploymentId}\n'
        ' deployed time : ${deployment?.deployed}\n'
        '     role name : ${deployment?.deviceConfiguration.roleName}\n'
        '      platform : ${DeviceInfo().platform.toString()}\n'
        '     device ID : ${DeviceInfo().deviceID.toString()}\n'
        ' data endpoint : ${dataEndPoint?.type}\n'
        '  data manager : $_dataManager\n'
        '===============================================================\n';
    debugPrint(statusMsg);
  }

  /// Tries to register the connected [device] with the deployment service.
  /// The [device] must be available in this [SmartPhoneClientManager] device controller.
  Future<void> tryRegisterConnectedDevice(DeviceConfiguration device) async {
    if (device is PrimaryDeviceConfiguration) {
      warning(
        '$runtimeType - Trying to register a primary device as a connected device. Skipping this.',
      );
      return;
    }

    String deviceType = device.type;
    String? deviceRoleName = device.roleName;

    // Check if this phone has this type of device.
    if (_deviceController.hasDevice(deviceType)) {
      DeviceManager deviceManager = _deviceController.getDeviceManager(
        deviceType,
      )!;

      try {
        await _deploymentService.registerDevice(
          study.studyDeploymentId,
          deviceRoleName,
          deviceManager.registration!,
        );
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

  /// Asking for permissions for all the measures included in this
  /// [study].
  ///
  /// Since we only ask for permission relevant to the deployment, this method
  /// should be called after deployment has taken place but before this controller
  /// is started.
  ///
  /// This method is only relevant on Android, and does nothing on iOS.
  /// iOS automatically asks for permissions when a resource is accessed.
  Future<void> askForAllPermissions() async {
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

  /// Initialize all devices in this [deployment].
  void _initializeDevices() {
    assert(deployment != null, 'Deployment is null.');

    for (var configuration in deployment!.devices) {
      _initializeDevice(configuration);
    }
  }

  /// Initialize the device specified in the [configuration].
  void _initializeDevice(DeviceConfiguration configuration) {
    if (_deviceController.hasDevice(configuration.type)) {
      _deviceController.devices[configuration.type]?.initialize(configuration);
    } else {
      warning(
        "$runtimeType - A device of type '${configuration.type}' is not available on this device. "
        "This may be because this device is not available on this operating system. "
        "Or it may be because the sampling package containing this device has not been "
        "registered in the SamplingPackageRegistry.",
      );
    }
  }

  /// Start heartbeat monitoring for all devices, incl. the phone, for the
  /// [deployment] controlled by this controller.
  void _startHeartbeatMonitoring() {
    for (var configuration in deployment?.devices ?? <DeviceConfiguration>[]) {
      _deviceController
          .getDeviceManager(configuration.type)
          ?.startHeartbeatMonitoring(this);
    }
  }

  /// Stop heartbeat monitoring for all devices, incl. the phone, for the
  /// [deployment] controlled by this controller.
  void _stopHeartbeatMonitoring() {
    for (var configuration in deployment?.devices ?? <DeviceConfiguration>[]) {
      _deviceController
          .getDeviceManager(configuration.type)
          ?.stopHeartbeatMonitoring();
    }
  }

  /// Start connecting all connectable devices to be used in the [deployment]
  /// and which are available on this phone.
  Future<void> connectAllConnectableDevices() async {
    assert(deployment != null, 'Deployment is null.');

    debug('$runtimeType - Trying to connect to all connectable devices.');

    // connect all the connected devices and the primary device (i.e. this phone)
    for (var configuration in deployment?.devices ?? <DeviceConfiguration>[]) {
      var device = _deviceController.getDeviceManager(configuration.type);
      if (device != null && device.canConnect()) await device.connect();
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
      await askForAllPermissions();
    }

    // Restore the app task controller state for this study.
    await AppTaskController()._restoreQueue(study);

    // Resume data sampling, if needed. Wait for a few seconds to let devices
    // connect before resuming sampling.
    if (study.samplingStatus == ExecutorState.Resumed) {
      Future.delayed(Duration(seconds: 5), () => executor.resume());
    }
  }

  /// Resume data sampling.
  void resume() => executor.resume();

  /// Pause data sampling.
  void pause() => executor.pause();

  /// Called when this controller is disposed.
  ///
  /// This entails:
  ///   * pausing data sampling
  ///   * stopping heartbeat monitoring
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
    _stopHeartbeatMonitoring();
    dataManager?.close();
  }
}
