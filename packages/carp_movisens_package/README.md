# CARP Movisens Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_movisens_package.svg)](https://pub.dev/packages/carp_movisens_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

This library contains a [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) (CAMS) sampling package for collecting data from [Movisens](https://www.movisens.com) devices:

* [Move 4](https://docs.movisens.com/Sensors/Move4/)
* [EcgMove 4](https://docs.movisens.com/Sensors/EcgMove4/)
* [EdaMove 4](https://docs.movisens.com/Sensors/EdaMove4/)

> [!IMPORTANT]
> As stressed by Movisens, none of the Movisens devices are medical devices. Do not use them for medical purposes.

This package supports sampling of the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types) types:

* `dk.cachet.carp.movisens.activity` – Physical activity like body positions, step count, inclination, acceleration, and metabolic (MET) levels.
* `dk.cachet.carp.movisens.hr` - Heart Rate (HR), HR Variability (HRV), Mean HR
* `dk.cachet.carp.movisens.eda` - Elecrodermal Activity
* `dk.cachet.carp.movisens.skin_temperature` - Skin temperature.
* `dk.cachet.carp.movisens.tap_marker` - Markers of user tapping on the sensor.

These measures collect different types of data (note that the package defines its own namespace of `dk.cachet.carp.movisens...`):

**Physical Activity:**

* `dk.cachet.carp.movisens.activity.steps`
* `dk.cachet.carp.movisens.activity.body_position`
* `dk.cachet.carp.movisens.activity.inclination`
* `dk.cachet.carp.movisens.activity.movement_acceleration`
* `dk.cachet.carp.movisens.activity.met_level`
* `dk.cachet.carp.movisens.activity.met`

**Heart Rate:**

* `dk.cachet.carp.movisens.hr.hr_mean`
* `dk.cachet.carp.movisens.hr.hrv`
* `dk.cachet.carp.movisens.hr.is_hrv_valid`

**Misc:**

* `dk.cachet.carp.movisens.eda`
* `dk.cachet.carp.movisens.skin_temperature`
* `dk.cachet.carp.movisens.tap_marker`

For understanding how to use the Movisens Devices, please consult the [Movisens Documentation](https://docs.movisens.com).

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
  carp_movisens_package: ^latest
  ...
`````

### Android Integration

Add the following to your app's `manifest.xml` file located in `android/app/src/main`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

Update the Android `minSdkVersion` to at least 19 in the `android/app/build.gradle` file.

### iOS Integration

Add the following to your `ios/Runner/Info.plist` file:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need BLE permission</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Need BLE permission</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Need Location permission</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Need Location permission</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Need Location permission</string>
````

## Usage

To use this package, import it into your app together with the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package:

`````dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:movisens_package/movisens.dart';
`````

Before creating a study and running it, register this package in the [`SamplingPackageRegistry`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry-class.html).

`````dart
 SamplingPackageRegistry().register(MovisensSamplingPackage());
`````

Once the package is registered, Movisens measures can be added to a study protocol like this.

````dart
// Create a study protocol
var protocol = StudyProtocol(
  ownerId: 'owner@dtu.dk',
  name: 'Movisens Example',
);

// Define which devices are used for data collection - both phone and Movisens
// and add them to the protocol.
// Note that the Movisens device is added as a connected device to the phone.
var phone = Smartphone();
var movisens = MovisensDevice(
  sensorLocation: SensorLocation.Chest,
  sex: Sex.Male,
  height: 175,
  weight: 75,
  age: 25,
);

protocol
  ..addPrimaryDevice(phone)
  ..addConnectedDevice(movisens, phone);

// Adding a movisens measure
protocol.addTaskControl(
  ImmediateTrigger(),
  BackgroundTask(
    name: 'Movisens Task',
    measures: [Measure(type: MovisensSamplingPackage.ACTIVITY)],
  ),
  movisens,
);
````

This protocol collects physical activity data (steps, inclination, etc.) from a Movisens device.
The device's user parameters (sex, height, etc.) is used by the Movisens device to calculate the metabolic (MET) levels. These user parameters are transmitted to the device when connected. Hence, if you want to change or update these user parameters (e.g., based on input from the user using the phone), you should update the `MovisensDevice` device configuration **before** connecting to the device.

The default Movisens names of devices are `MOVISENS Sensor <serial>`, where `serial` is the 5-digit serial number written on the back of the device.
Once this protocol is deployed on a phone and connected to a Movisens device using Bluetooth, it will start to collect the physical activity data from the device.

Please see the [CARP Mobile Sensing App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app) for an example of how to build a mobile sensing app that can handle protocols and connect to devices.
