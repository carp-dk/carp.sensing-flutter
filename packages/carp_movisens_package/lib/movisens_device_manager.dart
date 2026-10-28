/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movisens_package.dart';

/// A Movisens sensor used as a connected device in a protocol.
///
/// Add it with [SmartphoneStudyProtocol.addConnectedDevice] and use it as the
/// target device of tasks with Movisens measures (see
/// [MovisensSamplingPackage]). At runtime it is handled by a
/// [MovisensDeviceManager].
///
/// Key points:
///  * Holds the [sensorLocation] on the body and the [weight], [height],
///    [age] and [sex] of the person wearing it. These are written to the
///    device on connect, because its algorithms (like MET) depend on them.
///  * Optional by default ([isOptional] is true), so a study can start
///    without it.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensDevice extends BLEDevice<BLEDeviceRegistration> {
  /// The type of a Movisens device.
  static const String DEVICE_TYPE = '${CamsDevice.CAMS_DEVICE_NAMESPACE}.MovisensDevice';

  /// The default role name for a Movisens device.
  static const String DEFAULT_ROLE_NAME = 'movisens';

  /// Sensor placement on the body.
  SensorLocation sensorLocation;

  /// Weight of the person wearing the Movisens device in kg.
  int weight;

  /// Height of the person wearing the Movisens device in cm.
  int height;

  /// Age of the person wearing the Movisens device in years.
  int age;

  /// Biological sex of the person wearing the Movisens device, male or female.
  Sex sex;

  /// Creates a new [MovisensDevice].
  ///
  /// Default user settings are a 25 year old male, 178 cm tall, weighing
  /// 78 kg, with the sensor placed on the chest. [roleName] defaults to
  /// [DEFAULT_ROLE_NAME].
  MovisensDevice({
    String? roleName,
    this.sensorLocation = SensorLocation.Chest,
    this.sex = Sex.Male,
    this.height = 178,
    this.weight = 78,
    this.age = 25,
  }) : super(roleName: roleName ?? DEFAULT_ROLE_NAME, isOptional: true);

  @override
  Function get fromJsonFunction => _$MovisensDeviceFromJson;
  factory MovisensDevice.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as MovisensDevice;
  @override
  Map<String, dynamic> toJson() => _$MovisensDeviceToJson(this);
}

/// A [BLEDeviceManager] that connects to a Movisens device.
///
/// Created by [MovisensSamplingPackage] and used by the [MovisensProbe]s to
/// reach the device's BLE services through [device].
///
/// Key points:
///  * Uses [deviceName] (not the BLE address) to find the device. The default
///    name is `MOVISENS Sensor <serial>`, where `serial` is the 5-digit serial
///    number on the back of the device.
///  * [deviceName] must be set before connecting; otherwise [canConnect] is
///    false.
///  * On connect, it writes the user data from the [MovisensDevice]
///    configuration to the device and listens for battery level events.
class MovisensDeviceManager extends BLEDeviceManager<MovisensDevice, BLEDeviceRegistration> {
  // the last known battery level of the Movisens device
  int? _batteryLevel;
  String? _connectionStatus;
  StreamSubscription<BluetoothConnectionState>? _subscription;

  movisens.MovisensDevice? _device;

  /// The Movisens device handler from the `movisens_flutter` plugin.
  ///
  /// Null until [deviceName] has been set.
  movisens.MovisensDevice? get device =>
      deviceName != null ? _device ??= movisens.MovisensDevice(name: deviceName!) : _device = null;

  /// The name of the device used for connecting to the device.
  ///
  /// The default Movisens names of devices are `MOVISENS Sensor <serial>`, where
  /// `serial` is the 5-digit serial number written on the back of the device.
  String? deviceName;

  @override
  String? get displayName => deviceName;

  @override
  BLEDeviceRegistration createRegistration() => BLEDeviceRegistration(
    deviceDisplayName: displayName,
    isConnected: isConnected,
    batteryChargingState: batteryLevel != null
        ? HardwareDeviceRegistration.parseBatteryLevel(batteryLevel!)
        : BatteryChargingState.unknown,
    bleAddress: deviceName ?? 'No Movisens device name specified',
    bleName: deviceName ?? 'No Movisens device name specified',
  );

  /// Not set anywhere at the moment, so it is always null.
  String? get connectionStatus => _connectionStatus;

  /// Creates a device manager for the device [type], typically
  /// [MovisensDevice.DEVICE_TYPE].
  MovisensDeviceManager(super.type, {super.configuration});

  @override
  int? get batteryLevel => _batteryLevel;

  @override
  bool get canConnect => device != null;

  @override
  Future<DeviceStatus> onConnect() async {
    try {
      await device?.connect();

      // listen for BTLE connection events
      _subscription = device?.state?.listen((state) {
        switch (state) {
          case BluetoothConnectionState.connected:
            status = DeviceStatus.connected;
            break;
          case BluetoothConnectionState.disconnected:
            status = DeviceStatus.disconnected;
            break;
          default:
            status = DeviceStatus.unknown;
            break;
        }
      });

      // listen for battery events
      await device?.batteryService?.enableNotify();

      device?.batteryService?.events.listen((event) {
        debug('$runtimeType :: Movisens event : $event');

        _batteryLevel = (event is movisens.BatteryLevelEvent) ? event.batteryLevel : _batteryLevel;
      });

      if (configuration != null) {
        // set user data parameters
        await device?.userDataService?.setAgeFloat(configuration!.age.toDouble());
        await device?.userDataService?.setSensorLocation(
          movisens.SensorLocation.values[configuration!.sensorLocation.index],
        );
        await device?.userDataService?.setWeight(configuration!.weight.toDouble());
        await device?.userDataService?.setHeight(configuration!.height);
        await device?.userDataService?.setGender(movisens.Gender.values[configuration!.sex.index]);
      }
    } catch (error) {
      warning("$runtimeType - could not connect to device of type '$deviceType' - error: $error");
      return DeviceStatus.disconnected;
    }

    return DeviceStatus.connecting;
  }

  @override
  Future<bool> onDisconnect() async {
    _subscription?.cancel();
    await device?.disconnect();
    return true;
  }
}
