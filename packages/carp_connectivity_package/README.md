# CARP Connectivity Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_connectivity_package.svg)](https://pub.dev/packages/carp_connectivity_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

This library contains a sampling package for collection of connectivity related measures to work with the [`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing) framework.
This package supports sampling of the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types) types:

* `dk.cachet.carp.wifi`
* `dk.cachet.carp.connectivity`
* `dk.cachet.carp.bluetooth`
* `dk.cachet.carp.beacon`

See the [CAMS documentation site](https://docs.carp.dk/carp-mobile-sensing/) for further documentation.
See the [CARP Mobile Sensing App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app) for an example of how to build a mobile sensing app in Flutter.

There is privacy protection of wifi and bluetooth names as part of the default [Privacy Schema](https://docs.carp.dk/carp-mobile-sensing/data-transformation-and-privacy#privacy-transformer-schemas).

For Flutter plugins for other CARP products, see [CARP Mobile Sensing in Flutter](https://github.com/cph-cachet/carp.sensing-flutter).

If you're interested in writing your own sampling packages for CARP, see the description on
how to [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) CARP Mobile Sensing.

## Installing

To use this package, add the following to your `pubspec.yaml` file. Note that this package only works together with [`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing).

`````dart
dependencies:
  flutter:
    sdk: flutter
  carp_mobile_sensing: ^latest
  carp_connectivity_package: ^latest
  ...
`````

### Android

As explained in the Android [Wi-Fi scanning overview](https://developer.android.com/guide/topics/connectivity/wifi-scan), access to wifi information requires location access and wifi access permissions.
As explained in the [dchs_flutter_beacon](https://pub.dev/packages/dchs_flutter_beacon#setup-specific-for-android) plugin, access to iBeacons requires location access and Bluetooth access permissions.
In summary, you should add the following to your app's `AndroidManifest.xml` file located in `android/app/src/main`:

````xml
<!-- Required for accessing location information -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Optional: background scanning -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Required for accessing network information -->
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

<!-- Required for BLE scanning on Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- Recommended when checking Bluetooth state or prompting the user to enable Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
````

> [!IMPORTANT]  
> Connectivity changes are **not** communicated to Android apps in the background starting with Android 8 (SDK 26). Hence, connectivity status is only collected when your app is resumed.

### iOS

Access to network information on iOS is highly restricted.
From iOS >= 13 there is no longer direct access to wifi information.
See the [network_info_plus](https://pub.dev/packages/network_info_plus#ios) description
and the [iOS](https://developer.apple.com/documentation/systemconfiguration/1614126-cncopycurrentnetworkinfo) description.

To enable bluetooth tracking, add these permissions in the `Info.plist` file located in `ios/Runner`:

````xml
<!-- Bluetooth Privacy -->
<!-- for iOS 13 + -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Reason why app needs bluetooth</string>
<key>UIBackgroundModes</key>
  <array>
  <string>bluetooth-central</string>
  <string>bluetooth-peripheral</string>
  <string>external-accessory</string>
  <string>fetch</string>
</array>
````

> [!NOTE]
> On iOS, it is [impossible to do a general Bluetooth scan when the screen is off or the app is in background](https://developer.apple.com/forums/thread/652592). This will simply result in an empty scan. Hence, bluetooth devices are only collected when the app is in the foreground.

To collect iBeacon measurements, please follow the setup described in the [dchs_flutter_beacon](https://pub.dev/packages/dchs_flutter_beacon) plugin. Especially, for iOS you need permissions to access location information in the `Info.plist` file:

````xml
<!-- When in use -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Reason why app needs location</string>
<!-- Always -->
<!-- for iOS 11 + -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Reason why app needs location</string>
<!-- for iOS 9/10 -->
<key>NSLocationAlwaysUsageDescription</key>
<string>Reason why app needs location</string>
````

## Using it

To use this package, import it into your app together with the
[`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package:

`````dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_connectivity_package/connectivity.dart';
`````

Before creating a study and running it, register this package in the
[`SamplingPackageRegistry`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry-class.html).

`````dart
SamplingPackageRegistry().register(ConnectivitySamplingPackage());
`````

Collection of connectivity measures can be added to a study protocol like this.

```dart
// Create a study protocol
StudyProtocol protocol = StudyProtocol(
  ownerId: 'owner@dtu.dk',
  name: 'Connectivity Sensing Example',
);

// Define which devices are used for data collection
// In this case, its only this smartphone
Smartphone phone = Smartphone();
protocol.addPrimaryDevice(phone);

// Add an automatic task that immediately starts collecting connectivity,
// wifi information, and nearby bluetooth devices.
protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(measures: [
      Measure(type: ConnectivitySamplingPackage.CONNECTIVITY),
      Measure(type: ConnectivitySamplingPackage.WIFI),
      Measure(type: ConnectivitySamplingPackage.BLUETOOTH),
    ]),
    phone);
```

The [`BluetoothScanPeriodicSamplingConfiguration`](https://pub.dev/documentation/carp_connectivity_package/latest/connectivity/BluetoothScanPeriodicSamplingConfiguration-class.html) configuration can be used to specify how Bluetooth scanning is to take place:

```dart
protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(measures: [
      Measure(
          type: ConnectivitySamplingPackage.BLUETOOTH,
          samplingConfiguration: BluetoothScanPeriodicSamplingConfiguration(
            interval: const Duration(minutes: 20),
            duration: const Duration(seconds: 15),
            withRemoteIds: ['123', '456'],
            withServices: ['service1', 'service2'],
          ))
    ]),
    phone);
```

The default configuration scans every 10 minutes for 10 seconds, and does not specify any remote IDs or services.

Scanning for iBeacons is configured by the [`BeaconRangingPeriodicSamplingConfiguration`](https://pub.dev/documentation/carp_connectivity_package/latest/connectivity/BeaconRangingPeriodicSamplingConfiguration-class.html).
The following example will scan for iBeacons in the specified regions which are closer than 2 meters. The regions are specified by their identifier and UUID. See the [dchs_flutter_beacon](https://pub.dev/packages/dchs_flutter_beacon) plugin for more information on how to set up iBeacon regions.

```dart
  protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(measures: [
        Measure(
            type: ConnectivitySamplingPackage.BEACON,
            samplingConfiguration: BeaconRangingPeriodicSamplingConfiguration(
              beaconDistance: 2, 
              beaconRegions: [
                BeaconRegion(
                  identifier: 'region1',
                  uuid: '12345678-1234-1234-1234-123456789012',
                ),
                BeaconRegion(
                  identifier: 'region2',
                  uuid: '12345678-1234-1234-1234-123456789012',
                ),
              ],
            ))
      ]),
      phone);
```

> [!IMPORTANT]
> There is no default sampling configuration for iBeacons. You need to specify at least one region to scan for.
