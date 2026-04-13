# CARP eSense Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_esense_package.svg)](https://pub.dev/packages/carp_esense_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

This library contains a sampling package for
the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) framework
to work with the [eSense](https://www.esense.io) earable computing platform.
This packages supports sampling of the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types) types (note that the package defines its own namespace of `dk.cachet.carp.esense`):

* `dk.cachet.carp.esense.button` : eSense button pressed / released events
* `dk.cachet.carp.esense.sensor` : eSense sensor (accelerometer & gyroscope) events.

See the user documentation on the [eSense device](https://www.esense.io/share/eSense-User-Documentation.pdf) for how to use the device.
See the [`esense_flutter`](https://pub.dev/packages/esense_flutter) Flutter plugin and its [API](https://pub.dev/documentation/esense_flutter/latest/) documentation to understand how sensor data is generated and their data formats.

See the [CAMS documentation site](https://docs.carp.dk/carp-mobile-sensing/) for further documentation.
See the [CARP Mobile Sensing App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app) for an example of how to build a mobile sensing app in Flutter.

For Flutter plugins for other CARP products, see [CARP Mobile Sensing in Flutter](https://github.com/cph-cachet/carp.sensing-flutter).

If you're interested in writing your own sampling packages for CARP, see the description on
how to [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) CARP Mobile Sensing.

## Installing

To use this package, add the following to you `pubspec.yaml` file. Note that this package only works together with `carp_mobile_sensing`.

`````dart
dependencies:
  flutter:
    sdk: flutter
  carp_core: ^latest
  carp_mobile_sensing: ^latest
  carp_esense_package: ^latest
  ...
`````

The package uses bluetooth to fetch data from the eSense earplugs. Therefore permission to access bluetooth must be enabled on both Android and iOS, as follows.
Then make sure to obtain permissions in your app to use bluetooth.

### Android Integration

Add the following to your app's `manifest.xml` file located in `android/app/src/main`:

```xml
<uses-permission
    android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="30" />
<uses-permission
    android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30" />
<uses-permission
    android:name="android.permission.BLUETOOTH_SCAN" 
    android:usesPermissionFlags="neverForLocation" /> 
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

### iOS Integration

Requires iOS 10 or later. Hence, in your `Podfile` in the `ios` folder of your app, make sure that the platform is set to `10.0`.

```ruby
platform :ios, '10.0'
```

Add this permission in the `Info.plist` file located in `ios/Runner`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Uses bluetooth to connect to the eSense device</string>
<key>UIBackgroundModes</key>
  <array>
 <string>bluetooth-central</string>
 <string>bluetooth-peripheral</string>
  <string>audio</string>
  <string>external-accessory</string>
  <string>fetch</string>
</array>
```

## Using it

To use this package, import it into your app together with the
[`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package:

`````dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_esense_package/esense.dart';
`````

Before executing a study with an eSense measure, register this package in the [`SamplingPackageRegistry`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry-class.html).

`````dart
SamplingPackageRegistry().register(ESenseSamplingPackage());
`````

Collection of eSense measurements can be added to a study protocol like this.

```dart
// Create a study protocol
var protocol = StudyProtocol(
  ownerId: 'owner@dtu.dk',
  name: 'eSense Sensing Example',
);

// Define which devices are used for data collection - both phone and eSense
// and add them to the protocol.
var phone = Smartphone();
var eSense = ESenseDevice(samplingRate: 10);

protocol
  ..addPrimaryDevice(phone)
  ..addConnectedDevice(eSense, phone);

// Add a background task that immediately starts collecting eSense button and
// sensor events from the eSense device.
protocol.addTaskControl(
  ImmediateTrigger(),
  BackgroundTask(
    measures: [
      Measure(type: ESenseSamplingPackage.ESENSE_BUTTON),
      Measure(type: ESenseSamplingPackage.ESENSE_SENSOR),
    ],
  ),
  eSense,
);    
````

Connection to an eSense device happens via the `ESenseDeviceManager` calling the `connect` method. This method uses the `bleName` of the device to connect via BLE.

> [!IMPORTANT]  
> The physical eSense device must be paired with the phone via BLE **before** CAMS can connect to it.
