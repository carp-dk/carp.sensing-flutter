/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_polar_package.dart';

/// Enumeration of supported Polar devices.
enum PolarDeviceType {
  /// Unknown Polar type
  UNKNOWN,

  /// Polar H9 Heart rate sensor
  H9,

  /// Polar H10 Heart rate sensor
  H10,

  /// Polar Verity Sense heart rate sensor
  SENSE,
}

/// A [DeviceConfiguration] for a Polar device used in a [StudyProtocol].
///
/// This device descriptor defined the basic configuration of the Polar
/// device, including the [deviceType], the [identifier], and the [name]
/// of the device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarDevice extends BLEHeartRateDevice {
  /// The type of a Polar device.
  static const String DEVICE_TYPE =
      '${DeviceConfiguration.DEVICE_NAMESPACE}.PolarDevice';

  /// The default role name for a Polar device.
  static const String DEFAULT_ROLE_NAME = 'Polar HR Device';

  /// The polar sensor settings.
  /// This is know only **after** a polar device is connected.
  // @JsonKey(ignore: true)
  PolarSensorSetting? settings;

  /// Polar device id printed on the sensor/device or UUID.
  /// This [identifier] is required for connecting to a Polar device.
  String? identifier;

  /// The Bluetooth address of the sensor.
  String? address;

  /// The type of Polar device, if known.
  PolarDeviceType? deviceType;

  /// The user-friendly name of the sensor.
  String? name;

  /// RSSI (Received Signal Strength Indicator) value from advertisement
  int? rssi;

  /// Create a new [PolarDevice].
  PolarDevice({
    super.roleName = PolarDevice.DEFAULT_ROLE_NAME,
    super.isOptional = true,
    this.deviceType,
    this.identifier,
    this.name,
  });

  @override
  Function get fromJsonFunction => _$PolarDeviceFromJson;
  factory PolarDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarDevice;
  @override
  Map<String, dynamic> toJson() => _$PolarDeviceToJson(this);
}

/// A Polar [DeviceManager].
class PolarDeviceManager
    extends BTLEDeviceManager<PolarDevice, MACAddressDeviceRegistration> {
  int? _batteryLevel;
  bool _polarFeaturesAvailable = false;
  Polar? _polar;
  final StreamController<int> _batteryEventController =
      StreamController.broadcast();
  StreamSubscription<PolarBatteryLevelEvent>? _batterySubscription;
  StreamSubscription<PolarDeviceInfo>? _connectingSubscription;
  StreamSubscription<PolarDeviceInfo>? _connectedSubscription;
  StreamSubscription<PolarDeviceDisconnectedEvent>? _disconnectedSubscription;
  StreamSubscription<PolarSdkFeatureReadyEvent>? _sdkFeatureSubscription;

  /// The [Polar] device handler.
  Polar get polar => _polar ??= Polar();

  /// List of [PolarDataType]s that are available in Polar devices for online
  /// streaming or offline recording.
  ///
  /// Only available **after** a Polar device is successfully connected.
  List<PolarDataType> features = [];

  @override
  String get id => configuration?.identifier ?? '---';

  @override
  String? get displayName => btleName;

  @override
  String get btleName => configuration?.name ?? '';

  @override
  set btleName(String btleName) {
    configuration?.name = btleName;

    // the Polar BTLE name is typically of the form
    //  *  Polar Sense B34B4B56
    //  *  Polar H10 B36KB56
    // I.e., on the form "Polar <type> <identifier>
    if (btleName.split(' ').first.toUpperCase() == 'POLAR') {
      configuration?.identifier = btleName.split(' ').last;

      switch (btleName.split(' ').elementAt(1).toUpperCase()) {
        case 'H9':
          configuration?.deviceType = PolarDeviceType.H9;
          break;
        case 'H10':
          configuration?.deviceType = PolarDeviceType.H10;
          break;
        case 'SENSE':
          configuration?.deviceType = PolarDeviceType.SENSE;
          break;
        default:
          configuration?.deviceType = PolarDeviceType.UNKNOWN;
          break;
      }
    }
  }

  /// Are the [features] available (i.e., received from the device)?
  bool get polarFeaturesAvailable => _polarFeaturesAvailable;

  @override
  int? get batteryLevel => _batteryLevel;

  @override
  Stream<int> get batteryEvents => _batteryEventController.stream;

  @override
  String get btleAddress => configuration?.address ?? '';

  @override
  set btleAddress(String btleAddress) => configuration?.address = btleAddress;

  @override
  MACAddressDeviceRegistration get registration => MACAddressDeviceRegistration(
    deviceId: id,
    deviceDisplayName: displayName,
    macAddress: btleAddress,
  );

  PolarDeviceManager(super.type, [super.configuration]);

  @override
  bool canConnect() => configuration?.identifier != null;

  @override
  Future<DeviceStatus> onConnect() async {
    // fast out if already connected.
    if (isConnected) return status;

    if (configuration?.identifier == null) {
      warning('$runtimeType - cannot connect to device, identifier is null.');
      // return status as initialized, so that the "user" can try to reconnect with another identifier
      return DeviceStatus.initialized;
    } else {
      try {
        // listen for battery level events
        _batterySubscription = polar.batteryLevel.listen((event) {
          debug('$runtimeType - Polar event : $event');
          _batteryLevel = event.level;
          _batteryEventController.add(_batteryLevel!);
        });

        // listen for connection events
        _connectingSubscription = polar.deviceConnecting.listen((event) {
          debug('$runtimeType - Polar event : $event');
          status = DeviceStatus.connecting;
          configuration?.address = event.address;
          configuration?.name = event.name;
          configuration?.rssi = event.rssi;
        });

        _connectedSubscription = polar.deviceConnected.listen((event) {
          debug('$runtimeType - Polar event : $event');
          // we do not mark the device as fully connected before the features are available
          status = DeviceStatus.connecting;
          configuration?.address = event.address;
          configuration?.name = event.name;
          configuration?.rssi = event.rssi;
        });

        _disconnectedSubscription = polar.deviceDisconnected.listen((event) {
          debug('$runtimeType - Polar event : $event');
          status = DeviceStatus.disconnected;
          _batteryLevel = null;
        });

        // connect to the device based on its identified (id)
        polar.connectToDevice(id, requestPermissions: true);

        // listen for what features the connected Polar device supports
        _sdkFeatureSubscription = polar.sdkFeatureReady.listen((event) {
          debug('$runtimeType - Polar event : $event');

          if (configuration!.identifier == event.identifier &&
              event.feature == PolarSdkFeature.onlineStreaming) {
            polar.getAvailableOnlineStreamDataTypes(event.identifier).then((
              dataTypes,
            ) {
              features = dataTypes.toList();
              debug('$runtimeType - features: $features');
              _polarFeaturesAvailable = true;
              status = DeviceStatus.connected;
            });
          }
        });

        return DeviceStatus.connecting;
      } catch (error) {
        warning(
          "$runtimeType - could not connect to device of type '$deviceType' and id '$id' - error: $error",
        );
        return DeviceStatus.error;
      }
    }
  }

  @override
  Future<bool> onDisconnect() async {
    if (configuration?.identifier == null) {
      warning(
        '$runtimeType - cannot disconnect from device, identifier is null.',
      );
      return false;
    }

    stop();

    _batteryLevel = null;

    _batterySubscription?.cancel();
    _connectingSubscription?.cancel();
    _connectedSubscription?.cancel();
    _disconnectedSubscription?.cancel();
    _sdkFeatureSubscription?.cancel();

    await polar.disconnectFromDevice(configuration!.identifier!);

    return true;
  }
}
