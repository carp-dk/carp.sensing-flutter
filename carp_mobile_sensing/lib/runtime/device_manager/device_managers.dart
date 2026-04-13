// ignore_for_file: unnecessary_getters_setters

/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// A [DeviceManager] for an onboard service, like a location service.
abstract class ServiceManager<
  TDeviceConfiguration extends ServiceConfiguration<TRegistration>,
  TRegistration extends ServiceRegistration
>
    extends DeviceManager<TDeviceConfiguration, TRegistration> {
  ServiceManager(super.deviceType, {super.configuration});
}

/// A [DeviceManager] for a hardware device.
///
/// The main assumption for a hardware device is that it has a battery and
/// this hardware device manager allow for getting the battery level and
/// listen to battery events.
abstract class HardwareDeviceManager<
  TDeviceConfiguration extends DeviceConfiguration<TRegistration>,
  TRegistration extends DeviceRegistration
>
    extends DeviceManager<TDeviceConfiguration, TRegistration> {
  /// The runtime battery level of this hardware device in percent (0-100).
  /// Returns null if unknown.
  int? get batteryLevel;

  /// The stream of battery level events (0-100) from this hardware device.
  Stream<int> get batteryEvents => const Stream.empty();

  HardwareDeviceManager(super.deviceType, {super.configuration});
}

/// A device manager for a connectable Bluetooth Low Energy (BLE) device.
abstract class BLEDeviceManager<
  TDeviceConfiguration extends BLEDevice<TRegistration>,
  TRegistration extends BLEDeviceRegistration
>
    extends HardwareDeviceManager<TDeviceConfiguration, TRegistration> {
  /// The BLE address of this device.
  ///
  /// The format of the BLE address is platform-specific.
  /// On Android, it is typically a MAC address of the form `00:04:79:00:0F:4D`.
  /// On iOS, it is typically be a UUID string on the form `E2C56DB5-DFFB-48D2-B060-D0F5A71096E0`.
  ///
  /// Returns null if unknown. Typically, the BLE address is only known after
  /// pairing with a specific BLE device.
  String? bleAddress;

  /// The BLE name of this device, if known.
  String? bleName;

  /// Advertised services of this device, if known.
  List<String> serviceUuids = [];

  /// Manufacturer specific data. The first 2 bytes are the Company Identifier Codes.
  List<int> manufacturerData = [];

  /// Default display name for a BLE device is its BLE name or address.
  @override
  String? get displayName => bleName ?? bleAddress;

  @override
  BLEDeviceManager(super.deviceType, {super.configuration});

  @override
  @mustCallSuper
  void onConfigure() {
    bleAddress ??= registration?.bleAddress;
    bleName ??= registration?.bleName;
  }

  /// Pair this device manager with a BLE device by specifying the [bleAddress],
  /// and optionally its [bleName], [serviceUuids], and [manufacturerData].
  @nonVirtual
  void pair({
    required String bleAddress,
    String? bleName,
    List<String>? serviceUuids,
    List<int>? manufacturerData,
  }) {
    this.bleAddress = bleAddress;
    this.bleName = bleName;
    this.serviceUuids = serviceUuids ?? [];
    this.manufacturerData = manufacturerData ?? [];
    if (onPaired()) {
      status = DeviceStatus.paired;
      info('$runtimeType - Paired with BLE device: $bleAddress');
    } else {
      warning('$runtimeType - Failed to pair with BLE device: $bleAddress');
    }
  }

  /// Callback on [pair].
  ///
  // By default, pairing is successful, but can be overridden in sub-classes
  // for device-specific pairing handling.
  /// Called by the [pair] method after setting the BLE device information.
  bool onPaired() => true;

  @override
  @mustCallSuper
  Future<bool> onHasPermissions() async => (Platform.isAndroid)
      ? await Permission.bluetoothConnect.isGranted &&
            await Permission.bluetoothScan.isGranted
      // : (Platform.isIOS)
      //     ? await Permission.bluetooth.isGranted
      // for some reason it seems like Permission.bluetooth.isGranted always
      // return false on iOS....?
      : true;

  @override
  @mustCallSuper
  Future<void> onRequestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
    }
    if (Platform.isIOS) {
      await Permission.bluetooth.request();
    }
  }
}

/// A device manager for a smartphone.
class SmartphoneDeviceManager
    extends HardwareDeviceManager<Smartphone, SmartphoneRegistration> {
  int _batteryLevel = 0;
  final _battery = Battery();
  final Set<DataType> _supportedDataTypes = {};

  SmartphoneDeviceManager([Smartphone? configuration])
    : super(Smartphone.DEVICE_TYPE, configuration: configuration);

  @override
  Set<DataType> get supportedDataTypes => _supportedDataTypes;

  @override
  String? get displayName => DeviceInfoService().toString();

  @override
  SmartphoneRegistration createRegistration() => SmartphoneRegistration(
    deviceId: DeviceInfoService().deviceID,
    deviceDisplayName: displayName,
    platform: DeviceInfoService().platform,
    batteryChargingState: HardwareDeviceRegistration.parseBatteryLevel(
      batteryLevel,
    ),
    hardwareName: DeviceInfoService().hardware,
    deviceManufacturer: DeviceInfoService().deviceManufacturer,
    deviceModel: DeviceInfoService().deviceModel,
    operatingSystem: DeviceInfoService().operatingSystemName,
    sdk: DeviceInfoService().sdk,
    release: DeviceInfoService().release,
  );

  @override
  void onConfigure() {
    // listen to the battery
    _battery.onBatteryStateChanged.listen(
      (state) async => _batteryLevel = await _battery.batteryLevel,
    );

    // find the supported data types
    for (var package in SamplingPackageRegistry().packages) {
      if (package is SmartphoneSamplingPackage) {
        _supportedDataTypes.addAll(
          package.dataTypes.map((type) => DataType.fromString(type.type)),
        );
      }
    }
  }

  @override
  int get batteryLevel => _batteryLevel;

  @override
  Stream<int> get batteryEvents =>
      _battery.onBatteryStateChanged.map((_) => _batteryLevel);

  @override
  bool get canConnect => true; // can always connect to the phone

  @override
  Future<void> onRequestPermissions() async {}

  @override
  Future<DeviceStatus> onConnect() async => DeviceStatus.connected;

  @override
  Future<bool> onDisconnect() async => true;
}
