## 2.0.0

* upgrade to CARP Core and CAMS API level 2.0.0

## 1.5.0

* upgrade to carp_mobile_sensing: ^1.5.0
* upgrade to carp_webservices: ^3.0.0
* upgrade to carp_backend: ^1.5.0

## 1.4.0

* upgrade to Dart 3.2
* update to `carp_mobile_sensing` v. 1.4.0
* `CommunicationSamplingPackage` added so that protocols with communication measure are now supported

## 1.3.1

* update to new authentication from carp_webservices 2.0.0
* use new style of `CarpApp`

## 1.3.0

* update to `carp_mobile_sensing` v. 1.3.0
* `dryrun` command renamed to `dry-run` (to be consistent with Dart)

## 0.40.0

* update to `carp_mobile_sensing` v. 0.40.0

## 0.33.0

* update to `carp_mobile_sensing` v. 0.33.0

## 0.32.1

* support for uploading messages to CARP

## 0.32.0

* update to `carp_mobile_sensing` v. 0.32.0

## 0.31.1

* small update to dependencies in pubspec

## 0.31.0+1

* upgrade to `carp_mobile_sensing` v. 0.31.0
* removal of `description` command, since the study description is now part of the protocol.
* update of README docs

## 0.30.5

* upgrade to `carp_mobile_sensing` v. 0.30.5
* upgrade to `carp_webservices` v. 0.30.1
* upgrade to `carp_backend` v. 0.30.5
* fix of misc bugs in json serialization

## 0.30.3+2

* upgrade to null-safety
* more robust error messages in `dryrun`
* upgrade to `carp_backend` v 0.30.3
* support for setting study descriptions
* fix of small errors

## 0.21.5

* improvement to `localization` command

## 0.21.4

* fix of error with `study_id` not being set

## 0.21.3

* [PR #192](https://github.com/cph-cachet/carp.sensing-flutter/pull/192)

## 0.21.2+2

* setting `ownerId` for the custom protocol also
* command for updating a protocol added
* `carp.yaml` renamed to `carpspec.yaml`

## 0.21.1+1

* more robust error messages in `dryrun`
* bug fixed in json initialization

## 0.21.0

* Initial release that coresponds to CAMS v. 0.21.x
