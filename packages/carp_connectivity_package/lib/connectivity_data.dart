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

/// The connectivity status of the phone.
///
/// Collected by [ConnectivityProbe] for the
/// [ConnectivitySamplingPackage.CONNECTIVITY] measure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Connectivity extends Data {
  /// The active connection types. Can hold more than one, e.g. wifi and vpn.
  List<ConnectivityStatus> connectivityStatus = [];

  Connectivity() : super();

  /// Creates a [Connectivity] from the `connectivity_plus` plugin's results.
  Connectivity.fromConnectivityResult(
    List<connectivity.ConnectivityResult> result,
  ) : super() {
    connectivityStatus = result
        .map((connectivity.ConnectivityResult e) => _parseConnectivityStatus(e))
        .toList();
  }

  @override
  Function get fromJsonFunction => _$ConnectivityFromJson;
  factory Connectivity.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Connectivity>(json);
  @override
  Map<String, dynamic> toJson() => _$ConnectivityToJson(this);

  static ConnectivityStatus _parseConnectivityStatus(
    connectivity.ConnectivityResult result,
  ) {
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
  String toString() =>
      '${super.toString()}, connectivityStatus: $connectivityStatus';
}

/// The nearby Bluetooth devices found in one scan.
///
/// Collected by [BluetoothProbe] for the [ConnectivitySamplingPackage.BLUETOOTH]
/// measure. Each device appears only once, keyed by its
/// [BluetoothDevice.bluetoothDeviceId].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Bluetooth extends Data {
  /// Timestamp of scan start.
  late DateTime startScan;

  /// Timestamp of scan end, if available.
  DateTime? endScan;

  // A map of [BluetoothDevice] indexed by their id to make
  // sure that the same device only appears once.
  final Map<String, BluetoothDevice> _scanResult = {};

  /// The list of [BluetoothDevice] found in a scan.
  ///
  /// Setting it adds the devices to the existing result.
  List<BluetoothDevice> get scanResult => _scanResult.values.toList();
  set scanResult(List<BluetoothDevice> devices) => _scanResult.addEntries(
    devices.map((device) => MapEntry(device.bluetoothDeviceId, device)),
  );

  Bluetooth({DateTime? startScan, this.endScan}) : super() {
    this.startScan = startScan ?? DateTime.now();
  }

  /// Adds [device], replacing any device with the same id.
  void addBluetoothDevice(BluetoothDevice device) =>
      _scanResult[device.bluetoothDeviceId] = device;

  /// Adds the devices in a list of `flutter_blue_plus` scan results.
  void addBluetoothDevicesFromScanResults(List<ScanResult> results) {
    for (var scanResult in results) {
      addBluetoothDevice(BluetoothDevice.fromScanResult(scanResult));
    }
  }

  /// Adds a beacon found by ranging as a device named [beaconName].
  void addBluetoothDevicesFromRangingResults(Beacon result, String beaconName) {
    addBluetoothDevice(BluetoothDevice.fromRangingResult(result, beaconName));
  }

  @override
  Function get fromJsonFunction => _$BluetoothFromJson;
  factory Bluetooth.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Bluetooth>(json);
  @override
  Map<String, dynamic> toJson() => _$BluetoothToJson(this);

  @override
  String toString() => '${super.toString()}, scanResult: $scanResult';
}

/// A Bluetooth device found in a scan, as listed in [Bluetooth].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BluetoothDevice {
  /// The bluetooth advertising name of the device.
  String advertisementName;

  /// The bluetooth id of the nearby device.
  String bluetoothDeviceId;

  /// The bluetooth name of the nearby device.
  String bluetoothDeviceName;

  /// Whether the device is connectable.
  bool connectable;

  /// The advertised transmit power level, if available.
  int? txPowerLevel;

  /// The RSSI signal strength to the device, in dBm.
  int rssi;

  BluetoothDevice({
    required this.advertisementName,
    required this.bluetoothDeviceId,
    required this.bluetoothDeviceName,
    required this.connectable,
    required this.rssi,
    this.txPowerLevel,
  }) : super();

  /// Creates a [BluetoothDevice] from a `flutter_blue_plus` [ScanResult].
  factory BluetoothDevice.fromScanResult(ScanResult result) => BluetoothDevice(
    bluetoothDeviceId: result.device.remoteId.str,
    bluetoothDeviceName: result.device.platformName,
    connectable: result.advertisementData.connectable,
    txPowerLevel: result.advertisementData.txPowerLevel,
    advertisementName: result.advertisementData.advName,
    rssi: result.rssi,
  );

  /// Creates a [BluetoothDevice] from a ranged [Beacon], using [beaconName]
  /// as id and names.
  factory BluetoothDevice.fromRangingResult(Beacon result, String beaconName) =>
      BluetoothDevice(
        bluetoothDeviceId: beaconName,
        bluetoothDeviceName: beaconName,
        connectable: false,
        txPowerLevel: result.txPower,
        advertisementName: beaconName,
        rssi: result.rssi,
      );

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) =>
      _$BluetoothDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$BluetoothDeviceToJson(this);

  @override
  String toString() =>
      '$runtimeType - '
      ', advertisementName: $advertisementName'
      ', id: $bluetoothDeviceId'
      ', name: $bluetoothDeviceName'
      ', connectable: $connectable'
      ', rssi: $rssi';
}

