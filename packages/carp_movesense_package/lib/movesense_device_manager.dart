/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movesense_package.dart';

/// Enumeration of supported Movesense devices.
enum MovesenseDeviceType {
  /// Unknown Movesense type
  UNKNOWN,

  /// Movesense Medical sensor
  MD,

  /// Movesense ACTIVE HR+
  HR_PLUS,

  /// Movesense ACTIVE HR2 sensor
  HR2,

  /// Movesense FLASH sensor
  FLASH,
}

@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseDevice extends BLEDevice<MovesenseDeviceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.MovesenseDevice';

  static const String DEFAULT_ROLE_NAME = 'Movesense ECG Device';

  MovesenseDevice({
    super.roleName = MovesenseDevice.DEFAULT_ROLE_NAME,
    super.isOptional = true,
  });

  @override
  Function get fromJsonFunction => _$MovesenseDeviceFromJson;
  factory MovesenseDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovesenseDevice;
  @override
  Map<String, dynamic> toJson() => _$MovesenseDeviceToJson(this);
}

/// A [DeviceRegistration] for a Movesense device.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MovesenseDeviceRegistration extends BLEDeviceRegistration {
  /// The Movesense device serial number.
  String? serial;

  /// The type of Movesense device, if known.
  MovesenseDeviceType movesenseDeviceType;

  /// The detailed device info for the connected Movesense device.
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  Map<String, dynamic>? deviceInfo;

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
  }) : super(
         deviceDisplayName: deviceDisplayName ?? bleName,
         hardwareName: hardwareName ?? movesenseDeviceType.name,
       );

  @override
  Function get fromJsonFunction => _$MovesenseDeviceRegistrationFromJson;
  factory MovesenseDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovesenseDeviceRegistration;
  @override
  Map<String, dynamic> toJson() => _$MovesenseDeviceRegistrationToJson(this);
}

/// A [BLEDeviceManager] for managing Movesense devices.
///
/// Typical BLE name is "Movesense 220330000122".
class MovesenseDeviceManager
    extends BLEDeviceManager<MovesenseDevice, MovesenseDeviceRegistration> {
  int? _batteryLevel;
  final StreamController<int> _batteryEventController =
      StreamController.broadcast();

  MovesenseDeviceManager(super.type);

  @override
  int? get batteryLevel => _batteryLevel;

  /// The device info for the connected Movesense device.
  /// Only available after device is connected.
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  Map<String, dynamic>? deviceInfo;

  /// The type of Movesense device based on the "hw" property in the device info.
  MovesenseDeviceType get movesenseDeviceType {
    final hw = (deviceInfo?["hw"] as String?)?.toUpperCase();

    // Try to figure out the type of device based on the "hw" property
    // H3 is "HR+", H4 is "HR2", A1 is "MD"
    return switch (hw) {
      'A1' => MovesenseDeviceType.MD,
      'H3' => MovesenseDeviceType.HR_PLUS,
      'H4' => MovesenseDeviceType.HR2,
      _ => MovesenseDeviceType.UNKNOWN,
    };
  }

  @override
  MovesenseDeviceRegistration createRegistration() =>
      MovesenseDeviceRegistration(
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

  /// The serial number of the connected Movesense device.
  /// Returns null if not connected.
  String? serial;

  @override
  Future<DeviceStatus> onConnect() async {
    if (isConnected) return DeviceStatus.connected;
    if (bleAddress?.isEmpty ?? true) {
      warning(
        '$runtimeType - cannot connect to device, BLE address is missing.',
      );
      return DeviceStatus.disconnected;
    }

    status = DeviceStatus.connecting;

    Mds.connect(
      bleAddress!,
      // onConnected
      (String serial) {
        _connected(serial);
        status = DeviceStatus.connected;
      },
      // onDisconnected
      () {
        _batteryLevel = null;
        status = DeviceStatus.disconnected;
      },
      // onConnectionError
      (String error) {
        // Note that an "error" might be that the device is already connected,
        // and the error message would read like;
        //    "Already connected to 0C:8C:DC:1B:23:BF"
        //
        // In this case, we treat it as a "connected" event.
        if (error.startsWith('Already connected to')) {
          var serial = error.split(' ').last.trim();
          _connected(serial);
          status = DeviceStatus.connected;
        } else {
          warning("$runtimeType - Error in connecting to device: $error");
          // we return status to be initialized so that the user has a chance to reconnect
          status = DeviceStatus.configured;
        }
      },
      // onBleConnected
      // - for now we ignore this callback
      (_) {},
    );

    return status;
  }

  /// Mark the Movesense device with [serial] as connected.
  void _connected(String serial) {
    this.serial = serial;

    debug(
      "$runtimeType - Successfully connected to Movesense device, serial: $serial",
    );

    _getDeviceInfo();
    _getBatteryStatus();
  }

  /// Get the detailed info about this Movesense device.
  ///
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  ///
  /// Example response from the device see ../test/json/info.json
  void _getDeviceInfo() {
    // fast out if not connected
    if (serial == null) return;

    debug('$runtimeType - Getting device info.');

    Mds.get(Mds.createRequestUri(serial!, "/Info"), "{}", ((info, statusCode) {
      debug('$runtimeType - Movesense Device Info:\n$info');
      final dataContent = json.decode(info);
      deviceInfo = dataContent["Content"] as Map<String, dynamic>;
    }), (error, statusCode) => {});
  }

  /// Setting up a request (GET) for battery status at a regular interval.
  /// We can subscribe to battery state changes, but they come so rarely that its
  /// better to request the status.
  void _getBatteryStatus() {
    // fast out if not connected
    if (serial == null) return;

    _batteryLevel = 80;
    debug('$runtimeType - Setting up battery monitoring.');

    Timer.periodic(const Duration(minutes: 10), (_) {
      Mds.get(
        Mds.createRequestUri(serial!, "/System/States/1"),
        "{}",
        ((data, statusCode) {
          final dataContent = json.decode(data);
          num batteryState = dataContent["Content"] as num;
          // Movesense only reports "OK" (0) or "LOW" (1) battery state
          // This is translated to 80% & 10% battery level
          _batteryLevel = batteryState == 0 ? 80 : 10;
          _batteryEventController.add(_batteryLevel ?? 0);
        }),
        (error, statusCode) => {},
      );
    });
  }

  @override
  Future<bool> onDisconnect() async {
    if (bleAddress == null) {
      warning('$runtimeType - cannot disconnect from device, address is null.');
      return false;
    }
    debug("$runtimeType - Disconnecting from '$bleAddress'...");

    Mds.disconnect(bleAddress!);
    return true;
  }
}
