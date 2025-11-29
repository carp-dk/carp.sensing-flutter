/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movisens_package.dart';

/// A [DeviceConfiguration] for a Movisens device used in a [StudyProtocol].
///
/// This device descriptor defined the basic configuration of the Movisens
/// device, including the BTLE MAC [address], the [deviceName], the [sensorLocation]
/// and the [weight], [height], [age], [sex] of the user using the device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensDevice extends DeviceConfiguration<MACAddressDeviceRegistration> {
  /// The type of a Movisens device.
  static const String DEVICE_TYPE =
      '${DeviceConfiguration.DEVICE_NAMESPACE}.MovisensDevice';

  /// The default role name for a Movisens device.
  static const String DEFAULT_ROLE_NAME = 'movisens';

  /// The name of the device used for connecting to the device.
  ///
  /// The default Movisens names of devices are `MOVISENS Sensor <serial>`, where
  /// `serial` is the 5-digit serial number written on the back of the device.
  String deviceName;

  /// Sensor placement on body
  SensorLocation sensorLocation;

  /// Weight of the person wearing the Movisens device in kg.
  int weight;

  /// Height of the person wearing the Movisens device in cm.
  int height;

  /// Age of the person wearing the Movisens device in years.
  int age;

  /// Biological sex of the person wearing the Movisens device, male or female.
  Sex sex;

  /// Create a new [MovisensDevice].
  ///
  /// Default user settings are a 25 year old male, height 178 cm high, weight
  /// 78 kg with the sensor place on the chest.
  MovisensDevice({
    String? roleName,
    required this.deviceName,
    this.sensorLocation = SensorLocation.Chest,
    this.sex = Sex.Male,
    this.height = 178,
    this.weight = 78,
    this.age = 25,
  }) : super(roleName: roleName ?? DEFAULT_ROLE_NAME, isOptional: true);

  @override
  Function get fromJsonFunction => _$MovisensDeviceFromJson;
  factory MovisensDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensDevice;
  @override
  Map<String, dynamic> toJson() => _$MovisensDeviceToJson(this);
}

/// A Movisens [DeviceManager].
class MovisensDeviceManager
    extends BTLEDeviceManager<MovisensDevice, MACAddressDeviceRegistration> {
  // the last known voltage level of the Movisens device
  int _batteryLevel = -1;
  String? _connectionStatus;
  StreamSubscription<BluetoothConnectionState>? _subscription;

  /// The [Movisens] device handler.
  /// Only available after this device manger has been initialized via the
  /// [initialize] method.
  movisens.MovisensDevice? device;

  @override
  String get id => device?.id ?? MovisensDevice.DEVICE_TYPE;

  @override
  String? get displayName => device?.name;

  @override
  MACAddressDeviceRegistration get registration => MACAddressDeviceRegistration(
    deviceId: id,
    deviceDisplayName: displayName,
    macAddress: id,
  );

  String? get connectionStatus => _connectionStatus;

  MovisensDeviceManager(super.type, [super.configuration]);

  @override
  Future<void> onInitialize(MovisensDevice configuration) async {
    super.onInitialize(configuration);
    device = movisens.MovisensDevice(name: configuration.deviceName);
  }

  @override
  int get batteryLevel => _batteryLevel;

  @override
  String get btleAddress => device?.id ?? super.btleAddress;

  @override
  bool canConnect() => device != null;

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

        _batteryLevel = (event is movisens.BatteryLevelEvent)
            ? event.batteryLevel
            : _batteryLevel;
      });

      if (configuration != null) {
        // set user data parameters
        await device?.userDataService?.setAgeFloat(
          configuration!.age.toDouble(),
        );
        await device?.userDataService?.setSensorLocation(
          movisens.SensorLocation.values[configuration!.sensorLocation.index],
        );
        await device?.userDataService?.setWeight(
          configuration!.weight.toDouble(),
        );
        await device?.userDataService?.setHeight(configuration!.height);
        await device?.userDataService?.setGender(
          movisens.Gender.values[configuration!.sex.index],
        );
      }
    } catch (error) {
      warning(
        "$runtimeType - could not connect to device of type '$deviceType' - error: $error",
      );
      return DeviceStatus.error;
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
