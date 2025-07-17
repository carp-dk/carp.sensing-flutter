/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../connectivity.dart';

/// Connection status of a device.
enum ConnectivityStatus {
  /// Device connected via Bluetooth.
  bluetooth,

  /// Device connected via WiFi.
  wifi,

  /// Device connected to ethernet network.
  ethernet,

  /// Device connected to cellular network.
  mobile,

  /// Device not connected to any network.
  none,

  /// Device connected to a VPN.
  vpn,

  /// Unknown connectivity status.
  unknown,
}

/// Holds connectivity status of the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Connectivity extends Data {
  static const dataType = ConnectivitySamplingPackage.CONNECTIVITY;

  /// The status of the connectivity.
  List<ConnectivityStatus> connectivityStatus = [];

  Connectivity() : super();

  Connectivity.fromConnectivityResult(List<connectivity.ConnectivityResult> result) : super() {
    connectivityStatus = result.map((connectivity.ConnectivityResult e) => _parseConnectivityStatus(e)).toList();
  }

  @override
  Function get fromJsonFunction => _$ConnectivityFromJson;
  factory Connectivity.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Connectivity>(json);
  @override
  Map<String, dynamic> toJson() => _$ConnectivityToJson(this);

  static ConnectivityStatus _parseConnectivityStatus(connectivity.ConnectivityResult result) {
    switch (result) {
      case connectivity.ConnectivityResult.bluetooth:
        return ConnectivityStatus.bluetooth;
      case connectivity.ConnectivityResult.wifi:
        return ConnectivityStatus.wifi;
      case connectivity.ConnectivityResult.mobile:
        return ConnectivityStatus.mobile;
      case connectivity.ConnectivityResult.ethernet:
        return ConnectivityStatus.ethernet;
      case connectivity.ConnectivityResult.vpn:
        return ConnectivityStatus.vpn;
      case connectivity.ConnectivityResult.none:
        return ConnectivityStatus.none;
      default:
        return ConnectivityStatus.unknown;
    }
  }

  @override
  String toString() => '${super.toString()}, connectivityStatus: $connectivityStatus';
}

/// A [Data] holding information of nearby Bluetooth devices.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Bluetooth extends Data {
  static const dataType = ConnectivitySamplingPackage.BLUETOOTH;

  /// Timestamp of scan start.
  late DateTime startScan;

  /// Timestamp of scan end, if available.
  DateTime? endScan;

  /// A map of [BluetoothDevice] indexed by their [bluetoothDeviceId] to make
  /// sure that the same device only appears once.
  final Map<String, BluetoothDevice> _scanResult = {};

  /// The list of [BluetoothDevice] found in a scan.
  List<BluetoothDevice> get scanResult => _scanResult.values.toList();
  set scanResult(List<BluetoothDevice> devices) =>
      _scanResult.addEntries(devices.map((device) => MapEntry(device.bluetoothDeviceId, device)));

  Bluetooth({DateTime? startScan, this.endScan}) : super() {
    this.startScan = startScan ?? DateTime.now();
  }

  void addBluetoothDevice(BluetoothDevice device) => _scanResult[device.bluetoothDeviceId] = device;

  void addBluetoothDevicesFromScanResults(List<ScanResult> results) {
    for (var scanResult in results) {
      addBluetoothDevice(BluetoothDevice.fromScanResult(scanResult));
    }
  }

  void addBluetoothDevicesFromRangingResults(
    Beacon result,
    String beaconName,
  ) {
    addBluetoothDevice(BluetoothDevice.fromRangingResult(result, beaconName));
  }

  @override
  Function get fromJsonFunction => _$BluetoothFromJson;
  factory Bluetooth.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Bluetooth>(json);
  @override
  Map<String, dynamic> toJson() => _$BluetoothToJson(this);

  @override
  String toString() => '${super.toString()}, scanResult: $scanResult';
}

/// Bluetooth device data.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BluetoothDevice {
  /// The bluetooth advertising name of the device.
  String advertisementName;

  /// The bluetooth id of the nearby device.
  String bluetoothDeviceId;

  /// The bluetooth name of the nearby device.
  String bluetoothDeviceName;

  /// Is the device connectable.
  bool connectable;

  /// The power level of the device in percentage.
  int? txPowerLevel;

  /// The RSSI signal strength to the device.
  int rssi;

  BluetoothDevice({
    required this.advertisementName,
    required this.bluetoothDeviceId,
    required this.bluetoothDeviceName,
    required this.connectable,
    required this.rssi,
    this.txPowerLevel,
  }) : super();

  factory BluetoothDevice.fromScanResult(ScanResult result) => BluetoothDevice(
        bluetoothDeviceId: result.device.remoteId.str,
        bluetoothDeviceName: result.device.platformName,
        connectable: result.advertisementData.connectable,
        txPowerLevel: result.advertisementData.txPowerLevel,
        advertisementName: result.advertisementData.advName,
        rssi: result.rssi,
      );

  factory BluetoothDevice.fromRangingResult(Beacon result, String beaconName) => BluetoothDevice(
        bluetoothDeviceId: beaconName,
        bluetoothDeviceName: beaconName,
        connectable: false,
        txPowerLevel: result.txPower,
        advertisementName: beaconName,
        rssi: result.rssi,
      );

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) => _$BluetoothDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$BluetoothDeviceToJson(this);

  @override
  String toString() => '$runtimeType - '
      ', advertisementName: $advertisementName'
      ', id: $bluetoothDeviceId'
      ', name: $bluetoothDeviceName'
      ', connectable: $connectable'
      ', rssi: $rssi';
}

/// A [Data] holding wifi connectivity status in terms of connected SSID
/// and BSSID.
///
/// Note that it wifi information cannot be collected on emulators.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Wifi extends Data {
  static const dataType = ConnectivitySamplingPackage.WIFI;

  /// The wifi service set ID (SSID) of the connected network
  String? ssid;

  /// The basic service set identifier (BSSID) of the connected network
  String? bssid;

  /// The internet protocol (IP) address of the connected network
  String? ip;

  Wifi({
    this.ssid,
    this.bssid,
    this.ip,
  }) : super();

  @override
  Function get fromJsonFunction => _$WifiFromJson;
  factory Wifi.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Wifi>(json);
  @override
  Map<String, dynamic> toJson() => _$WifiToJson(this);

  @override
  String toString() => '${super.toString()}, SSID: $ssid, BSSID: $bssid, IP: $ip';
}

/// Beacon Region to use when monitoring for beacons.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BeaconRegion {
  /// A unique identifier for the beacon region.
  /// Used to distinguish between different regions being monitored.
  String identifier;

  /// The proximity UUID of the beacon.
  /// This is a 128-bit value used to identify a group of related beacons.
  String uuid;

  /// The major value of the beacon region (optional).
  /// Used to further distinguish a subset of beacons within the same UUID.
  int? major;

  /// The minor value of the beacon region (optional).
  /// Provides a finer granularity within a group of beacons identified by the same UUID and major value.
  int? minor;

  BeaconRegion({
    required this.identifier,
    required this.uuid,
    this.major,
    this.minor,
  });

  Region toRegion() {
    return Region(
      identifier: identifier,
      proximityUUID: uuid,
      major: major,
      minor: minor,
    );
  }

  @override
  String toString() => '${super.toString()}, Identifier: $identifier, UUID: $uuid, Major: $major, Minor: $minor';
}
