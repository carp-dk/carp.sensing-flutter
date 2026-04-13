# CARP Data Backend

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_context_package.svg)](https://pub.dev/packages/carp_backend)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

This package integrates the [CARP Mobile Sensing](https://carp.dk/cams/) Framework with the [CARP Web Services (CAWS)](https://carp.dk/caws/) backend.

For an overview of all CAMS packages, see [CARP Mobile Sensing in Flutter](https://github.com/carp-dk/carp.sensing-flutter).
For documentation on how to use CAMS, see the [CAMS documentation](https://docs.carp.dk/carp-mobile-sensing/).

This library supports:

* downloading a **study invitation**
* download a **study deployment**
* getting and uploading **resources**
  * informed consent document
  * translation files
  * messages
* uploading collected **data**

from/to a CAWS server.

> [!NOTE]
> This package does nothing on its own and is only to be used as part of the overall [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing) ecosystem. See the [CAMS documentation](https://docs.carp.dk/carp-mobile-sensing/) on how to use CAMS, and checkout the [CARP Mobile Sening Demo App](https://github.com/cph-cachet/carp.sensing-flutter/tree/master/apps/carp_mobile_sensing_app) for a full example of an app using CARP Mobile Sensing and CAWS, including this library.

## Using the Plugin

Add `carp_backend` as a [dependency in your pubspec.yaml](https://flutter.io/platform-plugins/) file and import the library along with the other CAMS libraries.

```dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_backend/carp_backend.dart';
```

## Configuration

This library uses the [`carp_webservices`](https://pub.dev/packages/carp_webservices) API for accessing CAWS. In order to access CAWS, a [`CarpApp`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpApp-class.html) needs to be configured like this:

```dart
  // Configure an app that points to the CARP web services (CAWS)
  final Uri uri = Uri(
    scheme: 'https',
    host: 'dev.carp.dk',
  );

  late CarpApp app = CarpApp(
    name: "CAWS @ DTU",
    uri: uri,
    studyId: '<the_study_id_if_known>',
    studyDeploymentId: '<the_study_deployment_id_if_known>',
  );

  // The authentication configuration
  late CarpAuthProperties authProperties = CarpAuthProperties(
    authURL: uri,
    clientId: 'studies-app',
    redirectURI: Uri.parse('carp-studies-auth://auth'),
    // For authentication at CAWS the path is '/auth/realms/Carp'
    discoveryURL: uri.replace(pathSegments: [
      'auth',
      'realms',
      'Carp',
    ]),
  );

  // Configure the CAWS services
  await CarpAuthService().configure(authProperties);
  CarpService().configure(app);

  // Authenticate at CAWS using username and password
  await CarpAuthService().authenticateWithUsernamePassword(
    username: 'the_username',
    password: 'the_password',
  );

// Configure the other services needed.
// Note that these CAWS services work as singletons and can be
// accessed throughout the app.
CarpParticipationService().configureFrom(CarpService());
CarpDeploymentService().configureFrom(CarpService());
```

## Downloading a Study Invitation and Deployment from CAWS

Getting a study invitation and deployment from CAWS is done using the `CarpParticipationService` and `CarpDeploymentService` services, respectively.

```dart
// Get the invitations to studies for this user.
List<ActiveParticipationInvitation> invitations =
    await CarpParticipationService().getActiveParticipationInvitations();

// Use the first (i.e. latest) invitation.
final invitation = invitations[0];
```

The invitation contains information about the deployment, including the `studyDeploymentId` and the device `roleName`. This invitation is used to configure a study, which can be deployed and started in a [`SmartPhoneClientManager`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SmartPhoneClientManager-class.html).

```dart
// Create and configure a client manager for this phone.
// If no deployment service is specified in the configure method,
// the default CarpDeploymentService() singleton is used.
final client = SmartPhoneClientManager();
await client.configure();

// Define the study based on the invitation and add it to the client.
final study = SmartphoneStudy.fromInvitation(invitation);
await client.addStudy(study);

// Deploy the study.
await SmartPhoneClientManager().tryDeployment(
  study.studyDeploymentId,
  study.deviceRoleName,
);

// Resume sampling.
SmartPhoneClientManager().resume();
```

## Getting and Uploading Resources

CAWS handles three types of special-purpose resources:

* The informed consent document to be shown to the user
* A set of messages and news items to be show to the user
* Translation files that can help translate the text used in a study deployment protocol (like the text is a user survey)

Each of the are handled by an [InformedConsentManager](https://pub.dev/documentation/carp_backend/latest/carp_backend/InformedConsentManager-class.html), [MessageManager](https://pub.dev/documentation/carp_backend/latest/carp_backend/MessageManager-class.html), and [LocalizationManager](https://pub.dev/documentation/carp_backend/latest/carp_backend/LocalizationManager-class.html), respectively. All of these managers are implemented in the [CarpResourceManager](https://pub.dev/documentation/carp_backend/latest/carp_backend/CarpResourceManager-class.html) manager.

### Informed Consent Documents

Here is an example of uploading and downloading an informed consent document to be shown to the user (via the [Research Package](https://pub.dev/packages/research_package)):

```dart
// Create and initialize the informed consent manager.
//
// The CarpResourceManager() is a singleton that uses the
// the CarpService() singleton for accessing CAWS. Hence,
// CarpService needs to be authenticated and initialized before
// using the CarpResourceManager.
InformedConsentManager icManager = CarpResourceManager();
icManager.initialize();

// Create a simple informed consent...
final consent = RPOrderedTask(
  identifier: '12',
  steps: [
    RPInstructionStep(identifier: "1", title: "Welcome!")
      ..text = "Welcome to this study! ",
    RPCompletionStep(
      identifier: "2",
      title: "Thank You!",
      text: "We saved your consent document.",
    ),
  ],
);
// .. and upload it to CAWS.
await icManager.setConsentDocument(consent);

// Get the informed consent back as a RPOrderedTask, if available.
RPOrderedTask? myConsent = await icManager.getConsentDocument();
```

Note that we distinguish between a **"consent document"** and the **"informed consent"**.
A consent document is typically created and uploaded once for a study. Then later, all participants (i.e., deployments) can access this informed consent document via the `getConsentDocument` method, and show it to the user for signature.
Once the consent document is signed by the user, it can be stored as an [InformedConsentInput](https://pub.dev/documentation/carp_core/latest/common/InformedConsentInput-class.html) and then be uploaded to CAWS using the [`setInformedConsent`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/ParticipationReference/setInformedConsent.html) method on a [`ParticipationReference`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/ParticipationReference-class.html).

### Messages

Below are examples of how messages can be uploaded and retrieved from CAWS:

```dart
// Create and initialize the message manager.
MessageManager messageManager = CarpResourceManager();
messageManager.initialize();

// Create a message and upload it to CAWS.
messageManager.setMessage(Message(
  id: '123',
  title: 'Great News!',
  message: 'There are great news from CARP',
  type: MessageType.news,
));

// Get all messages from CAWS.
messageManager.getMessages().then((messages) {
  print('Messages: $messages');
});

// Get a specific message from CAWS.
messageManager.getMessage('123').then((message) {
  print('Message: $message');
});

// Delete a specific message from CAWS.
messageManager.deleteMessage('123').then((_) {
  print('Message deleted...');
});
```

### Translations Files

Translations files can be up- and downloaded like this:

```dart
// Create and initialize the message manager.
LocalizationManager localizationManager = CarpResourceManager();
localizationManager.initialize();

// A Danish locale
var locale = Locale('da');

// Create a translation file for Danish and upload it to CAWS.
localizationManager.setLocalizations(locale, {
  'morning': 'morgen',
  'midday': 'middag',
  'evening': 'aften',
});

// Get translation file for Danish
if (localizationManager.isSupported(locale)) {
  localizationManager.getLocalizations(locale);
}
```

> [!NOTE]
> Using translations in an app is a whole separate topic, which is supported by the [Research Package](https://pub.dev/packages/research_package) and described in this tutorial on [Localization Support in Research Package](https://carp.dk/localization/). An example of using localization downloaded from CAWS can be found in the [CARP Studies App](https://github.com/cph-cachet/carp_studies_app). In the `carp_study_app.dart` file a [RPLocalizationsDelegate](https://pub.dev/documentation/research_package/latest/ui/RPLocalizationsDelegate-class.html) is used, which again used a [ResourceLocalizationLoader](https://github.com/cph-cachet/carp_studies_app/blob/master/lib/data/localization_loader.dart) to load the translations from CAWS.

## Uploading of Data to CARP

Configuration of data upload is done as a [`DataEndPoint`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/DataEndPoint-class.html), which is part of a [`SmartphoneStudyProtocol`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/SmartphoneStudyProtocol-class.html).

CAWS and hence this plugin supports three methods of data upload:

* The (default) data stream upload using the [CARP Core Data subsystem](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-data.md)
* The (legacy) [`DataPoint`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/DataPoint-class.html) upload
* File upload of raw SQLite `.db` files

### Specifying a CARP Data Endpoint

Create a `CarpDataEndPoint` that specify which method to use for uploading data, and the details. For example, a streaming data upload is created like this:

```dart
// Using the (default) data stream batch upload method
var streamingEndPoint = CarpDataEndPoint();
```

Upload methods are defined in the `uploadMethod` property. A data point upload method is created like this:

```dart
// Using the "legacy" DataPoint endpoint for uploading batches of data points.
var dataPointEndPoint =
    CarpDataEndPoint(uploadMethod: CarpUploadMethod.datapoint);
```

Similarly, an endpoint uploading the raw SQLite db files can be specified:

```dart
// Using the file method would upload SQLite db files.
var fileEndPoint = CarpDataEndPoint(uploadMethod: CarpUploadMethod.file);
```

There are some details in how the three different types of endpoints work:

* **Streaming** - Using the streaming data method requires that the study deployment has been obtained from CAWS via an invitation, as shown above. This ensures that there is a linkage between the study deployment ID from the deployment and the ID in the data being streamed back to CAWS.

* **Data Point** & **File** - The data point and file endpoints need the study ID and study deployment ID. This can be obtained via the invitation (as above), but it can also be specified when creating the `CarpApp` configuration. Hence, the data point and file endpoints can be used if these IDs are known, e.g., are static to the app.

For all three upload types (stream, data point, and file), additional parameters can be specified for a an endpoint.

```dart
/// Specify parameters on upload interval (in minutes), if upload only
/// should happen when the phone is connected to WiFi, and whether data
/// buffered locally on the phone should be deleted when uploaded.
streamingEndPoint = CarpDataEndPoint(
  uploadInterval: 20,
  onlyUploadOnWiFi: true,
  deleteWhenUploaded: false,
);
```

### Adding a Data Endpoint to the Study Protocol

To use the data endpoint, add it to the study protocol like this:

```dart
// Create a study protocol with a specific data endpoint.
SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
  ownerId: 'AB',
  name: 'Track patient movement',
  dataEndPoint: streamingEndPoint,
);
```

### Register the Data Manager

In order to use the CAWS data manger for uploading of data, you should register its factory in the [`DataManagerRegistry`](https://pub.dev/documentation/carp_mobile_sensing/latest/domain/DataManagerRegistry-class.html).

````dart
// Register CAWS as a data backend where data can be uploaded.
DataManagerRegistry().register(CarpDataManagerFactory());
````

## Features and bugs

Please file feature requests and bug reports at the [issue tracker][tracker]. Remember to specify which CARP library you're filing an issue for (in this case `carp_backend`).

## License

This software is copyright (c) the [Technical University of Denmark (DTU)](https://www.dtu.dk).
This software is made available 'as-is' in a MIT [license](/LICENSE).

<!-- LINKS  -->

[tracker]: https://github.com/cph-cachet/carp.sensing/issues
