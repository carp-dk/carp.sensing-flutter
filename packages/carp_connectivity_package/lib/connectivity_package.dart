part of '../connectivity.dart';

class ConnectivitySamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for continuous collection of connectivity status of the phone
  /// (none/mobile/wifi).
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * No sampling configuration needed.
  static const String CONNECTIVITY = "${NameSpace.CARP}.connectivity";

  /// Measure type for collection of nearby Bluetooth devices on a regular basis.
  ///  * Event-based (Periodic) measure - default every 10 minutes for 10 seconds.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * Use a [PeriodicSamplingConfiguration] for configuration.
  static const String BLUETOOTH = "${NameSpace.CARP}.bluetooth";

  /// Measure type for collection of wifi information (SSID, BSSID, IP).
  ///  * Event-based (Interval) measure - default every 10 minutes.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * Use a [IntervalSamplingConfiguration] for configuration.
  static const String WIFI = "${NameSpace.CARP}.wifi";

  /// Measure type for Beacon ranging to detect and estimate proximity to
  /// Bluetooth beacons (e.g., iBeacon, Eddystone).
  /// * Typically returns beacon identifiers (UUID, major, minor) and
  ///    estimated distance or RSSI.
  ///  * Use a [PeriodicSamplingConfiguration] for configuration.
  static const String BEACON = "${NameSpace.CARP}.beacon";

  @override
  DataTypeSamplingSchemeMap get samplingSchemes => DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: CONNECTIVITY,
            displayName: "Connectivity Status",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
            CamsDataTypeMetaData(
              type: BLUETOOTH,
              displayName: "Bluetooth Scan of Nearby Devices",
              timeType: DataTimeType.TIME_SPAN,
              permissions: [Permission.bluetoothScan],
            ),
            PeriodicSamplingConfiguration(
              interval: const Duration(minutes: 10),
              duration: const Duration(seconds: 10),
            )),
        DataTypeSamplingScheme(
            CamsDataTypeMetaData(
              type: WIFI,
              displayName: "Wifi Connectivity Status",
              timeType: DataTimeType.POINT,
            ),
            IntervalSamplingConfiguration(
              interval: const Duration(minutes: 10),
            )),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: BEACON,
            displayName: "Ranging beacons in proximity",
            timeType: DataTimeType.POINT,
            permissions: [Permission.bluetoothScan, Permission.locationAlways],
          ),
          PeriodicSamplingConfiguration(
            interval: const Duration(minutes: 10),
            duration: const Duration(seconds: 10),
          ),
        ),
      ]);

  @override
  Probe? create(String type) {
    switch (type) {
      case CONNECTIVITY:
        return ConnectivityProbe();
      case BLUETOOTH:
        return BluetoothProbe();
      case WIFI:
        return WifiProbe();
      case BEACON:
        return BeaconProbe();
      default:
        return null;
    }
  }

  @override
  void onRegister() {
    // register all data types
    FromJsonFactory().registerAll([
      Connectivity(),
      Bluetooth(),
      Wifi(),
      BluetoothScanPeriodicSamplingConfiguration(
        interval: const Duration(minutes: 10),
        duration: const Duration(seconds: 10),
      ),
    ]);

    // registering default privacy functions
    DataTransformerSchemaRegistry().lookup(PrivacySchema.DEFAULT)!.add(BLUETOOTH, bluetoothNameAnonymizer);
    DataTransformerSchemaRegistry().lookup(PrivacySchema.DEFAULT)!.add(WIFI, wifiNameAnonymizer);
  }
}

/// A sampling configuration specifying how to scan for Bluetooth devices on a
/// regular basis for a specific period.
///
/// Data collection will be started as specified by the [interval] for a time
/// period specified as the [duration]. Bluetooth scanning is filtering
/// on the [withServices] and [withRemoteIds] to only collect data from
/// specific services and remote ids.
///
/// Filtering on remoteIds allows Android to scan for devices in the background
/// without needing to be in the foreground. This is not possible on iOS.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BluetoothScanPeriodicSamplingConfiguration extends PeriodicSamplingConfiguration {
  /// List of Bluetooth service UUIDs to filter the scan results.
  List<String> withServices;

  /// List of remote device IDs to filter the scan results.
  List<String> withRemoteIds;


  BluetoothScanPeriodicSamplingConfiguration({
    required super.interval,
    required super.duration,
    this.withServices = const [],
    this.withRemoteIds = const [],
  });

  @override
  Map<String, dynamic> toJson() => _$BluetoothScanPeriodicSamplingConfigurationToJson(this);
  @override
  Function get fromJsonFunction => _$BluetoothScanPeriodicSamplingConfigurationFromJson;
  factory BluetoothScanPeriodicSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BluetoothScanPeriodicSamplingConfiguration>(json);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BeaconRangingPeriodicSamplingConfiguration extends PeriodicSamplingConfiguration {
  /// List of beacon regions to monitor and/or range using the `flutter_beacon` package.
  List<BeaconRegion?> beaconRegions;

  /// When a device is within this distance from the beacon, a predefined event is triggered.
  /// Defaults to 2 meters.
  int beaconDistance;

  BeaconRangingPeriodicSamplingConfiguration({
    required super.interval,
    required super.duration,
    this.beaconRegions = const [],
    this.beaconDistance = 2,
  });

  @override
  Map<String, dynamic> toJson() => _$BeaconRangingPeriodicSamplingConfigurationToJson(this);
  @override
  Function get fromJsonFunction => _$BeaconRangingPeriodicSamplingConfigurationFromJson;
  factory BeaconRangingPeriodicSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BeaconRangingPeriodicSamplingConfiguration>(json);
}
