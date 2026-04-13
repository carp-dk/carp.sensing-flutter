## 4.0.0

* upgrade to CARP Core and CAMS API level 2.0.0

## 3.2.0

* Fix of [#472](https://github.com/cph-cachet/carp.sensing-flutter/issues/472)

## 3.1.0

* upgrade to halth plugins v. 12.1.0
* fixing issues in flutter analyze

## 3.0.1

* upgrading to health v. 12.x
* improving on requesting permissions for different health probes (issue [#461](https://github.com/cph-cachet/carp.sensing-flutter/issues/461))
* added support for `HealthAppTask` which are app task used to collect health data

## 2.11.0

* upgrading to health v. 11.x
* upgrade to carp_core v. 1.8 & carp_serialization v. 2.0
* type safe `fromJson()` methods & nested json serialization

## 2.10.0

* upgrading to carp_mobile_sensing v. 1.9.0 (better permission handling)
* upgrading to health v. 10.x

## 2.9.4

* update to `health` v. 9.x
* better handling of different issues on iOS and Health Connect in terms of permissions
* fix of bug in deserialization from JSON

## 2.9.2

* only using Health Connect on Android - discontinued support for Google Fit.
* checking for API level >= 34 on Google Health Connect and handling exceptions if not installed (issue [#221](https://github.com/cph-cachet/carp-studies-app/issues/221))
* checking that a protocol only contains data types that are valid for the selected platform
* types are no longer to be defined as part of the service
* update to documentation

## 2.8.0

* upgrade to Dart 3.2
* update to `carp_mobile_sensing` v. 1.4.0

## 2.7.1

* upgrade of uuid and permission_handler plugins
* update to `carp_mobile_sensing` v. 1.3.0
* addition of source id and name
* improvements to API docs

## 2.6.0

* update to `carp_mobile_sensing` v. 1.2.0
* now uses a dedicated `HealthService` to access the health data on the phone
* upgrade to `health` v. 8.x which supports Google Health Connect

## 2.5.0

* update to `carp_mobile_sensing` v. 0.40.0
* update to `health` v. 4.3.0

## 2.4.0

* update to `carp_mobile_sensing` v. 0.40.0

## 2.3.0

* update to `carp_mobile_sensing` v. 0.33.0

## 2.2.0

* update to `carp_mobile_sensing` v. 0.32.0

## 2.1.2

* small update to dependencies in pubspec

## 2.1.0

* upgrade to `carp_mobile_sensing` v. 0.31.0

## 2.0.0

* upgrade to null-safety

## 1.6.0

* update to `carp_mobile_sensing` v. 0.21.x

## 1.5.2

* update to `carp_mobile_sensing` v. 0.20.4

## 1.5.1

* update to `carp_core` v. 0.20.3 (json serialization)

## 1.5.0

* **BREAKING:** upgrade to `carp_mobile_sensing` v. 0.20.x

## 1.4.0

* upgrade to `carp_mobile_sensing` v. 0.12.0

## 1.3.0

* upgrade to `carp_mobile_sensing` v. 0.11.0

## 1.2.0

* upgrade to `health` v. 3.0.0
* upgrade to `carp_mobile_sensing` v. 0.10.0

## 1.1.2

* upgrade to `carp_mobile_sensing` v. 0.9.5

## 1.1.1

* upgrade to `carp_mobile_sensing` v. 0.9.3

## 1.1.0

* upgrade to `carp_mobile_sensing` v. 0.9.x

## 1.0.1

* Synced with Health version 2.0.2

## 1.0.0

* upgrade to Health 2.0.x API

## 0.7.0

* upgrade to `carp_mobile_sensing` v. 0.7.x

## 0.6.5

* upgrade to `carp_mobile_sensing` v. 0.6.5

## 0.6.2

* Small update on the documentation and printing.

## 0.6.1

* Small updates to documentation and adding an example.

## 0.6.0

* Initial release depending on version 0.6.x of `carp_mobile_sensing`
