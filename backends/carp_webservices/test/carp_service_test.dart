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

String _encode(Object? object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  SharedPreferences.setMockInitialValues({});
  const String userId = "jakob@bardram.net";
  const String studyId = "test_1234";
  const String collectionName = 'test_patients';
  const String newCollectionName = 'new_patients';

  final lightData = AmbientLight(12, 23, 0.3, 0.4);

  final deviceData = DeviceInformation(
    platform: 'Android',
    deviceId: '12345jE',
  );

  /// Setup CAWS and authenticate.
  /// Runs once before all tests.
  setUpAll(() async {
    Settings().debugLevel = DebugLevel.debug;

    await CarpAuthService().configure(CarpProperties().authProperties);

    // configure the service with both an app and a study, using the same
    // test study for all tests
    CarpService().configure(CarpProperties().app, CarpProperties().study);
    CarpParticipationService().configureFrom(CarpService());

    await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );
  });

  /// Close connection to CARP.
  /// Runs once after all tests.
  tearDownAll(() {
    CarpAuthService().logoutNoContext();
  });

  group(
    "CARP Base Services",
    () {
      // setUp(() async {
      //   await CarpAuthService().authenticateWithUsernamePassword(
      //     username: username,
      //     password: password,
      //   );

      //   expect(CarpAuthService().authenticated, true);
      // });

      group('authentication', () {
        test('- authentication w. username and password', () async {
          CarpUser user =
              await CarpAuthService().authenticateWithUsernamePassword(
            username: username,
            password: password,
          );

          expect(user.token, isNotNull);
          expect(user.isAuthenticated, true);

          debugPrint("signed in : $user");
          debugPrint("token  : ${user.token}");
        });

        test('- authentication with access link', () async {
          CarpUser user = await CarpAuthService()
              .authenticateWithAccessLink(uri: accessLinkUri);

          // expect(user.token, isNotNull);
          // expect(user.isAuthenticated, true);

          debugPrint("signed in : $user");
          debugPrint("token  : ${user.token}");
        });

        test('- get user profile', () async {
          assert(CarpAuthService().authenticated);

          CarpUser newUser = CarpAuthService().currentUser;

          debugPrint("signed in : $newUser");
          debugPrint("   name   : ${newUser.firstName} ${newUser.lastName}");

          expect(newUser.firstName, isNotEmpty);
          expect(newUser.lastName, isNotEmpty);
          expect(newUser.isAuthenticated, true);
        });

        test('- oauth token refreshes', () async {
          debugPrint('expiring token...');
          CarpAuthService().currentUser.token!.expire();

          CarpAuthService().currentUser;
        });

        test('- refreshing token', () async {
          CarpUser user =
              await CarpAuthService().authenticateWithUsernamePassword(
            username: username,
            password: password,
          );

          CarpUser newUser = await CarpAuthService().refresh();

          assert(newUser.isAuthenticated);
          assert(newUser.username == user.username);

          debugPrint("signed in : $newUser");
          debugPrint("   token  : ${newUser.token}");
        });
      });

      group('Informed Consent', () {
        test('- create', () async {
          ConsentDocument uploaded = await CarpService().createConsentDocument(
              {"text": "The original terms text.", "signature": "Image Blob"});

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

          ConsentDocument downloaded =
              await CarpService().getConsentDocument(1);
          // await CarpService().getConsentDocument(uploaded.id);

          debugPrint('$downloaded');
          debugPrint('id        : ${downloaded.id}');
          debugPrint('createdAt : ${downloaded.createdAt}');
          debugPrint('createdBy : ${downloaded.createdBy}');
          debugPrint('document  : ${downloaded.document}');
        });
      });

      group(
        "Data points",
        () {
          test('- post', () async {
            final DataPoint data = DataPoint.fromData(lightData);
            // studyId & userId is required for upload
            data.carpHeader.studyId = testStudyId;
            data.carpHeader.userId = userId;

            debugPrint(_encode(data.toJson()));

            int dataPointId =
                await CarpService().dataPointReference().post(data);

            assert(dataPointId > 0);
            debugPrint("data_point_id : $dataPointId");
          });

          test('- post w/o trigger id & device role name', () async {
            final DataPoint data = DataPoint.fromData(lightData);
            // studyId & userId is required for upload
            data.carpHeader.studyId = testStudyId;
            data.carpHeader.userId = userId;

            // triggerId, deviceRoleName, startTime & endTime are not required
            data.carpHeader.triggerId = null;
            data.carpHeader.deviceRoleName = null;
            data.carpHeader.startTime = null;
            data.carpHeader.endTime = null;

            debugPrint(_encode(data.toJson()));

            int dataPointId =
                await CarpService().dataPointReference().post(data);

            assert(dataPointId > 0);
            debugPrint("data_point_id : $dataPointId");
          });

          test('- batch', () async {
            final before = await CarpService().dataPointReference().getAll();
            debugPrint('N_before = ${before.length}');

            List<DataPoint> batch = [];
            batch.addAll([
              DataPoint.fromData(lightData),
              DataPoint.fromData(lightData),
              DataPoint.fromData(deviceData),
              DataPoint.fromData(deviceData),
              DataPoint.fromData(deviceData),
            ]);

            // debugPrint('N_batch = ${batch.length}');

            var reference = CarpService().dataPointReference();

            // test two consecutive batch uploads
            await reference.batch(batch);
            await reference.batch(batch);

            debugPrint('N_batch = ${2 * batch.length}');

            // wait for the batch requests to finish
            await Future.delayed(const Duration(seconds: 5), () {});

            final after = await CarpService().dataPointReference().getAll();
            debugPrint('N_after = ${after.length}');
            // data.forEach((datapoint) => debugPrint(_encode((datapoint.toJson()))));

            assert(after.length > before.length);
          });

          test('- upload', () async {
            final File file = File("test/json/batch-correct-test.json");
            await CarpService().dataPointReference().upload(file);

            // wait for the batch requests to finish
            await Future.delayed(const Duration(seconds: 2), () {});

            String query = 'carp_header.data_format.namespace==test';
            debugPrint("query : $query");

            List<DataPoint> data =
                await CarpService().dataPointReference().query(query);

            debugPrint('N=${data.length}');
            // data.forEach((datapoint) => debugPrint(_encode((datapoint.toJson()))));

            assert(data.length >= 140);
          });

          test('- query for test data points', () async {
            String query = 'carp_header.data_format.namespace==dk.cachet.carp';
            // String query = 'carp_header.data_format.namespace==test';
            // String query =
            //     'carp_header.data_format.name==${lightData.format.name}';

            debugPrint("query : $query");
            List<DataPoint> data =
                await CarpService().dataPointReference().query(query);

            debugPrint('N=${data.length}');
            // data.forEach((datapoint) => debugPrint(_encode((datapoint.toJson()))));

            expect(data, isNotNull);
          });

          test('- count data points based on query', () async {
            String query = 'carp_header.data_format.namespace==test';
            debugPrint("query : $query");
            int count = await CarpService().dataPointReference().count(query);

            debugPrint('N=$count');
            expect(count, greaterThanOrEqualTo(0));
          });

          test('- delete test data points', () async {
            String query = 'carp_header.data_format.namespace==test';
            debugPrint("query : $query");
            List<DataPoint> data =
                await CarpService().dataPointReference().query(query);

            debugPrint('N=${data.length}');
            debugPrint('deleting...');
            for (var datapoint in data) {
              debugPrint(' ${datapoint.id}');
              await CarpService().dataPointReference().delete(datapoint.id!);
            }
          });

          test('- get by id', () async {
            final DataPoint dataPost = DataPoint.fromData(lightData);
            // studyId & userId is required for upload
            dataPost.carpHeader.studyId = studyId;
            dataPost.carpHeader.userId = userId;

            debugPrint(_encode(dataPost.toJson()));

            int dataPointId =
                await CarpService().dataPointReference().post(dataPost);

            assert(dataPointId > 0);

            DataPoint dataGet =
                await CarpService().dataPointReference().get(dataPointId);

            debugPrint(_encode(dataGet.toJson()));
            assert(dataGet.id == dataPointId);
          });

          test(
            '- get all',
            () async {
              List<DataPoint> data =
                  await CarpService().dataPointReference().getAll();

              for (var datapoint in data) {
                debugPrint(_encode((datapoint.toJson())));
              }
              expect(data, isNotNull);
              debugPrint('N=${data.length}');
            },
            skip: false,
          );

          test('- query', () async {
            await CarpService()
                .dataPointReference()
                .post(DataPoint.fromData(lightData)
                  ..carpHeader.studyId = studyId
                  ..carpHeader.userId = userId);
            await CarpService()
                .dataPointReference()
                .post(DataPoint.fromData(deviceData)
                  ..carpHeader.studyId = studyId
                  ..carpHeader.userId = userId);

            // String query =
            //     'carp_header.user_id==$userId;carp_body.timestamp>2019-11-02T12:53:40.219598Z';
            //String query = 'carp_header.data_format.namespace==test';
            String query =
                'carp_header.data_format.name==${lightData.format.name}';
            // String query = 'carp_header.user_id==$userId';
            //String query = 'carp_body.timestamp>2019-11-02T12:53:40.219598Z';
            //String query = 'carp_header.data_format.namespace=in=(carp,omh)';
            debugPrint("query : $query");
            List<DataPoint> data =
                await CarpService().dataPointReference().query(query);

            expect(data, isNotNull);
            debugPrint('N=${data.length}');
            String str = '[';
            for (var datapoint in data) {
              str += '${datapoint.id},';
            }
            // data.forEach((datapoint) => debugPrint(_encode((datapoint.toJson()))));
            str += ']';
            debugPrint(str);
          });

          test('- delete', () async {
            int dataPointId = await CarpService()
                .dataPointReference()
                .post(DataPoint.fromData(lightData)
                  ..carpHeader.studyId = studyId
                  ..carpHeader.userId = userId);

            await CarpAuthService().refresh();

            debugPrint("DELETE data_point_id : $dataPointId");
            await CarpService().dataPointReference().delete(dataPointId);
          });

          test(
            '- delete all',
            () async {
              List<DataPoint> data =
                  await CarpService().dataPointReference().getAll();

              debugPrint('N=${data.length}');
              debugPrint('deleting...');
              for (var datapoint in data) {
                debugPrint(' ${datapoint.id}');
                await CarpService().dataPointReference().delete(datapoint.id!);
              }

              // wait for the delete requests to finish
              await Future.delayed(const Duration(seconds: 2), () {});

              List<DataPoint> empty =
                  await CarpService().dataPointReference().getAll();

              debugPrint('N=${empty.length}');
              assert(empty.isEmpty);
            },
            skip: true,
          );
        },
        skip: false,
      );

      /// In order to run the test in this group you need to be authenticated
      /// as a participant.
      group("Documents & Collections - PARTICIPANT", () {
        test(' - clean up old test documents', () async {
          await CarpService()
              .collection(collectionName)
              .document(userId)
              .collection('activities')
              .document('cooking')
              .delete();

          await CarpService()
              .collection(collectionName)
              .document(userId)
              .delete();
        });

        test(' - CRUD document', () async {
          // first create a document
          var document = await CarpService()
              .collection(collectionName)
              .document(userId)
              .setData({'email': userId, 'role': 'Administrator'});

          expect(document, isNotNull);

          // create a document reference
          final reference =
              CarpService().collection(collectionName).document(userId);

          // get it back from the server
          final original = await reference.get();
          debugPrint(_encode(original?.data));

          // updating the role to super user
          final updated = await reference
              .updateData({'email': userId, 'role': 'Super User'});

          debugPrint('----------- updated -------------');
          debugPrint('$updated');
          debugPrint(_encode(updated.data));
          debugPrint('${updated.data["role"]}');
          expect(updated.id, greaterThan(0));
          expect(updated.data["role"], 'Super User');

          // delete document again
          await CarpService()
              .collection(collectionName)
              .document(userId)
              .delete();
        });

        test(' - get document by id', () async {
          // first create a document
          var document = await CarpService()
              .collection(collectionName)
              .document(userId)
              .setData({'email': userId, 'role': 'Administrator'});

          debugPrint('$document');
          expect(document, isNotNull);

          // then get it back by the id
          var newDocument = await CarpService().documentById(document.id).get();

          debugPrint('$newDocument');
          expect(newDocument, isNotNull);
          expect(newDocument?.id, document.id);

          // delete document again
          await CarpService()
              .collection(collectionName)
              .document(userId)
              .delete();
        });

        test(' - get document by path', () async {
          var document = await CarpService()
              .collection(collectionName)
              .document(userId)
              .setData({'email': userId, 'role': 'Administrator'});

          expect(document, isNotNull);

          DocumentSnapshot? newDocument = await CarpService()
              .collection(collectionName)
              .document(document.name)
              .get();

          debugPrint('$newDocument');
          expect(newDocument?.id, document.id);

          // delete document again
          await CarpService()
              .collection(collectionName)
              .document(userId)
              .delete();
        });

        test(' - get non-existing document', () async {
          DocumentSnapshot? newDocument = await CarpService()
              .collection(collectionName)
              .document('not_available')
              .get();

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
          expect(
              doc1.path, equals('$collectionName/$userId/activities/cooking'));

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
          DocumentSnapshot d = await CarpService()
              .collection(collectionName)
              .document()
              .setData({'email': username, 'name': 'Administrator'});

          expect(d.id, greaterThan(0));
          debugPrint('$d');
        });

        test(" - get a collection from path name", () async {
          await CarpService()
              .collection(collectionName)
              .document(userId)
              .setData({'email': userId, 'role': 'Administrator'});

          CollectionReference collection =
              await CarpService().collection(collectionName).get();
          expect(collection.path, collectionName);
        });

        test(" - list documents in a collection", () async {
          List<DocumentSnapshot> documents =
              await CarpService().collection(collectionName).documents;

          debugPrint('N = ${documents.length}');
          for (var doc in documents) {
            debugPrint('$doc');
          }
          expect(documents.length, greaterThan(0));
        });

        test(" - list collections in a document", () async {
          DocumentSnapshot? newDocument = await CarpService()
              .collection(collectionName)
              .document(userId)
              .get();
          newDocument?.collections.forEach((element) => debugPrint(element));
        });

        test(" - list all nested documents in a collection", () async {
          List<DocumentSnapshot> documents =
              await CarpService().collection(collectionName).documents;
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
          CollectionReference collection =
              await CarpService().collection(collectionName).get();
          expect(collection.id!, greaterThan(0));
          debugPrint('$collection');
        });

        test(' - delete document', () async {
          var document = await CarpService()
              .collection(collectionName)
              .document(userId)
              .setData({'email': userId, 'role': 'Administrator'});

          expect(document, isNotNull);

          await CarpService()
              .collection(collectionName)
              .document(document.name)
              .delete();
        });

        test(' - delete specific document', () async {
          await CarpService()
              .collection(collectionName)
              .document(userId)
              .delete();
        });
      }, skip: false);

      /// In order to run the test in this group you need to be authenticated
      /// as a researcher.
      group("Documents & Collections - RESEARCHER", () {
        test(' - get documents by query', () async {
          var document = await CarpService()
              .collection(collectionName)
              .document(userId)
              .setData({'email': userId, 'role': 'Administrator'});

          expect(document, isNotNull);

          String query = 'name==$userId';
          List<DocumentSnapshot> documents =
              await CarpService().documentsByQuery(query);

          debugPrint(
              "Found ${documents.length} document(s) for user '$userId'");
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
          CollectionReference collection =
              await CarpService().collection(collectionName).get();
          debugPrint('Collection before rename: $collection');
          await collection.rename(newCollectionName);
          expect(collection.name, newCollectionName);
          debugPrint('Collection after rename: $collection');
          collection = await CarpService().collection(newCollectionName).get();
          expect(collection.name, newCollectionName);
          debugPrint('Collection after get: $collection');
        });

        test(' - delete collection', () async {
          CollectionReference collection =
              await CarpService().collection(collectionName).get();

          await collection.delete();
          expect(collection.id, -1);
          debugPrint('$collection');

          try {
            collection =
                await CarpService().collection(newCollectionName).get();
          } catch (error) {
            debugPrint('$error');
            expect((error as CarpServiceException).httpStatus!.httpResponseCode,
                HttpStatus.notFound);
          }
        });
      }, skip: false);

      group("Files", () {
        test('- upload + small file', () async {
          final file = File("test/files/img.jpg");

          final uploadTask = CarpService().getFileStorageReference().upload(
            file,
            {
              'content-type': 'image/jpg',
              'content-language': 'en',
              'activity': 'test'
            },
          );

          final response = await uploadTask.onComplete;
          expect(response.id, greaterThan(0));
          debugPrint(toJsonString(response.map));
        });

        test('- upload + BIG file', () async {
          final file = File("test/files/CAP7858089012525879504.jpg");

          final uploadTask = CarpService().getFileStorageReference().upload(
            file,
            {
              'content-type': 'image/jpg',
              'content-language': 'en',
              'activity': 'test'
            },
          );

          final response = await uploadTask.onComplete;
          expect(response.id, greaterThan(0));
          debugPrint(toJsonString(response.map));
        });

        test('- get', () async {
          final File myFile = File("test/files/img.jpg");

          final FileUploadTask uploadTask = CarpService()
              .getFileStorageReference()
              .upload(myFile, {
            'content-type': 'image/jpg',
            'content-language': 'en',
            'activity': 'test'
          });

          CarpFileResponse response = await uploadTask.onComplete;
          expect(response.id, greaterThan(0));
          var id = response.id;

          final CarpFileResponse result =
              await CarpService().getFileStorageReference(id).get();
          debugPrint(toJsonString(result.map));
          expect(result.id, id);
        });

        test('- upload & download', () async {
          final File upFile = File("test/files/img.jpg");

          final FileUploadTask uploadTask = CarpService()
              .getFileStorageReference()
              .upload(upFile, {
            'content-type': 'image/jpg',
            'content-language': 'en',
            'activity': 'test'
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

          final FileDownloadTask downloadTask =
              CarpService().getFileStorageReference(id).download(downFile);

          int downResponse = await downloadTask.onComplete;
          expect(downResponse, 200);
          debugPrint('status code : $downResponse');
        });

        test('- download', () async {
          var id = 46;

          File downFile = File("test/files/img-$id.jpg");

          final FileDownloadTask downloadTask =
              CarpService().getFileStorageReference(id).download(downFile);

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
            expect(error, isA<CarpServiceException>());
            expect((error as CarpServiceException).httpStatus!.httpResponseCode,
                HttpStatus.notFound);
          }
        });
        test('- get all', () async {
          final List<CarpFileResponse> results =
              await CarpService().getAllFiles(testStudyId);
          for (var result in results) {
            debugPrint(toJsonString((result.map)));
          }
        });

        test('- query', () async {
          final List<CarpFileResponse> results =
              await CarpService().queryFiles('original_name==img.jpg');

          if (results.isNotEmpty) {
            expect(results[0].originalName, 'img.jpg');
          }
          for (var result in results) {
            debugPrint(toJsonString((result.map)));
          }
        });

        test('- get by name', () async {
          final FileStorageReference? reference =
              await CarpService().getFileStorageReferenceByName('img.jpg');

          if (reference != null) {
            final CarpFileResponse result = await reference.get();
            expect(result.originalName, 'img.jpg');
            debugPrint(toJsonString(result.map));
          } else {
            debugPrint('File not found.');
          }
        });

        test('- delete', () async {
          final FileStorageReference? reference =
              await CarpService().getFileStorageReferenceByName('img.jpg');

          if (reference != null) {
            expect(reference.id, isNotNull);

            final int result = await CarpService()
                .getFileStorageReference(reference.id)
                .delete();
            expect(result, greaterThan(0));
            debugPrint('result : $result');
          } else {
            debugPrint('File not found.');
          }
        });
      }, skip: false);
    },
  );
}
