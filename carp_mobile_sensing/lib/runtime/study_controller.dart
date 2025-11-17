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
  int _samplingSize = 0;
  DataManager? _dataManager;
  // DataEndPoint? _dataEndPoint;
  final SmartphoneDeploymentExecutor _executor = SmartphoneDeploymentExecutor();
  Map<Permission, PermissionStatus>? _permissions;

  /// Create a new [SmartphoneStudyController] to control the runtime behavior
  /// of a [study].
  SmartphoneStudyController(SmartphoneStudy study) : _study = study {
    study.events.listen((event) {
      switch (event.event) {
        case StudyStatusEventTypes.DeploymentStatusReceived:
          _deploymentStatusReceived();
          break;
        case StudyStatusEventTypes.DeviceDeploymentReceived:
          // case StudyStatusEventTypes.DeploymentUpdated:
          _deviceDeploymentReceived();
          break;
        default:
      }
    });

    // Keep the sampling status updated.
    executor.stateEvents.listen((state) => study.samplingStatus = state);
  }

  /// The study that this [SmartphoneStudyController] controls
  SmartphoneStudy get study => _study;

  /// The deployment associated with this [study].
  SmartphoneDeployment? get deployment =>
      study.deployment as SmartphoneDeployment?;

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
    (measurement) => measurement.data.format.toString() == type,
  );

  /// The sampling size of this [deployment] in terms of number of measurements
  /// that has been collected since sampling was started.
  /// Note that this number is not persistent, and the counter hence resets
  /// across app restart.
  int get samplingSize => _samplingSize;

  /// Handles updates of the [deployment] status.
  Future<void> _deploymentStatusReceived() async {}

  /// Handles the reception of a new or updated [deployment].
  ///
  /// This entails configuring devices, data manager, and executor to get
  /// ready to handle sampling of data. Note that data sampling is NOT started
  /// automatically on reception of a new deployment. This has to be done explicitly
  /// by calling the [start] method.
  Future<void> _deviceDeploymentReceived() async {
    assert(
      study.deployment is SmartphoneDeployment,
      'A StudyDeploymentController can only work with a SmartphoneDeployment device deployment',
    );

    // fast out if study has been stopped
    if (study.status == StudyStatus.Stopped) {
      info('$runtimeType - Study has been stopped and cannot be started.');
      return;
    }

    // fast out if already deployed
    if (study.deployment != null &&
        study.status.index >= StudyStatus.Deployed.index) {
      info(
        '$runtimeType - Study deployment already deployed. Skipping deployment.',
      );
      return;
    }

    info('$runtimeType - Configuring based on new deployment information...');

    // initialize all devices from the deployment, incl. this smartphone.
    initializeDevices();

    // try to register relevant connected devices
    tryRegisterRemainingDevicesToRegister();

    // initialize the data manager
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

    // initialize the executor, which recursively initializes all executors and probes
    _executor.initialize(deployment!, deployment!);

    // Connect to all connectable devices, incl. this phone.
    // (Re-)connecting a device will trigger that sampling is (re)started
    await connectAllConnectableDevices();

    // start heartbeat monitoring
    if (SmartPhoneClientManager().heartbeat) startHeartbeatMonitoring();

    // listen to all measurements to keep track of sampling size
    measurements.listen((_) => _samplingSize++);

    // start data sampling
    start();

    var statusMsg =
        '===============================================================\n'
        '  CARP Mobile Sensing (CAMS) - $runtimeType\n'
        '===============================================================\n'
        '  study status : ${study.status.name}\n'
        ' deployment id : ${deployment?.studyDeploymentId}\n'
        ' deployed time : ${deployment?.deployed}\n'
        '     role name : ${deployment!.deviceConfiguration.roleName}\n'
        '      platform : ${DeviceInfo().platform.toString()}\n'
        '     device ID : ${DeviceInfo().deviceID.toString()}\n'
        ' data endpoint : $dataEndPoint\n'
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
      DeviceManager deviceManager = _deviceController.getDevice(deviceType)!;

      // create a registration based on the device manager's unique id and name of the device
      var registration = deviceManager.configuration.createRegistration(
        deviceId: deviceManager.id,
        deviceDisplayName: deviceManager.displayName,
      );

      try {
        await _deploymentService.registerDevice(
          study.studyDeploymentId,
          deviceRoleName,
          registration,
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
  /// study [deployment].
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

    for (var measure in deployment!.measures) {
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
  void initializeDevices() {
    assert(deployment != null, 'Deployment is null.');

    for (var configuration in deployment!.devices) {
      initializeDevice(configuration);
    }
  }

  /// Initialize the device specified in the [configuration].
  void initializeDevice(DeviceConfiguration configuration) {
    if (_deviceController.hasDevice(configuration.type)) {
      _deviceController.devices[configuration.type]?.initialize(configuration);
    } else {
      warning(
        "A device of type '${configuration.type}' is not available on this device. "
        "This may be because this device is not available on this operating system. "
        "Or it may be because the sampling package containing this device has not been "
        "registered in the SamplingPackageRegistry.",
      );
    }
  }

  /// Start heartbeat monitoring for all devices, incl. the phone, for the
  /// [deployment] controlled by this controller.
  void startHeartbeatMonitoring() {
    for (var configuration in deployment!.devices) {
      _deviceController
          .getDevice(configuration.type)
          ?.startHeartbeatMonitoring(this);
    }
  }

  /// Start connecting all connectable devices to be used in the [deployment]
  /// and which are available on this phone.
  Future<void> connectAllConnectableDevices() async {
    assert(deployment != null, 'Deployment is null.');

    debug('$runtimeType - Trying to connect to all connectable devices.');

    // connect all the connected devices and the primary device (i.e. this phone)
    for (var configuration in deployment!.devices) {
      var device = _deviceController.getDevice(configuration.type);
      if (device != null && device.canConnect()) await device.connect();
    }
  }

  /// Start data collection using this controller.
  ///
  /// If [resume] is true, immediately resume data collection according to the
  /// configuration in [deployment]. If not, sampling can be started later
  /// by calling [executor.start].
  Future<void> start() async {
    if (study.status == StudyStatus.Stopped) {
      warning(
        '$runtimeType - Study has been stopped. Will not start data sampling.',
      );
      return;
    }

    info(
      '$runtimeType - Starting data sampling for study deployment: ${deployment?.studyDeploymentId}',
    );

    // if this study has not yet been deployed, do this first.
    if (study.status.index < StudyStatus.Deployed.index) {
      await SmartPhoneClientManager().tryDeployment(
        study.studyDeploymentId,
        study.deviceRoleName,
      );
    }

    // ask for permissions for all measures in this deployment
    if (SmartPhoneClientManager().askForPermissions) {
      await askForAllPermissions();
    }

    // Start data sampling, if needed.
    if (study.samplingStatus == ExecutorState.started) executor.start();
  }

  /// Start data sampling.
  void resume() => executor.start();

  /// Pause data sampling.
  void pause() => executor.stop();

  /// Called when this controller is disposed.
  ///
  /// This entails:
  ///   * stopping data sampling
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
