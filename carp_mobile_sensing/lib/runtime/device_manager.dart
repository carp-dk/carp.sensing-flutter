// ignore_for_file: unnecessary_getters_setters

/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

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

  final bool _restartOnReconnect;
  bool _hasPermissions = false;
  Timer? _heartbeatTimer;
  DeviceStatus _status = DeviceStatus.unknown;
  final String _deviceType;
  TDeviceConfiguration? _configuration;
  TRegistration? _registration;

  /// Create a new [DeviceManager] specifying its [deviceType].
  ///
  /// Its [configuration] can be specified on creation here, or specified later
  /// in the [configure] method.
  DeviceManager(
    String deviceType, [
    TDeviceConfiguration? configuration,
    this._restartOnReconnect = true,
  ]) : _deviceType = deviceType,
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

  /// Is data sampling resumed when this device is (re)connected?
  bool get restartOnReconnect => _restartOnReconnect;

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
  Stream<DeviceStatus> get statusEvents => _eventController.stream;

  /// Has this device manager been configured?
  bool get isConfigured => status.index >= DeviceStatus.configured.index;

  /// Is this device manager connecting or connected to the real device?
  bool get isConnecting =>
      status == DeviceStatus.connected || status == DeviceStatus.connecting;

  /// Is this device manager connected to the real device?
  bool get isConnected => status == DeviceStatus.connected;

  /// Configure this device manager by specifying its [configuration].
  /// Optionally, a [registration] can be specified to provide runtime information
  /// about the real device, e.g., the BLE address of a Bluetooth device.
  @nonVirtual
  void configure(
    TDeviceConfiguration configuration, [
    TRegistration? registration,
  ]) {
    info(
      '$runtimeType - Configuring, type: $typeName, configuration: $configuration, registration: $registration',
    );
    _configuration = configuration;
    _registration = registration;
    onConfigure();

    // Listen to status events and when this device is (re)connected, restart sampling.
    if (restartOnReconnect) {
      statusEvents
          .where((status) => status == DeviceStatus.connected)
          .listen((_) => restart());
    }
    status = DeviceStatus.configured;
  }

  /// Callback on [configure].
  ///
  /// When called, the [configuration] and the [registration] is available.
  ///
  /// Is to be overridden in sub-classes. Note, however, that it must not be
  /// doing a lot of work on startup.
  void onConfigure();

  /// Start heartbeat monitoring for this device for the deployment controlled
  /// by [controller].
  void startHeartbeatMonitoring(SmartphoneStudyController controller) {
    if (!isConfigured) {
      warning(
        '$runtimeType - Trying to start heartbeat monitoring before device is initialized. '
        'Please initialize device first.',
      );
      return;
    }
    debug(
      '$runtimeType - Setting up heartbeat monitoring for device: $configuration',
    );
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: DeviceController.HEARTBEAT_PERIOD),
      (_) => (isConnected)
          ? controller.executor.addMeasurement(
              Measurement.fromData(
                Heartbeat(
                  period: DeviceController.HEARTBEAT_PERIOD,
                  deviceType: deviceType,
                  deviceRoleName: configuration?.roleName ?? "unknown",
                ),
              ),
            )
          : null,
    );
  }

  /// Stop heartbeat monitoring for this device.
  void stopHeartbeatMonitoring() => _heartbeatTimer?.cancel();

  /// Does this device manager have the [permissions] to run?
  @nonVirtual
  Future<bool> hasPermissions() async {
    if (!_hasPermissions) {
      info(
        // '$runtimeType - Checking permissions for device of type: $typeName and id: $id',
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
  /// Is to be overridden in sub-classes for device-specific permission handling.
  Future<void> onRequestPermissions();

  /// Ask this [DeviceManager] to start connecting to the device.
  /// Returns the [DeviceStatus] of the device.
  @nonVirtual
  Future<DeviceStatus> connect() async {
    info('$runtimeType - Trying to connect to device of type: $typeName.');

    if (!isConfigured) {
      warning('$runtimeType has not been initialized - cannot connect to it.');
      return status;
    }

    if (!(await hasPermissions())) {
      warning(
        '$runtimeType has not the permissions required to connect. '
        'Call requestPermissions() before calling connect.',
      );
      status = DeviceStatus.disconnected;
      return status;
    }

    try {
      status = await onConnect();
    } catch (error) {
      status = DeviceStatus.disconnected;
      warning(
        '$runtimeType - Error connecting to device of type: $typeName. $error',
      );
    }

    return status;
  }

  /// Callback on [connect]. Returns the [DeviceStatus] of the device.
  ///
  /// Is to be overridden in sub-classes and implement device-specific connection.
  Future<DeviceStatus> onConnect();

  /// Restart sampling of the measures using this device.
  ///
  /// This entails that all measures in the study protocol using this device's
  /// type is restarted. This method is useful after the device is (re)connected.
  @nonVirtual
  void restart() {
    info('$runtimeType - Resuming sampling...');

    for (var executor in executors) {
      executor.state == ExecutorState.Resumed ? executor.resume() : null;
    }
  }

  /// Stop sampling the measures using this device.
  ///
  /// This entails that all measures in the study protocol using this device's
  /// type is stopped.
  @nonVirtual
  void stop() {
    for (var executor in executors) {
      executor.pause();
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
    bool success = false;
    if (status == DeviceStatus.connected || status == DeviceStatus.connecting) {
      info(
        '$runtimeType - Trying to disconnect from device of type: $typeName.',
      );

      // Stop all sampling on this device.
      stop();

      success = await onDisconnect();
      status = (success) ? DeviceStatus.disconnected : status;

      return success;
    } else {
      warning(
        '$runtimeType is not connected, so nothing to disconnect from....',
      );
      return true;
    }
  }

  /// Callback on [disconnect].
  ///
  /// Is to be overridden in sub-classes and implement device-specific disconnection.
  Future<bool> onDisconnect();

  @override
  String toString() => '$runtimeType - type: $typeName, status: $status';
}
