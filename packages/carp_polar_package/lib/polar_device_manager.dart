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
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarDevice extends BLEDevice<PolarDeviceRegistration> {
  /// The type of a Polar device.
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.PolarDevice';

  /// The default role name for a Polar device.
  static const String DEFAULT_ROLE_NAME = 'Polar HR Device';

  /// Create a new [PolarDevice].
  PolarDevice({
    super.roleName = PolarDevice.DEFAULT_ROLE_NAME,
    super.isOptional = true,
  });

  @override
  Function get fromJsonFunction => _$PolarDeviceFromJson;
  factory PolarDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarDevice;
  @override
  Map<String, dynamic> toJson() => _$PolarDeviceToJson(this);
}

/// A [DeviceRegistration] for a Polar device.
///
/// This device registration defines the basic configuration of the Polar
/// device, including the device type, the identifier, and the name
/// of the device.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PolarDeviceRegistration extends BLEDeviceRegistration {
  /// Polar device id printed on the sensor/device or UUID.
  String identifier;

  /// The type of Polar device, if known.
  PolarDeviceType polarDeviceType;

  /// RSSI (Received Signal Strength Indicator) value from advertisement
  int? rssi;

  PolarDeviceRegistration({
    String? deviceDisplayName,
    super.registrationCreatedOn,
    super.isConnected,
    super.batteryChargingState,
    String? hardwareName,
    required this.identifier,
    required super.bleAddress,
    super.bleName,
    required this.polarDeviceType,
    this.rssi,
  }) : super(
         deviceDisplayName: deviceDisplayName ?? bleName,
         hardwareName: hardwareName ?? polarDeviceType.name,
       );

  @override
  Function get fromJsonFunction => _$PolarDeviceRegistrationFromJson;
  factory PolarDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarDeviceRegistration;
  @override
  Map<String, dynamic> toJson() => _$PolarDeviceRegistrationToJson(this);
}

/// A Polar [DeviceManager].
///
/// The Polar BLE name is typically of the form
///
///  *  Polar Sense B34B4B56
///  *  Polar H10 B36KB56
///
/// I.e., on the form "Polar <type> <identifier>".
class PolarDeviceManager
    extends BLEDeviceManager<PolarDevice, PolarDeviceRegistration> {
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

  @override
  String get id => polarIdentifier ?? bleAddress ?? 'Unknown Polar device';

  @override
  String? get displayName => bleName;

  /// Polar device id printed on the sensor/device or UUID.
  /// Typically on the form "B34B4B56".
  ///
  /// This identifier can be set directly if known, or can be extracted
  /// from the [bleName] when the device is paired (e.g., "Polar H10 B36KB56").
  ///
  /// This identifier is used for connecting to a Polar device.
  /// It is typically the last part of the BLE name of the device,
  /// which is on the form "Polar <type> <identifier>".
  /// It is not the same as the BLE address, which is typically on the
  /// form "00:11:22:33:44:55". Polar devices do not use the BLE address
  /// for connecting.
  String? polarIdentifier;

  PolarDeviceType? get polarDeviceType {
    if (bleName == null) return null;

    // The Polar BLE name is typically of the form
    //  *  Polar Sense B34B4B56
    //  *  Polar H10 B36KB56
    // I.e., on the form "Polar <type> <identifier>".
    if (bleName!.split(' ').first.toUpperCase() == 'POLAR') {
      switch (bleName!.split(' ').elementAt(1).toUpperCase()) {
        case 'H9':
          return PolarDeviceType.H9;
        case 'H10':
          return PolarDeviceType.H10;
        case 'SENSE':
          return PolarDeviceType.SENSE;
        default:
          return PolarDeviceType.UNKNOWN;
      }
    }

    return null;
  }

  /// RSSI (Received Signal Strength Indicator) value from advertisement
  int? rssi;

  /// List of [PolarDataType]s that are available in Polar devices for online
  /// streaming or offline recording.
  ///
  /// Only available **after** a Polar device is successfully connected.
  List<PolarDataType> features = [];

  /// Are the [features] available (i.e., received from the device)?
  bool get polarFeaturesAvailable => _polarFeaturesAvailable;

  @override
  int? get batteryLevel => _batteryLevel;

  @override
  Stream<int> get batteryEvents => _batteryEventController.stream;

  @override
  void onConfigure(PolarDevice configuration) {}

  @override
  PolarDeviceRegistration createRegistration() => PolarDeviceRegistration(
    deviceDisplayName: bleName,
    isConnected: isConnected,
    bleAddress: bleAddress ?? 'Null',
    bleName: bleName,
    batteryChargingState: batteryLevel != null
        ? HardwareDeviceRegistration.parseBatteryLevel(batteryLevel!)
        : BatteryChargingState.unknown,
    identifier: polarIdentifier ?? 'Unknown',
    polarDeviceType: polarDeviceType ?? PolarDeviceType.UNKNOWN,
    rssi: rssi,
  );

  PolarDeviceManager(super.type, [super.configuration]);

  @override
  bool onPaired() => (polarIdentifier = bleName?.split(' ').last) != null;

  @override
  bool canConnect() => polarIdentifier != null;

  @override
  Future<DeviceStatus> onConnect() async {
    // fast out if already connected.
    if (isConnected) return status;

    if (polarIdentifier == null) {
      warning(
        '$runtimeType - cannot connect to device, the Polar identifier is null.',
      );
      // return status as configured, so we can try to reconnect with another identifier
      return DeviceStatus.configured;
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
          bleAddress = event.address;
          bleName = event.name;
          rssi = event.rssi;
        });

        _connectedSubscription = polar.deviceConnected.listen((event) {
          debug('$runtimeType - Polar event : $event');
          // we do not mark the device as fully connected before the features are available
          status = DeviceStatus.connecting;
          bleAddress = event.address;
          bleName = event.name;
          rssi = event.rssi;
        });

        _disconnectedSubscription = polar.deviceDisconnected.listen((event) {
          debug('$runtimeType - Polar event : $event');
          status = DeviceStatus.disconnected;
          _batteryLevel = null;
          rssi = null;
        });

        // connect to the device based on its identified
        polar.connectToDevice(polarIdentifier!, requestPermissions: true);

        // listen for what features the connected Polar device supports
        _sdkFeatureSubscription = polar.sdkFeatureReady.listen((event) {
          debug('$runtimeType - Polar event : $event');

          if (polarIdentifier != event.identifier &&
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
        return DeviceStatus.disconnected;
      }
    }
  }

  @override
  Future<bool> onDisconnect() async {
    if (polarIdentifier == null) {
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

    await polar.disconnectFromDevice(polarIdentifier!);

    return true;
  }
}
