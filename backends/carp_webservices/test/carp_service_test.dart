import 'dart:convert';
import 'dart:io';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_carp_properties.dart';
import '_credentials.dart';

String _encode(Object? object) => const JsonEncoder.withIndent(' ').convert(object);

void main() {
  SharedPreferences.setMockInitialValues({});
  const String userId = "jakob@bardram.net";
  const String studyId = "test_1234";
  const String collectionName = 'test_patients';
  const String newCollectionName = 'new_patients';

  /// Setup CAWS and authenticate.
  /// Runs once before all tests.
  setUpAll(() async {
    Settings().debugLevel = DebugLevel.debug;

    await CarpAuthService().configure(CarpProperties().authProperties);

    // configure the service with both an app and a study, using the same
    // test study for all tests
    CarpService().configure(CarpProperties().app, CarpProperties().study);
    CarpParticipationService().configureFrom(CarpService());

    await CarpAuthService().authenticateWithUsernamePassword(username: username, password: password);
  });

  /// Close connection to CARP.
  /// Runs once after all tests.
  tearDownAll(() {
    CarpAuthService().logoutNoContext();
  });

  group("CARP Services", () {
    group('Informed Consent', () {
      test('- create', () async {
        ConsentDocument uploaded = await CarpService().createConsentDocument({
          "text": "The original terms text.",
          "signature": "Image Blob",
        });

        debugPrint('$uploaded');
        debugPrint('id        : ${uploaded.id}');
        debugPrint('createdAt : ${uploaded.createdAt}');
        debugPrint('createdBy : ${uploaded.createdBy}');
        debugPrint('document  : ${uploaded.document}');
      });

      test('- get', () async {
        // ConsentDocument uploaded = await CarpService().createConsentDocument(
        //     {"text": "The original terms text.", "signature": "Image Blob"});

        // debugPrint(uploaded);
        // expect(uploaded.id, isNotNull);

        ConsentDocument downloaded = await CarpService().getConsentDocument(1);
        // await CarpService().getConsentDocument(uploaded.id);

        debugPrint('$downloaded');
        debugPrint('id        : ${downloaded.id}');
        debugPrint('createdAt : ${downloaded.createdAt}');
        debugPrint('createdBy : ${downloaded.createdBy}');
        debugPrint('document  : ${downloaded.document}');
      });
    });

    group("Documents & Collections - PARTICIPANT", () {
      /// Run this test before any other tests in this group to ensure a clean state.
      test(' - clean up old test documents', () async {
        await CarpService()
            .collection(collectionName)
            .document(userId)
            .collection('activities')
            .document('cooking')
            .delete();

        await CarpService().collection(collectionName).document(userId).delete();
      });

      test(' - CRUD document', () async {
        // first create a document
        var document = await CarpService().collection(collectionName).document(userId).setData({
          'email': userId,
          'role': 'Administrator',
        });

        expect(document, isNotNull);

        // create a document reference
        final reference = CarpService().collection(collectionName).document(userId);

        // get it back from the server
        final original = await reference.get();
        debugPrint(_encode(original?.data));

        // updating the role to super user
        final updated = await reference.updateData({'email': userId, 'role': 'Super User'});

        debugPrint('----------- updated -------------');
        debugPrint('$updated');
        debugPrint(_encode(updated.data));
        debugPrint('${updated.data["role"]}');
        expect(updated.id, greaterThan(0));
        expect(updated.data["role"], 'Super User');

        // delete document again
        await CarpService().collection(collectionName).document(userId).delete();
      });

      test(' - get document by id', () async {
        // first create a document
        var document = await CarpService().collection(collectionName).document(userId).setData({
          'email': userId,
          'role': 'Administrator',
        });

        debugPrint('$document');
        expect(document, isNotNull);

        // then get it back by the id
        var newDocument = await CarpService().documentById(document.id).get();

        debugPrint('$newDocument');
        expect(newDocument, isNotNull);
        expect(newDocument?.id, document.id);

        // delete document again
        await CarpService().collection(collectionName).document(userId).delete();
      });

      test(' - get document by path', () async {
        var document = await CarpService().collection(collectionName).document(userId).setData({
          'email': userId,
          'role': 'Administrator',
        });

        expect(document, isNotNull);

        DocumentSnapshot? newDocument = await CarpService().collection(collectionName).document(document.name).get();

        debugPrint('$newDocument');
        expect(newDocument?.id, document.id);

        // delete document again
        await CarpService().collection(collectionName).document(userId).delete();
      });

      test(' - get non-existing document', () async {
        DocumentSnapshot? newDocument = await CarpService().collection(collectionName).document('not_available').get();

        expect(newDocument, isNull);
      });

      //     test(' - rename document', () async {
      //       assert(document != null);

      //       debugPrint('----------- local document -------------');
      //       debugPrint(document);
      //       debugPrint(_encode(document.data));

      //       debugPrint('----------- renamed document -------------');
      //       DocumentSnapshot renamedDocument = await CarpService()
      //           .collection(collectionName)
      //           .document(document.name)
      //           .rename('new_name');
      //       debugPrint(renamedDocument);
      //       debugPrint(_encode(renamedDocument.data));

      //       // get the document back from the server
      // //      DocumentSnapshot server_document =
      // //          await CarpService().collection(collectionName).document(renamed_document.name).get();

      //       debugPrint('----------- server document by ID -------------');
      //       DocumentSnapshot serverDocument =
      //           await CarpService().documentById(documentId).get();
      //       debugPrint(serverDocument);
      //       debugPrint(_encode(serverDocument.data));

      //       debugPrint('----------- server document by NAME -------------');
      //       serverDocument = await CarpService()
      //           .collection(collectionName)
      //           .document(renamedDocument.name)
      //           .get();
      //       debugPrint(serverDocument);
      //       debugPrint(_encode(serverDocument.data));

      //       assert(serverDocument.id > 0);
      //       assert(serverDocument.name == renamedDocument.name);
      //       assert(serverDocument.data.length == document.data.length);
      //     }, skip: true);

      test(' - add & get document in nested collections', () async {
        // is not providing an document id, so this should create a new document
        // if the collection don't exist, it is created (according to David).
        DocumentSnapshot doc1 = await CarpService()
            .collection(collectionName)
            .document(userId)
            .collection('activities')
            .document('cooking')
            .setData({'what': 'breakfast', 'time': 'morning'});

        debugPrint('$doc1');
        expect(doc1.id, greaterThan(0));
        expect(doc1.path, equals('$collectionName/$userId/activities/cooking'));

        DocumentSnapshot? doc2 = await CarpService()
            .collection(collectionName)
            .document(userId)
            .collection('activities')
            .document('cooking')
            .get();

        expect(doc2, isNotNull);
        expect(doc2?.id, doc1.id);

        // delete document again
        await CarpService()
            .collection(collectionName)
            .document(userId)
            .collection('activities')
            .document('cooking')
            .delete();
      });

      test('- expire token and the upload document', () async {
        debugPrint('expiring token...');
        CarpAuthService().currentUser.token!.expire();

        debugPrint('trying to upload a document w/o a name...');
        DocumentSnapshot d = await CarpService().collection(collectionName).document().setData({
          'email': username,
          'name': 'Administrator',
        });

        expect(d.id, greaterThan(0));
        debugPrint('$d');
      });

      test(" - get a collection from path name", () async {
        await CarpService().collection(collectionName).document(userId).setData({
          'email': userId,
          'role': 'Administrator',
        });

        CollectionReference collection = await CarpService().collection(collectionName).get();

        debugPrint('Collection: $collection');
        expect(collection.path, collectionName);
      });

      test(" - list documents in a collection", () async {
        List<DocumentSnapshot> documents = await CarpService().collection(collectionName).documents;

        debugPrint('N = ${documents.length}');
        for (var doc in documents) {
          debugPrint('$doc');
        }
        expect(documents.length, greaterThan(0));
      });

      test(" - list collections in a document", () async {
        DocumentSnapshot? newDocument = await CarpService().collection(collectionName).document(userId).get();
        newDocument?.collections.forEach((element) => debugPrint(element));
      });

      test(" - list all nested documents in a collection", () async {
        List<DocumentSnapshot> documents = await CarpService().collection(collectionName).documents;
        for (var doc in documents) {
          debugPrint('$doc');
          for (var col in doc.collections) {
            debugPrint(col);
          }
        }
      });

      //    test(" - list all collections in the root", () async {
      //      List<String> root = await CarpService().collection("").collections;
      //      for (String ref in root) {
      //        debugPrint(ref);
      //        // List all documents in each collection
      //        List<DocumentSnapshot> documents =
      //            await CarpService().collection("/$ref").documents;
      //        for (DocumentSnapshot doc in documents) {
      //          debugPrint(doc);
      //        }
      //      }
      //
      //      documents = await CarpService().collection(collectionName).documents;
      //      for (DocumentSnapshot doc in documents) {
      //        debugPrint(doc);
      //      }
      //    });

      test(' - get collection from path', () async {
        CollectionReference collection = await CarpService().collection(collectionName).get();
        expect(collection.id!, greaterThan(0));
        debugPrint('$collection');
      });

      test(' - delete document', () async {
        var document = await CarpService().collection(collectionName).document(userId).setData({
          'email': userId,
          'role': 'Administrator',
        });

        expect(document, isNotNull);

        await CarpService().collection(collectionName).document(document.name).delete();
      });

      test(' - delete specific document', () async {
        await CarpService().collection(collectionName).document(userId).delete();
      });
    }, skip: false);

    /// In order to run the test in this group you need to be authenticated
    /// as a researcher.
    group("Documents & Collections - RESEARCHER", () {
      test(' - get documents by query', () async {
        var document = await CarpService().collection(collectionName).document(userId).setData({
          'email': userId,
          'role': 'Administrator',
        });

        expect(document, isNotNull);

        String query = 'name==$userId';
        List<DocumentSnapshot> documents = await CarpService().documentsByQuery(query);

        debugPrint("Found ${documents.length} document(s) for user '$userId'");
        for (var document in documents) {
          debugPrint(' - $document');
        }

        expect(documents.length, greaterThan(0));
      });

      test(' - get all documents', () async {
        List<DocumentSnapshot> documents = await CarpService().documents();

        debugPrint('Found ${documents.length} document(s)');
        for (var document in documents) {
          debugPrint(' - $document');
        }
        expect(documents.length, greaterThan(0));
      });

      test(' - rename collection', () async {
        CollectionReference collection = await CarpService().collection(collectionName).get();
        debugPrint('Collection before rename: $collection');
        await collection.rename(newCollectionName);
        expect(collection.name, newCollectionName);
        debugPrint('Collection after rename: $collection');
        collection = await CarpService().collection(newCollectionName).get();
        expect(collection.name, newCollectionName);
        debugPrint('Collection after get: $collection');
      });

      test(' - delete collection', () async {
        CollectionReference collection = await CarpService().collection(collectionName).get();

        await collection.delete();
        expect(collection.id, -1);
        debugPrint('$collection');

        try {
          collection = await CarpService().collection(newCollectionName).get();
        } catch (error) {
          debugPrint('$error');
          expect((error as CarpServiceRequestException).httpStatus.httpResponseCode, HttpStatus.notFound);
        }
      });
    }, skip: false);

    group("Files", () {
      test('- upload + small file', () async {
        final file = File("test/files/img.jpg");

        final uploadTask = CarpService().getFileStorageReference().upload(file, {
          'content-type': 'image/jpg',
          'content-language': 'en',
          'activity': 'test',
        });

        final response = await uploadTask.onComplete;
        expect(response.id, greaterThan(0));
        debugPrint(toJsonString(response.map));
      });

      test('- upload + BIG file', () async {
        final file = File("test/files/CAP7858089012525879504.jpg");

        final uploadTask = CarpService().getFileStorageReference().upload(file, {
          'content-type': 'image/jpg',
          'content-language': 'en',
          'activity': 'test',
        });

        final response = await uploadTask.onComplete;
        expect(response.id, greaterThan(0));
        debugPrint(toJsonString(response.map));
      });

      test('- get', () async {
        final File myFile = File("test/files/img.jpg");

        final FileUploadTask uploadTask = CarpService().getFileStorageReference().upload(myFile, {
          'content-type': 'image/jpg',
          'content-language': 'en',
          'activity': 'test',
        });

        CarpFileResponse response = await uploadTask.onComplete;
        expect(response.id, greaterThan(0));
        var id = response.id;

        final CarpFileResponse result = await CarpService().getFileStorageReference(id).get();
        debugPrint(toJsonString(result.map));
        expect(result.id, id);
      });

      test('- upload & download', () async {
        final File upFile = File("test/files/img.jpg");

        final FileUploadTask uploadTask = CarpService().getFileStorageReference().upload(upFile, {
          'content-type': 'image/jpg',
          'content-language': 'en',
          'activity': 'test',
        });

        CarpFileResponse upResponse = await uploadTask.onComplete;
        expect(upResponse.id, greaterThan(0));
        var id = upResponse.id;

        debugPrint(' $id');

        // need to refresh the token to have access to the newly uploaded file
        // see https://github.com/cph-cachet/carp-webservices-spring/issues/111

        // TODO - it seems like a refresh isn't enough....?
        await CarpAuthService().refresh();

        // await CarpAuthService().authenticateWithUsernamePassword(
        //   username: username,
        //   password: password,
        // );

        File downFile = File("test/files/img-$id.jpg");

        final FileDownloadTask downloadTask = CarpService().getFileStorageReference(id).download(downFile);

        int downResponse = await downloadTask.onComplete;
        expect(downResponse, 200);
        debugPrint('status code : $downResponse');
      });

      test('- download', () async {
        var id = 46;

        File downFile = File("test/files/img-$id.jpg");

        final FileDownloadTask downloadTask = CarpService().getFileStorageReference(id).download(downFile);

        int downResponse = await downloadTask.onComplete;
        expect(downResponse, 200);
        debugPrint('status code : $downResponse');
      });

      // NOTE that the following "get non-existing, "get all", "query",
      // "get by name", and "delete" unit tests ONLY works if you're
      // authenticated as a RESEARCHER.
      // See https://github.com/cph-cachet/carp.webservices-docker/issues/56

      test('- get non-existing', () async {
        try {
          await CarpService().getFileStorageReference(876872).get();
        } catch (error) {
          debugPrint('$error');
          expect(error, isA<CarpServiceRequestException>());
          expect((error as CarpServiceRequestException).httpStatus.httpResponseCode, HttpStatus.notFound);
        }
      });
      test('- get all', () async {
        final List<CarpFileResponse> results = await CarpService().getAllFiles(testStudyId);
        for (var result in results) {
          debugPrint(toJsonString((result.map)));
        }
      });

      test('- query', () async {
        final List<CarpFileResponse> results = await CarpService().queryFiles('original_name==img.jpg');

        if (results.isNotEmpty) {
          expect(results[0].originalName, 'img.jpg');
        }
        for (var result in results) {
          debugPrint(toJsonString((result.map)));
        }
      });

      test('- get by name', () async {
        final FileStorageReference? reference = await CarpService().getFileStorageReferenceByName('img.jpg');

        if (reference != null) {
          final CarpFileResponse result = await reference.get();
          expect(result.originalName, 'img.jpg');
          debugPrint(toJsonString(result.map));
        } else {
          debugPrint('File not found.');
        }
      });

      test('- delete', () async {
        final FileStorageReference? reference = await CarpService().getFileStorageReferenceByName('img.jpg');

        if (reference != null) {
          expect(reference.id, isNotNull);

          await CarpService().getFileStorageReference(reference.id).delete();
        } else {
          debugPrint('File not found.');
        }
      });
    }, skip: false);
  });
}
