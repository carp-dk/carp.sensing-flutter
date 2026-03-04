# CARP Mobile Sensing Framework in Flutter

[![pub package](https://img.shields.io/pub/v/carp_mobile_sensing.svg)](https://pub.dartlang.org/packages/carp_mobile_sensing)
[![pub points](https://img.shields.io/pub/points/carp_mobile_sensing?color=2E8B57&label=pub%20points)](https://pub.dev/packages/carp_mobile_sensing/score)
[![github stars](https://img.shields.io/github/stars/cph-cachet/carp.sensing-flutter.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/cph-cachet/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)

This library contains the core Flutter package for the [CARP Mobile Sensing (CAMS)](https://carp.dk/cams/) framework.
Supports cross-platform (iOS and Android) mobile sensing.

For an overview of all CAMS packages, see [CARP Mobile Sensing in Flutter](https://github.com/cph-cachet/carp.sensing-flutter).
For documentation on how to use CAMS, see the [CAMS wiki][wiki].

## Usage

To use this plugin, add [`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing) as [dependencies in your `pubspec.yaml` file](https://flutter.io/platform-plugins/).

`````yaml
dependencies:
  carp_core: ^latest
  carp_mobile_sensing: ^latest
`````

## Configuration

When you want to add CAMS to you app, there are a few things to do in terms of configuring your app.

First, CAMS rely on the [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) plugin. So **if you want to use App Tasks and notifications** you should configure your app to the [platforms it supports](https://pub.dev/packages/flutter_local_notifications#-supported-platforms) and configure your app for both [Android](https://pub.dev/packages/flutter_local_notifications#-android-setup) and [iOS](https://pub.dev/packages/flutter_local_notifications#-ios-setup). There is a lot of details in configuring for notifications - especially for Android - so read this carefully.

Second, to support data sampling in the background, CAMS rely on the [flutter_background](https://pub.dev/packages/flutter_background) plugin. This only works on Android and requires adding permissions to the `AndroidManifest.xml` and specifying the appropriate [`foregroundServiceType`](https://developer.android.com/develop/background-work/services/fgs/service-types) for your use case.

### Android Integration

Set the minimum android SDK to 26 and Java SDK Version to 36 by setting the `minSdkVersion`, the `compileSdkVersion`, and `targetSdkVersion` in the `build.gradle` file, located in the `android/app/` folder:

If collecting step counts or using notifications in your app, add the following to your app's `AndroidManifest.xml` file located in `android/app/src/main`:

````xml
<!-- Used for activity recognition (step count) -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>

<!-- Used for sending and scheduling notifications -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
        android:maxSdkVersion="32" />
````

Also specify the following between the `<application>` tags so that the plugin can show the scheduled notifications:

```xml
<!-- Used for scheduling notifications -->
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

On Android, remember to update your `build.gradle` files and to "[desugar](https://pub.dev/packages/flutter_local_notifications#gradle-setup)" them and to add the `app_icon.png` to the `android/app/src/main/res/drawable/` folder.

### iOS Integration

The pedometer (step count) probe uses `NSMotion` on iOS and the `NSMotionUsageDescription` needs to be specified in the app's `Info.plist` file located in `ios/Runner`:

```xml
<key>NSMotionUsageDescription</key>
<string>This application tracks your steps</string>
```

-------------------------------------

> [!NOTE]  
> Other CAMS sampling packages require additional permissions in the `AndroidManifest.xml` or `Info.plist` files.
> See the **documentation** for each package.

## Documentation

The [Dart API doc](https://pub.dartlang.org/documentation/carp_mobile_sensing/latest/) describes the different libraries and classes.

The CAMS [wiki][wiki] contains detailed documentation on the CARP Mobile Sensing Framework, including the [domain model](https://github.com/cph-cachet/carp.sensing-flutter/wiki/2.-Domain-Model), how to use it by create a [study configuration](https://github.com/cph-cachet/carp.sensing-flutter/wiki/3.-Using-CARP-Mobile-Sensing), how to [extend](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing) it, and
an overview of the available [measure types](https://github.com/cph-cachet/carp.sensing-flutter/wiki/A.-Measure-Types).

More scientific documentation of CAMS is available in the following papers:

* Bardram, Jakob E. "[The CARP Mobile Sensing Framework--A Cross-platform, Reactive, Programming Framework and Runtime Environment for Digital Phenotyping.](https://arxiv.org/abs/2006.11904)" arXiv preprint arXiv:2006.11904 (2020). [[pdf](https://arxiv.org/pdf/2006.11904.pdf)]
* Bardram, Jakob E. "[Software Architecture Patterns for Extending Sensing Capabilities and Data Formatting in Mobile Sensing.](https://www.mdpi.com/1424-8220/22/7/2813)" Sensors 22.7 (2022). [[pdf]](https://www.mdpi.com/1424-8220/22/7/2813/pdf).

Please use these references in any scientific papers using CAMS.

## Examples of Configuring and Using CAMS

There is a **very simple** [example app](https://github.com/cph-cachet/carp.sensing-flutter/blob/master/carp_mobile_sensing/example/lib/main.dart) app which shows how a study protocol can be configured and used to create, deploy, and run a study.
This app just prints the collected data to the console.
There is also a range of different [examples](https://github.com/cph-cachet/carp.sensing-flutter/blob/master/carp_mobile_sensing/example/lib/example.dart) on how to create a study to take inspiration from.

However, the [CARP Mobile Sensing App](https://github.com/cph-cachet/carp.sensing-flutter/tree/master/apps/carp_mobile_sensing_app) provides a **MUCH** better example of how to use the framework in a Flutter MVVM architecture, including good documentation of how to do this.

Below is a small primer in the use of CAMS for a very simple sampling study running locally on the phone. This example is similar to the [example app](https://github.com/cph-cachet/carp.sensing-flutter/blob/master/carp_mobile_sensing/example/lib/main.dart) app.

Following [`carp_core`](https://pub.dev/documentation/carp_core/latest/), a CAMS study can be configured, deployed, executed, and used in different steps:

1. Define a [`SmartphoneStudyProtocol`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SmartphoneStudyProtocol-class.html).
2. Deploy this protocol to the [`SmartPhoneClientManager`](https://pub.dev/documentation/carp_mobile_sensing/latest/application/SmartPhoneClientManager-class.html).
3. Use the generated data (called `measurements`) locally in the app or specify how and where to store or upload it using a [`DataEndPoint`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/DataEndPoint-class.html).
4. Control the execution of the study, like calling [`start`](https://pub.dev/documentation/carp_mobile_sensing/latest/application/SmartPhoneClientManager/start.html).

### Defining a `SmartphoneStudyProtocol`

In CAMS, a sensing protocol is configured in a [`SmartphoneStudyProtocol`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SmartphoneStudyProtocol-class.html).
Below is a simple example of how to set up a protocol that samples step counts, ambient light, screen events, and battery events.

```dart
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
```

The above example defines a simple [`SmartphoneStudyProtocol`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SmartphoneStudyProtocol-class.html) which will use a [`Smartphone`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/Smartphone-class.html) as a primary device for data collection and store data in a SQLite database locally on the phone using a [`SQLiteDataEndPoint`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SQLiteDataEndPoint-class.html).
Sampling is configured by adding a [`TaskControl`](https://pub.dev/documentation/carp_core/latest/carp_core_common/TaskControl-class.html) to the protocol using an [`DelayedTrigger`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/DelayedTrigger-class.html) which triggers a [`BackgroundTask`](https://pub.dev/documentation/carp_core/latest/carp_core_common/BackgroundTask-class.html) containing four different [`Measure`](https://pub.dev/documentation/carp_core/latest/carp_core_common/Measure-class.html)s.
When this task control is triggered (after a delay of 10 seconds), the sampling will start.

Sampling can be configured in very sophisticated ways, by specifying different types of devices, task controls, triggers, tasks, measures, and sampling configurations.
See the CAMS [wiki][wiki] for an overview and more details.

### Deploying and Running a Study on a `SmartPhoneClientManager`

In CAMS, we talk about a study protocol being 'deployed' on a primary device, like a phone. CAMS has a fairly [sophisticated software architecture](https://github.com/cph-cachet/carp.sensing-flutter/wiki/1.-Software-Architecture) for doing this.
However, if we just want to define and deploy a study locally on the phone, this can be done using the [`SmartPhoneClientManager`](https://pub.dev/documentation/carp_mobile_sensing/latest/application/SmartPhoneClientManager-class.html) singleton.

```dart
// Create and configure a client manager for this phone.
await SmartPhoneClientManager().configure();

// Create a study based on the protocol.
await SmartPhoneClientManager().addStudyFromProtocol(protocol);

/// Start the study.
SmartPhoneClientManager().start();

/// Resume sampling.
SmartPhoneClientManager().resume();
```

In this example, the client manager is configured, the protocol is added, and sampling is started. This can actually be done in one line of code, like this:

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
        (_) => SmartPhoneClientManager()
          ..start()
          ..resume(),
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

Note that `measurements` is a Dart [Stream](https://api.dart.dev/stable/3.0.7/dart-async/Stream-class.html) and you can hence apply all the usual stream operations to the collected measurements, including sorting, mapping, reducing, and transforming measurements.

Data stored in the SQLite database is accessed via the file system, as explain in the [SQLiteDataManager](https://pub.dev/documentation/carp_mobile_sensing/latest/infrastructure/SQLiteDataManager-class.html).

### Controlling the sampling of data

Data sampling can be controlled on runtime by resuming, pausing, and disposing sampling.
For example, calling `SmartPhoneClientManager().pause()` would pause all data sampling running on the client. Calling `resume()` would resume it again.

Calling `SmartPhoneClientManager().dispose()` would dispose of the client manager. Once dispose is called, you cannot call `resume` or `pause` sampling anymore. This methods is typically used in the Flutter `dispose()` method.

## Extending CAMS

CAMS is designed to be extended in at least three ways: (i) [adding new sampling capabilities](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing#adding-new-sampling-capabilities) by implementing a Sampling Package; (ii) [adding a new data management and backend support](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing#adding-a-new-data-manager) by creating a Data Manager; and (iii) [creating data and privacy transformer schemas](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing#adding-data-and-privacy-transformers) that can transform CARP data to other formats, including privacy protecting them, by implementing a [Transformer Schema](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/DataTransformerSchema-class.html).

For example, you can write your own `DataEndPoint` definitions and a corresponding [`DataManager`](https://pub.dev/documentation/carp_mobile_sensing/latest/application/DataManager-class.html) class for uploading data to your own data endpoint. See the wiki on how to [add a new data manager](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing#adding-a-new-data-manager).

Please see the wiki on how to [extend](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing) CAMS.

## Features and bugs

Please read about existing issues and file new feature requests and bug reports at the [issue tracker][tracker].

## License

This software is copyright (c) the [Technical University of Denmark (DTU)](https://www.dtu.dk) and is part of the [Copenhagen Research Platform](https://carp.dk/).
This software is available 'as-is' under a [MIT license](LICENSE).

<!-- LINKS  -->

[tracker]: https://github.com/cph-cachet/carp.sensing-flutter/issues
[wiki]: https://github.com/cph-cachet/carp.sensing-flutter/wiki
