// ignore_for_file: unnecessary_getters_setters

/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// The runtime status of a [DeviceManager] and its device.
///
/// Emitted on [DeviceManager.statusEvents].
enum DeviceStatus {
  /// The state of the device is unknown.
  unknown,

  /// The device manager has been configured, but not yet connected.
  configured,

  /// The device is paired with this phone.
  /// This status is mainly used in Bluetooth devices (via a [BLEDeviceManager]).
  paired,

  /// The phone is trying to connect to the device.
  connecting,

  /// The device is connected to the phone and ready to be used.
  connected,

  /// The device is reconnected after a temporary disconnection.
  ///
  /// E.g. after a temporary loss of Bluetooth connection.
  /// Setting this status restarts sampling; see [DeviceManager.restart].
  reconnected,

  /// The device is temporarily disconnected, but expected to reconnect.
  ///
  /// E.g. due to a temporary loss of Bluetooth connection.
  /// Setting this status pauses sampling on the device; see
  /// [DeviceManager.isDisconnecting].
  disconnecting,

  /// The device is disconnected from the phone.
  disconnected,
}

/// Manages one device or service used for data collection.
///
/// It configures the device, connects to it, and starts and stops sampling on
/// it. Examples include a hardware device like a smartwatch or fitness band,
/// an onboard service on the smartphone like a location service, or an
/// online service, like a weather service. Each [SamplingPackage] provides
/// one, and the [DeviceController] keeps them by device type.
///
/// Key points:
///  * Lifecycle: [configure], then [connect]; [disconnect] stops sampling
///    first. Subclasses implement the `on...` callbacks ([onConfigure],
///    [onConnect], [onDisconnect], [onRequestPermissions]).
///  * [status] drives sampling: [DeviceStatus.connected] resumes all
///    [executors], [DeviceStatus.disconnecting] pauses them (to be resumed),
///    and [DeviceStatus.reconnected] resumes them again after 15 seconds.
///  * [connect] checks [hasPermissions] first and fails if they are missing.
///
/// See [ServiceManager], [HardwareDeviceManager], [BLEDeviceManager] and
/// [SmartphoneDeviceManager] for the main subtypes.
abstract class DeviceManager<
  TDeviceConfiguration extends DeviceConfiguration<TRegistration>,
  TRegistration extends DeviceRegistration
