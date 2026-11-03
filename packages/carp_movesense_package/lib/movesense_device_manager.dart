/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movesense_package.dart';

/// The Movesense hardware models this package can tell apart.
///
/// [MovesenseDeviceManager.movesenseDeviceType] derives it from the device
/// info after connecting.
enum MovesenseDeviceType {
  /// Unknown Movesense type.
  UNKNOWN,

  /// Movesense Medical sensor (hardware type "A1").
  MD,

  /// Movesense Active HR+ sensor (hardware type "H3").
  HR_PLUS,

  /// Movesense Active HR2 sensor (hardware type "H4").
  HR2,

  /// Movesense FLASH sensor. Not detected automatically.
  FLASH,
}

/// A Movesense sensor used as a connected device in a protocol.
///
/// Add it with [SmartphoneStudyProtocol.addConnectedDevice] and use it as the
/// target device of tasks with Movesense measures (see
/// [MovesenseSamplingPackage]). At runtime it is handled by a
/// [MovesenseDeviceManager] and registered with a
/// [MovesenseDeviceRegistration].
///
/// Key points:
///  * Optional by default ([isOptional] is true), so a study can start
///    without it.
///  * [namePrefix] defaults to "Movesense", so a BLE scan only shows
///    Movesense devices.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseDevice extends BLEDevice<MovesenseDeviceRegistration> {
  /// The device type of a Movesense device.
  static const String DEVICE_TYPE = '${CamsDevice.CAMS_DEVICE_NAMESPACE}.MovesenseDevice';

  /// The default role name of a Movesense device in a protocol.
  static const String DEFAULT_ROLE_NAME = 'Movesense ECG Device';

  MovesenseDevice({
    super.roleName = MovesenseDevice.DEFAULT_ROLE_NAME,
    super.isOptional = true,
    super.namePrefix = 'Movesense',
  });

  @override
  Function get fromJsonFunction => _$MovesenseDeviceFromJson;
  factory MovesenseDevice.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as MovesenseDevice;
  @override
  Map<String, dynamic> toJson() => _$MovesenseDeviceToJson(this);
}

/// A [DeviceRegistration] for a Movesense device.
///
/// Created by [MovesenseDeviceManager.createRegistration] when a device is
/// paired and connected. Holds the BLE address and name plus Movesense
/// specific info.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MovesenseDeviceRegistration extends BLEDeviceRegistration {
  /// The Movesense device serial number.
  ///
  /// Not set by [MovesenseDeviceManager.createRegistration] at the moment.
  String? serial;

  /// The type of Movesense device. [MovesenseDeviceType.UNKNOWN] if not known.
  MovesenseDeviceType movesenseDeviceType;

  /// The detailed device info for the connected Movesense device, as returned
  /// by the device's `/Info` resource.
  ///
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  Map<String, dynamic>? deviceInfo;

  /// Creates a registration.
  ///
  /// [deviceDisplayName] defaults to [bleName] and [hardwareName] defaults to
  /// the name of [movesenseDeviceType].
  MovesenseDeviceRegistration({
    String? deviceDisplayName,
    super.registrationCreatedOn,
    super.isConnected,
    super.batteryChargingState,
    String? hardwareName,
    required super.bleAddress,
    super.bleName,
    this.movesenseDeviceType = MovesenseDeviceType.UNKNOWN,
    this.deviceInfo,
  }) : super(deviceDisplayName: deviceDisplayName ?? bleName, hardwareName: hardwareName ?? movesenseDeviceType.name);

  @override
  Function get fromJsonFunction => _$MovesenseDeviceRegistrationFromJson;
  factory MovesenseDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovesenseDeviceRegistration;
  @override
  Map<String, dynamic> toJson() => _$MovesenseDeviceRegistrationToJson(this);
}

/// A [BLEDeviceManager] that connects to and monitors a Movesense device.
///
/// Created by [MovesenseSamplingPackage] and used by the Movesense probes to
/// reach the device through its [serial]. The typical BLE name is
/// "Movesense 220330000122".
///
/// Key points:
///  * Connects using the [bleAddress] set when pairing, through a
///    `movesense_plus` [device].
///  * On connect, `movesense_plus` reads the device info and battery state.
///    The battery state is then polled every 10 minutes.
///  * Movesense only reports "OK" or "LOW" battery, which is mapped to a
///    [batteryLevel] of 80% or 10%.
///  * If a connection attempt fails, it disconnects so the native SDK stops
///    retrying in the background.
class MovesenseDeviceManager extends BLEDeviceManager<MovesenseDevice, MovesenseDeviceRegistration> {
  final StreamController<int> _batteryEventController = StreamController.broadcast();
  StreamSubscription<ms.MovesenseDeviceStatus>? _statusSubscription;
  Timer? _batteryTimer;

