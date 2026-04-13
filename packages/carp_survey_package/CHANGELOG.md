## 2.0.0

* upgrade to CARP Core and CAMS API level 2.0.0

## 1.9.1

* removing empty example app

## 1.9.0

* upgraded research package major version
* created example apps

## 1.8.6

* added a `SurveyStatus` to the survey results to know if a survey was "submitted" or "canceled"
* refix of issue [#342](https://github.com/cph-cachet/carp_studies_app/issues/342)
* removed `HEALTH_ASSESSMENT_TYPE`. Now part of carp_health_package
* upgrade to latest Flutter plugins

## 1.8.2

* upgrading to carp_mobile_sensing v. 1.11
* fix of issue [#342](https://github.com/cph-cachet/carp_studies_app/issues/342)
* added a no-op `SurveyProbe` to avoid warnings

## 1.7.0

* upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.10.0

## 1.6.0

* upgrading to carp_mobile_sensing v. 1.9 (better permission handling)

## 1.5.0

* update to `carp_mobile_sensing` v. 1.6

## 1.4.4

* added support for different commonly used task types.
* improvement to handling results from surveys
* fix of bug in deserialization from JSON

## 1.4.0

* upgrade to Dart 3.2
* update to `carp_mobile_sensing` v. 1.4

## 1.3.0

* update to `carp_mobile_sensing` v. 1.3.0
* update to the new `UserTask` model where the app (and not this package) is responsible for showing the user interface (`Widget`) of the survey task.
* upgrade of permission_handler plugins

## 0.40.1

* upgrade to `research_package` v. 1.2

## 0.40.0

* update to `carp_mobile_sensing` v. 0.40

## 0.33.0

* update to `carp_mobile_sensing` v. 0.33

## 0.32.1

* small update to dependencies in pubspec
* update to `research_package: ^0.7.0`

## 0.32.0

* update to `carp_mobile_sensing` v. 0.32

## 0.31.0

* update to `carp_mobile_sensing` v. 0.31

## 0.30.0

* upgrade to null-safety

## 0.21.0

* update to `carp_mobile_sensing` v. 0.21
* update to `research.package` v. 0.5.x with support for json serialization
* support for de/serialization of the `RPTask` survey in the `RPTaskMeasure`

## 0.20.4

* update to `carp_mobile_sensing` v. 0.20

## 0.20.3

* update to `carp_core` v. 0.20.3 (json serialization)

## 0.20.0

* **BREAKING:** upgrade to `carp_mobile_sensing` v. 0.20

## 0.12.2

* upgrade to `research_package` v. 0.4

## 0.12.1

* support for canceling a survey

## 0.12.0

* upgrade to `carp_mobile_sensing` v. 0.12

## 0.11.0

* upgrade to `carp_mobile_sensing` v. 0.11

## 0.10.0

* upgrade to `carp_mobile_sensing` v. 0.10

## 0.9.5

* upgrade to `carp_mobile_sensing` v. 0.9.5

## 0.9.3

* upgrade to `carp_mobile_sensing` v. 0.9.3

## 0.9.2

* upgrade to `carp_mobile_sensing` v. 0.9.2

## 0.9.0

* upgrade to `carp_mobile_sensing` v. 0.9.x

## 0.8.2

* support for canceling a survery ([Issue #77](https://github.com/cph-cachet/carp.sensing-flutter/issues/77))

## 0.8.1

* upgrade to `research_package` v. 0.3.x

## 0.8.0

* upgrade to `carp_mobile_sensing` v. 0.8.x

## 0.7.0

* upgrade to `carp_mobile_sensing` v. 0.7.0
* use the `AppTask` model for surveys

## 0.6.5

* upgrade to `carp_mobile_sensing` v. 0.6.5

## 0.6.1

* Upgrading to `research_package` v. 0.2.x

## 0.6.0

* Initial release compatible with `carp_mobile_sensing` version `^0.6.3`
