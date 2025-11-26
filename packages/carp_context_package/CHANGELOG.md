## 2.0.0

* upgrade to CARP Core and CAMS API level 2.0.0

## 1.12.0

* removing the deprecated `CURRENT_LOCATION` - see [why](https://github.com/cph-cachet/carp.sensing-flutter/issues/471#issuecomment-2774787144)
* upgrade to latest weather and air_quality plugins

## 1.11.2

* fix of [#471](https://github.com/cph-cachet/carp.sensing-flutter/issues/471)
* the `CURRENT_LOCATION` is deprecated, but still available
* added a `LocationSamplingConfiguration` which can be configured to only collect location once, and hence makes it possible to use a `LOCATION` measure instead of a `CURRENT_LOCATION`

## 1.10.1

* upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.10.0
* upgrade to mobility_features v. 6.0
* fix of error in Location.toJson() method

## 1.9.0

* upgrading to carp_mobile_sensing v. 1.9.0 (better permission handling)
* upgrading to location v. 7

## 1.7.0

* putting the location plugin back in business (instead of the geolocator plugin)
* revisiting issue [#389](https://github.com/cph-cachet/carp.sensing-flutter/issues/389), making a new implementation of the getCurrentLocation() method
* improved the README to better explain how to handle location permissions on iOS

## 1.6.0

* replacing the location plugin with the geolocator plugin
* fix of [#389](https://github.com/cph-cachet/carp.sensing-flutter/issues/389) - timeout to getCurrentLocation() method
* fix of linter issues

## 1.5.0

* bump dependencies - location version to 6.0.0 & openmhealth_schemas to 0.3.0
* bump Dart minimum version to 3.2 & Flutter to minimum version to 3.16

## 1.4.4

* default location updated changed to one minute (instead of 1 second)
* improvements to permission handling in the Location Manager
* improvements to connection handling in the Location Manager
* only requesting ACTIVITY permissions once

## 1.4.0

* upgrade to Dart 3.2
* update to `carp_mobile_sensing` v. 1.4.0

## 1.3.3

* upgrade of uuid and permission_handler plugins
* update to `carp_mobile_sensing` v. 1.3.0
* included [PR#344](https://github.com/cph-cachet/carp.sensing-flutter/pull/344)
* fix of [#349](https://github.com/cph-cachet/carp.sensing-flutter/issues/349)

## 1.2.0

* update to `carp_mobile_sensing` v. 1.2.0 using the new device permissions model

## 1.1.1

* update to `carp_mobile_sensing` v. 1.1.0
* fix of `getLastKnownLocation()` bug in the location manager

## 0.40.0

* update to `carp_mobile_sensing` v. 0.40.0

## 0.33.0

* update to `carp_mobile_sensing` v. 0.33.0
* removal of Weather and Air Quality API keys

## 0.32.1

* improvement to activity and mobility sensing
* using the `flutter_activity_recognition` plugin for AR
* upgrade to `mobility_features: ^3.1.0`

## 0.32.0

* update to `carp_mobile_sensing` v. 0.32.0

## 0.31.2

* small update to dependencies in pubspec
* re-generation of json serialization

## 0.31.0

* update to `carp_mobile_sensing` v. 0.31.0
* docs: issue [#218](https://github.com/cph-cachet/carp.sensing-flutter/issues/218)

## 0.30.1

* upgrade to use `location` instead of `carp_background_location`
* removal of request for local permissions - this has to take place in the app, due to Google's new privacy restrictions.

## 0.30.0+1

* upgrade to null-safety
* update of documentation on `manifest.xml` configuration

## 0.21.2

* upgrade of `activity_recognition_flutter` to version `4.0.2`

## 0.21.1

* update to `carp_mobile_sensing: ^0.21.0`
* update to `mobility_features: ^2.0.6`

## 0.20.4

* update to `carp_mobile_sensing` v. 0.20.4

## 0.20.3

* update to `carp_core` v. 0.20.3 (json serialization)

## 0.20.0

* **BREAKING:** upgrade to `carp_mobile_sensing` v. 0.20.x

## 0.12.1+1

* removed collection of UNKNOWN activity types (was generating a lot of events on iOS)
* updating dependencies

## 0.12.0

* upgrade to `carp_mobile_sensing` v. 0.12.x
* fix of small bug in activity probe.

## 0.11.0

* upgrade to `carp_mobile_sensing` v. 0.11.x
* small improvements to `geofence` measure.
* enhacement: issue [#135](https://github.com/cph-cachet/carp.sensing-flutter/issues/135)

## 0.10.0

* upgrade to `carp_mobile_sensing` v. 0.10.x

## 0.9.7

* upgrade to `activity_recognition_flutter` v. 2.0.2

## 0.9.6

* upgrade to `activity_recognition_flutter` v. 2.0.0

## 0.9.5

* upgrade to `carp_mobile_sensing` v. 0.9.5

## 0.9.4

* fix: using the [geolocator](https://pub.dev/packages/geolocator) plugin for the `location` measure.
* fix: stabilizing `weather` and `air_quality` probes

## 0.9.3

* upgrade: to `carp_mobile_sensing` v. 0.9.3
* doc: update of README to reflect using new CARP plugins for background location and activity recognition.

## 0.9.2

* upgrade: to `carp_mobile_sensing` v. 0.9.2

## 0.9.1

* upgrade: to `carp_mobile_sensing` v. 0.9.x

## 0.9.0+2

* fix: corrected static analysis errors caused by an old location plugin
* upgrade: dependencies to their newest versions
  * in particular; `MobilityFeatures` was upgraded to the 2.x.x API

## 0.9.0+1

* fic: corrected static analysis error caused by the new Activity Recognition API
* docs: added example

## 0.8.6

* refactor: removed the latitude and longitude fields from `WeatherMeasure` since they were not used.

## 0.8.5

* Added mobility sampling via the [mobility_features](https://pub.dev/packages/mobility_features)  package

## 0.8.0

* upgrade to `carp_mobile_sensing` v. 0.8.x

## 0.7.1

* upgrade to `carp_mobile_sensing` v. 0.7.1 and `weather` v. 1.1.x

## 0.7.0

* upgrade to `carp_mobile_sensing` v. 0.7.0

## 0.6.6

* the ``location`` measure is now a ``DatumProbe`` and only collects location on request.
If continuous (stream-based) location is needed, use the `geolocation` measure.
* using our own Flutter plugin for activity recognition - [`activity_recognition_flutter`](https://pub.dev/packages/activity_recognition_flutter).

## 0.6.5

* upgrade to `carp_mobile_sensing` v. 0.6.5

## 0.6.4

* change of location provider to the [geolocator](https://pub.dev/packages/geolocator) plugin.
* introduction of a `geolocation` measure type for listening to location events.
* adjustment of the `LocationMeasure` to hold configuration for specifying various options.

## 0.6.3

* support for `air_quality`

## 0.6.1

* Changed the location probe to a periodic probe which can be configured to sample location data on a specific frequency.
* allignment with `carp_mobile_sensing` v. 0.6.1.
* testing on iOS reveals that activity recognition does not work on iOS

## 0.6.0

* update to `carp_mobile_sensing` version 0.6.0
* Weather measure is no longer periodic but 'one-off', i.e. at `DatumProbe`.
Use the new `Trigger` model in `carp_mobile_sensing` v.0.6.0 to achieve periodic sampling of weather information.

## 0.5.0 BREAKING

* Upgraded to use [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) version 0.5.0
  * **Breaking change.** This version has been migrated from the deprecated Android Support Library to *AndroidX*.
This should not result in any functional changes, but it requires any Android app using this plugin to also
[migrate](https://developer.android.com/jetpack/androidx/migrate) if using the original support library.
  * See Flutter [AndroidX compatibility](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)

## 0.3.6

* small update to domain model

## 0.3.5

* update to json_serialization v.2
* added support for `geofence` measure

## 0.3.4

* update to `carp_mobile_sensing` version 0.3.10

## 0.3.3

* Documentation

## 0.3.2

* Update to `carp_mobile_sensing` v. 0.3.7
* Using the data types in the package (`activity`, `weather`, `location`)

## 0.3.1

* Documentation

## 0.3.0

* Initial release compatible with `carp_mobile_sensing` version `0.3.*`
