// ignore_for_file: depend_on_referenced_packages

import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:flutter/material.dart';
import 'package:research_package/model.dart';

void main() async {
  // -----------------------------------------------
  // CONFIGURING THE CAWS APP
  // -----------------------------------------------

  // Configure an app that points to the CARP web services (CAWS)
  // The URI of the CAWS server to connect to.
  final Uri uri = Uri(scheme: 'https', host: 'dev.carp.dk');

  late CarpApp app = CarpApp(name: "CAWS @ DTU", uri: uri);

  // The authentication configuration
  late CarpAuthProperties authProperties = CarpAuthProperties(
    authURL: uri,
    clientId: 'studies-app',
    redirectURI: Uri.parse('carp-studies-auth://auth'),
    // For authentication at CAWS the path is '/auth/realms/Carp'
    discoveryURL: uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
  );

  // Configure the CAWS services
  await CarpAuthService().configure(authProperties);
  CarpService().configure(app);

  // Authenticate at CAWS
  await CarpAuthService().authenticateWithUsernamePassword(
    username: 'the_username',
    password: 'the_password',
  );

  // Configure the other services needed.
  // Note that these CAWS services work as singletons and can be
  // accessed throughout the app.
  CarpParticipationService().configureFrom(CarpService());
  CarpDeploymentService().configureFrom(CarpService());

  // -----------------------------------------------
  // GETTING INVITATIONS FROM CAWS
  // -----------------------------------------------

  // Get the invitations to studies from CARP for this user.
  List<ActiveParticipationInvitation> invitations =
      await CarpParticipationService().getActiveParticipationInvitations();

  // Use the first (i.e. latest) invitation.
  final invitation = invitations[0];

  // ------------------------------------------------------------
  // CONFIGURING A CLIENT TO GET STUDY DEPLOYMENTS FROM CAWS
  // ------------------------------------------------------------

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

  // -----------------------------------------------
  // DIFFERENT WAYS TO UPLOAD DATA TO CAWS
  // -----------------------------------------------

  // First register the CAWS data manager factory
  DataManagerRegistry().register(CarpDataManagerFactory());

  // The following `CarpDataEndPoint` configurations are added to the
  // `StudyProtocol` and specifies how data is uploaded to CAWS.
  // This configuration is downloaded as part of the deployment, as shown
  // above.

  // Using the (default) data stream batch upload method.
  //
  // Using the streaming data method requires that the study deployment has
  // been obtained from CAWS. This ensures that there is a linkage between the
  // study deployment ID from the deployment and the ID in the data being
  // streamed back to CAWS.
  var streamingEndPoint = CarpDataEndPoint();

  /// Specify parameters on upload interval (in minutes), if upload only
  /// should happen when the phone is connected to WiFi, and whether data
  /// buffered locally on the phone should be deleted when uploaded.
  streamingEndPoint = CarpDataEndPoint(
    uploadInterval: 20,
    onlyUploadOnWiFi: true,
    deleteWhenUploaded: false,
  );

  // Using the "old" DataPoint endpoint for uploading batches of data points.
  var dataPointEndPoint = CarpDataEndPoint(
    uploadMethod: CarpUploadMethod.datapoint,
  );

  // var dataPointEndPoint = CarpDataEndPoint(
  //   uploadMethod: CarpUploadMethod.datapoint,
  //   name: 'CAWS Staging Server',
  //   // uri: 'http://staging.carp.cachet.dk:8080',
  //   // clientId: 'carp',
  //   // clientSecret: 'a_secret',
  //   // email: 'username@cachet.dk',
  //   // password: 'password',
  // );

  // Note that if a user is already authenticated to a CAWS server - for example
  // based on the download of invitations and deployments - specification of server
  // and authentication info is not needed in the CarpDataEndPoint.
  var endpoint = CarpDataEndPoint(uploadMethod: CarpUploadMethod.datapoint);

  // Using the file method would upload SQLite db files.
  var fileEndPoint = CarpDataEndPoint(uploadMethod: CarpUploadMethod.file);

  // // Using the file method would upload SQLite db files.
  // //
  // // Since this endpoint is normally "outside" download of invitation, you can
  // // specify the URI and auth info for upload.
  // fileEndPoint = CarpDataEndPoint(
  //   uploadMethod: CarpUploadMethod.file,
  //   name: 'CAWS Staging Server',
  //   // uri: 'http://staging.carp.cachet.dk:8080',
  //   // clientId: 'carp',
  //   // clientSecret: 'a_secret',
  //   // email: 'username@cachet.dk',
  //   // password: 'password',
  // );

  // Create a study protocol with a specific data endpoint.
  var protocol = SmartphoneStudyProtocol(
    ownerId: 'AB',
    name: 'Track patient movement',
    dataEndPoint: streamingEndPoint,
  );

  // Register CAWS as a data backend where data can be uploaded
  DataManagerRegistry().register(CarpDataManagerFactory());

  // --------------------------------------------------
  // HANDLING INFORMED CONSENT FROM CARP
  // --------------------------------------------------

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

  // --------------------------------------------------
  // HANDLING MESSAGES CARP
  // --------------------------------------------------

  // Create and initialize the message manager.
  MessageManager messageManager = CarpResourceManager();
  messageManager.initialize();

  // Create a message and upload it to CAWS.
  messageManager.setMessage(
    Message(
      id: '123',
      title: 'Great News!',
      message: 'There are great news from CARP',
      type: MessageType.news,
    ),
  );

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

  // --------------------------------------------------
  // HANDLING TRANSLATION FILES
  // --------------------------------------------------

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
}