/// The wifi network the phone is connected to (SSID, BSSID and IP).
///
/// Collected by [WifiProbe] for the [ConnectivitySamplingPackage.WIFI] measure.
/// Wifi information cannot be collected on emulators.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Wifi extends Data {
  /// The wifi service set ID (SSID) of the connected network.
  String? ssid;

  /// The basic service set identifier (BSSID) of the connected network.
  String? bssid;

  /// The IP address of the phone on the connected network.
  String? ip;

  Wifi({this.ssid, this.bssid, this.ip}) : super();

  @override
  Function get fromJsonFunction => _$WifiFromJson;
  factory Wifi.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Wifi>(json);
  @override
  Map<String, dynamic> toJson() => _$WifiToJson(this);

  @override
  String toString() =>
      '${super.toString()}, SSID: $ssid, BSSID: $bssid, IP: $ip';
}

/// The nearby beacons found in a monitored beacon region.
///
/// Collected by [BeaconProbe] for the [ConnectivitySamplingPackage.BEACON]
/// measure. Each beacon appears only once, keyed by its [BeaconDevice.uuid].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BeaconData extends Data {
  /// The unique identifier of the region that this beacon belongs to.
  String region;

  // A map of [BeaconDevice] indexed by their UUID to make
  // sure that the same device only appears once.
  final Map<String, BeaconDevice> _scanResult = {};

  /// The list of [BeaconDevice] found in a scan.
  ///
  /// Setting it adds the devices to the existing result.
  List<BeaconDevice> get scanResult => _scanResult.values.toList();
  set scanResult(List<BeaconDevice> devices) => _scanResult.addEntries(
    devices.map((device) => MapEntry(device.uuid, device)),
  );

  /// Creates a [BeaconData] instance with the specified region.
  BeaconData({required this.region}) : super();

  /// Creates a [BeaconData] instance from a region and a list of beacons.
  BeaconData.fromRegionAndBeacons({
    required this.region,
    required List<Beacon> beacons,
  }) : super() {
    scanResult = beacons
        .map(
          (beacon) => BeaconDevice(
            uuid: beacon.proximityUUID,
            rssi: beacon.rssi,
            major: beacon.major,
            minor: beacon.minor,
            accuracy: beacon.accuracy,
            proximity: beacon.proximity,
          ),
        )
        .toList();
  }

  /// Adds [device], replacing any device with the same UUID.
  void addBeaconDevice(BeaconDevice device) =>
      _scanResult[device.uuid] = device;

  /// Sets [region] and adds all beacons from a beacon plugin [RangingResult].
  void addBeaconDevicesFromRangingResults(RangingResult result) {
    region = result.region.identifier;
    for (var beacon in result.beacons) {
      addBeaconDevice(BeaconDevice.fromRegionAndBeacon(beacon));
    }
  }

  @override
  Function get fromJsonFunction => _$BeaconDataFromJson;
  factory BeaconData.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BeaconData>(json);
  @override
  Map<String, dynamic> toJson() => _$BeaconDataToJson(this);

  @override
  String get jsonType => ConnectivitySamplingPackage.BEACON;

  @override
  String toString() => '${super.toString()}, scanResult: $scanResult';
}

/// A beacon found by ranging, as listed in [BeaconData].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BeaconDevice {
  /// The proximity UUID of the beacon.
  String uuid;

  /// The RSSI signal strength to the device, in dBm.
  int rssi;

  /// Major value (for iBeacon).
  int? major;

  /// Minor value (for iBeacon).
  int? minor;

  /// The estimated distance to the beacon, in meters.
  double? accuracy;

  /// The proximity zone of the beacon (e.g., immediate, near, far).
  final Proximity? proximity;

  BeaconDevice({
    required this.rssi,
    required this.uuid,
    this.major,
    this.minor,
    this.accuracy,
    this.proximity,
  }) : super();

  /// Creates a [BeaconDevice] from a ranged [Beacon].
  BeaconDevice.fromRegionAndBeacon(Beacon beacon)
    : this(
        rssi: beacon.rssi,
        uuid: beacon.proximityUUID,
        major: beacon.major,
        minor: beacon.minor,
        accuracy: beacon.accuracy,
        proximity: beacon.proximity,
      );

  factory BeaconDevice.fromJson(Map<String, dynamic> json) =>
      _$BeaconDeviceFromJson(json);
  Map<String, dynamic> toJson() => _$BeaconDeviceToJson(this);

  @override
  String toString() =>
      '$runtimeType - '
      ', uuid: $uuid, major: $major, minor: $minor, accuracy: $accuracy'
      ', rssi: $rssi';
}
