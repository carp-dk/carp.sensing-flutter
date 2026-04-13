// ignore_for_file: unnecessary_getters_setters

/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// Runtime status for a [DeviceManager].
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

  /// The device is reconnected after a temporary disconnection, e.g., due to a
  /// temporary loss of Bluetooth connection.
  reconnected,

  /// The device is temporarily disconnected, e.g., due to a temporary loss of
  /// Bluetooth connection, but is expected to be reconnected again.
  disconnecting,

  /// The device is disconnected from the phone.
  disconnected,
}

/// A [DeviceManager] handles the runtime of any type of device or service used
/// for data  collection.
///
/// Examples include a hardware device like a smartwatch or fitness band,
/// an onboard service on the smartphone like a location service, or an
/// online service, like a weather service.
abstract class DeviceManager<
  TDeviceConfiguration extends DeviceConfiguration<TRegistration>,
  TRegistration extends DeviceRegistration
>
    implements ConnectedDeviceDataCollector {
  final StreamController<DeviceStatus> _eventController =
      StreamController.broadcast();

  bool _hasPermissions = false;
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
      configuration?.supportedDataTypes
          ?.map((str) => DataType.fromString(str))
          .toSet() ??
      {};

  /// The type of the device managed by this device manager
  String get deviceType => _deviceType;

  // Get a printer-friendly display name for this device.
  String? get displayName;

  /// The configuration for this device.
  TDeviceConfiguration? get configuration => _configuration;

  /// The latest registration for this device.
  ///
  /// Is set using the [configure] method and contains the latest registered
  /// runtime information about the real device, e.g., the BLE address of a
  /// Bluetooth device.
  TRegistration? get registration => _registration;

  /// Create a device registration which can be used to configure this device
  /// for deployment.
  ///
  /// This method is used when a device is connected and a registration for this
  /// device is needed in the deployment and hence in the deployment service.
  /// The registration is typically created from the device information of the
  /// real device, e.g., the ID, name, and BLE address of the smartphone or a
  /// connected Bluetooth device.
  TRegistration createRegistration();

  /// Indicates whether this device manager should connect to the real device
  /// based on the last known registration information.
  /// Returns true (default) if no prior registration information is available,
  bool get shouldConnect => registration is CamsDeviceRegistration
      ? (registration as CamsDeviceRegistration).isConnected
      : true;

  /// The set of task control executors that use this device manager.
  final Set<TaskControlExecutor> executors = {};

  /// The name of the [deviceType] without the namespace.
  String get typeName => deviceType.split('.').last;

  /// The runtime status of this device.
  DeviceStatus get status => _status;

  /// Change the runtime status of this device.
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
      status == DeviceStatus.connected ||
      status == DeviceStatus.reconnected ||
      status == DeviceStatus.connecting;

  /// Is this device manager connected to the real device?
  bool get isConnected =>
      status == DeviceStatus.connected || status == DeviceStatus.reconnected;

  /// Configure this device manager by specifying its [configuration].
  /// Optionally, a [registration] can be specified to provide runtime information
  /// about the real device, e.g., the BLE address of a Bluetooth device.
  @nonVirtual
  void configure(
    TDeviceConfiguration configuration, [
    TRegistration? registration,
  ]) {
    // fast out if already configured
    if (isConfigured) return;

    info(
      '$runtimeType - Configuring, type: $typeName, configuration: $configuration, registration: $registration',
    );
    _configuration = configuration;
    _registration = registration;
    onConfigure();

    // Listen to status events and when this device is disconnecting or reconnected,
    // stop or restart sampling.
    statusEvents
        .where((status) => status == DeviceStatus.disconnecting)
        .listen((_) => isDisconnecting());
    statusEvents
        .where((status) => status == DeviceStatus.reconnected)
        .listen((_) => restart());

    status = DeviceStatus.configured;
  }

  /// Callback on [configure].
  ///
  /// When called, the [configuration] and the [registration] is available.
  ///
  /// Is to be overridden in sub-classes. Note, however, that it must not be
  /// doing a lot of work on startup.
  void onConfigure();

  /// Does this device manager have the [permissions] to run?
  @nonVirtual
  Future<bool> hasPermissions() async {
    if (!_hasPermissions) {
      info(
        '$runtimeType - Checking permissions for device of type: $typeName.',
      );
      _hasPermissions = true;

      // check any device-specific permission
      _hasPermissions = await onHasPermissions() && _hasPermissions;

      debug('$runtimeType - Permission of all permissions: $_hasPermissions');
    }
    return _hasPermissions;
  }

  /// Callback on [hasPermissions].
  ///
  /// Can be overridden in sub-classes for device-specific permission handling.
  Future<bool> onHasPermissions() async => true;

  /// Request all [permissions] for this device manager.
  @nonVirtual
  Future<void> requestPermissions() async {
    info(
      '$runtimeType - Requesting permissions for device of type: $typeName.',
    );

    await onRequestPermissions();
  }

  /// Callback on [requestPermissions].
  ///
  /// Can be overridden for device-specific permission handling.
  Future<void> onRequestPermissions();

  /// Ask this [DeviceManager] to start connecting to the device.
  /// Returns the [DeviceStatus] of the device.
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
      warning(
        '$runtimeType - Error connecting to device of type: $typeName. $error',
      );
      status = DeviceStatus.disconnected;
    }

    return status;
  }

  /// Callback on [connect]. Returns the [DeviceStatus] of the device.
  ///
  /// Can be overridden for device-specific connection handling.
  Future<DeviceStatus> onConnect();

  /// Start sampling of all measures using this device.
  ///
  /// This entails that all task control executors using this device are resumed,
  /// and hence all data collection for the measures using this device is started.
  @nonVirtual
  void start() {
    info('$runtimeType - Starting sampling...');
    executors.forEach((executor) => executor.resume());
  }

  /// Restart sampling of the measures using this device.
  ///
  /// This entails that all task control executors using this device are resumed,
  /// if they are supposed to be resumed, e.g., if they were paused due to a temporary
  /// disconnection (via [isDisconnecting]) of the device, but not if they were paused
  /// due to a manual [stop] of the sampling.
  @nonVirtual
  void restart() {
    info('$runtimeType - Restarting sampling...');

    for (var executor in executors) {
      debug(
        '$runtimeType - Restarting executor: $executor, state: ${executor.state}',
      );
      if (executor.state == ExecutorState.PausedButShouldBeResumed) {
        // resume data sampling with a delay to give the device some time to fully reconnect
        Future.delayed(const Duration(seconds: 15), () => executor.resume());
      }
    }
  }

  /// Stop sampling the measures using this device.
  ///
  /// This entails that all task control executors using this device are paused,
  /// and hence all data collection for the measures using this device is stopped.
  /// This method is e.g. used when the device is disconnected.
  ///
  /// If [shouldBeResumed] is true, the executors are paused but marked to be
  /// resumed later when the device is reconnected.
  /// This is useful when the device is temporarily disconnected, e.g., due to
  /// a temporary loss of Bluetooth connection, and we want to automatically resume
  /// sampling when the device is reconnected.
  @nonVirtual
  void stop({bool shouldBeResumed = false}) {
    debug(
      '$runtimeType - Stopping sampling - shouldResumeLater: $shouldBeResumed ...',
    );
    for (var executor in executors) {
      executor.state == ExecutorState.Resumed && shouldBeResumed
          ? executor.pauseButShouldBeResumed()
          : executor.pause();
    }
  }

  /// Ask this [DeviceManager] to disconnect from the device.
  ///
  /// All sampling on this device will be stopped before disconnection is
  /// initiate.
  ///
  /// Returns true if successful, false if not.
  @nonVirtual
  Future<bool> disconnect() async {
    if (!isConnecting) {
      warning(
        '$runtimeType is not connected, so nothing to disconnect from....',
      );
      return true;
    }
    bool success = false;
    info('$runtimeType - Trying to disconnect from device of type: $typeName.');

    stop();

    try {
      success = await onDisconnect();
    } catch (error) {
      warning(
        '$runtimeType - Error disconnecting from device of type: $typeName. $error',
      );
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

  /// Callback when the physical device is disconnected due to e.g., a temporary
  /// loss of Bluetooth connection.
  ///
  /// All sampling on this device will be stopped, but the sampling will be
  /// marked to be restarted (via [restart]) when the device is reconnected,
  /// e.g., when the Bluetooth connection is re-established.
  @nonVirtual
  Future<void> isDisconnecting() async {
    info('$runtimeType - Was disconnected from device of type: $typeName.');

    stop(shouldBeResumed: true);
    status = DeviceStatus.disconnected;
  }

  @override
  String toString() => '$runtimeType - type: $typeName, status: $status';
}