>
    implements ConnectedDeviceDataCollector {
  final StreamController<DeviceStatus> _eventController = StreamController.broadcast();

  DeviceStatus _status = DeviceStatus.unknown;
  final String _deviceType;
  TDeviceConfiguration? _configuration;
  TRegistration? _registration;

  /// Create a new [DeviceManager] specifying its [deviceType].
  ///
  /// Its [configuration] can be specified on creation here, or specified later
  /// in the [configure] method.
  DeviceManager(String deviceType, {TDeviceConfiguration? configuration})
    : _deviceType = deviceType,
      _configuration = configuration;

  @override
  Set<DataType> get supportedDataTypes =>
      configuration?.supportedDataTypes?.map((str) => DataType.fromString(str)).toSet() ?? {};

  /// The type of the device managed by this device manager, e.g.
  /// `dk.cachet.carp.common.application.devices.Smartphone`.
  String get deviceType => _deviceType;

  /// A human-readable name for this device, or null if unknown.
  String? get displayName;

  /// The configuration for this device.
  TDeviceConfiguration? get configuration => _configuration;

  /// The latest registration for this device.
  ///
  /// Is set using the [configure] method and contains the latest registered
  /// runtime information about the real device, e.g., the BLE address of a
  /// Bluetooth device.
  TRegistration? get registration => _registration;

  /// Creates a registration of this device for the deployment.
  ///
  /// This method is used when a device is connected and a registration for this
  /// device is needed in the deployment and hence in the deployment service.
  /// The registration is typically created from the device information of the
  /// real device, e.g., the ID, name, and BLE address of the smartphone or a
  /// connected Bluetooth device.
  TRegistration createRegistration();

  /// Whether to connect to the real device, based on the last registration.
  ///
  /// Uses [CamsDeviceRegistration.isConnected] if the [registration] is one.
  /// Otherwise true, e.g. if there is no prior registration.
  bool get shouldConnect =>
      registration is CamsDeviceRegistration ? (registration as CamsDeviceRegistration).isConnected : true;

  /// The task control executors whose tasks run on this device.
  ///
  /// Filled by the [SmartphoneDeploymentExecutor]. Resumed and paused by
  /// [start], [restart] and [stop].
  final Set<TaskControlExecutor> executors = {};

  /// The name of the [deviceType] without the namespace.
  String get typeName => deviceType.split('.').last;

  /// The runtime status of this device.
  DeviceStatus get status => _status;

  /// Changes the runtime status of this device.
  ///
  /// Emits the new status on [statusEvents] if it differs from the current one.
  set status(DeviceStatus newStatus) {
    if (newStatus != _status) {
      debug('$runtimeType - Setting device status: ${newStatus.name}');
      _status = newStatus;
      _eventController.add(_status);
    }
  }

  /// The stream of status events for this device.
  Stream<DeviceStatus> get statusEvents => _eventController.stream.distinct();

  /// Has this device manager been configured?
  bool get isConfigured => status.index >= DeviceStatus.configured.index;

  /// Is this device manager connecting or already connected to a device?
  bool get isConnecting =>
      status == DeviceStatus.connected || status == DeviceStatus.reconnected || status == DeviceStatus.connecting;

  /// Is this device manager connected to the real device?
  bool get isConnected => status == DeviceStatus.connected || status == DeviceStatus.reconnected;

  /// Configures this device manager with its [configuration].
  ///
  /// Optionally, a [registration] can be specified to provide runtime
  /// information about the real device, e.g., the BLE address of a Bluetooth
  /// device. Calls [onConfigure] and sets [status] to
  /// [DeviceStatus.configured]. Does nothing if already configured.
  @nonVirtual
  void configure(TDeviceConfiguration configuration, [TRegistration? registration]) {
    // fast out if already configured
    if (isConfigured) return;

    info('$runtimeType - Configuring, type: $typeName, configuration: $configuration, registration: $registration');

    _configuration = configuration;
    _registration = registration;
    onConfigure();

    // A device connecting after the study has started has its executors paused,
    // and nothing else resumes them.
    statusEvents.where((status) => status == DeviceStatus.connected).listen((_) => start());
    statusEvents.where((status) => status == DeviceStatus.disconnecting).listen((_) => isDisconnecting());
    statusEvents.where((status) => status == DeviceStatus.reconnected).listen((_) => restart());

    status = DeviceStatus.configured;
  }

  /// Callback on [configure].
  ///
  /// When called, the [configuration] and the [registration] is available.
  ///
  /// Is to be overridden in sub-classes. Note, however, that it must not be
  /// doing a lot of work on startup.
  void onConfigure();

  /// Whether this device manager has the permissions it needs to run.
  ///
  /// Note that the result is not cached, since permissions can be revoked in
  /// the phone's settings at any time, without the app knowing about it.
  @nonVirtual
  Future<bool> hasPermissions() async {
    return onHasPermissions();
  }

  /// Callback on [hasPermissions].
  ///
  /// Can be overridden in sub-classes for device-specific permission handling.
  Future<bool> onHasPermissions() async => true;

  /// Asks the user for the permissions this device manager needs.
  /// Calls [onRequestPermissions].
  @nonVirtual
  Future<void> requestPermissions() async {
    info('$runtimeType - Requesting permissions for device of type: $typeName.');

    await onRequestPermissions();
  }

  /// Callback on [requestPermissions].
  ///
  /// Can be overridden for device-specific permission handling.
  Future<void> onRequestPermissions();

  /// Connects to the device and returns its new [DeviceStatus].
  ///
  /// Does nothing if already connecting or connected, or if not configured.
  /// Sets [status] to [DeviceStatus.disconnected] if permissions are missing
  /// or [onConnect] throws.
  @nonVirtual
  Future<DeviceStatus> connect() async {
    // Fast out if already connecting or connected to the device.
    if (isConnecting) return status;

    if (!isConfigured) {
      warning('$runtimeType has not been configured - cannot connect to it.');
      return status;
    }

    status = DeviceStatus.connecting;

    if (!(await hasPermissions())) {
      warning(
        '$runtimeType has not the permissions required to connect. '
        'Call requestPermissions() before calling connect.',
      );
      return status = DeviceStatus.disconnected;
    }

    info('$runtimeType - Trying to connect to device of type: $typeName.');
    try {
      status = await onConnect();
    } catch (error) {
      warning('$runtimeType - Error connecting to device of type: $typeName. $error');
      status = DeviceStatus.disconnected;
    }

    return status;
  }

  /// Callback on [connect]. Returns the [DeviceStatus] of the device.
  ///
  /// Can be overridden for device-specific connection handling.
  Future<DeviceStatus> onConnect();

  /// Starts sampling of all measures using this device.
  ///
  /// Resumes all [executors]. Called automatically when [status] becomes
  /// [DeviceStatus.connected].
  @nonVirtual
  void start() {
    info('$runtimeType - Starting sampling...');
    executors.forEach((executor) => executor.resume());
  }

  /// Restarts sampling of the measures using this device.
  ///
  /// Resumes, after 15 seconds, only the [executors] in
  /// [ExecutorState.PausedButShouldBeResumed], i.e. those paused by a
  /// temporary disconnection ([isDisconnecting]) and not by [stop].
  /// Called automatically when [status] becomes [DeviceStatus.reconnected].
  @nonVirtual
  void restart() {
    info('$runtimeType - Restarting sampling...');

    for (var executor in executors) {
      debug('$runtimeType - Restarting executor: $executor, state: ${executor.state}');
      if (executor.state == ExecutorState.PausedButShouldBeResumed) {
        // resume data sampling with a delay to give the device some time to fully reconnect
        Future.delayed(const Duration(seconds: 15), () => executor.resume());
      }
    }
  }

  /// Stops sampling the measures using this device.
  ///
  /// Pauses all [executors]. Used, e.g., when the device is disconnected.
  ///
  /// If [shouldBeResumed] is true, the executors are paused but marked to be
  /// resumed later when the device is reconnected.
  /// This is useful when the device is temporarily disconnected, e.g., due to
  /// a temporary loss of Bluetooth connection, and we want to automatically resume
  /// sampling when the device is reconnected.
  @nonVirtual
  void stop({bool shouldBeResumed = false}) {
    debug('$runtimeType - Stopping sampling - shouldResumeLater: $shouldBeResumed ...');
    for (var executor in executors) {
      executor.state == ExecutorState.Resumed && shouldBeResumed
          ? executor.pauseButShouldBeResumed()
          : executor.pause();
    }
  }

  /// Disconnects from the device.
  ///
  /// All sampling on this device is stopped first. Returns true if
  /// successful or if not connected, false if [onDisconnect] fails.
  @nonVirtual
  Future<bool> disconnect() async {
    if (!isConnecting) {
      warning('$runtimeType is not connected, so nothing to disconnect from....');
      return true;
    }
    bool success = false;
    info('$runtimeType - Trying to disconnect from device of type: $typeName.');

    stop();

    try {
      success = await onDisconnect();
    } catch (error) {
      warning('$runtimeType - Error disconnecting from device of type: $typeName. $error');
    }
    status = (success) ? DeviceStatus.disconnected : status;

    // TODO - we should also try to unregister the device from the deployment
    // service when it is disconnected by the user/app.
    // Need to implement a "tryUnregisterDisconnectedDevice(configuration)"
    // method somewhere, like in the ClientManager or DeviceController.

    return success;
  }

  /// Callback on [disconnect].
  ///
  /// This method is called **after** all sampling on this device has been stopped,
  /// and the device manager is trying to disconnect from the real device.
  ///
  /// Is to be overridden in sub-classes and implement device-specific disconnection.
  Future<bool> onDisconnect();

  /// Called when the device is lost for a while.
  ///
  /// E.g. due to a temporary loss of Bluetooth connection.
  /// Pauses sampling on this device but marks it to be resumed (via [restart])
  /// when the device is reconnected, and sets [status] to
  /// [DeviceStatus.disconnected]. Called automatically when [status] becomes
  /// [DeviceStatus.disconnecting].
  @nonVirtual
  Future<void> isDisconnecting() async {
    info('$runtimeType - Was disconnected from device of type: $typeName.');

    stop(shouldBeResumed: true);
    status = DeviceStatus.disconnected;
  }

  @override
  String toString() => '$runtimeType - type: $typeName, status: $status';
}
