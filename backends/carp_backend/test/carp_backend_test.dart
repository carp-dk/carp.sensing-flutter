import 'dart:io';
import 'dart:convert';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';
// import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_backend/carp_backend.dart';
import 'package:research_package/research_package.dart';

// import the context, eSense & audio sampling package
// this is used to be able to deserialize the downloaded protocol
// in the 'get study protocol' test
//
// import 'package:carp_esense_package/esense.dart';
// import 'package:carp_audio_package/audio.dart';
// import 'package:carp_context_package/context.dart';

import 'credentials.dart';

String _encode(Object? object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  SharedPreferences.setMockInitialValues({});
  WidgetsFlutterBinding.ensureInitialized();

  // Initialization of serialization
  CarpMobileSensing.ensureInitialized();
  ResearchPackage.ensureInitialized();

  // register the context, eSense & audio sampling package
  // this is used to be able to deserialize the downloaded protocol
  // in the 'get study protocol' test
  // SamplingPackageRegistry().register(ContextSamplingPackage());
  // SamplingPackageRegistry().register(ESenseSamplingPackage());
  // SamplingPackageRegistry().register(AudioSamplingPackage());

  /// Setup CARP and authenticate.
  /// Runs once before all tests.
  setUpAll(() async {
    Settings().debugLevel = DebugLevel.debug;
    StudyProtocol(ownerId: 'user@dtu.dk', name: 'ignored');

    // Configure an app that points to the CARP web services (DEV)
    final Uri uri = Uri(scheme: 'https', host: hostName);

    late CarpApp app = CarpApp(
      name: "CAWS @ DTU",
      uri: uri.replace(pathSegments: []),
    );

    // The authentication configuration
    late CarpAuthProperties authProperties = CarpAuthProperties(
      authURL: uri,
      clientId: 'studies-app',
      redirectURI: Uri.parse('carp-studies-auth://auth'),
      // For authentication at CAWS the path is '/auth/realms/Carp'
      discoveryURL: uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
    );

    // Configure the service with the same study we will use for all testing
    var study = SmartphoneStudy(
      studyId: testStudyId,
      studyDeploymentId: testDeploymentId,
      deviceRoleName: testDeviceRoleName,
    );

    // Configure the CAWS services
    await CarpAuthService().configure(authProperties);
    CarpService().configure(app, study);

    // create a carp data manager in order to initialize json serialization
    CarpDataManager();

    await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );

    // configure the other services needed
    CarpParticipationService().configureFrom(CarpService());
    CarpDeploymentService().configureFrom(CarpService());
  });

  tearDownAll(() {
    CarpAuthService().logoutNoContext();
  });

  group('Base Services', () {
    test('- authentication w. username and password', () async {
      CarpUser user = await CarpAuthService().authenticateWithUsernamePassword(
        username: username,
        password: password,
      );

      expect(user.token, isNotNull);
      expect(user.isAuthenticated, true);

      print("User  : $user");
      // print("Token : ${user.token}");
    });
  });

  group("Informed Consent", () {
    test('- get', () async {
      RPOrderedTask? informedConsent = await CarpResourceManager()
          .getConsentDocument(refresh: true);

      print(_encode(informedConsent));
    });

    test('- set', () async {
      RPOrderedTask anotherInformedConsent = RPOrderedTask(
        identifier: '12',
        steps: [
          RPInstructionStep(
            identifier: "1",
            title: "Welcome!",
            text: "Welcome to this study!",
          ),
          RPCompletionStep(
            identifier: "2",
            title: "Thank You!",
            text: "We saved your consent document - VIII",
          ),
        ],
      );

      bool success = await CarpResourceManager().setConsentDocument(
        anotherInformedConsent,
      );
      print('updated: $success');
      RPOrderedTask? informedConsent = await CarpResourceManager()
          .getConsentDocument(refresh: true);

      print(_encode(informedConsent));
    });

    test('- delete', () async {
      bool success = await CarpResourceManager().deleteConsentDocument();
      print('deleted: $success');
    });
  });

  group("Localizations", () {
    Locale locale = const Locale('en');

    test('- get', () async {
      Map<String, String>? localizations = await CarpResourceManager()
          .getLocalizations(locale, refresh: true, cache: false);

      print(_encode(localizations));
    });

    test('- set', () async {
      Map<String, String> daLocalizations = {'Hi': 'Hej', 'Bye': 'Farvel'};

      bool success = await CarpResourceManager().setLocalizations(
        locale,
        daLocalizations,
      );
      print('updated: $success');

      Map<String, String>? localizations = await CarpResourceManager()
          .getLocalizations(locale);
      expect(localizations, localizations);
      print(_encode(localizations));
    });

    test('- delete', () async {
      bool success = await CarpResourceManager().deleteLocalizations(locale);
      print('deleted: $success');
    });
  });

  group("Messages", () {
    Message getMessage([String? id]) => Message(
      id: id,
      type: MessageType.article,
      title: 'The importance of healthy eating',
      subTitle: '',
      message:
          'A healthy diet is essential for good health and nutrition. '
          'It protects you against many chronic noncommunicable diseases, such as heart disease, diabetes and cancer. '
          'Eating a variety of foods and consuming less salt, sugars and saturated and industrially-produced trans-fats, are essential for healthy diet.\n\n'
          'A healthy diet comprises a combination of different foods. These include:\n\n'
          ' - Staples like cereals (wheat, barley, rye, maize or rice) or starchy tubers or roots (potato, yam, taro or cassava).\n'
          ' - Legumes (lentils and beans).\n'
          ' - Fruit and vegetables.\n'
          ' - Foods from animal sources (meat, fish, eggs and milk).\n\n'
          'Here is some useful information, based on WHO recommendations, to follow a healthy diet, and the benefits of doing so.',
      url: 'https://www.who.int/initiatives/behealthy/healthy-diet',
    );

    test('- create', () async {
      Message message = getMessage('1');
      print(_encode(message));
    });

    test('- set', () async {
      Message message = getMessage();
      await CarpResourceManager().setMessage(message);
      print('Message uploaded: $message');

      List<Message> messages = await CarpResourceManager().getMessages();
      expect(messages.length, greaterThanOrEqualTo(1));
      print(_encode(messages));
    });

    test('- create & get', () async {
      Message message_1 = getMessage();
      print(_encode(message_1));
      await CarpResourceManager().setMessage(message_1);
      Message? message_2 = await CarpResourceManager().getMessage(message_1.id);
      print(_encode(message_2));
      expect(message_2, isNotNull);
      expect(message_2!.id, message_1.id);
    });

    test('- get specific', () async {
      final message = await CarpResourceManager().getMessage(
        'fc8539f0-2eb2-11ee-b8d3-af65eeff3f6f',
      );
      print(_encode(message));
      expect(message, isNotNull);
      // expect(message_2!.id, message_1.id);
    });

    test('- get all', () async {
      List<Message> messages = await CarpResourceManager().getMessages();
      print(_encode(messages));
    });

    test('- delete', () async {
      Message message = getMessage();
      await CarpResourceManager().setMessage(message);
      print('Message uploaded: $message');
      await CarpResourceManager().deleteMessage(message.id);
      print('Message ${message.id} deleted...');
    });

    test('- delete all', () async {
      await CarpResourceManager().deleteAllMessages();
    });
  }, skip: true);

  group("Documents & Collections", () {
    test('- get by id', () async {
      final doc = await CarpService().documentById(102).get();
      print(toJsonString(doc?.data));
    });

    test('- get by collection', () async {
      final ref = await CarpService().collection('localizations').get();
      print((ref));
    });

    test(' - get document by path', () async {
      final doc = await CarpService().document('localizations/da').get();
      print((doc));
    });

    // NOTE - you must be authenticated as a researcher to get all documents
    test(' - get all documents', () async {
      List<DocumentSnapshot> documents = await CarpService().documents();

      print('Found ${documents.length} document(s)');
      for (var document in documents) {
        print(' - $document');
      }
    });

    test(' - delete old document', () async {
      DocumentReference doc = CarpService().documentById(167);
      doc.delete();
    });
  });

  group("Files", () {
    test('- upload mp4', () async {
      final File myFile = File("test/files/1730232460529.mp4");

      final uploadTask = CarpService().getFileStorageReference().upload(
        myFile,
        {
          'content-type': 'audio/mpeg',
          'content-language': 'en',
          'activity': 'test',
        },
      );

      final response = await uploadTask.onComplete;
      expect(response.id, greaterThan(0));
      debugPrint(toJsonString(response.map));
    });

    test('- upload jpg', () async {
      final File myFile = File("test/files/CAP7858089012525879504.jpg");

      final uploadTask = CarpService().getFileStorageReference().upload(
        myFile,
        {
          'content-type': 'image/jpg',
          'content-language': 'en',
          'activity': 'test',
        },
      );

      final response = await uploadTask.onComplete;
      expect(response.id, greaterThan(0));
      debugPrint(toJsonString(response.map));
    });

    test('- get by id', () async {
      var id = 66;

      final result = await CarpService().getFileStorageReference(id).get();
      expect(result.id, id);
      debugPrint(toJsonString(result.map));
    });
  });
}
