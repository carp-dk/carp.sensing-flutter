/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_polar_package.dart';

/// The Polar hardware models this package can tell apart.
///
/// [PolarDeviceManager.polarDeviceType] derives it from the BLE name.
enum PolarDeviceType {
  /// Unknown Polar type.
  Unknown,

  /// Polar H9 heart rate sensor.
  H9,

  /// Polar H10 heart rate sensor.
  H10,

  /// Polar Verity Sense optical heart rate sensor.
  Verity,
}

/// A Polar sensor used as a connected device in a protocol.
///
/// Add it with [SmartphoneStudyProtocol.addConnectedDevice] and use it as the
/// target device of tasks with Polar measures (see [PolarSamplingPackage]).
/// At runtime it is handled by a [PolarDeviceManager] and registered with a
/// [PolarDeviceRegistration].
///
/// Key points:
///  * Optional by default ([isOptional] is true), so a study can start
///    without it.
///  * [namePrefix] defaults to "Polar", so a BLE scan only shows Polar
///    devices.
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
/// Created by [PolarDeviceManager.createRegistration]. Holds the BLE address
/// and name plus the Polar [identifier], [polarDeviceType] and the data types
/// the device supports.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PolarDeviceRegistration extends BLEDeviceRegistration {
  /// Polar device id printed on the sensor/device or UUID. "Unknown" if not
  /// known.
  String identifier;

  /// The type of Polar device, if known.
  PolarDeviceType polarDeviceType;

  /// List of [PolarDataType]s that are available in the connected Polar device.
  /// Null if not known.
  List<PolarDataType>? supportedDataTypes;

  /// RSSI (Received Signal Strength Indicator) value from advertisement.
  int? rssi;

  /// Creates a registration.
  ///
  /// [deviceDisplayName] defaults to [bleName] and [hardwareName] defaults to
  /// the name of [polarDeviceType].
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

/// A [BLEDeviceManager] that connects to a Polar device.
///
/// Created by [PolarSamplingPackage] and used by the Polar probes to start
/// data streams through [polar], using [polarIdentifier].
///
/// The Polar BLE name is typically of the form
///
///  *  Polar Sense B34B4B56
///  *  Polar H10 B36KB56
///
/// I.e., on the form "Polar <type> <identifier>".
///
/// Key points:
///  * Connects using [polarIdentifier], not the BLE address. When paired, the
///    identifier is taken from the last part of the BLE name.
///  * The status becomes `reconnected` when the SDK reports the connection,
///    and `connected` once the device has reported the data types it
///    supports ([dataTypes]). Data types come from two SDK features (online
///    streaming and the HR service), which become ready independently.
///  * If connecting fails, it cancels its listeners so a later attempt does
///    not stack them.
///  * [onDisconnect] clears [batteryLevel] and [dataTypes].
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

  /// The [Polar] SDK handler, created on first use.
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

  /// The type of Polar device, based on the [bleName].
  ///
  /// Null if [bleName] is unknown or does not start with "Polar".
  /// [PolarDeviceType.Unknown] if the type part of the name is not recognized.
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

  /// RSSI (Received Signal Strength Indicator) value from advertisement.
  /// Cleared when the SDK reports a disconnect.
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

  /// Creates a device manager for the device [type], typically
  /// [PolarDevice.DEVICE_TYPE].
  PolarDeviceManager(super.type, {super.configuration});

  @override
  void onConfigure() {
    super.onConfigure();
    if (registration != null) {
      polarIdentifier = registration!.identifier;
    }
  }

  /// Sets [polarIdentifier] to the last part of the [bleName].
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

      // Data types come from two SDK features that become ready independently -
      // a device delivering HR over the standard BLE HR service only (e.g.
      // Verity Sense) never reports the online streaming (PMD) one.
      _sdkFeatureSubscription = polar.sdkFeatureReady
          .where((event) => event.identifier == polarIdentifier)
          .listen((event) async {
            Set<PolarDataType> available = {};
            if (event.feature == PolarSdkFeature.onlineStreaming) {
              available = await polar.getAvailableOnlineStreamDataTypes(
                polarIdentifier!,
              );
            } else if (event.feature == PolarSdkFeature.hr) {
              available = await polar.getAvailableHrServiceDataTypes(
                polarIdentifier!,
              );
            } else {
              return;
            }

            dataTypes = {...?dataTypes, ...available}.toList();
            status = DeviceStatus.connected;
          });

      // now finally, start connecting to the device based on its identifier
      polar.connectToDevice(polarIdentifier!, requestPermissions: true);
      return DeviceStatus.connecting;
    } catch (error) {
      warning(
        "$runtimeType - could not connect to device of type '$deviceType' and id '$polarIdentifier' - error: $error",
      );
      // Clean up the listeners set up above, so a later attempt does not stack
      // subscriptions on a half-connected device.
      await onDisconnect();
      return DeviceStatus.disconnected;
    }
  }

  @override
  Future<bool> onDisconnect() async {
    if (polarIdentifier == null) return false;

    _batteryLevel = null;
    dataTypes = null;
    // Disconnecting below makes the SDK emit a disconnect event, which must not
    // reach these listeners anymore.
    await Future.wait([
      ?_batterySubscription?.cancel(),
      ?_connectingSubscription?.cancel(),
      ?_connectedSubscription?.cancel(),
      ?_disconnectedSubscription?.cancel(),
      ?_sdkFeatureSubscription?.cancel(),
    ]);

    await polar.disconnectFromDevice(polarIdentifier!);

    return true;
  }
}
