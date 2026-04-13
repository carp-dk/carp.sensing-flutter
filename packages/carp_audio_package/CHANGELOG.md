## 2.0.0

* upgrade to CARP Core and CAMS API level 2.0.0

## 1.10.3

* upgrading flutter_sound to 9.28.0

## 1.10.2

* downgrading flutter_sound to 9.26.0

## 1.10.1

* changing pub.dev link to main instead of master branch

## 1.10.0

* upgrading gradle version to 8.6
* upgrading compilesdkversion to 35 and agp to 8.1.0

## 1.9.0

* upgrading gradle version and file system
* upgrading flutter_sound package
* upgrading compilesdkversion, minsdkversion, targetsdkversion

## 1.8.1

* explicit data objects for `AudioMedia`, `ImageMedia`, and `VideoMedia` (instead of the generic `Media` data type)
* removing `Permission.camera` from video/image measures, since this has to be requested in the app and not by CAMS

## 1.7.1

* upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.11.0
* fix of [#431](https://github.com/cph-cachet/carp_studies_app/issues/341)

## 1.6.0

* upgrading to carp_mobile_sensing v. 1.9.0 (better permission handling)

## 1.5.0

* update to `carp_mobile_sensing` v. 1.6.0

## 1.4.0

* upgrade to Dart 3.2
* update to `carp_mobile_sensing` v. 1.4.0

## 1.3.0

* upgrade of uuid and permission_handler plugins
* update to `carp_mobile_sensing` v. 1.3.0
* upgrade to noise_meter ^5.0.0

## 1.1.0

* update to `carp_mobile_sensing` v. 1.1.0

## 0.40.0

* update to `carp_mobile_sensing` v. 0.40.0

## 0.33.0

* update to `carp_mobile_sensing` v. 0.33.0

## 0.32.3

* upgrade to `carp_mobile_sensing: ^0.32.3`

## 0.32.2+1

* added check for permission to access microphone, if not granted.
* update of README

## 0.32.1

* the package now also supports video recordings
  * added a `VideoDatum`
  * added a `VideoProbe` which does nothing (video/images comes from the app, not background sensing)
* the package is renamed to `AudioVideoSamplingPackage` (instead of `AudioSamplingPackage`)

## 0.32.0

* update to `carp_mobile_sensing` v. 0.32.0
* improved exception handling in audio probe

## 0.31.1

* small update to dependencies in pubspec
* re-generation of json serialization

## 0.31.0

* update to `carp_mobile_sensing` v. 0.31.0

## 0.30.6

* fix of `onError` bug in `noise_meter` 3.0.3.

## 0.30.5

* update to `carp_mobile_sensing: ^0.30.5`
* refactor of file structure

## 0.30.1

* update to `carp_mobile_sensing: ^0.30.1`
* fix of filename in audio probe
* fix of unit tests

## 0.30.0

* upgrade to null-safety
* using `flutter_sound: ^8.1.4` for audio recording

## 0.21.0

* update to `carp_mobile_sensing: ^0.21.0`

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

## 0.9.7

* upgrade to `noise_meter` v. 2.0.0

## 0.9.6

* using the `record_mp3` package for the `audio` measure (replacing `flutter_sound`).
* fix of issue [#118](https://github.com/cph-cachet/carp.sensing-flutter/issues/118)

## 0.9.5

* upgrade to `carp_mobile_sensing` v. 0.9.5

## 0.9.3

* upgrade: to `carp_mobile_sensing` v. 0.9.3

## 0.9.2

* upgrade: to `carp_mobile_sensing` v. 0.9.2

## 0.9.0

* upgrade: to `carp_mobile_sensing` v. 0.9.x

## 0.8.1+2

* refactor: formatting
* docs: example added

## 0.8.1

* fix: bug in noise probe

## 0.8.0

* upgrade: to `carp_mobile_sensing` v. 0.8.x

## 0.7.2

* upgrade: to `carp_mobile_sensing` v. 0.7.2
* upgrade: alignment to the new `flutter_sound` [v 5.x.x API](https://github.com/dooboolab/flutter_sound/blob/master/doc/migration_5.x.x.md#migration-form-4xx-to-5xx).

## 0.7.1

* upgrade: of packages (`flutter_sound` and `noise_meter`).

## 0.7.0

* upgrade: to `carp_mobile_sensing` v. 0.7.0

## 0.6.5

* upgrade: to `carp_mobile_sensing` v. 0.6.5

## 0.6.3

* update: to `flutter_sound` v. 3.1.x
* refactor: default location of sound files are now with the data collected.

## 0.6.2

* NoiseDatum now w. doubles.

## 0.6.1

* upgrade: alignment with `carp_mobile_sensing` v. 0.6.1.
* refactor: improvement to the audio probe based

## 0.6.0

* update to `carp_mobile_sensing` version 0.6.0
* fixed noise probe.
* note that the noise and audio probe (still) can't run at the same time.

## 0.5.0 BREAKING

* **Breaking change.** This version has been migrated from the deprecated Android Support Library to *AndroidX*.
This should not result in any functional changes, but it requires any Android app using this plugin to also
[migrate](https://developer.android.com/jetpack/androidx/migrate) if they're using the original support library.
* Use [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) version 0.5.0
* See Flutter [AndroidX compatibility](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)

## 0.3.5

* upgrade to json_serializable v.2
* fixed bug in audio recording probe (issue [#23](https://github.com/cph-cachet/carp.sensing-flutter/issues/23))

## 0.3.4

* update to `carp_mobile_sensing` version 0.3.10

## 0.3.3

* solved issue [#21](https://github.com/cph-cachet/carp.sensing-flutter/issues/21).

## 0.3.2

* Update to `carp_mobile_sensing` v. 0.3.7
* Using the data types in the package (`audio`, `noise`)
* Update of readme file.

## 0.3.1

* Documentation

## 0.3.0

* Initial release compatible with `carp_mobile_sensing` version `0.3.*`
