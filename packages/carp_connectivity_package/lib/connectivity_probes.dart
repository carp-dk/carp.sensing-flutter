/*
 * Copyright 2018-2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../connectivity.dart';

/// Collects a [Connectivity] measurement every time the phone's connectivity
/// status changes.
///
/// Used for the [ConnectivitySamplingPackage.CONNECTIVITY] measure. Also
/// collects the current status when sampling is resumed.
class ConnectivityProbe extends StreamProbe {
  @override
  Future<bool> onResume() async {
    // collect the current connectivity status on sampling start
    var connectivityStatus = await connectivity.Connectivity()
        .checkConnectivity();
    addMeasurement(
      Measurement.fromData(
        Connectivity.fromConnectivityResult(connectivityStatus),
      ),
    );

    return super.onResume();
  }

  @override
  Stream<Measurement> get stream =>
      connectivity.Connectivity().onConnectivityChanged.map(
        (event) =>
            Measurement.fromData(Connectivity.fromConnectivityResult(event)),
      );
}

// This probe requests access to location permissions (both on Android and iOS).
// See https://pub.dev/packages/network_info_plus
/// Collects the phone's wifi connection (SSID, BSSID and IP) as [Wifi] data.
///
/// Used for the [ConnectivitySamplingPackage.WIFI] measure, at the interval
/// set in an [IntervalSamplingConfiguration].
///
/// To make this probe work on iOS (especially after iOS 12 and 13), the app
/// must meet a set of requirements. See
///
///  * [network_info_plus](https://pub.dev/packages/network_info_plus)
///  * [CNCopyCurrentNetworkInfo](https://developer.apple.com/documentation/systemconfiguration/1614126-cncopycurrentnetworkinfo)
///
/// Does not work on emulators (values are null).
///
/// From Android 10.0 onwards the `ACCESS_FINE_LOCATION` permission must be
/// granted.
class WifiProbe extends IntervalProbe {
  @override
  Future<Measurement> getMeasurement() async {
    String? ssid = await NetworkInfo().getWifiName();
    String? bssid = await NetworkInfo().getWifiBSSID();
    String? ip = await NetworkInfo().getWifiIP();

    return Measurement.fromData(Wifi(ssid: ssid, bssid: bssid, ip: ip));
  }
}

/// Scans for nearby, visible Bluetooth devices and collects a [Bluetooth]
/// measurement that lists each device found during the scan.
///
/// Used for the [ConnectivitySamplingPackage.BLUETOOTH] measure. Uses a
/// [PeriodicSamplingConfiguration] for the interval and duration of the scan.
/// Use a [BluetoothScanPeriodicSamplingConfiguration] to filter by [services]
/// and [remoteIds]. If the scan fails, the measurement holds an [Error].
class BluetoothProbe extends BufferingPeriodicStreamProbe {
  /// Default scan timeout in milliseconds (4 seconds), used if no duration
  /// is configured.
  static const DEFAULT_TIMEOUT = 4 * 1000;
  Data? _data;

  @override
  Stream<dynamic> get bufferingStream => FlutterBluePlus.scanResults;

  @override
  Future<Measurement?> getMeasurement() async =>
      _data != null ? Measurement.fromData(_data!) : null;

  // if a BT-specific sampling configuration is used, we need to
  // extract the services and remoteIds from it so FlutterBluePlus can
  // perform filtered scanning

  /// The service UUIDs to filter the scan on. Empty if no
  /// [BluetoothScanPeriodicSamplingConfiguration] is used.
  List<Guid> get services =>
      (samplingConfiguration is BluetoothScanPeriodicSamplingConfiguration)
      ? (samplingConfiguration as BluetoothScanPeriodicSamplingConfiguration)
            .withServices
            .map((e) => Guid(e))
            .toList()
      : [];

  /// The remote device ids to filter the scan on. Empty if no
  /// [BluetoothScanPeriodicSamplingConfiguration] is used.
  List<String> get remoteIds =>
      (samplingConfiguration is BluetoothScanPeriodicSamplingConfiguration)
      ? (samplingConfiguration as BluetoothScanPeriodicSamplingConfiguration)
            .withRemoteIds
      : [];

  @override
  void onSamplingStart() {
    _data = Bluetooth();

    // startScan is async - a plain try/catch would not catch its errors
    // (e.g. adapter not ready yet on iOS: CBManagerStateUnknown).
    FlutterBluePlus.startScan(
      withServices: services,
      withRemoteIds: remoteIds,
      timeout:
          samplingConfiguration?.duration ??
          const Duration(milliseconds: DEFAULT_TIMEOUT),
    ).catchError((Object error) {
      _data = Error(message: 'Error scanning for bluetooth - $error');
    });
  }

  @override
  void onSamplingEnd() {
    FlutterBluePlus.stopScan().catchError((Object error) {
      _data = Error(message: 'Error stopping bluetooth scan - $error');
    });

    if (_data is Bluetooth) (_data as Bluetooth).endScan = DateTime.now();
  }

  @override
  void onSamplingData(event) {
    if (_data is Bluetooth && event is List<ScanResult>) {
      (_data as Bluetooth).addBluetoothDevicesFromScanResults(event);
    }
  }
}

/// Monitors iBeacon regions and collects a [BeaconData] measurement listing
/// each nearby [BeaconDevice] while the phone is inside a region.
///
/// Used for the [ConnectivitySamplingPackage.BEACON] measure. Uses a
/// [BeaconRangingPeriodicSamplingConfiguration] for the [beaconRegions] to
/// monitor and the [beaconDistance]. Only beacons closer than [beaconDistance]
/// are included. Does not start if no regions are configured.
class BeaconProbe extends StreamProbe {
  @override
  BeaconRangingPeriodicSamplingConfiguration? get samplingConfiguration =>
      super.samplingConfiguration as BeaconRangingPeriodicSamplingConfiguration;

  /// The configured regions, converted to the beacon plugin's [Region] type.
  List<Region> get beaconRegions =>
      samplingConfiguration?.beaconRegions
          .map((region) => region.toRegion())
          .toList() ??
      [];

  /// The maximum beacon distance in meters. Default is 2.
  int get beaconDistance => samplingConfiguration?.beaconDistance ?? 2;

  @override
  bool onInitialize() {
    super.onInitialize();
    if (beaconRegions.isEmpty) {
      warning(
        '$runtimeType - No beacon regions specified for monitoring. Will not start monitoring.',
      );
      return false;
    }

    try {
      info('$runtimeType - Initializing iBeacon scanning...');
      flutterBeacon.initializeScanning.then(
        (_) {
          info('$runtimeType - Initialized.');
          return true;
        },
        onError: (Object error) {
          warning('$runtimeType - Error while initializing scanner - $error');
          return false;
        },
      );
    } catch (error) {
      warning('$runtimeType - Error while initializing scanner - $error');
      return false;
    }
    return true;
  }

  @override
  Stream<Measurement> get stream async* {
    await for (final monitoringResult in flutterBeacon.monitoring(
      beaconRegions,
    )) {
      if (monitoringResult.monitoringState == MonitoringState.inside) {
        debug(
          '$runtimeType - Entered region: ${monitoringResult.region.identifier}',
        );

        yield* flutterBeacon.ranging(beaconRegions).map((rangingResult) {
          final closeBeacons = rangingResult.beacons
              .where((beacon) => beacon.accuracy <= beaconDistance)
              .toList();

          return Measurement.fromData(
            BeaconData.fromRegionAndBeacons(
              region: rangingResult.region.identifier,
              beacons: closeBeacons,
            ),
          );
        });
      } else if (monitoringResult.monitoringState == MonitoringState.outside) {
        debug(
          '$runtimeType - Exited region: ${monitoringResult.region.identifier}',
        );
      }
    }
  }
}
