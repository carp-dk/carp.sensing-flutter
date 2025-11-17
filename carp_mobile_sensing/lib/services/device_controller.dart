/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../services.dart';

/// A [DeviceController] handles runtime management of all devices and services
/// available to this phone, including the phone itself.
///
/// Each specific device is handled by a [DeviceManager] which are available as
/// a map of [devices].
class DeviceController implements DeviceDataCollectorFactory {
  static final DeviceController _instance = DeviceController._();
  final Map<String, DeviceManager> _devices = {};
  final StreamGroup<BatteryStatus> _batteryEventGroup = StreamGroup.broadcast();

  /// The period of sending [Heartbeat] measurements, in minutes.
  static const int HEARTBEAT_PERIOD = 5;

  /// Get the singleton [DeviceController].
  factory DeviceController() => _instance;
  DeviceController._();

  @override
  Map<String, DeviceManager> get devices => _devices;

  /// The smartphone (primary device) manager.
  SmartphoneDeviceManager get smartphoneDeviceManager =>
      devices.values.whereType<SmartphoneDeviceManager>().first;

  /// The list of connected devices on runtime.
  List<DeviceManager> get connectedDevices =>
      _devices.values.where((manager) => manager.isConnected).toList();

  /// The stream of all battery events from all connected devices.
  Stream<BatteryStatus> get batteryEvents => _batteryEventGroup.stream;

  @override
  bool supportsDevice(String type) {
    for (var package in SamplingPackageRegistry().packages) {
      if (package.deviceType == type) return true;
    }
    return false;
  }

  DeviceManager? getDevice(String deviceType) => _devices[deviceType];

  @override
  bool hasDevice(String deviceType) => _devices.containsKey(deviceType);

  @override
  Future<DeviceManager?> createDevice(String deviceType) async {
    // early out if already registered
    if (_devices.containsKey(deviceType)) return _devices[deviceType]!;

    info('$runtimeType - Creating device manager for device type: $deviceType');

    // look for a device manager of this type in the sampling packages
    DeviceManager? manager;
    for (var package in SamplingPackageRegistry().packages) {
      if (package.deviceType == deviceType) manager = package.deviceManager;
    }

    if (manager == null) {
      warning('$runtimeType - No device manager found for device: $deviceType');
    } else {
      registerDevice(deviceType, manager);
    }

    return manager;
  }

  /// A convenient method for creating and registering all devices which are
  /// available in each [SamplingPackage] that has been registered in the
  /// [SamplingPackageRegistry].
  void registerAllAvailableDevices() {
    for (var package in SamplingPackageRegistry().packages) {
      registerDevice(package.deviceType, package.deviceManager);
    }
  }

  @override
  void registerDevice(String deviceType, DeviceDataCollector manager) {
    if (_devices.containsKey(deviceType)) return;

    debug('$runtimeType - registering device of type: $deviceType');
    manager.type = deviceType;
    _devices[deviceType] = manager as DeviceManager;
    if (manager is HardwareDeviceManager) {
      _batteryEventGroup.add(
        manager.batteryEvents.map(
          (batteryLevel) => BatteryStatus(
            manager.id,
            manager.type,
            manager.configuration?.roleName,
            batteryLevel,
          ),
        ),
      );
    }
  }

  @override
  void unregisterDevice(String deviceType) => _devices.remove(deviceType);

  /// A convenient method for disconnecting all connected devices.
  Future<void> disconnectAllConnectedDevices() async {
    for (var device in connectedDevices) {
      device.disconnect();
    }
  }

  /// A string representation of all [devices].
  String devicesToString() =>
      _devices.keys.map((key) => key.split('.').last).toString();

  @override
  String toString() => '$runtimeType [${_devices.length}]';

  @override
  DeviceDataCollector localDataCollector;

  @override
  ConnectedDeviceDataCollector<
    DeviceConfiguration<DeviceRegistration>,
    DeviceRegistration
  >
  createConnectedDataCollector(
    String deviceType,
    DeviceRegistration deviceRegistration,
  ) {
    // TODO: implement createConnectedDataCollector
    throw UnimplementedError();
  }
}

/// Runtime battery status of a device.
class BatteryStatus {
  final String deviceId;
  final String deviceType;
  final String? deviceRoleName;
  final int batteryLevel;

  BatteryStatus(
    this.deviceId,
    this.deviceType,
    this.deviceRoleName,
    this.batteryLevel,
  );

  @override
  String toString() =>
      '$runtimeType - '
      'device id: $deviceId, '
      'type: $deviceType, '
      'role name: $deviceRoleName, '
      'battery level: $batteryLevel ';
}
