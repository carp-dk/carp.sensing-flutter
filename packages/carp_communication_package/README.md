# CARP Communication Sampling Package

[![pub package](https://img.shields.io/pub/v/carp_communication_package.svg)](https://pub.dartlang.org/packages/carp_communication_package)
[![pub points](https://img.shields.io/pub/points/carp_communication_package?color=2E8B57&label=pub%20points)](https://pub.dev/packages/carp_communication_package/score)
[![github stars](https://img.shields.io/github/stars/cph-cachet/carp.sensing-flutter.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/cph-cachet/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)

This library contains a sampling package for communication sampling to work with
the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package.
This packages supports sampling of the following [`Measure`](https://github.com/cph-cachet/carp.sensing-flutter/wiki/A.-Measure-Types) types:

* `dk.cachet.carp.phone_log` - the phone log.
* `dk.cachet.carp.text_message_log` - the text (sms) message log.
* `dk.cachet.carp.text_message` - incoming text (sms) messages.
* `dk.cachet.carp.calendar` - all calendar entries.

Note that collection of phone and text message data is only supported on Android.

See the [wiki](https://github.com/cph-cachet/carp.sensing-flutter/wiki) for further documentation, particularly on available [measure types](https://github.com/cph-cachet/carp.sensing-flutter/wiki/A.-Measure-Types).
See the [CARP Mobile Sensing App](https://github.com/cph-cachet/carp.sensing-flutter/tree/master/apps/carp_mobile_sensing_app) for an example of how to build a mobile sensing app in Flutter.

This package have implemented default privacy protection of text messages, phone numbers, and calendar entries as part of the default [Privacy Schema](https://github.com/cph-cachet/carp.sensing-flutter/wiki/3.-Using-CARP-Mobile-Sensing#privacy-transformer-schemas). These functions are implemented in the `communication_privacy.dart` file and use standard SHA1 hashing.

For Flutter plugins for other CARP products, see [CARP Mobile Sensing in Flutter](https://github.com/cph-cachet/carp.sensing-flutter/).

If you're interested in writing you own sampling packages for CARP, see the description on
how to [extend](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing) CARP on the wiki.

## Installing

To use this package, add the following to you `pubspc.yaml` file. Note that
this package only works together with `carp_mobile_sensing`.

`````dart
dependencies:
  carp_mobile_sensing: ^latest
  carp_communication_package: ^latest
  ...
`````

### Android Integration

Add the following to your app's `AndroidManifest.xml` file located in `android/app/src/main`:

````xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  package="<your_package_name>"
  xmlns:tools="http://schemas.android.com/tools">

  ...
   
  <!-- The following permissions are used in the CARP Communication Package -->
  <uses-permission android:name="android.permission.CALL_PHONE"/>
  <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
  <uses-permission android:name="android.permission.READ_PHONE_NUMBERS"/>
  <uses-permission android:name="android.permission.READ_SMS"/>
  <uses-permission android:name="android.permission.RECEIVE_SMS"/>
  <uses-permission android:name="android.permission.READ_CALENDAR"/>
  <!-- Even though we only want to READ the calendar, for some unknown 
       reason we also need to add the WRITE permission. -->
  <uses-permission android:name="android.permission.WRITE_CALENDAR"/>


  <application>
   ...
   ...
    <!-- Registration of broadcast receiver to listen to SMS messages 
         when the app is in the background -->
   <receiver android:name="com.shounakmulay.telephony.sms.IncomingSmsReceiver"
     android:permission="android.permission.BROADCAST_SMS" android:exported="true">
    <intent-filter>
        <action android:name="android.provider.Telephony.SMS_RECEIVED"/>
      </intent-filter>
    </receiver>

   </application>
</manifest>
````

### iOS Integration

Add this permission in the `Info.plist` file located in `ios/Runner`:

````xml
<key>NSCalendarsUsageDescription</key>
<string>INSERT_REASON_HERE</string>
````

## Using it

To use this package, import it into your app together with the
[`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package:

`````dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_communication_package/communication.dart';
`````

Before creating a study and running it, register this package in the
[SamplingPackageRegistry](https://pub.dartlang.org/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry.html).

`````dart
SamplingPackageRegistry().register(CommunicationSamplingPackage());
`````

Collection of communication measures can be added to a study protocol like this.

```dart
// Create a study protocol
StudyProtocol protocol = StudyProtocol(
  ownerId: 'owner@dtu.dk',
  name: 'Communication Sensing Example',
);

// Define which devices are used for data collection
// In this case, its only this smartphone
Smartphone phone = Smartphone();
protocol.addPrimaryDevice(phone);

// Add an automatic task that collects incoming SMS messages
protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
        measures: [Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE)]),
    phone);

// Add an automatic task that every 3 hour collects the logs for:
//  * in/out SMS
//  * in/out phone calls
//  * calendar entries
protocol.addTaskControl(
    PeriodicTrigger(period: const Duration(hours: 3)),
    BackgroundTask(measures: [
      Measure(type: CommunicationSamplingPackage.PHONE_LOG),
      Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE_LOG),
      Measure(type: CommunicationSamplingPackage.CALENDAR),
    ]),
    phone);
```
