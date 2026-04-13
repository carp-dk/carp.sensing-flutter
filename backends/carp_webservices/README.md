# CARP Web Service Plugin for Flutter

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_webservices.svg)](https://pub.dev/packages/carp_webservices)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/NKuUwCsV)

A Flutter library to access the [CARP Web Service (CAWS)](https://carp.cachet.dk/caws/) web API.
This library is intended to be used with the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) framework, but also works on its own, if a app is to connect directly to CAWS.

For an overview of CARP and other Flutter CARP libraries, see [CARP Mobile Sensing in Flutter](https://github.com/cph-cachet/carp.sensing-flutter/blob/master/README.md).

## Setup

1. You need a CARP Web Service (CAWS) host running. See the [CARP Web Service GitHub](https://github.com/cph-cachet/carp.webservices-docker) repro and documentation for how to do this. If you're part of the [CARP](https://carp.cachet.dk/) team, you can use the specified test, staging, and production servers.

1. Add `carp_services` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

This package uses the [oidc](https://pub.dev/packages/oidc) plugin for authentication. Please follow their [getting started](https://bdaya-dev.github.io/oidc/oidc-getting-started/) guide and take a look at their [example app](https://github.com/Bdaya-Dev/oidc/tree/main/packages/oidc/example).

### Android

On Android you need to edit both the `build.gradle` file and the `AndroidManifest.xml` file plus disable some backup settings.
You also need to add an activity to the `AndroidManifest.xml` to allow for redirection to/from the web view for authentication (if you are using the `authenticate()` or `authenticateWithMagicLink` methods in the package). You manifest file would look something like this:

```xml
  ...

  <application
    android:name="${applicationName}"
    android:label="CAWS Example"
    android:icon="@mipmap/ic_launcher">

  <!-- Used by authentication redirect to/from web view -->
  <activity
    android:name="net.openid.appauth.RedirectUriReceiverActivity"
    android:theme="@style/Theme.AppCompat.NoActionBar"
    android:exported="true"
    tools:node="replace">
    <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="carp-studies-auth" android:pathPrefix="/auth" />
    </intent-filter>
    <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="http" />
      <data android:host="carp.computerome.dk" />
      <data android:pathPrefix="/auth" />
    </intent-filter>
  </activity>

  <!-- Used by authentication redirect to/from web view for anonymous users -->
  <activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true">
    <intent-filter android:label="flutter_web_auth_2">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="caws-example-app" android:pathPrefix="/" />
    </intent-filter>
  </activity>
```

### iOS

Add the following `CFBundleURLTypes` entry in your `Info.plist` file:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.my.app</string>
            <string>my-redirect-uri</string>
        </array>
    </dict>
</array>
```

Replace `com.my.app` with your application id and `my-redirect-url` with your redirect uri.

## Services

CARP Web Services (CAWS) consists of a set of sub-services, which are accessible for the client:

- [`CarpAuthService`](https://pub.dev/documentation/carp_webservices/latest/carp_auth_carp_auth/CarpAuthService-class.html) - authentication service for CAWS
- [`CarpParticipationService`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpParticipationService-class.html) - CAWS-specific implementation of the [ParticipationService](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-deployments.md#participationservice)
- [`CarpDeploymentService`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpDeploymentService-class.html) - CAWS-specific implementation of the [DeploymentService](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-deployments.md#deploymentservice)
- [`CarpDataStreamService`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpDataStreamService-class.html) - CAWS-specific implementation of the [DataStreamService](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-data.md#datastreamservice)
- [`CarpService`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpService-class.html) - resource management (folders, documents, and files) and alternative data management service

The `CarpParticipationService`, `CarpDeploymentService`, and `CarpDataStreamService` follows the [CARP Core architecture](https://github.com/cph-cachet/carp.core-kotlin?tab=readme-ov-file#architecture), and are CAWS-specific implementations of the ParticipationService, DeploymentService, and DataStreamService, respectively.
The`CarpAuthService` and `CarpService` are only part of the CAWS architecture ("non-core" endpoints).

## Configuration

All CAWS services needs to be configured before used, using the `configure` method taking a [`CarpApp`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpApp-class.html) configuration.

```dart
// The URI of the CAWS server to connect to.
final Uri uri = Uri(
  scheme: 'https',
  host: 'dev.carp.dk',
);

final CarpApp app = CarpApp(
  name: "CAWS @ DTU [DEV]",
  uri: uri,
);

// Configure the CARP Service with this app.
CarpService().configure(app);
```

The singleton can now be accessed via `CarpService()`.

Any service can be configured based on another service, like this:

```dart
CarpParticipationService().configureFrom(CarpService());
```

## Authentication Service

Authentication is done using the `CarpAuthService` singleton, which is configured using the `CarpAuthProperties` properties:

```dart
// The authentication configuration
late CarpAuthProperties authProperties = CarpAuthProperties(
  authURL: uri,
  clientId: 'my-client-id',
  redirectURI: Uri.parse('my-redirect-uri:/my-path'),
  anonymousRedirectURI: Uri.parse('my-redirect-uri:/my-anonymous-user-path'),
  // For authentication at CAWS the path is '/auth/realms/Carp'
  discoveryURL: uri.replace(pathSegments: [
    'auth',
    'realms',
    'Carp',
  ]),
);

await CarpAuthService().configure(authProperties);
```

Basic authentication is using the CAWS Keycloak login page, which the system opens when running:

```dart
CarpUser user = await CarpAuthService().authenticate();
```

This [`CarpUser`](https://pub.dev/documentation/carp_webservices/latest/carp_auth_carp_auth/CarpUser-class.html) object contains the OAuth token in the `token` (of type [`OAuthToken`](https://pub.dev/documentation/carp_webservices/latest/carp_auth_carp_auth/OAuthToken-class.html)) parameter.
Since the `CarpUser` object can be serialized to JSON, the user and the (valid) OAuth token can be stored on the phone.

The OAuth token can be refreshed by calling the `refresh()` method:

```dart
await CarpAuthService().refresh()
```

This method returns a `CarpUser`, with a new access token.

To authenticate using username and password without opening the web view, use the `authenticateWithUsernamePassword` method:

```dart
CarpUser user = await CarpAuthService().authenticateWithUsernamePassword('username', 'password');
```

To authenticate using a magic link (e.g., as read from a QR code) use the `authenticateWithMagicLink` method. This method takes the URL as a `String` parameter, authenticates the user, and generates and returns a `CarpUser` object.

```dart
CarpUser user = await CarpAuthService().authenticateWithMagicLink(qrcode);
```

To log out, just call the `logout` or `logoutNoContext` methods:

```dart
await CarpAuthService().logout()
```

## Deployments

A core notion of CARP is the [Deployment](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-deployments.md) subsystem, which has two services:

- **Participation Service** - allows retrieving participation information for study deployments, and managing data related to participants which is input by users.
- **Deployment Service** - allows for retrieving primary device deployments for participating primary devices as defined in the study protocol.

### Participation Service

Enables the client to get invitations for a specific `accountId`, i.e. a user. Default is the user who is authenticated to the CARP Service.

```dart
// We assume that we are authenticated to CAWS and that the CarpService()
// instance has been configured.

// Configure from another CAWS service
CarpParticipationService().configureFrom(CarpService());

// Get invitations for this account (user)
List<ActiveParticipationInvitation> invitations =
    await CarpParticipationService().getActiveParticipationInvitations();
```

There is also support for showing a modal UI dialog for the user to select amongst several invitations. This is done using the `getStudyInvitation` method, like this:

```dart
var invitation =
    await CarpParticipationService().getStudyInvitation(context);
```

The invitation holds information on the study deployment. So, once you (or the user) has selected an invitation, you can let the CAWS services know about the deployment by using the `setInvitation` method:

```dart
CarpParticipationService().setInvitation(invitation);
```

The participant service also handles the collection of "participant data", which are specified in the [`StudyProtocol`](https://pub.dev/documentation/carp_core/latest/protocol/StudyProtocol-class.html) (as [`expectedParticipantData`](https://pub.dev/documentation/carp_core/latest/protocol/StudyProtocol/expectedParticipantData.html)).

You can get and set participation data like this:

```dart
// Get participant data for a deployment with id [deploymentId].
final data = await CarpParticipationService().getParticipantData(deploymentId);

// Set participant data for a deployment with id [deploymentId].
// When role name is not specified, this data is set for the entire deployment.
await CarpParticipationService().setParticipantData(
  testDeploymentId,
  {
    AddressInput.type: AddressInput(
      address1: 'DTU HealthTech',
      address2: 'Technical University of Denmark',
      street: 'Ørsteds Plads',
      city: 'Kgs. Lyngby',
      postalCode: 'DK-2800',
      country: 'Denmark',
    )
  },
);
```

However, a more convenient way to handle participant data is to use a [`ParticipationReference`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/ParticipationReference-class.html), which can be obtained from the `CarpParticipationService` singleton.

```dart
ParticipationReference participation = CarpParticipationService().participation();
```

A `ParticipationReference` can now be used to set and get participant data, including the more specialized "Informed Consent" data type:

```dart
// The following example is from a family deployment with a father, mother, and child.

// Get all participant data for this deployment
ParticipantData data = await participation.getParticipantData();

// Set the address of the deployment (i.e., the family)
data = await participation.setParticipantData(
  {
    AddressInput.type: AddressInput(
      address1: 'Peder Bangs Vej 3',
      city: 'Kgs. Lyngby',
      postalCode: 'DK-2800',
      country: 'Denmark',
    )
  },
);

// Set role-specific data (sex of the father)
final data = await participation.setParticipantData(
  {SexInput.type: SexInput(value: Sex.Male)},
  father,
);

// Set the informed consent for a user (father)
await participation.setInformedConsent(
  InformedConsentInput(
    userId: 'ec44c84d-3acd-45d5-83ef-1511e0c39e48',
    name: father,
    consent: 'I agree!',
    signatureImage: 'blob',
  ),
  father,
);

// Get the informed consent for all role names in this deployment
Map<String, InformedConsentInput?> consent = await participation.getInformedConsent();

// Remove the informed consent for a user (father)
await participation.removeInformedConsent(father);
```

### Deployment Service

The Deployment Service handles "deployment" configurations, i.e. configurations that describe how data sampling in a study should take place.

The [`CarpDeploymentService`](https://pub.dev/documentation/carp_webservices/latest/carp_services/CarpDeploymentService-class.html) has methods for getting deployments and for updating deployment and device status. Here are a list of examples:

```dart
// We assume that we are authenticated to CAWS and that the CarpService()
// instance has been configured.

CarpDeploymentService().configureFrom(CarpService());

// Get the deployment status.
StudyDeploymentStatus status = await CarpDeploymentService()
    .getStudyDeploymentStatus(deploymentId);

// Register the primary device for the deployment.
await CarpDeploymentService().registerDevice(
    deploymentId,
    status.primaryDeviceStatus!.device.roleName,
    DefaultDeviceRegistration(deviceDisplayName: 'Samsung A10'));

// Get the deployment describing what data to collect.
PrimaryDeviceDeployment deployment = await CarpDeploymentService().getDeviceDeploymentFor(
  deploymentId,
  status.primaryDeviceStatus!.device.roleName,
);

// Mark the deployment as successfully deployed on this device.
await CarpDeploymentService().deviceDeployed(
  deploymentId,
  status.primaryDeviceStatus!.device.roleName,
  deployment.lastUpdatedOn,
);
```

However, instead of keeping track of deployment IDs, a more convenient way to access deployments are to use a [`DeploymentReference`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/DeploymentReference-class.html):

```dart
// We assume that we are authenticated to CAWS, that the CarpService()
// instance has been configured, and that the deployment information has
// be saved by setting the invitation (using the 'setInvitation' method).

CarpDeploymentService().configureFrom(CarpService());

// get a deployment reference to the invited deployment
final deploymentReference = CarpDeploymentService().deployment();

// get the status of this deployment
var status = await deploymentReference.getStatus();

// register a device
status = await deploymentReference.registerDevice(
    status.primaryDeviceStatus!.device.roleName,
    DefaultDeviceRegistration(deviceDisplayName: 'Samsung A10'));

// get the primary device deployment
var deployment = await deploymentReference.get();

// mark the deployment as a successfully deployed
status = await deploymentReference.deployed();
```

## Data Stream Service

Collected data is streamed back to a CARP Web Service using the [`Data`](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-data.md) subsystem.
This is done using the [`CarpDataStreamService`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpDataStreamService-class.html) like this:

```dart
// Configure a [CarpDataStreamService] from an existing CAWS service.
CarpDataStreamService().configureFrom(CarpService());

// Create a (very simple) data batch with one measurement to upload
var measurement = Measurement(
  sensorStartTime: 1642505144000000,
  data: Geolocation(
      latitude: 55.680802203873114, longitude: 12.581802212861367));

var batch = [
  DataStreamBatch(
    dataStream: DataStreamId(
        studyDeploymentId:
            CarpDataStreamService().app.studyDeploymentId ?? '',
        deviceRoleName: 'smartphone',
        dataType: Geolocation.dataType),
    firstSequenceId: 0,
    measurements: [measurement],
    triggerIds: {0}),
];

// Get a data stream and append the batch
CarpDataStreamService().stream().append(batch);
```

However, you would rarely need to use these endpoints in your app, since the [carp_backend](https://pub.dev/packages/carp_backend) would handle this when you use a [`CarpDataEndPoint`](https://pub.dev/documentation/carp_backend/latest/carp_backend/CarpDataEndPoint-class.html) as the data endpoint in the study protocol.

## CARP Web Service

The [`CarpService`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CarpService-class.html) provides access to a set of "non-core" endpoints in CAWS.
These "non-core" endpoints are:

- JSON Documents organized in Collections
- File Management
- Informed Consent Documents
- Data Points

All of these endpoints can be considered as additional "resources" which are available for up- or download from clients.

### Collections of JSON Documents

CARP Web Service supports storing JSON documents in nested collections.

A [`CollectionReference`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/CollectionReference-class.html) is used to access collections and a [`DocumentReference`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/DocumentReference-class.html) is used to access documents. Both of these can be used to:

- creating, updating, and deleting documents
- accessing documents in collections

```dart
// access a document
//  - if the document id is not specified, a new document (with a new id)
//    is created
//  - if the collection ('users') don't exist, it is created
DocumentSnapshot document = await CarpService()
    .collection('users')
    .document()
    .setData({'email': username, 'name': 'Administrator'});

// update the document
DocumentSnapshot updatedDocument = await CarpService()
    .collection('/users')
    .document(document.name)
    .updateData({'email': username, 'name': 'Super User'});

// get the document
DocumentSnapshot newDocument =
    await CarpService().collection('users').document(document.name).get();

// get the document by its unique ID
newDocument = await CarpService().documentById(document.id).get();

// delete the document
await CarpService().collection('users').document(document.name).delete();

// get all collections from a document
List<String> collections = newDocument.collections;

// get all documents in a collection.
List<DocumentSnapshot> documents =
    await CarpService().collection('users').documents;
```

### File Management

CARP Web Service supports storing raw binary file.

A [`FileStorageReference`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/FileStorageReference-class.html) is used to manage files and have methods for:

- uploading a file
- downloading a file
- getting a file object
- getting all file objects
- deleting a file

When uploading a file, you can add metadata as a `Map<String, String>`.

```dart
// first upload a file
final File uploadFile = File('test/img.jpg');
final FileUploadTask uploadTask = CarpService()
    .getFileStorageReference()
    .upload(uploadFile, {
  'content-type': 'image/jpg',
  'content-language': 'en',
  'activity': 'test'
});
CarpFileResponse response = await uploadTask.onComplete;
int id = response.id;

// then get its description back from the server
final CarpFileResponse result =
    await CarpService().getFileStorageReference(id).get();

// then download the file again
// note that a local file to download is needed
final File downloadFile = File('test/img-$id.jpg');
final FileDownloadTask downloadTask =
    CarpService().getFileStorageReference(id).download(downloadFile);
int responseCode = await downloadTask.onComplete;

// now get references to ALL files in this study
final List<CarpFileResponse> results =
    await CarpService().getFileStorageReference(id).getAll();

// finally, delete the file
responseCode = await CarpService().getFileStorageReference(id).delete();
```

### Informed Consent Document

> [!CAUTION]
> This is an old endpoint which is deprecated. Informed consent should be uploaded as a "participant data" as outlined above. However, at the moment, CAWS supports both types of informed consent (for backward compatibility reasons).

A [`ConsentDocument`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/ConsentDocument-class.html) can be uploaded and downloaded to and from CAWS.

```dart
try {
  ConsentDocument uploaded = await CarpService().createConsentDocument({
    'text': 'The original terms text.',
    'signature': 'Image Blob',
  });

  ConsentDocument downloaded =
      await CarpService().getConsentDocument(uploaded.id);
} catch (error) {
  ...;
}
```

### Data Points

> [!CAUTION]
> This is an old endpoint which is deprecated. Data should be uploaded using "data streams" as outlined above. However, at the moment, CAWS supports both types of data upload (for backward compatibility reasons).

A [`DataPointReference`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/DataPointReference-class.html) is used to manage [`DataPoint`](https://pub.dev/documentation/carp_webservices/latest/carp_services_carp_services/DataPoint-class.html) objects on a CARP Web Service, and have CRUD methods for:

- post a data point
- batch upload multiple data points
- get a data point
- delete data points

```dart
// Create a piece of data
final lightData = AmbientLight(
  maxLux: 12,
  meanLux: 23,
  minLux: 0.3,
  stdLux: 0.4,
);

// create a CARP data point
final data = DataPoint.fromData(lightData);

// post it to the CARP server, which returns the ID of the data point
int dataPointId =
    await CarpService().getDataPointReference().postDataPoint(data);

// get the data point back from the server
CARPDataPoint dataPoint =
    await CarpService().getDataPointReference().getDataPoint(dataPointId);

// batch upload a list of raw json data points in a file
final File file = File('test/batch.json');
await CarpService().getDataPointReference().batchPostDataPoint(file);

// delete the data point
await CarpService().getDataPointReference().deleteDataPoint(dataPointId);
```

## Features and bugs

Please file feature requests and bug reports at the [issue tracker][tracker].

[tracker]: https://github.com/cph-cachet/carp.sensing/issues

## License

This software is copyright (c) the [Technical University of Denmark (DTU)](https://www.dtu.dk).
This software is made available 'as-is' in a MIT [license](/LICENSE).
