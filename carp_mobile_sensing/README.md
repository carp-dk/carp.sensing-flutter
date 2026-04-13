# CARP Mobile Sensing Framework in Flutter

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_mobile_sensing.svg)](https://pub.dartlang.org/packages/carp_mobile_sensing)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

This library contains the core Flutter package for the [CARP Mobile Sensing (CAMS)](https://carp.dk/cams/) framework. Supports cross-platform (iOS and Android) mobile sensing.

For an overview of all CAMS packages, see [CARP Mobile Sensing in Flutter][github].
See the [CARP Mobile Sensing Documentation][docs] for how to [install & configure](https://docs.carp.dk/carp-mobile-sensing/install-and-configure), [use](https://docs.carp.dk/carp-mobile-sensing/using-carp-mobile-sensing), and [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) CAMS.

## Usage

To use this plugin, add [`carp_core`](https://pub.dev/packages/carp_core) and [`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing) as [dependencies in your `pubspec.yaml` file](https://flutter.io/platform-plugins/).

`````yaml
dependencies:
  carp_core: ^latest
  carp_mobile_sensing: ^latest
`````

## Configuration

When you want to add CAMS to your app, there are a few things to do in terms of configuring your app.

First, CAMS rely on the [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) plugin. So **if you want to use App Tasks and notifications** you should configure your app to the [platforms it supports](https://pub.dev/packages/flutter_local_notifications#-supported-platforms) and configure your app for both [Android](https://pub.dev/packages/flutter_local_notifications#-android-setup) and [iOS](https://pub.dev/packages/flutter_local_notifications#-ios-setup). There are a lot of details in configuring for notifications — especially for Android — so read this carefully.

Second, to support data sampling in the background, CAMS rely on the [flutter_background](https://pub.dev/packages/flutter_background) plugin. This only works on Android and requires adding permissions to the `AndroidManifest.xml` and specifying the appropriate [`foregroundServiceType`](https://developer.android.com/develop/background-work/services/fgs/service-types) for your use case.

Please see the [Install and Configure](https://docs.carp.dk/carp-mobile-sensing/install-and-configure) page for details for [Android](https://docs.carp.dk/carp-mobile-sensing/install-and-configure#2-android-configuration) and [iOS](https://docs.carp.dk/carp-mobile-sensing/install-and-configure#3-ios-configuration).

> [!IMPORTANT]  
> Other CAMS sampling packages require additional permissions in the `AndroidManifest.xml` or `Info.plist` files.
> See the **documentation** for each package.

## Documentation

The [Dart API doc](https://pub.dartlang.org/documentation/carp_mobile_sensing/latest/) describes the different libraries and classes.

The [CARP Mobile Sensing Documentation](https://docs.carp.dk/carp-mobile-sensing/) has detailed documentation on the CARP Mobile Sensing Framework, including the overall [software architecture](https://docs.carp.dk/carp-mobile-sensing/software-architecture), the [domain model](https://docs.carp.dk/carp-mobile-sensing/domain-model), how to [use](https://docs.carp.dk/carp-mobile-sensing/using-carp-mobile-sensing) it to create a [study protocol](https://docs.carp.dk/carp-mobile-sensing/using-carp-mobile-sensing#1-define-a-study-protocol), how to [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) it, and
an overview of the available [measure types](https://docs.carp.dk/carp-mobile-sensing/measure-types).

> [!NOTE]
> More scientific documentation of CAMS is available in the following papers:
>
> * Bardram, Jakob E. "[The CARP Mobile Sensing Framework--A Cross-platform, Reactive, Programming Framework and Runtime Environment for Digital Phenotyping.](https://arxiv.org/abs/2006.11904)" arXiv preprint arXiv:2006.11904 (2020). [[pdf](https://arxiv.org/pdf/2006.11904.pdf)]
> * Bardram, Jakob E. "[Software Architecture Patterns for Extending Sensing Capabilities and Data Formatting in Mobile Sensing.](https://www.mdpi.com/1424-8220/22/7/2813)" Sensors 22.7 (2022). [[pdf]](https://www.mdpi.com/1424-8220/22/7/2813/pdf).
>
> Please use these references in any scientific papers using CAMS.

## Examples of Configuring and Using CAMS

There is a **very simple** [example app](https://github.com/carp-dk/carp.sensing-flutter/tree/main/carp_mobile_sensing/example) which shows how a study protocol can be configured and used to create, deploy, and run a study.
This app just prints the collected data to the console.
There is also a range of different [examples](https://github.com/carp-dk/carp.sensing-flutter/blob/main/carp_mobile_sensing/example/lib/example.dart) on how to create a study to take inspiration from.

However, the [CARP Mobile Sensing App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app) provides a **MUCH** better example of how to use the framework in a Flutter MVVM architecture, including good documentation of how to do this.

Below is a small primer in the use of CAMS for a very simple sampling study running locally on the phone. This example is similar to the [example app](https://github.com/carp-dk/carp.sensing-flutter/blob/main/carp_mobile_sensing/example/lib/main.dart) app.

A CAMS study can be configured, deployed, executed, and used in different steps:

1. Define a [`SmartphoneStudyProtocol`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SmartphoneStudyProtocol-class.html).
2. Add a study based on this protocol to the [`SmartPhoneClientManager`](https://pub.dev/documentation/carp_mobile_sensing/latest/application/SmartPhoneClientManager-class.html).
3. Deploy the study and resume sampling.
4. Use the generated data (called `measurements`) locally in the app or specify how and where to store or upload it using a [`DataEndPoint`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/DataEndPoint-class.html).
5. Control the execution of the study, like calling `resume` or `pause` on the client, the study, or individual probes.

### Creating a study protocol and deploying it

Below is a simple example of how to set up a protocol that samples step counts, ambient light, screen events, and battery events.

```dart
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

// Create a protocol collecting steps, light, and screen and battery events
// from the phone and store collected measurements in a local SQLite database
final phone = Smartphone();
final protocol =
    SmartphoneStudyProtocol(
        ownerId: 'AB',
        name: 'Tracking steps, light, screen, and battery',
        dataEndPoint: SQLiteDataEndPoint(),
      )
      ..addPrimaryDevice(phone)
      ..addTaskControl(
        DelayedTrigger(delay: const Duration(seconds: 10)),
        BackgroundTask(
          measures: [
            Measure(type: SensorSamplingPackage.STEP_EVENT),
            Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
            Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
            Measure(type: DeviceSamplingPackage.BATTERY_STATE),
          ],
        ),
        phone,
      );

// Create and configure a client manager for this phone.
await SmartPhoneClientManager().configure();

// Create a study based on the protocol.
var study = await SmartPhoneClientManager().addStudyFromProtocol(protocol);

// Deploy the study.
await SmartPhoneClientManager().tryDeployment(
  study.studyDeploymentId,
  study.deviceRoleName,
);

// Resume sampling.
SmartPhoneClientManager().resume();

// Listening on the measurements stream.
SmartPhoneClientManager().measurements.listen((measurement) {
  // Do something with the measurement, e.g. print the json.
  print(toJsonString(measurement));
});

// Pause sampling.
SmartPhoneClientManager().pause();

// Resume sampling again.
SmartPhoneClientManager().resume();

// Dispose the client. Can not be used anymore.
SmartPhoneClientManager().dispose();
```

The above example defines a simple [`SmartphoneStudyProtocol`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SmartphoneStudyProtocol-class.html) which will use a [`Smartphone`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/Smartphone-class.html) as a primary device for data collection and store data in a SQLite database locally on the phone using a [`SQLiteDataEndPoint`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SQLiteDataEndPoint-class.html).
Sampling is configured using a [`DelayedTrigger`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/DelayedTrigger-class.html) which triggers a [`BackgroundTask`](https://pub.dev/documentation/carp_core/latest/carp_core_common/BackgroundTask-class.html) containing four different [`Measure`](https://pub.dev/documentation/carp_core/latest/carp_core_common/Measure-class.html)s.
When this study is resumed, the background task is started after a delay of 10 seconds, and will continue to collect the four measures until paused.

Sampling can be configured in very sophisticated ways, by specifying different types of devices, task controls, triggers, tasks, measures, and sampling configurations.
See the CAMS [documentation][docs] for an overview and more details.

### Minimal example

In the example above, the client manager is configured, the protocol is added, and sampling is started. This can actually be done in one line of code, like this:

```dart
SmartPhoneClientManager().configure().then(
  (_) => SmartPhoneClientManager()
      .addStudyFromProtocol(
        SmartphoneStudyProtocol.local(
          name: 'Tracking steps, light, screen, and battery',
          measures: [
            Measure(type: SensorSamplingPackage.STEP_EVENT),
            Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
            Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
            Measure(type: DeviceSamplingPackage.BATTERY_STATE),
          ],
        ),
      )
      .then(
        (study) => SmartPhoneClientManager()
            .tryDeployment(study.studyDeploymentId, study.deviceRoleName)
            .then((_) => SmartPhoneClientManager().resume()),
      ),
);
```

This will start the sampling immediately (and not delayed as above) and data is stored in the SQLite database.

### Using the generated data

The generated data can be accessed and used in the app. Access to data is done by listening on the [`measurements`](https://pub.dev/documentation/carp_mobile_sensing/latest/application/SmartPhoneClientManager/measurements.html) stream from the client manager:

```dart
// Listening on the data stream and print them as json.
SmartPhoneClientManager()
    .measurements
    .listen((measurement) => print(toJsonString(measurement)));
```

Note that `measurements` is a Dart [Stream](https://dart.dev/libraries/async/using-streams) and you can hence apply all the usual stream operations to the collected measurements, including sorting, mapping, reducing, and transforming measurements.

Data stored in the SQLite database is accessed via the file system, as explained in the [Data Managers](https://docs.carp.dk/carp-mobile-sensing/data-managers).

### Controlling the sampling of data

Data sampling can be controlled on runtime by resuming, pausing, and disposing sampling.
For example, calling `SmartPhoneClientManager().pause()` would pause all data sampling running on the client. Calling `resume()` would resume it again.

Calling `SmartPhoneClientManager().dispose()` would dispose of the client manager. Once dispose is called, you cannot call `resume` or `pause` sampling anymore. This method is typically used in the Flutter `dispose()` method.

## Extending CAMS

CAMS is designed to be extended in at least four ways:
(i) adding new triggers,
(ii) adding new data sampling capabilities and support for new devices,
(iii) adding a new data manager for storing and uploading data, and
(iv) adding data transformers for different data formats and data privacy protection.

Please see the documentation on how to [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) CAMS.

## Features and bugs

Please read about existing issues and file new feature requests and bug reports at the [issue tracker][tracker].

## License

This software is copyright (c) the [Technical University of Denmark (DTU)](https://www.dtu.dk) and is part of the [Copenhagen Research Platform][carp].
This software is available 'as-is' under a [MIT license](LICENSE).

<!-- LINKS  -->

[github]: https://github.com/carp-dk/carp.sensing-flutter
[tracker]: https://github.com/carp-dk/carp.sensing-flutter/issues
[docs]: https://docs.carp.dk/carp-mobile-sensing/
[carp]: https://carp.dk/
