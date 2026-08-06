# CARP Movesense Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_movesense_package.svg)](https://pub.dev/packages/carp_movesense_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

This library contains a sampling package for the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) framework
to work with the [Movesense](https://www.movesense.com/) heart rate devices.
This packages supports sampling of the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types) types (note that the package defines its own namespace of `dk.cachet.carp.movesense`):

* `dk.cachet.carp.movesense.state` : State changes (like moving, tapping, etc.)
* `dk.cachet.carp.movesense.hr` : Heart rate
* `dk.cachet.carp.movesense.ecg` : Electrocardiogram (ECG)
* `dk.cachet.carp.movesense.temperature` : Device temperature
* `dk.cachet.carp.movesense.imu` : 9-axis Inertial Movement Unit (IMU)

This package uses the Flutter [carp_movesense_flutter](https://pub.dev/packages/carp_movesense_flutter) plugin, which is based on the official [Movesense Mobile API](https://www.movesense.com/docs/mobile/mobile_sw_overview/).

> [!NOTE]
> As of version 3.0.0 this package is based on the [`carp_movesense_flutter`](https://pub.dev/packages/carp_movesense_flutter) plugin instead of the `mdsflutter` plugin. The public API of this sampling package is unchanged. The main practical difference is that `carp_movesense_flutter` bundles the native Movesense MDS libraries (the Android `.aar` and the iOS `.xcframework`), so apps no longer need to vendor them manually (see [Installing](#installing) below).

The following heart rate devices are supported:

* [Movesense Medical (MD)](https://www.movesense.com/product/movesense-medical-mdr/)
* [Movesense HR+](https://www.movesense.com/product/movesense-sensor-hr/)
* [Movesense HR2](https://www.movesense.com/product/movesense-sensor-hr2/)

See the [CAMS documentation site](https://docs.carp.dk/carp-mobile-sensing/) for further documentation.
See the [CARP Mobile Sensing App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app) for an example of how to build a mobile sensing app in Flutter.

For Flutter plugins for other CARP products, see [CARP Mobile Sensing in Flutter](https://github.com/carp-dk/carp.sensing-flutter).

If you're interested in writing your own sampling packages for CARP, see the description on
how to [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) CARP Mobile Sensing.

## Installing

To use this package, add the following to you `pubspec.yaml` file. Note that this package only works together with `carp_mobile_sensing`.

`````dart
dependencies:
  carp_core: ^latest
  carp_mobile_sensing: ^latest
  carp_movesense_package: ^latest
  ...
`````

Unlike previous (`mdsflutter`-based) versions, the underlying `carp_movesense_flutter` plugin **bundles the native Movesense MDS libraries** for both Android and iOS. This means you no longer have to download and vendor the Movesense SDK yourself. The remaining setup below only concerns Bluetooth permissions.

### Android

The Movesense `mdslib` `.aar` is bundled inside the `carp_movesense_flutter` plugin, so **no manual `.aar` download or `flatDir` repository is required** anymore. The plugin also declares the Bluetooth permissions it needs (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and — on Android 11 and lower — `ACCESS_FINE_LOCATION`) in its own manifest, and these are merged into your app automatically. The plugin requires a minimum Android SDK of `24`.

> [!IMPORTANT]
> The package does not *request* runtime permissions. On the first run, make sure your app requests the Bluetooth (and, on Android 11 and lower, location) permissions. Location access is necessary to use BLE on older Android versions.

### iOS

The Movesense `MovesenseMDS.xcframework` is bundled inside the `carp_movesense_flutter` plugin, so **no manual `pod 'Movesense', :git => ...` entry is required** in your `Podfile` anymore. The plugin targets a minimum deployment of iOS 15.0.

> [!NOTE]
> Because the bundled framework is statically linked, some app setups still need `use_frameworks! :linkage => :static` (and `use_modular_headers!`) in the `Podfile`. If you hit linker/module errors, add these flags to your `Runner` target.

Add the permission to access bluetooth in the background by adding this to the `Info.plist` file located in `ios/Runner`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Uses bluetooth to connect to the Movesense device</string>
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>
```

## Using it

To use this package, import it into your app together with the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package:

`````dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';
`````

Collection of Movesense measures can be added to a study protocol like this.

```dart
// Create a study protocol
StudyProtocol protocol = StudyProtocol(
  ownerId: 'owner@dtu.dk',
  name: 'Movesense Sensing Example',
);

// Define which devices are used for data collection - both phone and eSense
// and add them to the protocol.
var phone = Smartphone();
var movesense = MovesenseDevice();

protocol
  ..addPrimaryDevice(phone)
  ..addConnectedDevice(movesense, phone);

// Add a background task that immediately starts collecting HR and ECG data
// from the Movesense device.
protocol.addTaskControl(
  ImmediateTrigger(),
  BackgroundTask(
    measures: [
      Measure(type: MovesenseSamplingPackage.HR),
      Measure(type: MovesenseSamplingPackage.ECG),
    ],
  ),
  movesense,
);
````

Before executing a study with an Movesense measure, register this package in the [`SamplingPackageRegistry`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry-class.html).

`````dart
SamplingPackageRegistry().register(MovesenseSamplingPackage());
`````

Use the [`MovesenseDeviceManager`](https://pub.dev/documentation/carp_movesense_package/latest/carp_movesense_package/MovesenseDeviceManager-class.html) to connect to the device using the `connect` method. The connect method uses the `bleAddress` to identify the Movesense device, which is typically on the form "Movesense 220330000122". You should set the BLE address before trying to connect.

> [!IMPORTANT]
> The package does not handle permissions for Bluetooth scanning / connectivity. This should be handled on an app level.

## Known Limitations

### State Events

There is currently a hardware limitation in the Movesense device and only **one** movement state (movement, tap, double_tap, free_fall) can be subscribed at the same time.
See issue [#15](https://github.com/petri-lipponen-movesense/mdsflutter/issues/15).
Therefore the `MovesenseStateChangeProbe` is only able to collect single tap events and the `STATE` measure hence only reports on single tap events.

### Unstable Subscriptions

When subscribing to multiple high-frequency measures - like HR, ECG, IMU - these subscriptions may time out with an error code `408`. This is probably because the Movesense hardware can't keep up with streaming all the data. So, if you need to stream multiple streams of data, you would often need to reconnect to the device, even multiple times. See also this [thread on stackoverflow](https://stackoverflow.com/questions/78074167/getting-error-status-408-when-subscribing-to-a-movesense-device).