  /// Creates a device manager for the device [type], typically
  /// [MovesenseDevice.DEVICE_TYPE].
  MovesenseDeviceManager(super.type);

  /// The `movesense_plus` device for [bleAddress]. Null until [connect] is called.
  ms.MovesenseDevice? device;

  @override
  int? get batteryLevel => switch (device?.batteryLevel) {
    ms.MovesenseBatteryLevel.ok => 80,
    ms.MovesenseBatteryLevel.low => 10,
    _ => null,
  };

  /// The device info for the connected Movesense device.
  ///
  /// Null until the device is connected and has answered the info request.
  ///
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  Map<String, dynamic>? get deviceInfo => device?.deviceInfo?.toJson();

  /// The serial number of the connected Movesense device.
  ///
  /// Null when not connected. Used to address the device in MDS requests.
  String? get serial => device?.serial;

  /// The type of Movesense device, based on the "hw" property in [deviceInfo].
  ///
  /// [MovesenseDeviceType.UNKNOWN] if [deviceInfo] is not yet available or the
  /// hardware type is not recognized.
  MovesenseDeviceType get movesenseDeviceType => switch (device?.deviceType) {
    ms.MovesenseDeviceType.md => MovesenseDeviceType.MD,
    ms.MovesenseDeviceType.hrPlus => MovesenseDeviceType.HR_PLUS,
    ms.MovesenseDeviceType.hr2 => MovesenseDeviceType.HR2,
    ms.MovesenseDeviceType.flash => MovesenseDeviceType.FLASH,
    _ => MovesenseDeviceType.UNKNOWN,
  };

  @override
  MovesenseDeviceRegistration createRegistration() => MovesenseDeviceRegistration(
    deviceDisplayName: bleName,
    isConnected: isConnected,
    bleAddress: bleAddress ?? 'Unknown Movesense Device',
    bleName: bleName,
    batteryChargingState: batteryLevel != null
        ? HardwareDeviceRegistration.parseBatteryLevel(batteryLevel!)
        : BatteryChargingState.unknown,
    movesenseDeviceType: movesenseDeviceType,
    deviceInfo: deviceInfo,
  );

  @override
  bool get canConnect => bleAddress != null;

  @override
  String? get displayName => bleName;

  @override
  Stream<int> get batteryEvents => _batteryEventController.stream;

  @override
  Future<DeviceStatus> onConnect() async {
    final address = bleAddress;
    if (address == null || address.isEmpty) {
      warning('$runtimeType - cannot connect to device, BLE address is missing.');
      return DeviceStatus.disconnected;
    }

    if (device?.address != address) {
      await _statusSubscription?.cancel();
      device = ms.MovesenseDevice(address: address, name: bleName);
      _statusSubscription = device!.statusEvents.listen(_onDeviceStatus);
    }

    await device!.connect();
    return device!.isConnected ? DeviceStatus.connected : DeviceStatus.connecting;
  }

  void _onDeviceStatus(ms.MovesenseDeviceStatus deviceStatus) {
    switch (deviceStatus) {
      case ms.MovesenseDeviceStatus.connecting:
        break;
      case ms.MovesenseDeviceStatus.connected:
        debug('$runtimeType - Connected to Movesense device, serial: $serial');
        _startBatteryPolling();
        status = DeviceStatus.connected;
      case ms.MovesenseDeviceStatus.disconnected:
        _batteryTimer?.cancel();
        status = DeviceStatus.disconnected;
      case ms.MovesenseDeviceStatus.error:
        warning('$runtimeType - Error in connecting to device: $bleAddress');
        _batteryTimer?.cancel();
        // Tear down the half-open connection, or the native SDK keeps
        // retrying it in the background.
        device?.disconnect().ignore();
        status = DeviceStatus.disconnected;
    }
  }

  /// Polls the battery state, since Movesense battery state changes are too
  /// rare to subscribe to.
  void _startBatteryPolling() {
    _batteryTimer?.cancel();
    _batteryTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      await device?.getBatteryStatus();
      final level = batteryLevel;
      if (level != null) _batteryEventController.add(level);
    });
  }

  @override
  Future<bool> onDisconnect() async {
    _batteryTimer?.cancel();
    if (device == null) {
      warning('$runtimeType - cannot disconnect from device, not connected.');
      return false;
    }
    debug("$runtimeType - Disconnecting from '$bleAddress'...");
    await device!.disconnect();
    return true;
  }
}
