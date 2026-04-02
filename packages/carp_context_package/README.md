# CARP Context Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_context_package.svg)](https://pub.dev/packages/carp_context_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

This library contains a sampling package for collection of contextual data to work with the [`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing) framework.
This package supports sampling of the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types) types:

* `dk.cachet.carp.activity`
* `dk.cachet.carp.location`
* `dk.cachet.carp.geofence`
* `dk.cachet.carp.mobility`
* `dk.cachet.carp.weather`
* `dk.cachet.carp.air_quality`

See the [CAMS documentation site](https://docs.carp.dk/carp-mobile-sensing/) for further documentation.
See the [CARP Mobile Sensing App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app) for an example of how to build a mobile sensing app in Flutter.

For Flutter plugins for other CARP products, see [CARP Mobile Sensing in Flutter](https://github.com/carp-dk/carp.sensing-flutter).

If you're interested in writing your own sampling packages for CARP, see the description on
how to [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) CARP Mobile Sensing.

## Installing

To use this package, add the following to your `pubspec.yaml` file. Note that this package only works together with [`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing).

`````dart
dependencies:
  carp_mobile_sensing: ^latest
  carp_context_package: ^latest
  ...
`````

## Location Permissions

This context package makes use of what Apple and Google denote as sensitive information, especially location. Therefore it is important to configure the app to access location information. Please read carefully the [**instructions on how to set up the permission_handler plugin**]( https://pub.dev/packages/permission_handler#setup) - both for Android and iOS.

> [!IMPORTANT]  
> This context package **DOES NOT** ask for location access. This should be done by the app since the app should (according to the Apple and Google guidelines) tell the user why location is accessed. The Android Developers documentation contains a good description of how to [request location access at runtime](https://developer.android.com/develop/sensors-and-location/location/permissions#request-location-access-runtime).

### Android

Add the following to your app's `AndroidManifest.xml` file located in `android/app/src/main`:

````xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="<your_package_name>"
    xmlns:tools="http://schemas.android.com/tools">

   ...
   
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

    <!-- for Android 9 (API 28 and below), use: -->
    <uses-permission 
        android:name="com.google.android.gms.permission.ACTIVITY_RECOGNITION" 
        android:maxSdkVersion="28" />
    <!-- for Android 10 (API 29 and later), use: -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

</manifest>
````

> [!NOTE]  
> For Android 10 (API 29 and later) use the following permission:
>
> `<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />`
>
> See [Privacy changes in Android 10](https://developer.android.com/about/versions/10/privacy/changes#physical-activity-recognition).

> [!NOTE]  
> For Android 14 (API 34 and later) [foreground service types are required](https://developer.android.com/about/versions/14/changes/fgs-types-required) and you should add
>
> `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />`

### iOS

In order to use Location, you need to set your minimum deployment target to iOS 13.0 or later. Furthermore, you need to enable the macros from the [permission_handler]( https://pub.dev/packages/permission_handler#setup) plugin. Please see the [setup instructions]( https://pub.dev/packages/permission_handler#setup) for iOS.

Change the `post_install` part of your `ios/Podfile`:

```ruby
platform :ios, '14.0'


...

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      end
    end
  end
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        # See https://pub.dev/packages/permission_handler#setup - under iOS setup

        # The context package uses the following permissions:
        'PERMISSION_LOCATION=1',      # Location access
        'PERMISSION_NOTIFICATIONS=1', # CARP Mobile Sensing uses notifications
        'PERMISSION_SENSORS=1',       # Core Motion sensors on iOS (pedometer)
      ]
    end
  end
end

```

Add the following permissions in the `Info.plist` file located in `ios/Runner` (use your own text for explanation in the `<string>` tags):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Uses the location API to record location.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Uses the location API to record location.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Uses the location API to record location.</string>
<key>NSMotionUsageDescription</key>
<string>Detects activity.</string>
<key>UIBackgroundModes</key>
  <array>
    <string>fetch</string>
    <string>location</string>
  </array>
```

Also - make sure to activate Background mode for your Runner. Open XCode and go to "Signing & Capabilities". Add the "Background Modes" section and add "Location updates" to the list:

![iOS Setup](https://raw.githubusercontent.com/wiki/rekab-app/background_locator/images/background_location_update.png)

## Using it

To use this package, import it into your app together with the
[`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing) package:

`````dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_context_package/carp_context_package.dart';
`````

Before creating a study and running it, register this package in the [`SamplingPackageRegistry`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry-class.html).

````dart
SamplingPackageRegistry().register(ContextSamplingPackage());
````

The context package uses different "services" (incl. the phone itself) to collect data.

### Activity Measure

The `ACTIVITY` measure uses the phone itself and can be added like this:

```dart
// Create a study protocol
StudyProtocol protocol = StudyProtocol(
  ownerId: 'owner@dtu.dk',
  name: 'Context Sensing Example',
);

// Define the smartphone as the master device.
Smartphone phone = Smartphone();
protocol.addMasterDevice(phone);

// Add a background task that collects activity data from the phone
protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(measures: [
      Measure(type: ContextSamplingPackage.ACTIVITY),
    ]),
    phone);
```

### Location Measures

All of the location-based measures;

* `LOCATION`
* `GEOFENCE`
* `MOBILITY`

use the `LocationService` service as a "connected device" to collect data and can be added to a protocol like this:

```dart
// Define the online location service and add it as a 'connected device'
final locationService = LocationService(
    accuracy: GeolocationAccuracy.high,
    distance: 10,
    interval: const Duration(minutes: 1));

protocol.addConnectedDevice(locationService, phone);

// Add a background task that continuously collects location and mobility
// patterns. Delays sampling by 5 minutes.
protocol.addTaskControl(
    DelayedTrigger(delay: Duration(minutes: 5)),
    BackgroundTask(measures: [
      Measure(type: ContextSamplingPackage.LOCATION),
      Measure(type: ContextSamplingPackage.MOBILITY)
    ]),
    locationService);
```

> [!TIP]
> You would often need to balance the configuration of the `LocationService` with the measure you are collecting. For example, if only using the `MOBILITY` measure, a lower `accuracy`, `distance`, and sampling `interval` could be used.

If you only want to collect location information one time during a measurement, you can override the sampling configuration using a `LocationSamplingConfiguration` like this:

```dart
// Add a background task that collects location on a regular basis
// using a periodic trigger and a location sampling configuration that only
// collects location data once.
protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 5)),
    BackgroundTask(measures: [
      Measure(type: ContextSamplingPackage.LOCATION)
        ..overrideSamplingConfiguration =
            LocationSamplingConfiguration(once: true),
    ]),
    locationService);
```

### Weather and Air Quality Measures

The `WEATHER` and `AIR_QUALITY` measure types use the online [Open Weather API](https://openweathermap.org/api) and [Air Quality Open Data Platform](https://aqicn.org/data-platform/token/#/), respectively.
In order to use these services, you need to obtain an API key from each of them.
Once you have this, these services can be configured and added to a protocol like this:

```dart
// Define the online weather service and add it as a 'device'
final weatherService = WeatherService(apiKey: 'OW_API_key_goes_here');
protocol.addConnectedDevice(weatherService, phone);

// Add a background task that collects weather every 30 minutes.
protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 30)),
    BackgroundTask(measures: [
      Measure(type: ContextSamplingPackage.WEATHER),
    ]),
    weatherService);

// Define the online air quality service and add it as a 'device'
final airQualityService = AirQualityService(apiKey: 'WAQI_API_key_goes_here');
protocol.addConnectedDevice(airQualityService, phone);

// Add a background task that collects air quality every 30 minutes.
protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 30)),
    BackgroundTask(measures: [
      Measure(type: ContextSamplingPackage.AIR_QUALITY),
    ]),
    airQualityService);
```

Note that the weather and air quality measures are so-called "[one-time measures](https://docs.carp.dk/carp-mobile-sensing/measure-types#event-based-vs-one-time-measures)" and collect data once when triggered (in contrast to "event-based measures").

See the `example.dart` file for more examples of how to set up a CAMS study protocol for this context sampling package.
