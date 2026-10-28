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
///  * Connects using the [bleAddress] set when pairing.
///  * On connect, it reads [deviceInfo] and starts polling the battery state
///    every 10 minutes.
///  * Movesense only reports "OK" or "LOW" battery, which is mapped to a
///    [batteryLevel] of 80% or 10%.
///  * If a connection attempt fails, it disconnects so the native SDK stops
///    retrying in the background.
class MovesenseDeviceManager extends BLEDeviceManager<MovesenseDevice, MovesenseDeviceRegistration> {
  int? _batteryLevel;
  final StreamController<int> _batteryEventController = StreamController.broadcast();

  /// Creates a device manager for the device [type], typically
  /// [MovesenseDevice.DEVICE_TYPE].
  MovesenseDeviceManager(super.type);

  @override
  int? get batteryLevel => _batteryLevel;

  /// The device info for the connected Movesense device.
  ///
  /// Null until the device is connected and has answered the info request.
  ///
  /// See https://www.movesense.com/docs/esw/api_reference/#info
  Map<String, dynamic>? deviceInfo;

  /// The type of Movesense device, based on the "hw" property in [deviceInfo].
  ///
  /// [MovesenseDeviceType.UNKNOWN] if [deviceInfo] is not yet available or the
  /// hardware type is not recognized.
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

  /// The serial number of the connected Movesense device.
  ///
  /// Null until the device has connected. Used to address the device in MDS
  /// requests and subscriptions. Not cleared on disconnect.
  String? serial;

  @override
  Future<DeviceStatus> onConnect() async {
    if (isConnected) return DeviceStatus.connected;
    if (bleAddress?.isEmpty ?? true) {
      warning('$runtimeType - cannot connect to device, BLE address is missing.');
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
          // Tear down the half-open connection, or the native SDK keeps
          // retrying it in the background.
          Mds.disconnect(bleAddress!);
          status = DeviceStatus.disconnected;
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

    debug("$runtimeType - Successfully connected to Movesense device, serial: $serial");

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

  /// Sets up a request (GET) for battery status at a regular interval.
  /// We can subscribe to battery state changes, but they come so rarely that it
  /// is better to request the status.
  void _getBatteryStatus() {
    // fast out if not connected
    if (serial == null) return;

    _batteryLevel = 80;
    debug('$runtimeType - Setting up battery monitoring.');

    Timer.periodic(const Duration(minutes: 10), (_) {
      Mds.get(Mds.createRequestUri(serial!, "/System/States/1"), "{}", ((data, statusCode) {
        final dataContent = json.decode(data);
        num batteryState = dataContent["Content"] as num;
        // Movesense only reports "OK" (0) or "LOW" (1) battery state
        // This is translated to 80% & 10% battery level
        _batteryLevel = batteryState == 0 ? 80 : 10;
        _batteryEventController.add(_batteryLevel ?? 0);
      }), (error, statusCode) => {});
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
