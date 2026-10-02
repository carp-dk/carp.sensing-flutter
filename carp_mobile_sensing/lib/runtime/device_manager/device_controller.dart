/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// Keeps the [DeviceManager] of every device and service on this phone.
///
/// This includes the phone itself.
/// A singleton, used by the [SmartPhoneClientManager] as its
/// [DeviceDataCollectorFactory]. Device managers come from the
/// [SamplingPackage]s registered in the [SamplingPackageRegistry], one per
/// device type, and are kept in [devices].
///
/// Use it to find a device manager, e.g. to connect a Bluetooth device:
/// `SmartPhoneClientManager().deviceController.getDeviceManager(type)`.
class DeviceController extends DeviceDataCollectorFactory {
  static final DeviceController _instance = DeviceController._();
  DeviceController._() : super();
  final Map<String, DeviceManager> _devices = {};

  /// The period of sending [Heartbeat] measurements, in minutes.
  static const int HEARTBEAT_PERIOD = 5;

  /// Returns the singleton [DeviceController].
  factory DeviceController() => _instance;

  /// The registered device managers, by device type.
  Map<String, DeviceManager> get devices => _devices;

  @override
  DeviceDataCollector get localDataCollector => smartphoneDeviceManager;

  /// The device manager of this phone (the primary device).
  ///
  /// Throws a [StateError] if none is registered.
  SmartphoneDeviceManager get smartphoneDeviceManager => devices.values.whereType<SmartphoneDeviceManager>().first;

  /// The device managers whose device is connected now.
  List<DeviceManager> get connectedDevices => _devices.values.where((manager) => manager.isConnected).toList();

  /// Whether a registered [SamplingPackage] provides the device [deviceType].
  bool supportsDevice(String deviceType) {
    for (var package in SamplingPackageRegistry().packages) {
      if (package.deviceType == deviceType) return true;
    }
    return false;
  }

  /// Whether a device manager for [deviceType] is registered in [devices].
  bool hasDevice(String deviceType) => _devices.containsKey(deviceType);

  @override
  DeviceManager? createConnectedDataCollector(String deviceType, DeviceRegistration deviceRegistration) =>
      getDeviceManager(deviceType);

  /// Returns the device manager for [deviceType].
  ///
  /// If none is registered yet, it is taken from the sampling packages and
  /// registered. Returns null if no sampling package provides [deviceType].
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

  /// Registers the device managers of all packages in [SamplingPackageRegistry].
  void registerAllAvailableDevices() {
    for (var package in SamplingPackageRegistry().packages) {
      registerDevice(package.deviceType, package.deviceManager);
    }
  }

  /// Registers [manager] for [deviceType].
  ///
  /// Does nothing if a manager is already registered for [deviceType].
  void registerDevice(String deviceType, DeviceManager manager) {
    // Fast out if already registered.
    if (devices.containsKey(deviceType)) return;

    debug('$runtimeType - registering device of type: $deviceType');
    devices[deviceType] = manager;
  }

  /// Unregister the manager for [deviceType].
  void unregisterDevice(String deviceType) => _devices.remove(deviceType);

  /// Starts disconnecting all [connectedDevices]. Does not wait for them.
  Future<void> disconnectAllConnectedDevices() async {
    for (var device in connectedDevices) {
      device.disconnect();
    }
  }

  /// The short names of all device types in [devices], for logging.
  String devicesToString() => _devices.keys.map((key) => key.split('.').last).toString();

  @override
  String toString() => '$runtimeType (${_devices.length} devices registered)';
}
