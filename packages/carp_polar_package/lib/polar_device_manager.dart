/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_polar_package.dart';

/// Enumeration of supported Polar devices.
enum PolarDeviceType {
  /// Unknown Polar type
  Unknown,

  /// Polar H9 Heart rate sensor
  H9,

  /// Polar H10 Heart rate sensor
  H10,

  /// Polar Verity Sense heart rate sensor
  Verity,
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
    super.namePrefix = 'Polar',
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

  /// List of [PolarDataType]s that are available in the connected Polar device.
  List<PolarDataType>? supportedDataTypes;

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
    this.supportedDataTypes,
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
  String? get displayName => bleName ?? '';

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
          return PolarDeviceType.Verity;
        default:
          return PolarDeviceType.Unknown;
      }
    }

    return null;
  }

  /// RSSI (Received Signal Strength Indicator) value from advertisement
  int? rssi;

  /// List of [PolarDataType]s that are available in Polar devices for online
  /// streaming.
  ///
  /// Only available **after** a Polar device is successfully connected.
  List<PolarDataType>? dataTypes;

  /// Are the [dataTypes] available (i.e., received from the device)?
  bool get polarDataTypesAvailable => dataTypes != null;

  @override
  int? get batteryLevel => _batteryLevel;

  @override
  Stream<int> get batteryEvents => _batteryEventController.stream;

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
    polarDeviceType: polarDeviceType ?? PolarDeviceType.Unknown,
    supportedDataTypes: dataTypes,
    rssi: rssi,
  );

  PolarDeviceManager(super.type, {super.configuration});

  @override
  void onConfigure() {
    super.onConfigure();
    if (registration != null) {
      polarIdentifier = registration!.identifier;
    }
  }

  @override
  bool onPaired() => (polarIdentifier = bleName?.split(' ').last) != null;

  @override
  bool get canConnect => polarIdentifier != null;

  @override
  Future<DeviceStatus> onConnect() async {
    // fast out if no identifier is available for connecting
    if (polarIdentifier == null) {
      warning(
        '$runtimeType - cannot connect to device, the Polar identifier is null.',
      );
      return DeviceStatus.configured;
    }

    // Set listeners for Polar events and connect to the device.
    // We do not mark the device as fully connected before the data types are
    // available.
    try {
      // listen for battery level events
      _batterySubscription = polar.batteryLevel.listen((event) {
        _batteryLevel = event.level;
        _batteryEventController.add(_batteryLevel!);
      });

      // listen for connecting events
      _connectingSubscription = polar.deviceConnecting.listen(
        (_) => status = DeviceStatus.connecting,
      );

      // listen for connected events
      _connectedSubscription = polar.deviceConnected.listen((event) {
        // we do not mark the device as fully connected before the data types
        // are available - see below
        status = DeviceStatus.reconnected;
        bleAddress = event.address;
        bleName = event.name;
        rssi = event.rssi;
      });

      // listen for disconnected events
      _disconnectedSubscription = polar.deviceDisconnected.listen((event) {
        status = DeviceStatus.disconnecting;
        _batteryLevel = null;
        rssi = null;
      });

      // find out what data types the connected Polar device supports in streaming mode,
      // and mark the device as fully connected when the types are available
      polar.sdkFeatureReady
          .firstWhere(
            (event) =>
                event.identifier == polarIdentifier &&
                event.feature == PolarSdkFeature.onlineStreaming,
          )
          .then((_) {
            polar.getAvailableOnlineStreamDataTypes(polarIdentifier!).then((
              availableDataTypes,
            ) {
              dataTypes = availableDataTypes.toList();
              status = DeviceStatus.connected;
            });
          });

      // now finally, start connecting to the device based on its identifier
      polar.connectToDevice(polarIdentifier!, requestPermissions: true);
      return DeviceStatus.connecting;
    } catch (error) {
      warning(
        "$runtimeType - could not connect to device of type '$deviceType' and id '$polarIdentifier' - error: $error",
      );
      return DeviceStatus.disconnected;
    }
  }

  @override
  Future<bool> onDisconnect() async {
    if (polarIdentifier == null) return false;

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
