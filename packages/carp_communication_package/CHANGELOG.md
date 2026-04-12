## 2.0.1

* upgrade to CARP Core and CAMS API level 2.0.0
* using the [device_calendar_plus](https://pub.dev/packages/device_calendar_plus) plugin

## 1.8.0

* replacing the `telephony` plugin with the `another_telephony` plugin (issue [#464](https://github.com/cph-cachet/carp.sensing-flutter/issues/464))

## 1.7.1

* upgrade of APK error caused by `call_log` plugin - replaced by `call_e_log`
* upgrade to latest Flutter plugins

## 1.6.1

* upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.10.0

## 1.5.0

* upgrading to carp_mobile_sensing v. 1.9.0 (better permission handling)

## 1.4.2

* `Permission.calendarFullAccess` used instead of deprecated `Permission.calendar`.
* fix of bug in deserialization from JSON

## 1.4.0

* upgrade to Dart 3.2
* update to `carp_mobile_sensing` v. 1.4.0
* upgrade of permission_handler plugins

## 0.40.0

* update to `carp_mobile_sensing` v. 0.40.0

## 0.33.0

* update to `carp_mobile_sensing` v. 0.33.0

## 0.32.0

* update to `carp_mobile_sensing` v. 0.32.0

## 0.31.1

* small update to dependencies in pubspec
* re-generation of json serialization

## 0.31.0

* update to `carp_mobile_sensing` v. 0.31.x
* upgrade to `device_calendar: ^4.0.1-dev.13167`

## 0.30.0

* upgrade to null-safety

## 0.21.0

* update to `carp_mobile_sensing` v. 0.21.x

## 0.20.4

* update to `carp_mobile_sensing` v. 0.20.4

## 0.20.3

* update to `carp_core` v. 0.20.3 (json serialization)

## 0.20.0

* **BREAKING:** upgrade to `carp_mobile_sensing` v. 0.20.x

## 0.12.0

* upgrade to `carp_mobile_sensing` v. 0.12.x

## 0.11.0

* upgrade to `carp_mobile_sensing` v. 0.11.x

## 0.10.0

* upgrade to `carp_mobile_sensing` v. 0.10.x

## 0.9.5

* upgrade to `carp_mobile_sensing` v. 0.9.5

## 0.9.3

* upgrade to `carp_mobile_sensing` v. 0.9.3

## 0.9.2

* upgrade to `carp_mobile_sensing` v. 0.9.2

## 0.9.0

* upgrade to `carp_mobile_sensing` v. 0.9.x

## 0.8.0

* upgrade to `carp_mobile_sensing` v. 0.8.x
* upgrading the `PhoneLogProbe`
  * removed the `PhoneLogMeasure` measure
  * using the new `MarkedMeasure` for the
* using `Duration` to specify the `CalendarMeasure`

## 0.7.0

* upgrade to `carp_mobile_sensing` v. 0.7.0

## 0.6.6

* upgrade to `carp_mobile_sensing` v. 0.6.6

## 0.6.5

* upgrade to `carp_mobile_sensing` v. 0.6.5

## 0.6.1

* alignment with `carp_mobile_sensing` v. 0.6.1.
* extensive testing on iOS

## 0.6.0

* update to `carp_mobile_sensing` version 0.6.0

## 0.5.0

* `calendar` measure, probe, and  added incl. default privacy protection
* `phone_log` measure redesigned as a periodic measure
* `text_message_log` measure redesigned as a periodic measure
* Relying on carp_mobile_sensing ^0.5.0 which is migrated to AndroidX.
  * This shouldn't result in any functional changes, but it requires any Android apps using this plugin to also
[migrate](https://developer.android.com/jetpack/androidx/migrate) if they're using the original support library.
  * See Flutter [AndroidX compatibility](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)

## 0.3.4

* upgrade to json_serializable v.2
* privacy schema support for hashing text messages and phone numbers

## 0.3.3

* update to `carp_mobile_sensing` version 0.3.10

## 0.3.2

* Documentation

## 0.3.1

* Documentation

## 0.3.0

* Initial release compatible with `carp_mobile_sensing` version `0.3.*`
