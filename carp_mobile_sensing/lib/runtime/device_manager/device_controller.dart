/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// A [DeviceController] handles runtime management of all devices and services
/// available to this phone, including the phone itself.
///
/// Each specific device is handled by a [DeviceManager] which are available as
/// a map of [devices].
class DeviceController extends DeviceDataCollectorFactory {
  static final DeviceController _instance = DeviceController._();
  DeviceController._() : super();
  final Map<String, DeviceManager> _devices = {};

  /// The period of sending [Heartbeat] measurements, in minutes.
  static const int HEARTBEAT_PERIOD = 5;

  /// Get the singleton [DeviceController].
  factory DeviceController() => _instance;

  /// The map of device managers registered in this controller.
  Map<String, DeviceManager> get devices => _devices;

  @override
  DeviceDataCollector get localDataCollector => smartphoneDeviceManager;

  /// The smartphone (primary device) manager.
  SmartphoneDeviceManager get smartphoneDeviceManager =>
      devices.values.whereType<SmartphoneDeviceManager>().first;

  /// The list of connected devices on runtime.
  List<DeviceManager> get connectedDevices =>
      _devices.values.where((manager) => manager.isConnected).toList();

  /// Do this controller support the specified device [deviceType]?
  bool supportsDevice(String deviceType) {
    for (var package in SamplingPackageRegistry().packages) {
      if (package.deviceType == deviceType) return true;
    }
    return false;
  }

  /// Do this controller support the specified device [deviceType]?
  bool hasDevice(String deviceType) => _devices.containsKey(deviceType);

  @override
  DeviceManager? createConnectedDataCollector(
    String deviceType,
    DeviceRegistration deviceRegistration,
  ) => getDeviceManager(deviceType);

  /// Get a device manger for the specified [deviceType].
  /// If a device manager is not yet available, it is created from the
  /// sampling packages.
  /// Returns null if no device manager for [deviceType] is found.
  DeviceManager? getDeviceManager(String deviceType) {
    // early out if already registered
    if (devices.containsKey(deviceType)) return devices[deviceType];

    info('$runtimeType - Creating device manager for device type: $deviceType');

    // look for a device manager of this type in the sampling packages
    DeviceManager? manager;
    for (var package in SamplingPackageRegistry().packages) {
      if (package.deviceType == deviceType) manager = package.deviceManager;
    }

    if (manager == null) {
      warning(
        "$runtimeType - No device manager found for device: '$deviceType'. "
        'This may be because this device is not supported on this phone. '
        'Or it may be because the sampling package containing this device manager '
        'has not been registered in the SamplingPackageRegistry.',
      );
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

  /// Register [manager] as a device manager for a device of type [deviceType].
  void registerDevice(String deviceType, DeviceManager manager) {
    // Fast out if already registered.
    if (devices.containsKey(deviceType)) return;

    debug('$runtimeType - registering device of type: $deviceType');
    devices[deviceType] = manager;
  }

  /// Unregister the manager for [deviceType].
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
  String toString() => '$runtimeType (${_devices.length} devices registered)';
}
