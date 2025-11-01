/*
 * Copyright 2018-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// A [SmartphoneDeploymentController] controls the execution of a [SmartphoneDeployment].
class SmartphoneDeploymentController extends StudyRuntime<DeviceRegistration> {
  int _samplingSize = 0;
  DataManager? _dataManager;
  DataEndPoint? _dataEndPoint;
  final SmartphoneDeploymentExecutor _executor = SmartphoneDeploymentExecutor();
  late DataTransformer _transformer;
  Map<Permission, PermissionStatus>? _permissions;

  @override
  SmartphoneStudy? get study => super.study as SmartphoneStudy;

  @override
  SmartphoneDeployment? get deployment =>
      super.deployment as SmartphoneDeployment?;

  @override
  DeviceController get deviceRegistry =>
      super.deviceRegistry as DeviceController;

  /// The permissions granted to this client from the OS.
  Map<Permission, PermissionStatus> get permissions => _permissions ?? {};

  /// The executor executing the [deployment].
  SmartphoneDeploymentExecutor get executor => _executor;

  /// The configuration of the data endpoint, i.e. how data is saved or uploaded.
  DataEndPoint? get dataEndPoint => _dataEndPoint;

  /// The data manager responsible for handling the data collected by this controller.
  DataManager? get dataManager => _dataManager;

  /// The privacy schema used to encrypt data before upload.
  String get privacySchemaName =>
      deployment?.privacySchemaName ?? NameSpace.CARP;

  /// The transformer used to transform data before upload.
  DataTransformer get transformer => _transformer;

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
      ..data = _transformer(
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

  /// The sampling size of this [deployment] in terms of number of [Measurement]
  /// that has been collected since sampling was started.
  /// Note that this number is not persistent, and the counter hence resets
  /// across app restart.
  int get samplingSize => _samplingSize;

  /// Create a new [SmartphoneDeploymentController] to control the runtime behavior
  /// of a study deployment.
  SmartphoneDeploymentController(super.deploymentService, super.deviceRegistry);

  /// Configure this [SmartphoneDeploymentController].
  ///
  /// Must be called after a deployment is ready using [tryDeployment] and
  /// before [start] is called.
  ///
  /// The [dataEndPoint] parameter is a custom [DataEndPoint] specifying where to save
  /// or upload data. If not specified, the endpoint specified in the study deployment
  /// ([SmartphoneDeployment.dataEndPoint]) which originates from the study protocol
  /// is used. If no data endpoint is specified in the study protocol either,
  /// then no data management is done, but sensing  can still be started.
  /// This is useful for apps that wants to use the framework for in-app consumption
  /// of sensing events without saving the data.
  ///
  /// The [transformer] is a generic [DataTransformer] function which transform
  /// each collected measurement. If not specified, a 1:1 mapping is done,
  /// i.e. no transformation.
  Future<void> configure({
    DataEndPoint? dataEndPoint,
    DataTransformer? transformer,
  }) async {
    assert(
      deployment != null,
      'Cannot configure a StudyDeploymentController without a deployment.',
    );
    assert(
      deployment is SmartphoneDeployment,
      'A StudyDeploymentController can only work with a SmartphoneDeployment device deployment',
    );
    info('Configuring $runtimeType');

    // initialize all devices from the primary deployment, incl. this smartphone.
    initializeDevices();

    // try to register relevant connected devices
    super.tryRegisterRemainingDevicesToRegister();

    // initialize optional parameters
    _dataEndPoint = dataEndPoint ?? deployment!.dataEndPoint;
    _transformer = transformer ?? ((data) => data);

    if (_dataEndPoint != null) {
      _dataManager = DataManagerRegistry().create(_dataEndPoint!.type);
    }

    if (_dataManager == null) {
      warning(
        "No data manager for the specified data endpoint found: '${deployment?.dataEndPoint}'. "
        "Data sampling will still start, but no data will be saved.",
      );
    }

    // initialize the data manager, device registry, and study executor
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

    measurements.listen((_) => _samplingSize++);
    status = StudyStatus.Deployed;

    var statusMsg =
        '===============================================================\n'
        '  CARP Mobile Sensing (CAMS) - $runtimeType\n'
        '===============================================================\n'
        ' deployment id : ${deployment!.studyDeploymentId}\n'
        ' deployed time : ${deployment!.deployed}\n'
        '     role name : ${deployment!.deviceConfiguration.roleName}\n'
        '      platform : ${DeviceInfo().platform.toString()}\n'
        '     device ID : ${DeviceInfo().deviceID.toString()}\n'
        ' data endpoint : $_dataEndPoint\n'
        '  data manager : $_dataManager\n'
        '        status : ${status.toString().split('.').last}\n'
        '===============================================================\n';
    debugPrint(statusMsg);
  }

  /// Asking for permissions for all the measures included in this
  /// study [deployment].
  ///
  /// Should be called after deployment has taken place (using the [tryDeployment] method)
  /// but before this controller is started (via the [start] method).
  ///
  /// This method is only relevant on Android, and does nothing on iOS.
  /// iOS automatically asks for permissions when a resource is accessed.
  Future<void> askForAllPermissions() async {
    if (Platform.isIOS) {
      warning(
        '$runtimeType - Requesting all permissions at once is not feasible on iOS. Skipping this.',
      );
      return;
    }

    if (deployment == null) {
      warning(
        '$runtimeType - No deployment available. Skipping requesting permissions.',
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
    if (deviceRegistry.hasDevice(configuration.type)) {
      deviceRegistry.devices[configuration.type]?.initialize(configuration);
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
      deviceRegistry
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
      var device = deviceRegistry.getDevice(configuration.type);
      if (device != null && await device.canConnect()) await device.connect();
    }
  }

  /// Verifies whether the primary device is ready for deployment and in case
  /// it is, deploy the [study] previously added.
  ///
  /// If [useCached] is true (default), any previously cached [deployment] will be
  /// retrieved from the local cache. Otherwise, the [deployment] will be retrieved
  /// from the deployment service, based on the [study].
  ///
  /// In case already deployed, nothing happens and the current [status] is returned.
  @override
  Future<StudyStatus> tryDeployment({bool useCached = true}) async {
    assert(
      study != null,
      'Cannot deploy without a valid study deployment id and device role name. '
      "Call 'addStudy()' or 'addStudyProtocol()' first.",
    );

    if (deployment != null && status.index >= StudyStatus.Deployed.index) {
      // already deployed
      return status;
    }

    info('$runtimeType - Trying to deploy study: $study');
    if (useCached) {
      // restore the deployment and app task queue
      bool success = await restoreDeployment();
      if (success) {
        await AppTaskController().restoreQueue();
        return status = deployment?.status ?? StudyStatus.Deployed;
      }
    }

    // if no cache, get the deployment from the deployment service
    // and save a local cache
    status = await super.tryDeployment();
    if (status == StudyStatus.Deployed && deployment != null) {
      deployment!.studyId = study?.studyId;
      deployment!.participantId = study?.participantId;
      deployment!.participantRoleName = study?.participantRoleName;
      deployment?.status = status;
      deployment!.deployed = DateTime.now().toUtc();

      // create local folder structure and store local deployment
      Settings().getCacheBasePath(deployment!.studyDeploymentId);
      saveDeployment();
    }

    return status;
  }

  /// Save the [deployment] persistently to the local cache.
  /// Returns `true` if successful.
  Future<bool> saveDeployment() async => (deployment != null)
      ? await Persistence().saveDeployment(deployment!)
      : false;

  /// Restore the [deployment] from a local cache.
  /// Returns `true` if successful.
  Future<bool> restoreDeployment() async => (studyDeploymentId != null)
      ? (deployment = await Persistence().restoreDeployment(
              studyDeploymentId!,
            )) !=
            null
      : false;

  /// Erase study deployment information cached locally on this phone.
  Future<void> eraseDeployment() async {
    if (studyDeploymentId == null) return;

    try {
      info(
        "$runtimeType - Erasing deployment cache for deployment '$studyDeploymentId'.",
      );
      await Persistence().eraseDeployment(studyDeploymentId!);

      final name = await Settings().getDeploymentBasePath(studyDeploymentId!);
      await File(name).delete(recursive: true);
    } catch (exception) {
      warning('Failed to erase deployment - $exception');
    }
  }

  /// Start this controller.
  ///
  /// If [start] is true, immediately start data collection according to the
  /// parameters specified in [configure].
  ///
  /// [configure] must be called before starting sampling.
  @override
  Future<void> start([bool start = true]) async {
    info(
      '$runtimeType - Starting data sampling for study deployment: ${deployment?.studyDeploymentId}',
    );

    // if this study has not yet been deployed, do this first.
    if (status.index < StudyStatus.Deployed.index) {
      await tryDeployment();
      await configure();
    }

    // ask for permissions for all measures in this deployment
    if (SmartPhoneClientManager().askForPermissions) {
      await askForAllPermissions();
    }

    super.start();
    if (start) executor.start();
  }

  /// Stop this controller and data sampling.
  @override
  Future<void> stop() async {
    info('$runtimeType - Stopping data sampling...');
    executor.stop();
    await super.stop();
  }

  /// Remove a study from this [SmartphoneDeploymentController].
  ///
  /// This entails:
  ///   * stopping data sampling
  ///   * closing the data manager (e.g., flushing data to a file)
  ///   * erasing any locally cached deployment information
  ///
  /// Note that only cached deployment information is deleted. Any data sampled
  /// from this deployment will remain on the phone.
  ///
  /// If the same deployment is deployed again, it will start on a fresh start
  /// and not use old deployment information. This means, for example,
  /// that any [OneTimeTrigger] will trigger again, since it is considered to
  /// be a new deployment.
  @override
  Future<void> remove() async {
    info('$runtimeType - Removing deployment from this smartphone...');
    executor.dispose();
    await dataManager?.close();

    await eraseDeployment();

    await super.remove();
  }

  /// Called when this controller is disposed permanently.
  ///
  /// When this method is called, the controller is never used again. It is an error
  /// to call any of the [start] or [stop] methods at this point.
  @mustCallSuper
  @override
  void dispose() {
    info('$runtimeType - Disposing ...');
    remove().then((_) => super.dispose());
  }
}
