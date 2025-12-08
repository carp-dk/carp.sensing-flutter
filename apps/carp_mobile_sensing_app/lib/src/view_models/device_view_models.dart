part of '../../main.dart';

/// A view model for [DevicesListPage].
class DeviceListViewModel with ChangeNotifier {
  /// The list of all devices in this deployment.
  Iterable<DeviceViewModel> get deployedDevices =>
      bloc.sensing.deployedDevices!.map((device) => DeviceViewModel(device));
}

/// A view model for a [DeviceManager].
class DeviceViewModel {
  DeviceManager deviceManager;
  String? get type => deviceManager.deviceType;
  DeviceStatus get status => deviceManager.status;
  Stream<DeviceStatus> get deviceEvents => deviceManager.statusEvents;

  /// The device id.
  String get id => deviceManager.id;

  /// A printer-friendly name for this device.
  String? get name => DeviceDescription.descriptors[type!]?.name;

  /// A printer-friendly description of this device.
  String get description =>
      '${DeviceDescription.descriptors[type!]?.description} - $statusString'
      '${(deviceManager is HardwareDeviceManager && batteryLevel != null) ? '\n$batteryLevel% battery remaining.' : ''}';

  String get statusString => status.name;

  /// The battery level of this device, if known.
  int? get batteryLevel => deviceManager is HardwareDeviceManager
      ? (deviceManager as HardwareDeviceManager).batteryLevel
      : null;

  /// The icon for this type of device.
  Icon? get icon => DeviceDescription.descriptors[type!]?.icon;

  /// The icon for the runtime state of this device.
  Icon? get stateIcon => deviceStateIcon[status];

  DeviceViewModel(this.deviceManager) : super();

  static Map<DeviceStatus, Icon> get deviceStateIcon => {
    DeviceStatus.unknown: Icon(Icons.error_outline, color: CachetColors.RED),
    DeviceStatus.error: Icon(Icons.error_outline, color: CachetColors.RED),
    DeviceStatus.disconnected: Icon(Icons.close, color: CachetColors.YELLOW),
    DeviceStatus.connected: Icon(Icons.check, color: CachetColors.GREEN),
    DeviceStatus.paired: Icon(
      Icons.bluetooth_connected,
      color: CachetColors.DARK_BLUE,
    ),
  };

  /// Connect to this device.
  void connectToDevice() => bloc
      .sensing
      .client
      .deviceController
      .devices[deviceManager.deviceType]!
      .connect();
}
