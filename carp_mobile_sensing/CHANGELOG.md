## 2.1.1 - BREAKING

This release has two new main features: (i) to support adding, running, and removing **multiple studies** to the client manager, and (ii) to **save runtime state persistently** so that sampling of data in all studies will resume effortlessly across app restart. In addition, a set of issues have been addressed, as listed in [Milestone 2.0.0](https://github.com/carp-dk/carp.sensing-flutter/milestone/3?closed=1). The important ones include:

* Update of the client software architecture to reflect the CARP Core client architecture. This - amongst other things - provides better support for `StudyStatus` in the client manager ([#504](https://github.com/cph-cachet/carp.sensing-flutter/issues/504))
* Simplified configuration - now only the client and not the controller needs configuration.
* Revised state machine model for executors, now using states 'resumed' and 'paused' instead of 'started' and 'stopped'
* Added `AppLifecycleEvent` measure to collect life-cycle event from the app
* Correct device registration in the deployment service ([#550](https://github.com/cph-cachet/carp.sensing-flutter/issues/550)).

The example app has also been update to illustrate how a client can run multiple studies ([#559](https://github.com/cph-cachet/carp.sensing-flutter/issues/559)).
Also note that CAMS now has a completely new [documentation](https://docs.carp.dk/carp-mobile-sensing/) site.

## 1.13.1

* Fix of [#491](https://github.com/cph-cachet/carp.sensing-flutter/issues/491)
* Fix of [#492](https://github.com/cph-cachet/carp.sensing-flutter/issues/492)
* Fix of [#493](https://github.com/cph-cachet/carp.sensing-flutter/issues/493)
* Fix of [#494](https://github.com/cph-cachet/carp.sensing-flutter/issues/494)
* Fix of [#498](https://github.com/cph-cachet/carp.sensing-flutter/issues/498)

## 1.12.6

* Deprecating the `ONE_TIME_SENSING_TYPE` - now there is only one type of sensing user task ([#488](https://github.com/cph-cachet/carp.sensing-flutter/issues/488))

## 1.12.4

* Upgrade of Android APK
* Bumped minimum Flutter SDK requirement to 3.3
* Upgrade of plugins to latest versions
* Fix of [#470](https://github.com/cph-cachet/carp.sensing-flutter/issues/470)
* Upgrade to latest Flutter plugins
* Fix of [#481](https://github.com/cph-cachet/carp.sensing-flutter/issues/481)
* Fix of [#482](https://github.com/cph-cachet/carp.sensing-flutter/issues/482)

## 1.11.6

* Support for the `NoUserTaskTrigger` (issue [#453](https://github.com/cph-cachet/carp.sensing-flutter/issues/453))

## 1.11.5

* Fix of issue with restarting data collection on device reconnect (issue [#442](https://github.com/cph-cachet/carp.sensing-flutter/issues/442))
* Added timestamps to user tasks when completed (issue [#441](https://github.com/cph-cachet/carp.sensing-flutter/issues/441))

## 1.11.4

* Extended the `SmartphoneStudy` and `SmartphoneDeployment` to hold info on participant ID and participant role for a study running on the phone. This helps upload participant data (like informed consent) without the need to specify this every time.
* Fix of [#429](https://github.com/cph-cachet/carp.sensing-flutter/issues/429)
* Fix of [#430](https://github.com/cph-cachet/carp.sensing-flutter/issues/430)
* Fix of [#431](https://github.com/cph-cachet/carp_studies_app/issues/341)
* Fix of [#437](https://github.com/cph-cachet/carp.sensing-flutter/issues/437)

## 1.10.0

* Upgrade to carp_core v. 1.8 & carp_serialization v. 2.0
* Type safe `fromJson()` methods & nested json serialization
* Upgrade of example app to use new Flutter Android Gradle build setup

## 1.9.0

* Support for handling permission on a Measure level [#407](https://github.com/cph-cachet/carp.sensing-flutter/issues/407).

## 1.8.2

* Fix of [#408](https://github.com/cph-cachet/carp.sensing-flutter/issues/408)

## 1.8.1

* Added support for extension of triggers, [#403](https://github.com/cph-cachet/carp.sensing-flutter/issues/403). See the section on [Adding new Trigger](https://github.com/cph-cachet/carp.sensing-flutter/wiki/5.-Extending-CARP-Mobile-Sensing#adding-new-triggers) on the CAMS wiki.
* Refactor of the software architecture to align better with a domain-driven design architecture.
* Improvements to executor state machine (can only restart an executor/probe that is already started)

## 1.7.1

* Fix of [#390](https://github.com/cph-cachet/carp.sensing-flutter/issues/390)

## 1.7.0

* Refactor task and notification enqueueing process:
  * Move from sequential scheduling for each TaskControl to buffering tasks in AppTaskController.
  * Buffered tasks are sorted by time and scheduled in batches based on platform limits (iOS and Android notification limits).
* Enhance consistency in task scheduling:
  * Ensured all necessary tasks in the foreseeable future are queued.
  * Prevent task and notification drops due to notification slot limitations.
* Resolve issue with duplicate tasks being scheduled:
  * Ensure tasks are stored in the database after being scheduled the first time.

## 1.6.1

* Improvement to removing studies (linked to issue [#283](https://github.com/cph-cachet/carp_studies_app/issues/283) in the CARP Studies App)
  * adding a new "disposed" sensing state
  * removing study deployment runtime
  * better handling of restarting sampling on device reconnection
* Upgrade of carp_serialization and carp_core
* Getting rid of uuid package dependency
* Fix of [#394](https://github.com/cph-cachet/carp.sensing-flutter/issues/394)

## 1.5.1

* Automatically stopping a background task if all of its underlying probes have stopped (fix of [384](https://github.com/cph-cachet/carp.sensing-flutter/issues/384))
* Upgrade to carp_core v. 1.5.0 (getting rid of `IsoDuration`)

## 1.5.0

* Improvements to the Notification Controller
  * support app-specific methods to create, schedule, and cancel app-specific notifications
  * asks for permission on Android (Issue [#375](https://github.com/cph-cachet/carp.sensing-flutter/issues/375))
  * tapping a notification takes the user to the right task in the app (Issue [#376](https://github.com/cph-cachet/carp.sensing-flutter/issues/376))
* Fix of [#379](https://github.com/cph-cachet/carp.sensing-flutter/issues/379)

## 1.4.7

* Improvements to handling connected BLE devices
* Improvement to triggers and probes using BLE devices
* Improvements to restarting sampling on device reconnect
* Upgrade of packages

## 1.4.4

* Upgrade of plugins (battery_plus, sensor_plus, cron)
* Support for specifying ("overriding") sampling frequency in sensor measures (accelerometer, gyroscope, magnetometer) by using a `IntervalSamplingConfiguration`
* Improvement to executor state machine
* Improvement to restarting sampling on device (re)connection, including now also online service like the location service
* Improvements to device manager

## 1.4.0+1

* Upgrade to Dart 3.2
* Update to README

## 1.3.5

* Upgrade of uuid and permission_handler plugins
* Addition of a ACCELERATION_FEATURES that samples accelerometer readings over a sampling period and calculates a set of statistical features (Issue [336](https://github.com/cph-cachet/carp.sensing-flutter/issues/336) & [347](https://github.com/cph-cachet/carp.sensing-flutter/issues/347))
* Removal of support for awesome_notifications which does not compile on iOS
* Improvements to API docs
* Removal of `toString()` methods on data points - if you want to print data, print the json generated from the `toJson()` method.
* Rename of `TransformerSchemaRegistry` to `DataTransformerSchemaRegistry`

## 1.2.0

* Battery stream on device controller and device managers
* Support for creating, scheduling, and cancelling generic text-based notifications in the notification controller
* A device manager can now specify and handle its required permissions

## 1.1.3

* Added support for restoring a `SmartPhoneClientManager` on app restart
* A `privacySchemaName` is moved to be part of the `SmartphoneStudyProtocol` configuration.
* Simplification of API so that a simple local study can be configured, initialized, and started in one statement (without the need for understanding the whole deployment architecture).

## 1.1.2

> Note: This release has breaking changes.

* The first stable release of CARP Mobile Sensing which follows the [carp.core-kotlin](https://github.com/imotions/carp.core-kotlin) v. 1.1.0 domain model, which again is implemented in the [carp_core](https://pub.dev/packages/carp_core) v. 1.1.0 Dart Domain model.

* This entails a set of **breaking** changes to the domain model:
  * CARP cores now comes with a range of pre-defined Measure Types (e.g., `geolocation`, `stepcount`, etc.). These CARP Core measures has replaced the previous CAMS versions of these. However, most of the "old" measures are kept, so there should be backward compatibility.
  * Important new measure types are the `TriggeredTask`, `CompletedTask`, which now automatically collected data on when and how a trigger and task are done.
  * A `Heartbeat` measurement has been added, which sends a measure every 5 minutes for each device (incl. the phone), if connected. This can be used to retrospectively check if sampling has been running (typically used in our so-called [Coverage tests](https://carp.cachet.dk/sampling-coverage-in-mobile-sensing-on-android-11/)).
  * In the protocol, triggering is now controlled by the `Control` class, which basically states if sampling should be started or stopped. So, instead of adding a `TriggeredTask` to a protocol you now add a `TaskControl` instead.
  * As part of this, the states of sampling has changed from "resumed" and "paused" to "started" and "stopped" (to reflect the `Control` state of a `TaskControl`).
  * Configuration of sampling is done using the `SamplingConfiguration` which can be part of a `DataTypeSamplingScheme` which again can be part of a `DataTypeSamplingSchemeMap`. A description of how this works is on the [CARP Core description of Sampling Schemes and Configuration](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-common.md#sampling-schemes-and-configurations) section. Note that sampling configurations can be associated both with a `Measure`, with a `DeviceConfiguration` for a device, and with a `SamplingPackage`.
  
* The new [`data`](https://github.com/imotions/carp.core-kotlin/blob/develop/docs/carp-data.md) sub-system has been implemented in CAMS. This entails:
  * Sampled data is now stored as `Data` objects which again are stored as part of a `Measurement` (this replaces the old `DataPoint` data model).
  * Measurements are streamed using the `measurements` stream which is accessible from the `SmartphoneDeploymentController`.
  * Measurements can be stored or managed by a `DataManager`. CAMS comes with two build-in data managers: the `FileDataManager` and the `SQLiteDataManager`.

* The `UserTask` is no longer responsible for showing the user interface of the task. Now, instead of showing the user interface, the `onStart` methods now returns a `Widget` to be shown. In this model, the app (and not CAMS) is responsible for deciding when and how to show the user interface. This entails that the the life cycle methods of `onStart`, `onCancel`, `onExpired`, and `onDone` no longer takes the Flutter `BuildContext` as a parameter. Read more on the `AppTask` and `UserTask` model on the [CAMS wiki](https://github.com/cph-cachet/carp.sensing-flutter/wiki/4.-The-AppTask-Model).

* Other smaller changes include:
  * Use the `CarpMobileSensing.ensureInitialized()` static method in your `main` method to ensure that CAMS is initialized before use.
  * Update of `AppDelegate.swift` in example app to handle notifications in the background.
  * Adding info, warning, and debug information to the system log (instead of the console) using colors for better reading.
  
## 0.40.13

* Added support for `timezone` data type (issue [#301](https://github.com/cph-cachet/carp.sensing-flutter/issues/301)).
* fix of JsonKey annotations

## 0.40.12

* Better support for removing a study deployment from a client manager
  * Refactor of `DataManager` interfaces; file, sqlite, etc. to support multiple deployments on the same client.
  * NotificationController now cancels notifications for a study which is removed.
  * Removal of tasks from the AppTaskController.
* Support for local caching of files while keeping sampled data
* fix of JsonKey annotations

## 0.40.11

* Fix of issue [#305](https://github.com/cph-cachet/carp.sensing-flutter/issues/305).

## 0.40.10

* Adding `dispose`, `pause`, and `remove` life cycle methods to the `DeploymentController`
* Support for deleting cached runtime information (deployment and task list)
* Fix of bug in `getTaskExecutor` method

## 0.40.7

* Fix of `BufferingUserAccelerometerProbe` error.

## 0.40.6

* Addition of `USER_ACCELEROMETER` measure (issue [#283](https://github.com/cph-cachet/carp.sensing-flutter/issues/283)).
* Added the `FunctionTask` task type which can executed a Dart function when resumed (issue [#284](https://github.com/cph-cachet/carp.sensing-flutter/issues/284)).
* Support for application-specific data / configuration in the `SmartphoneStudyProtocol` (issue [#285](https://github.com/cph-cachet/carp.sensing-flutter/issues/285)).

## 0.40.5

* Fix of issue [#280](https://github.com/cph-cachet/carp.sensing-flutter/issues/280).

## 0.40.4+1

* Added convenience method `addStudyProtocol` to `SmartPhoneClientManager` and updated examples accordingly.

## 0.40.3

* Added the `UserTaskTrigger` trigger.
* Added the `magnetometer` measure type.
* Upgrade of `device_info_plus` v. ^8.0.0
* Upgrade to `carp_core` v. 0.40.3

## 0.40.2

* Upgrade to `carp_core` v. 0.40.2
* Fix of issue [#269](https://github.com/cph-cachet/carp.sensing-flutter/issues/269).

## 0.40.0 - BREAKING

* One purpose of this release is to make CAMS more stable across app re-restart (since the OSs (Android / iOS) increasingly are killing apps). This has lead to the following changes:
  * `MarkedMeasure` is no longer a separate measure type. The state of all measure are now saved across app restart.
  * A `OneTimeTrigger` no longer needs an id (this is now handled behind-the-scene).
  * All `AppTask` are now scheduled persistently using the notification system. When an app task is due, a notification is made on the phone, and when the user taps this notification, the app is (re)started.
  * As part of this, CAMS now asks for permissions to use notifications on the phone (if the `SmartphoneDeploymentController`is configured to use notifications).
* Another purpose is to change the configuration of the measures in the study protocol to resemble the newly released version 1.0.0 of the [CARP Core Framework](https://github.com/imotions/carp.core-kotlin) (Note, however, that CAMS is not yet updated to version 1.0.0 of CARP Core - this will happen in the next release). This entails:
  * `Measure` no longer contains sampling configurations but only specifies the `type` of data to collect (e.g., `dk.cachet.carp.memory`)
  * instead, sampling configuration is now done in the `SamplingConfiguration` and `SamplingScheme` classes (which can be part of a `StudyProtocol`).
  * default sampling configuration are now part of a `SamplingSchema` provided by the `SamplingPackage`. For example, periodic sampling in e.g. the `MemoryProbe` is configured using a `PeriodicSamplingConfiguration` in the `DeviceSamplingPackage`.
  * improved support for supporting 'connected devices' such as a wearable ECG monitor or an online weather service. This is configured using specialized `DeviceDescriptor` classes.
* Added support for storing data in a SQLite database using a `SQLiteDataEndPoint` data endpoint.
* Upgrade to Android `compileSdkVersion` 33. Make sure to update the `android/app/build.gradle` file and set the `compileSdkVersion` to 33.
* Upgraded to Dart 2.17 and Flutter 3.0
* Refactoring to comply to [official Dart recommended lint rules](https://pub.dev/packages/lints)
* Additional refactoring include:
  * `DeploymentDelayedTrigger` has been removed. Use `ElapsedTimeTrigger`.
  * `RecurrentScheduledTrigger` no longer supports the `remember` feature. Persistent sampling for app tasks is now supported by the persistent sampling configuration across app re-start as described above.
  * `AutomaticTask` is replaced by the `BackgroundTask` from carp_core.

## 0.33.0

* upgrade to `carp_core` v. 0.33.0
* support of new device model, incl. configuration of devices with device descriptors
* **BREAKING** - the `SmartphoneDeploymentController` no longer automatically deploys the study when calling `addStudy()`.
  * make sure to call the `tryDeployment()` method when you want the deployment to happen.
* the factory method for getting default sampling schemes (common, debug, etc.) are now instance members (rather than functions) on the singleton `SamplingPackageRegistry`.
* upgrade to `permission_handler: ^9.2.0`

## 0.32.3

* added `OneTimeTrigger` as a new trigger type.
* `timestamp` is now enforced (not null) on all `Datum` objects.

## 0.32.1

* notifications are no longer (re-)send when the app task queue is restored across app restart.

## 0.32.0

* upgrade to `permission_handler: ^8.3.0`
* **NOTE**
  * see the [permission_handler](https://pub.dev/packages/permission_handler) README on how to set up your app - for example:
  * on Android, in `build.graddle` set `compileSdkVersion 31`
  * on iOS, add permission to your `Info.plist` file and update the `Podfile`

## 0.31.4

* support for a `ConditionalPeriodicTrigger` which preiodically checks resume/pause conditions (originates from [#230](https://github.com/cph-cachet/carp.sensing-flutter/issues/230)).
* `PeriodicTrigger` now required a sampling `duration`.
* upgrade of `pubspec` libaries (`flutter_local_notifications`, `cron`, and `json`).
* re-generation of json serialization
* still cannot upgrade `permission_handler` since 8.2.0 gives a graddle compile error?????

## 0.31.1

* bug fix of [#221](https://github.com/cph-cachet/carp.sensing-flutter/issues/221).

## 0.31.0

* A CAMS-specific `StudyProtocol` named `SmartphoneStudyProtocol` has been reintroduced (c.f., v. 0.30.0). It turned out that there are several things which needs to be configured as part of a study protocol, which the generic `StudyProtocol` from carp_core doesn't support. The new `SmartphoneStudyProtocol` supports specifying:
  * The `StudyDescription` describing the study including the researcher responsible for the study.
  * The `DataEndPoint` specifying where and how to upload data.
* The `SmartphoneDeploymentService` is updated to handle the new `SmartphoneStudyProtocol`.
* `StudyDescription` now also supports specifying the URL of a study description and the privacy policy.

## 0.30.6

* separate method for asking permissions in `SmartphoneDeploymentController`
* bug fix of [#215](https://github.com/cph-cachet/carp.sensing-flutter/issues/215) - notifications can now be enabled/disabled in the `configure` method of the `SmartphoneDeploymentController`.

## 0.30.5

* all deployment information is now stored in a folder named `<local_application_path>/carp/deployments/<study_deployment_id>` where `local_application_path` is the folder where an application can place files that are private to the application.
  * On iOS, this is the `NSDocumentsDirectory` and this can be accessed like accessing files on iOS via the Finder.
  * On Android, Flutter files are stored in the `AppData` directory, which is located in the `data/data/<package_name>/app_flutter` folder. Files can be accessed via AndroidStudio.

## 0.30.4

* added support for the `DeploymentDelayedTrigger`
* `Settings` now have support for storing deployment information across app restart
* added local notifications to an `AppTask`

## 0.30.3+2

* small updates to `Settings`
* fixed a bug in path to json files in `FileDataManager`
* improvement to saving task list across app re-start
* `CAMSMasterDeviceDeployment` renamed to `SmartphoneDeployment` (to allign with the other naming using `Smartphone`)
* `StudyProtocolDescription` and `StudyProtocolReponsible` renamed to `StudyDescription` and `StudyReponsible`
* fix of bug in storing app tasks in `AppTaskController`
* updates to example apps

## 0.30.1

* `DebugLevel` is now an enum
* support for persistenly storing `AppTask`s on the `AppTaskController` queue across app re-start

## 0.30.0

* upgrade to null-safety, `carp_core` v. 0.30.0
* `CAMSStudyProtocol` is no longer used and is replaced by `StudyProtocol` in `carp_core`
* fix of bug in `RandomRecurrentTriggerExecutor` (Issue [#202](https://github.com/cph-cachet/carp.sensing-flutter/issues/202))

## 0.21.6

* bug fix of [#199](https://github.com/cph-cachet/carp.sensing-flutter/issues/199)

## 0.21.5

* rename of `ProtocolOwner` to `StudyProtocolReponsible` (in order not to confuse it with `ownerId` in `StudyProtocol`)

## 0.21.4

* small bug fixes
* upgrade to `carp_core 0.21.4`

## 0.21.3

* **NOTE** - `DataEndPoint` is no longer specified as part of a `StudyProtocol`.
  * Specifying where and how to store or upload data is really not part of specifying a study protocol, but rather a deployment issues. Therefore, the `DataEndPoint` is now part of a `MasterDeviceDeployment`.
  * The `SmartphoneDeploymentService` will use the `FileDataEndpoint` per default if not specified in the deployment. Hence, data is saved as files on the phone.
  * The `StudyDeploymentController.configure()` method now takes an optional `DataEndPoint` parameter to specify the data endpoint, if it should be different to what is specified in the deployment.
  * The `StudyDeploymentController.configure()` method also takes a `askForPermissions` parameter - if `false`, then CAMS will not ask for permissions, but hands this over to the app, which can show appropiate information to the user.
* settings are now a singleton accessed using `Settings()` (similar to other singletons in the framework)
* better support for handling json functions

## 0.21.2

* update to `carp_core` v. 0.21.2

## 0.21.1

* update to `carp_core` v. 0.21.0

## 0.21.0

* update to `carp_core` v. 0.21.0 client domain model
* support for using a `SmartPhoneClientManager` for executing multiple studies
* adjusted examples and example app to use the carp_core_client domain model

## 0.20.5

* Added a `RandomRecurrentTrigger` as a new trigger type (Issue [#170](https://github.com/cph-cachet/carp.sensing-flutter/issues/170))

## 0.20.4

* removed localization support again - this has to be handled on an application level, not as part of sensing.
* removed the `ConsentSection` also - again, this is separate to sensing.

## 0.20.3

* update to `carp_core` v. 0.20.3 (json serialization)

## 0.20.0

* **BREAKING**: Now using the [`carp_core`](https://pub.dev/packages/carp_core) domain models in order to align with the overall [domain-driven design of CARP](https://carp.cachet.dk/core/).
* This has an impact on the **naming** used in the API. The most important changes are:
  * `Study` is now called `StudyProtocol` and a CAMS-specific protocol called `CAMSStudyProtocol` is available
  * `PrincipalInvestigator` is now called `ProtocolOwner`
  * `Task` is now called `TaskDescriptor`
  * `Device` is now called `DeviceDescriptor`
  * `ManualTrigger` is now called `PassiveTrigger`
  * `ScheduledTrigger` is now called `DateTimeTrigger`
  * `Measure` is now called `CAMSMeasure` (but `Measure` is part of `carp_core`)
* A `StudyProtocol` now uses the concept of a [`TriggeredTask`](https://pub.dev/documentation/carp_core/latest/carp_core/TriggeredTask-class.html) which is slightly different to the previous `Study` model. See the [example](https://pub.dev/packages/carp_core/example).
* A `CAMSStudyProtocol` now supports localization. A `StudyProtocolDescription` and a list of `ConsentSection` can be added to a protocol for each locale (i.e., language code).
* Similarly, measures now also supports localization. For each `CAMSMeasure` there is the option to specify its `MeasureDescription` for each locale.  
* All json serialization of a protocol now use `camelCase` instead of `snake_case` to be consistent with `carp_core` in Kotlin.
  * Note, however, that `DataPoint` objects are still serialized as `snake_case` json.
* All the `events` streams are now called `data` and streams `DataPoint` data objects (instead of just the `Datum` data objects).
* The `DataPoint` comply to version 1.2 definition (Issue [#162](https://github.com/cph-cachet/carp.sensing-flutter/issues/162))

## 0.12.3

* extension of `Study` to include `purpose`, `title` and `PrincipalInvestigator`

## 0.12.2

* support for canceling `UserTask`

## 0.12.1

* small refactor for `Device` model.

## 0.12.0

* feature: support for handling devices as part of a study configuration.
* refactor: rename of `Device` to `DeviceInfo`

## 0.11.1

* feature: support for storing and retrieving study json protocols on the local file system.
* refactor: the `deploymentId` has been removed from `Study` since this is CARP specific info.

## 0.11.0

* refactor: improved (de)serialization in the `Serialization` class.
* refactor: named constructors in the `Study` and `Measure` classes.
* feature: support for handling local settings on the phone in the `Settings`.
* feature: added `description` property to `Measure`.
* feature: added support for an `AppTask` can expire, i.e. be removed from the queue.
* fix: issue [#139](https://github.com/cph-cachet/carp.sensing-flutter/issues/139)
* fix: issue [#140](https://github.com/cph-cachet/carp.sensing-flutter/issues/140)

## 0.10.1

* fix: issue [#123](https://github.com/cph-cachet/carp.sensing-flutter/issues/123)
* based on issue [#134](https://github.com/cph-cachet/carp.sensing-flutter/issues/134)
  the following measures has changed
  * `periodic_accelerometer` and `periodic_gyroscope` has been added
  * the "old" `accelerometer` and `gyroscope` measures are made to run continously
  * This implies that they need to be started and stopped using a `Trigger` instead.
  * This, however, open up for triggering the collection of accelerometer data as part of an `AppTask`. For example, sampling accelerometer data while a Parkinson's patient fill in a survey.

## 0.10.0

* **BREAKING**: a new `AppTask` model is implemented
  * see documentation on the CAMS [wiki](https://github.com/cph-cachet/carp.sensing-flutter/wiki/3.1-The-AppTask-Model).
  * see the [Pulmonary app](https://github.com/cph-cachet/pulmonary_monitor_app) for an example on how to use this new model.
* fix: issue [#98](https://github.com/cph-cachet/carp.sensing-flutter/issues/98)
* fix: issue [#114](https://github.com/cph-cachet/carp.sensing-flutter/issues/114)

## 0.9.6

* fix: issue [#113](https://github.com/cph-cachet/carp.sensing-flutter/issues/113)

## 0.9.5

* feature: added the `validNextState()` method to the `Probe` class, which checks if a probe can be move to a next state.
* fix : issue [#112](https://github.com/cph-cachet/carp.sensing-flutter/issues/112)
  * this means that the `initialize()` method is no longer a `Future` (and hence cannot be awaited)

## 0.9.4+1

* fix: issue [#106](https://github.com/cph-cachet/carp.sensing-flutter/issues/106).
* fix: fix of race condition in `FileDataManager`
* fix: small error in monthly recurrence in `RecurrentScheduledTrigger`
* refactor: `Device()` is now a singleton.

## 0.9.3

* refactor: all singleton adhering to the [Dart Singleton Pattern](https://scottt2.github.io/design-patterns-in-dart/singleton/).
  * `SamplingPackageRegistry`
  * `ProbeRegistry`
  * `TransformerSchemaRegistry`
  * `DataManagerRegistry`
* fix: fixed issue [#100](https://github.com/cph-cachet/carp.sensing-flutter/issues/100)
* feature: support for the `CronScheduledTrigger` that takes a cron expression for scheduling

## 0.9.2

* fix: error in screen probe
* refactor: small pedantic formatting issues
* refactor: `TransformerSchemaRegistry` and `SamplingPackageRegistry` are now accessed using an instance singleton

## 0.9.1

* refactor: using [pedantic](https://pub.dev/packages/pedantic#using-the-lints)

## 0.9.0

* refactor: new polymorphic JSON serialization using `$type` for class type identifier.
* docs: update of documentation and examples ([#92](https://github.com/cph-cachet/carp.sensing-flutter/issues/92))

## 0.8.8

* feature: support for saving ("remembering") `RecurrentScheduledTrigger` across app shutdown ([#80](https://github.com/cph-cachet/carp.sensing-flutter/issues/80))

## 0.8.7

* feature: support for monthly recurrences in `RecurrentScheduledTrigger` ([#78](https://github.com/cph-cachet/carp.sensing-flutter/issues/78))

## 0.8.6

* update: updated to the new pedometer API

## 0.8.5

* refactor: removed the Apps package and moved this to an external package

## 0.8.2

* refactor: converted from a plugin to a package by overhauling the project

## 0.8.1

* feature: support for Deployment ID in `Study`.
* update: upgrade to `screen_state` v. 1.x
* update: upgrade to [Android Embedding v2](https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects).

## 0.8.0

* using the Dart `Duration` class in many places where duration previously was specified using miliseconds.
* added the `MarkedMeasure` class for creating measures that collect all measures since last time data was collected.
Useful for collecting things like log entries and health data.
* added the `settings` global variable providing access to:
  * [`SharedPreferences`](https://pub.dev/documentation/shared_preferences/latest/shared_preferences/SharedPreferences-class.html)
  * [`PackageInfo`](https://pub.dev/documentation/package_info/latest/package_info/PackageInfo-class.html), and
  * a method for getting a unique, persistent user id

## 0.7.2

* added support for better logging using the `DebugLevel` settings

## 0.7.1

* Added `trigger_id` to the `Trigger` class.
* Made `Task` abstract rather than deprecated.
* Fixed issue [#61](https://github.com/cph-cachet/carp.sensing-flutter/issues/61).

## 0.7.0

* **BREAKING**: this release break some parts of the previous API.
* Extended Task model -- introduction of a `AutomaticTask` and `AppTask`.
* Added support for "manually" adding data points (`Datum`) and errors to the data stream (`events`). This is part of the `StudyExecutor` API.
* The `start()` method on all executors (probes, and study, trigger & task executors) has been removed.
Now an executor is 'started' by resuming it (calling `resume()`).
* Fixed a bug in `BufferingPeriodicStreamProbe`.
* Added the `FileDatum` data type which can hold a reference to a file.
For example, an audio file (see the `carp_audio_package`).

## 0.6.5

* upgrade to `persmission_handler` v. 5.x

## 0.6.4

* Support 1.0.0 version of stable dependencies. ([dart_lsc](https://github.com/amirh/dart_lsc))

## 0.6.3

* moved the `connectivity` sampling package to an external [`carp_connectivity_package`](https://pub.dev/packages/carp_connectivity_package)
  due to [issue#46](https://github.com/cph-cachet/carp.sensing-flutter/issues/46).

## 0.6.2

* intensive test of data upload to CARP and Firebase on both Android and iOS
* support for retry in upload of data to CARP
* handling that a study id can only be an integer in the CARP web services

## 0.6.1

* Thorough testing on iOS.
* Better handling of probes not available on iOS via the `initialize` method.
* Centralized concept for handling permissions.

## 0.6.0

* Extension of `Study` domain model to include support for
 `Trigger`, which manages the temporal triggering of data sampling.
 See the [documentation](https://github.com/cph-cachet/carp.sensing-flutter/wiki/2.-Domain-Model) on how to defined a study with triggers.
* Adjustment of runtime environment to reflect the new study model
  * Addition of a `TriggerExecutor`
  * Update to `Executors`, i.e. `StudyExecutor`, `TaskExecutor` and `Probe`
* The data manager model has been updated
  * A `DataManager` now expose a stream of state `events` as defined in `DataManagerEventTypes`
  * A `DataManager` now has a `type` which is a string as defined in `DataEndPointTypes`
  * These changes are also implemented for the file and CARP data managers.
* Minor refactoring
  * Apps and AppUsage are no longer periodic measure, but one-off measures.
     Hence, use the new trigger model to sample installed apps and their usage e.g. on a daily basis.
  * The `BluetoothDatum` now lists all devices found in a scan.
  * The pedometer now works as a simple step stream which sense and report each step taken.
  * `datastore` library have been renamed to `data_managers`.

## 0.5.1

* Update of readme file.

## 0.5.0

* **BREAKING** This version has been migrated from the deprecated Android Support Library to *AndroidX*.
This should not result in any functional changes, but it requires any Android app using this plugin to also
[migrate](https://developer.android.com/jetpack/androidx/migrate) if they're using the original support library.
  * See Flutter [AndroidX compatibility](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)
* Fixed error in `PedometerProbe`

## 0.4.0

* support for data transformers
  * OMH Geolocation
  * OMH PhysicalActivity
* support for privacy schema
  * added support for hashing bluetooth names in the bluetooth package
* upgrade to json_serializable v.2

## 0.3.10

* minor change to the `StreamProbe` API - now non-static streams can be used by implementing the `get stream` method.
* update of the relevant sampling packages using `StreamProbe`

## 0.3.8+9

* update and rename of `CARPDataPoint` to `DataPoint` to reflect new CARP API.
* moved CARP web service specific data model to `CARPDataPoint` to the `carp_webservices` package.

## 0.3.5+7

* rename of `packages` folder to `sampling_packages` (seems like Dart Pub don't like folders called `packages`)
* rename of `core` folder to `domain`

## 0.3.3

* update to new versions of [CACHET Flutter Plugins](https://github.com/cph-cachet/flutter-plugins)
* rename of `probes` folder to `packages`
* upgrade and test on Flutter v. 1.3.4 Dart v. 2.2.1

## 0.3.2

* support for dividing probes into separate sampling packages
* included in `carp_mobile_sensing` are
  * `device` (device, screen, memory, battery)
  * `sensors` (sensors, light, pedometer)
  * `connectivity` (connectivity, bluetooth)
  * `apps` (installed apps, app usage)
* implementation of the following **external** probe packages:
  * `communication` (sms & call log)
  * `context` (location, activity, weather)
  * `audio` (noise, audio recording)
  * `movisens` (Movisens Move/ECG devices)

## 0.3.1

* small updates to the data format incl. documentation on the [wiki](https://github.com/cph-cachet/carp.sensing-flutter/wiki/Sampling-Data-Formats).
* fixed error in the `stop` method.

## 0.3.0 - Domain Model update

* major updates to the domain model as a `core` library
  * `Measure` now have a `configuration`
* simplification to probe implementations
* all probes now uses the Dart `Stream` API and supports a reactive programming model
* all probes adjusted to a stream model
* implementation of `SamplingSchema` architecture
* support for power-aware sampling using different sampling schemas

## 0.2.6

* fixed small bug in `weater` probe.

## 0.2.5

* small bug fixes in connectivity datum model (to work w. `carp_firebase_backend).
* `weather` probe added.

## 0.2.4

* error in `light` probe fixed.
* `noise` probe added.
* using the `carp_core` domain model

## 0.2.3

* fixed error in `readme` file.

## 0.2.2

* `phone_log` probe added
* `audio` probe added
* `activity` probe added
* improvement to `readme` file on `manifest.xml` and `Info.plist`.

## 0.2.1

* re-organization of github location and outline
* improvements to `FileDataManager` to avoid race conditions
* improved API documentation

## 0.2.0

* refactor of organization of classes into libraries
* complete API documentation

## 0.1.1

* small improvements incl. documentation

## 0.1.0

* removal of all remote backend code to separate packages

## 0.0.1

* Initial version by Jakob E. Bardram
* Transferring the old implementation to this carp.sensing-flutter framework
* General refactor and clean-up
