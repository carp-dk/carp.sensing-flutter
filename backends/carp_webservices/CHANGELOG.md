## 4.0.0

* upgrade to CARP Core and CAMS API level 2.0.0
* better exception handling
* fix of issues [#500](https://github.com/cph-cachet/carp.sensing-flutter/issues/500)

## 3.8.0

* anonymous authentication
* upgrading packages

## 3.7.0

* fix of issues [#467](https://github.com/cph-cachet/carp.sensing-flutter/issues/467)

## 3.6.2

* updating gradle file structure and fix of build errors in example app
* bumping oidc version
* upgrade to latest Flutter version

## 3.5.2

* fix of issues [#457](https://github.com/cph-cachet/carp.sensing-flutter/issues/457)

## 3.5.1

* upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.10.0
* replacing study ID information from the `CarpApp` to instead allow any service to have info on which `SmartphoneStudy` it is handling.
* misc. updates to tests and docs
* better handling of NGINX error messages

## 3.3.1

* support for uploading compressed data to the CAWS data stream endpoint
* support for uploading participant data (like full name, informed consent, etc.)
* informed consent is now uploaded as an participant data type to CAWS (the old Informed Consent endpoint is deprecated)
* the old DataPoint data upload endpoint is marked as deprecated.

## 3.2.0

* upgrade of carp_serialization and carp_core
* fix of issues [#392](https://github.com/cph-cachet/carp.sensing-flutter/issues/392) and [#369](https://github.com/cph-cachet/carp.sensing-flutter/issues/369).

## 3.0.1

* refactor of authentication API based on the [`oidc`](https://pub.dev/packages/oidc) package. See [PR #374](https://github.com/cph-cachet/carp.sensing-flutter/pull/374) for details.
* added linter

## 2.0.1

* support for client secret for a CARP app for authentication.

## 2.0.0

Completely revamped authentication service to use an Identity Server, using the `flutter_appauth` library.

* Deprecated unused endpoints
* Refactored existing endpoints to use an Identity Server and native OS APIs for authentication.
* Added new endpoints to accommodate all use-cases
* API docs and README updated

## 1.3.0

* upgrade of uuid plugins
* update to `carp_mobile_sensing` v. 1.3.0

## 1.1.1

* upgrade UUID package to 4.0.0

## 1.1.0

* update to `carp_mobile_sensing` v. 1.1.0
* added support for the CARP Core [Data](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-data.md) subsystem
* moved support for handling `DataPoint` data from carp_core to carp_webservices (since this is specific to CAWS and not part of the CARP Core domain model)

## 0.40.1

* update to `carp_core` v. 0.40.1

## 0.40.0

* update to `carp_mobile_sensing` v. 0.40.0

## 0.32.0

* update to `carp_mobile_sensing` v. 0.33.0

## 0.32.4

* added support for counting data points

## 0.32.3

* fix: issue [#239](https://github.com/cph-cachet/carp.sensing-flutter/issues/239 )
* improvement to unit tests

## 0.32.2

* small improvement to login dialog - issue [#236](https://github.com/cph-cachet/carp.sensing-flutter/issues/236)

## 0.32.1

* small update to `HTTPStatus`
* improvement to unit tests

## 0.32.0

* update to `carp_mobile_sensing` v. 0.32.0

## 0.31.1

* support for stopping (permanently) a study deployment.

## 0.31.0

* upgrade to `carp_mobile_sensing` v. 0.31.0

## 0.30.1

* fix of bug in `DocumentReference.updateData()` method.
* Dialog windows for authentication and selection of study invitation can now be made "modal" (i.e., not closable by the user).
* support for "Reset Password" in the authentication dialog.
* fix of bug in `add` and `addVersion` endpoints in `CANSProtocolService`
* fix of [issue #213](https://github.com/cph-cachet/carp.sensing-flutter/issues/213)

## 0.30.0

* upgrade to null-safety and `carp_mobile_sensing` v. 0.30.0
* adjustment of `CarpFileResponse` to reflect new JSON format from server.

## 0.21.5

* upgrade to `carp_mobile_sensing` v. 0.21.5
* small updates to unit tests

## 0.21.4

* upgrade to `carp_mobile_sensing` v. 0.21.4

## 0.21.2

* Rename of all `CARP...` services to `Carp..`
* Clean-up in `CarpDeploymentService`
* Added the `CarpParticipationService` and `ParticipationReference` to support the participation CARP endpoint

## 0.21.1

* upgrade to `carp_mobile_sensing` v. 0.21.x
* small bug in `DocumentReference.get()` fixed

## 0.20.1

* support for more file endpoints
  * `getAllFiles()` - getting all files in a study
  * `queryFiles()` - query for specific files in a study
* fixed a bug in token refresh

## 0.20.0

* **BREAKING**: Now using the [`carp_core`](https://pub.dev/packages/carp_core) domain models in order to align with the overall [domain-driven design of CARP](https://carp.cachet.dk/core/)
* upgrade to `carp_mobile_sensing` v. 0.20.x
* implements the `CANSDeploymentService()` singleton for accessing the CANS deployment service

## 0.13.2+1

* fix of small render error in invitation dialog on iOS
* code cleanup

## 0.13.1

* error message to authentication dialog
* `AuthEvent` events extended with a `failed` event on authentication failure

## 0.13.0

* update to CARP core version 28

## 0.12.0

* updated to carp_mobile_sensing v. 0.12.x

## 0.11.3

* update of `CarpApp` to handle study ID from the server (as opposed to from a local `Study` configuration)
* refactor of the `getStudyInvitation` method

## 0.11.2

* updated to carp_mobile_sensing v. 0.11.1
* support for getting a list of deployment invitation using a modal dialog (UI).
* misc refactor and optimization of API

## 0.11.1

* the singleton CarpService is accessed using `CarpService()` (instead of the old `CarpService.instance`)
  in order to be consist with the rest of CAMS.
* support for authentication using a modal dialog (UI).
* support for sending 'forgotten password' emails using the `sendForgottenPasswordEmail()` method.

## 0.11.0

* updated to carp_mobile_sensing v. 0.11.x

## 0.10.0

* updated to carp_mobile_sensing v. 0.10.x
* alligning version number

## 0.5.2

* feature: support for `changePassword()`
* fix: password is no longer stored as part of `carp_webservices` neither in memory or serialized to json.
* refactor: removal of old deprecated methods for inviting participants and researchers.

## 0.5.1

* feature: support for deployment endpoints using the `DeploymentReference` class

## 0.5.0

* **BREAKING**: Updated to CAMS v. 0.9.0 with new `$type` json serialization
* fix: OAuth token in `CarpUser` is now serialized ([#96](https://github.com/cph-cachet/carp.sensing-flutter/issues/96))
* fix: fixed an error in the refresh token method.

## 0.4.6

* feature: better support for authentication with stored tokens ([#79](https://github.com/cph-cachet/carp.sensing-flutter/issues/79)).
* feature: `CarpUser` can be serialized to JSON.

## 0.4.5

* refactor: separation of Study ID and Deployment ID when calling CARP endpoints
* refactor: better error handling and messages
* test: unit test for uploading file fails, but seems to be a server-side issue

## 0.4.4

* feature: data point and informed consent endpoint changed to use `deployments` in URL.
* refactor: aligned the collection/documents to the new CANS endpoints

## 0.4.3

* refactor: `study_id` is now a String (not an int anymore).
* fix: fixed [#66](https://github.com/cph-cachet/carp.sensing-flutter/issues/66).

## 0.4.2

* update: updated to carp_mobile_sensing v. 0.8.x

## 0.4.1

* feature: upload of files to CANS implemented.
* feature: support for serializing the OAuth token to JSON.

## 0.4.0

* **Breaking** Update to the new CANS API and data model.

## 0.3.3

* improvement on retry in offline mode
* testing w. iOS
* aligned with `carp_mobile_sensing` version 0.6.2

## 0.3.2

* support for retry in all RESTfull calls, incl. upload of JSON data files.

## 0.3.1

* fixed a bug in the get all files method

## 0.3.0

* update to `carp_mobile_sensing` v.0.6.0
* json serialization 3.0.0

## 0.2.8+3

* fixed bug in token refresh.

## 0.2.8

* query interface for documents
* add participant to study by invite
* add researcher to study by invite
* changed create user to reflect the name of the backend endpoint

## 0.2.7

* update of GET user endpoint

## 0.2.6

* rename of collection is now supported
* refresh token
* get user profile incl. name
* create user from email and password
* upload and get of informed consent documents as a `ConsentDocument`
* `DocumentSnapshot` now handles timestamps as real `DateTime`

## 0.2.5

* support for rename, update, and delete of documents and collections
  * _note_ than rename of a collection don't happen in the CARP web service at the time of this release
* support for query of DataPoints

## 0.2.4

* dependent on `carp_mobile_sensing` library to version 0.5.0
* support for authenticate with (locally saved) token

## 0.2.3

* refresh of auth token when expired

## 0.2.2

* upgrade to json_serializable v.2

## 0.2.1

* support for get document by id

## 0.2.0

* upgrade and test on Flutter v. 1.3.4 Dart v. 2.2.1
* upgrading to the new CARP Web Service API for documents (instead of objects) and collections

## 0.1.3

* Adjustment to refactoring of `carp_mobile_sensing` library to version 0.3.0

## 0.1.2

* Small refactor and removal of debug print.
* Adding an example
* Added support for batch upload of data points as a file.

## 0.1.1

* Documentation update.

## 0.1.0

* Initial release.
