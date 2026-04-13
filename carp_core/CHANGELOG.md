## 2.1.2

* fix of issue [#561](https://github.com/carp-dk/carp.sensing-flutter/issues/561)
* upgrade of pubspec to latest standard.

## 2.0.0

* upgrade to reflect the latest CARP Core Kotlin domain model in the 'client' sub-system
* better support for `StudyStatus` in the client manager ( [#504](https://github.com/carp-dk/carp.sensing-flutter/issues/504))

## 1.9.4

* fix of issue [#506](https://github.com/carp-dk/carp.sensing-flutter/issues/506)
* added unit tests for input data types

## 1.9.3

* fix of issue [#491](https://github.com/carp-dk/carp.sensing-flutter/issues/491)
* fix of issue [#452](https://github.com/carp-dk/carp.sensing-flutter/issues/452)
* fix of issue [#499](https://github.com/carp-dk/carp.sensing-flutter/issues/499) and [#258](https://github.com/carp-dk/carp-webservices-spring/issues/258)
* adding `samplingConfiguration` to the constructor of `Measure`

## 1.8.3

* upgrade to carp_serialization v. 2.0
* type safe fromJson methods
* nested json serialization
* `addStudy` in client manager modified to take a `Study`
* fix of issue [#435](https://github.com/carp-dk/carp.sensing-flutter/issues/435)

## 1.7.1

* support for new [input data types](https://github.com/carp-dk/carp-webservices-spring/blob/master/docs/input-data-types.md) at CAWS

## 1.6.0

* fix of linter issues
* better support for disposing of a study deployment
* upgrade to UUID in carp_serialization (v. 1.2.0)

## 1.5.0

* durations are now specified using the Dart `Duration` class (rather than ISO 8061 format)

## 1.4.1

* small update to `DeviceDataCollectorFactory` API.

## 1.4.0

* upgrade to Dart 3.2

## 1.3.1

* fix of issue [#352](https://github.com/carp-dk/carp.sensing-flutter/issues/352)

## 1.3.0

* upgrade of uuid package

## 1.2.0

* added input data format for informed consent, participant name, and more

## 1.1.0

> Note: This release has breaking changes...

* the first stable release of CARP cores which follows the [carp.core-kotlin](https://github.com/imotions/carp.core-kotlin) v. 1.1.0 domain model
* upgrade to [carp_serializable](https://pub.dev/packages/carp_serializable) v. 1.1.0
* added `PersonalComputer` and `WebBrowser` as new device configurations
* moved support for handling `DataPoint` data from carp_core to carp_webservices (since this is specific to CAWS and not part of the CARP Core domain model)

## 0.40.8

* refactor of `DataManager` interface to support multiple deployment on the `ClientManager`
* adding `pause`, `remove`, and `dispose` life cycle methods to the `StudyRuntime`
* fix of JsonKey annotations

## 0.40.3

* fix of non-null `id` in `DeviceDataCollector`

## 0.40.2

* fix of issue [#269](https://github.com/carp-dk/carp.sensing-flutter/issues/269)

## 0.40.1

* fix of issue [#265](https://github.com/carp-dk/carp.sensing-flutter/issues/265)

## 0.40.0

* Serialization has been moved to a separate package - [carp_serializable](https://pub.dev/packages/carp_serializable)
* `ConcurrentTask` is renamed to `BackgroundTask`
* support for `BatteryAwareSamplingConfiguration` sampling configuration added
* fix of error in `SetParticipantData` request
* Upgraded to Dart 2.17
* Refactoring to comply to [official Dart recommended lint rules](https://pub.dev/packages/flutter_lints)

## 0.33.1

* implementation of `ScheduledTrigger` incl. test

## 0.33.0

* updates to the device model API in the `client` library.

## 0.31.3+1

* small update to dependencies in pubspec.
* re-generation of json serialization.

## 0.31.2

* support for stopping (permanently) a study deployment.

## 0.31.1

* small update to `DataManager` interface to fix issue [#221](https://github.com/carp-dk/carp.sensing-flutter/issues/221).

## 0.31.0

* `description` in `StudyProtocol` is now non-nullable (required when uploading a protocol to CARP)

## 0.30.1+3

* fix of json serialization bugs (x2)
* update of API docs
* re-build of json functions

## 0.30.0

* upgrade to null-safety

## 0.21.5

* Removed unnecessary JSON object from `CreateStudyDeployment` request ([PR#200](https://github.com/carp-dk/carp.sensing-flutter/pull/200)).

## 0.21.4+3

* small bug fix in json serialization
* new constructor to `Trigger` classes

## 0.21.3

* added support for `ProtocolService` sub-system including request classes for using this.
* added support for `DataEndPoint` and `DataManager` handling as part of `MasterDeviceDeployment`.
* now using a `SerializationException` to raise issues in de/serialization of objects to/from json.
* fixed a bug in the `StudyDeployment.getDeviceDeploymentFor()` method.

## 0.21.2

* removal of the overall `carp_core` library - now only using the sub-system libraries. This make the API documentation much more readable.
* update of API documentation

## 0.21.1

* small improvement to the `client` sub-system domain classes

## 0.21.0

* implementation of the `client` sub-system domain classes

## 0.20.3

* improvements to the `FromJsonFactory().fromJson()` method.
* added a example of how to support json serialization of polymorphic classes using the `Serialization` class.

## 0.20.2

* `DataPoint` updated to support both up- and download to the CARP server

## 0.20.1

* `ProtocolOwner` class added
* example added

## 0.20.0

* 1st extraction of core library from the CAMS package
