part of '../../main.dart';

/// A view model for [DevicesListPage].
class DeviceListViewModel with ChangeNotifier {
  /// The list of all devices in this deployment.
  Iterable<DeviceViewModel> get deployedDevices =>
      bloc.sensing.deployedDevices.map((device) => DeviceViewModel(device));
}

/// A view model for a [DeviceManager].
class DeviceViewModel {
  DeviceManager deviceManager;
  String? get type => deviceManager.deviceType;
  DeviceStatus get status => deviceManager.status;
  Stream<DeviceStatus> get deviceEvents => deviceManager.statusEvents;

  /// The device id.
  // String get id => deviceManager.id;

  /// A printer-friendly type name for this device.
  String get typeName =>
      DeviceDescription.descriptors[type!]?.description ?? type!;

  /// A longer description of this device.
  String get description =>
      '${deviceManager.displayName}'
      '${(deviceManager is BLEDeviceManager && isPaired) ? '\n${(deviceManager as BLEDeviceManager).bleAddress}' : ''}'
      '${(deviceManager is HardwareDeviceManager && batteryLevel != null) ? '\n$batteryLevel% battery.' : ''}';

  String get statusString => status.name;

  /// The battery level of this device, if known.
  int? get batteryLevel => deviceManager is HardwareDeviceManager
      ? (deviceManager as HardwareDeviceManager).batteryLevel
      : null;

  /// The icon for this type of device.
  Icon? get icon => DeviceDescription.descriptors[type!]?.icon;

  /// The icon for the runtime state of this device.
  Icon? get stateIcon => DeviceDescription.deviceStateIcon[status];

  /// Is this device currently paired?
  bool get isPaired =>
      status == DeviceStatus.paired || status == DeviceStatus.connected;

  /// Is this device currently connected?
  bool get isConnected => status == DeviceStatus.connected;

  /// Is this a BLE device?
  bool get isBleDevice => deviceManager.configuration is BLEDevice;

  DeviceViewModel(this.deviceManager) : super();

  /// Pair with the given [device] if this is a BLE device.
  void pairWithDevice(ble.DiscoveredDevice device) {
    if (isBleDevice) {
      (deviceManager as BLEDeviceManager).pair(
        bleAddress: device.id,
        bleName: device.name,
        serviceUuids: device.serviceUuids
            .map((uuid) => uuid.toString())
            .toList(),
        manufacturerData: device.manufacturerData.toList(),
      );
    }
  }

  /// Connect to this device.
  void connectToDevice() => bloc
      .sensing
      .client
      .deviceController
      .devices[deviceManager.deviceType]!
      .connect();
}
