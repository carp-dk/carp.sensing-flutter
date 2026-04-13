// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connectivity _$ConnectivityFromJson(Map<String, dynamic> json) => Connectivity()
  ..$type = json['__type'] as String?
  ..connectivityStatus = (json['connectivityStatus'] as List<dynamic>)
      .map((e) => $enumDecode(_$ConnectivityStatusEnumMap, e))
      .toList();

Map<String, dynamic> _$ConnectivityToJson(Connectivity instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'connectivityStatus': instance.connectivityStatus
          .map((e) => _$ConnectivityStatusEnumMap[e]!)
          .toList(),
    };

const _$ConnectivityStatusEnumMap = {
  ConnectivityStatus.bluetooth: 'bluetooth',
  ConnectivityStatus.wifi: 'wifi',
  ConnectivityStatus.ethernet: 'ethernet',
  ConnectivityStatus.mobile: 'mobile',
  ConnectivityStatus.none: 'none',
  ConnectivityStatus.vpn: 'vpn',
  ConnectivityStatus.unknown: 'unknown',
};

Bluetooth _$BluetoothFromJson(Map<String, dynamic> json) =>
    Bluetooth(
        startScan: json['startScan'] == null
            ? null
            : DateTime.parse(json['startScan'] as String),
        endScan: json['endScan'] == null
            ? null
            : DateTime.parse(json['endScan'] as String),
      )
      ..$type = json['__type'] as String?
      ..scanResult = (json['scanResult'] as List<dynamic>)
          .map((e) => BluetoothDevice.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$BluetoothToJson(Bluetooth instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'startScan': instance.startScan.toIso8601String(),
  'endScan': ?instance.endScan?.toIso8601String(),
  'scanResult': instance.scanResult.map((e) => e.toJson()).toList(),
};

BluetoothDevice _$BluetoothDeviceFromJson(Map<String, dynamic> json) =>
    BluetoothDevice(
      advertisementName: json['advertisementName'] as String,
      bluetoothDeviceId: json['bluetoothDeviceId'] as String,
      bluetoothDeviceName: json['bluetoothDeviceName'] as String,
      connectable: json['connectable'] as bool,
      rssi: (json['rssi'] as num).toInt(),
      txPowerLevel: (json['txPowerLevel'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BluetoothDeviceToJson(BluetoothDevice instance) =>
    <String, dynamic>{
      'advertisementName': instance.advertisementName,
      'bluetoothDeviceId': instance.bluetoothDeviceId,
      'bluetoothDeviceName': instance.bluetoothDeviceName,
      'connectable': instance.connectable,
      'txPowerLevel': ?instance.txPowerLevel,
      'rssi': instance.rssi,
    };

Wifi _$WifiFromJson(Map<String, dynamic> json) => Wifi(
  ssid: json['ssid'] as String?,
  bssid: json['bssid'] as String?,
  ip: json['ip'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$WifiToJson(Wifi instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'ssid': ?instance.ssid,
  'bssid': ?instance.bssid,
  'ip': ?instance.ip,
};

BeaconData _$BeaconDataFromJson(Map<String, dynamic> json) =>
    BeaconData(region: json['region'] as String)
      ..$type = json['__type'] as String?
      ..scanResult = (json['scanResult'] as List<dynamic>)
          .map((e) => BeaconDevice.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$BeaconDataToJson(BeaconData instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'region': instance.region,
      'scanResult': instance.scanResult.map((e) => e.toJson()).toList(),
    };

BeaconDevice _$BeaconDeviceFromJson(Map<String, dynamic> json) => BeaconDevice(
  rssi: (json['rssi'] as num).toInt(),
  uuid: json['uuid'] as String,
  major: (json['major'] as num?)?.toInt(),
  minor: (json['minor'] as num?)?.toInt(),
  accuracy: (json['accuracy'] as num?)?.toDouble(),
  proximity: $enumDecodeNullable(_$ProximityEnumMap, json['proximity']),
);

Map<String, dynamic> _$BeaconDeviceToJson(BeaconDevice instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'rssi': instance.rssi,
      'major': ?instance.major,
      'minor': ?instance.minor,
      'accuracy': ?instance.accuracy,
      'proximity': ?_$ProximityEnumMap[instance.proximity],
    };

const _$ProximityEnumMap = {
  Proximity.unknown: 'unknown',
  Proximity.immediate: 'immediate',
  Proximity.near: 'near',
  Proximity.far: 'far',
};

BluetoothScanPeriodicSamplingConfiguration
_$BluetoothScanPeriodicSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => BluetoothScanPeriodicSamplingConfiguration(
  interval: Duration(microseconds: (json['interval'] as num).toInt()),
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  withServices:
      (json['withServices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  withRemoteIds:
      (json['withRemoteIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
)..$type = json['__type'] as String?;

Map<String, dynamic> _$BluetoothScanPeriodicSamplingConfigurationToJson(
  BluetoothScanPeriodicSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'interval': instance.interval.inMicroseconds,
  'duration': instance.duration.inMicroseconds,
  'withServices': instance.withServices,
  'withRemoteIds': instance.withRemoteIds,
};

BeaconRangingPeriodicSamplingConfiguration
_$BeaconRangingPeriodicSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => BeaconRangingPeriodicSamplingConfiguration(
  beaconRegions:
      (json['beaconRegions'] as List<dynamic>?)
          ?.map((e) => BeaconRegion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  beaconDistance: (json['beaconDistance'] as num?)?.toInt() ?? 2,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$BeaconRangingPeriodicSamplingConfigurationToJson(
  BeaconRangingPeriodicSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'beaconRegions': instance.beaconRegions.map((e) => e.toJson()).toList(),
  'beaconDistance': instance.beaconDistance,
};

BeaconRegion _$BeaconRegionFromJson(Map<String, dynamic> json) => BeaconRegion(
  identifier: json['identifier'] as String,
  uuid: json['uuid'] as String,
  major: (json['major'] as num?)?.toInt(),
  minor: (json['minor'] as num?)?.toInt(),
);

Map<String, dynamic> _$BeaconRegionToJson(BeaconRegion instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'uuid': instance.uuid,
      'major': ?instance.major,
      'minor': ?instance.minor,
    };
