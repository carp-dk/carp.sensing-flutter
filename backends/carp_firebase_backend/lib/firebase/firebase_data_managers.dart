/*
 * Copyright 2018-2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of carp_firebase_backend;

/// Base class for data managers that upload to Firebase.
///
/// Sets up the Firebase app and signs in the user, based on the
/// [FirebaseEndPoint] of a [FirebaseDataEndPoint].
/// Extended by [FirebaseStorageDataManager] and [FirebaseDatabaseDataManager].
abstract class FirebaseDataManager extends AbstractDataManager {
  /// The Firebase project and credentials. Set by [initialize].
  FirebaseEndPoint? firebaseEndPoint;

  FirebaseApp? _firebaseApp;
  User? _user;

  FirebaseDataManager();

  @override
  Future initialize(
    String studyDeploymentId,
    DataEndPoint dataEndPoint,
    Stream<DataPoint> data,
  ) async {
    super.initialize(studyDeploymentId, dataEndPoint, data);
    assert(dataEndPoint is FirebaseDataEndPoint);
    firebaseEndPoint = (dataEndPoint as FirebaseDataEndPoint).firebaseEndPoint;
  }

  /// The Firebase app for [firebaseEndPoint], initialized on first access.
  ///
  /// Throws a [CarpFirebaseBackendException] if [initialize] has not been called.
  Future<FirebaseApp> get firebaseApp async {
    if (firebaseEndPoint == null)
      throw CarpFirebaseBackendException(
        "The Firebase Endpoint is not configured - call the 'initialize()' method first.",
      );

    if (_firebaseApp == null) {
      _firebaseApp = await Firebase.initializeApp(
        name: firebaseEndPoint!.name,
        options: new FirebaseOptions(
          appId: Platform.isIOS
              ? firebaseEndPoint!.iOSGoogleAppID
              : firebaseEndPoint!.androidGoogleAppID,
          messagingSenderId: firebaseEndPoint!.gcmSenderID,
          apiKey: firebaseEndPoint!.webAPIKey,
          projectId: firebaseEndPoint!.projectID,
        ),
      );
    }
    return _firebaseApp!;
  }

  /// The authenticated Firebase user.
  ///
  /// If no user is signed in yet, signs in according to
  /// [FirebaseEndPoint.firebaseAuthenticationMethod]:
  ///
  ///  * [FireBaseAuthenticationMethods.GOOGLE]: Google Sign-In.
  ///  * [FireBaseAuthenticationMethods.PASSWORD]: email and password.
  ///
  /// Emits a [FirebaseDataManagerEventTypes.authenticated] event on sign-in.
  /// Returns `null` if the user cannot be authenticated. Throws a
  /// [CarpFirebaseBackendException] if [initialize] has not been called.
  Future<User?> get user async {
    if (firebaseEndPoint == null)
      throw CarpFirebaseBackendException(
        "The Firebase Endpoint is not configured - call the 'initialize()' method first.",
      );

    if (_user == null) {
      switch (firebaseEndPoint!.firebaseAuthenticationMethod) {
        case FireBaseAuthenticationMethods.GOOGLE:
          {
            GoogleSignInAccount googleUser =
                await (_googleSignIn.signIn() as FutureOr<GoogleSignInAccount>);
            GoogleSignInAuthentication googleAuth =
                await googleUser.authentication;
            final AuthCredential credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            UserCredential result = await _auth.signInWithCredential(
              credential,
            );
            _user = result.user;
            break;
          }
        case FireBaseAuthenticationMethods.PASSWORD:
          {
            assert(firebaseEndPoint?.email != null);
            assert(firebaseEndPoint?.password != null);
            UserCredential result = await _auth.signInWithEmailAndPassword(
              email: firebaseEndPoint!.email!,
              password: firebaseEndPoint!.password!,
            );
            _user = result.user;
            break;
          }
        default:
          {
            //TODO : should probably throw a NotImplementedException
          }
      }
      if (_user != null) {
        addEvent(
          FirebaseDataManagerEvent(FirebaseDataManagerEventTypes.authenticated),
        );
        print("signed in as " + _user!.email! + " - uid: " + _user!.uid);
      }
    }

    return _user;
  }

  @override
  Future close() async {
    return;
  }

  @override
  void onDone() => close();

  @override
  void onError(error) => warning('Error in $runtimeType - $error');
}

/// A data manager that uploads files of JSON data to Firebase Storage.
///
/// Handles a [FirebaseStorageDataEndPoint]. Wraps a [FileDataManager], which
/// writes (and zips) files on the phone. Each closed file is uploaded to
/// [firebasePath] and then deleted locally. Its events are forwarded to this
/// manager's event stream.
class FirebaseStorageDataManager extends FirebaseDataManager {
  FirebaseStorage? _firebaseStorage;

  /// The wrapped manager that writes files on the phone.
  late FileDataManager fileDataManager;

  /// The data endpoint this manager uploads to. Set by [initialize].
  FirebaseStorageDataEndPoint? firebaseStorageDataEndPoint;

  String get type => DataEndPointTypes.FIREBASE_STORAGE;

  FirebaseStorageDataManager() : super() {
    // Create a [FileDataManager] and wrap it.
    fileDataManager = new FileDataManager();

    // merge the file data manager's events into this CARP data manager's event stream
    fileDataManager.events.forEach((event) => controller.add(event));

    // listen to data manager events, but only those from the file manager and
    // only closing events on a close event, upload the file to CARP
    fileDataManager.events
        .where((event) => event.runtimeType == FileDataManagerEvent)
        .where((event) => event.type == FileDataManagerEventTypes.FILE_CLOSED)
        .listen(
          (event) =>
              _uploadFileToFirestore((event as FileDataManagerEvent).path),
        );
  }

  Future initialize(
    String studyDeploymentId,
    DataEndPoint dataEndPoint,
    Stream<DataPoint> data,
  ) async {
    super.initialize(studyDeploymentId, dataEndPoint, data);
    assert(dataEndPoint is FirebaseStorageDataEndPoint);
    this.firebaseStorageDataEndPoint =
        dataEndPoint as FirebaseStorageDataEndPoint;

    fileDataManager.initialize(studyDeploymentId, dataEndPoint, data);

    final FirebaseStorage storage = await firebaseStorage;
    final User? authenticatedUser = await user;

    info('Initializig FirebaseStorageDataManager...');
    info(
      ' Firebase URI  : ${firebaseStorageDataEndPoint!.firebaseEndPoint.uri}',
    );
    info(' Folder path   : ${firebaseStorageDataEndPoint!.path}');
    info(' Storage       : ${storage.app.name}');
    info(
      ' Auth. user    : ${authenticatedUser?.displayName} <${authenticatedUser?.email}>\n',
    );
  }

  /// The Firebase Storage instance for the endpoint's bucket.
  ///
  /// Throws a [CarpFirebaseBackendException] if [initialize] has not been called.
  Future<FirebaseStorage> get firebaseStorage async {
    if (firebaseStorageDataEndPoint == null)
      throw CarpFirebaseBackendException(
        "The Firebase Endpoint is not configured - call the 'initialize()' method first.",
      );

    if (_firebaseStorage == null) {
      final FirebaseApp? app = await firebaseApp;
      _firebaseStorage = FirebaseStorage.instanceFor(
        app: app,
        bucket: firebaseStorageDataEndPoint!.firebaseEndPoint.uri,
      );
    }
    return _firebaseStorage!;
  }

  /// The folder in Firebase Storage that files are uploaded to:
  /// `<path>/<study_deployment_id>/<device_id>`.
  String get firebasePath =>
      "${firebaseStorageDataEndPoint!.path}/$studyDeploymentId/${DeviceInfo().deviceID.toString()}";

  Future<String> _uploadFileToFirestore(String localFilePath) async {
    final String filename = localFilePath.substring(
      localFilePath.lastIndexOf('/') + 1,
    );

    info(
      "Upload to Firestore started - path : '$firebasePath', filename : '$filename'",
    );

    final Reference ref =
        FirebaseStorage.instance.ref().child(firebasePath).child(filename);
    final File file = new File(localFilePath);
    final String deviceID = DeviceInfo().deviceID.toString();
    final String? userID = (await user)!.email;

    final UploadTask uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentEncoding: 'application/json',
        contentType: 'application/zip',
        customMetadata: <String, String>{
          'device_id': '$deviceID',
          'study_deployment_id': '$studyDeploymentId',
          'user_id': '$userID',
        },
        // TODO - add location as metadata
      ),
    );

    ref.fullPath;

    // await the upload is successful
    String downloadUrl = await ref.getDownloadURL();

    await uploadTask.whenComplete(() {
      addEvent(
        FirebaseDataManagerEvent(
          FirebaseDataManagerEventTypes.file_uploaded,
          file.path,
          downloadUrl,
        ),
      );
      info('Upload to Firestore finished - remote file url  : $downloadUrl');
      // then delete the local file.
      file.delete();
      addEvent(
        FileDataManagerEvent(FileDataManagerEventTypes.FILE_DELETED, file.path),
      );
    });

    return downloadUrl;
  }

  // forward to file data manager
  void onDataPoint(DataPoint dataPoint) => fileDataManager.write(dataPoint);
}

/// A data manager that uploads each JSON data object to Cloud Firestore.
///
/// Handles a [FirebaseDatabaseDataEndPoint]. Every data object is uploaded
/// as soon as it is collected, so this only works when the phone is online;
/// nothing is buffered. Use [FirebaseStorageDataManager] if offline buffering
/// is needed.
class FirebaseDatabaseDataManager extends FirebaseDataManager {
  FirebaseFirestore? _firebaseDatabase;

  /// The data endpoint this manager uploads to. Set by [initialize].
  FirebaseDatabaseDataEndPoint? firebaseDatabaseDataEndPoint;

  FirebaseDatabaseDataManager();

  String get type => DataEndPointTypes.FIREBASE_DATABSE;

  Future initialize(
    String studyDeploymentId,
    DataEndPoint dataEndPoint,
    Stream<DataPoint> data,
  ) async {
    super.initialize(studyDeploymentId, dataEndPoint, data);
    assert(dataEndPoint is FirebaseDatabaseDataEndPoint);
    firebaseDatabaseDataEndPoint =
        dataEndPoint as FirebaseDatabaseDataEndPoint?;

    final FirebaseFirestore database = await firebaseDatabase;
    final User? authenticatedUser = await user;

    print('Initializig $runtimeType...');
    print(
      ' Firebase URI    : ${firebaseDatabaseDataEndPoint!.firebaseEndPoint.uri}',
    );
    print(' Collection path : ${firebaseDatabaseDataEndPoint!.collection}');
    print(' Database        : ${database.app.name}');
    print(
      ' Auth. user      : ${authenticatedUser?.displayName} <${authenticatedUser?.email}>\n',
    );
  }

  /// The Firestore instance for the Firebase app.
  ///
  /// Throws a [CarpFirebaseBackendException] if [initialize] has not been called.
  Future<FirebaseFirestore> get firebaseDatabase async {
    if (firebaseDatabaseDataEndPoint == null)
      throw CarpFirebaseBackendException(
        "The Firebase Endpoint is not configured - call the 'initialize()' method first.",
      );

    if (_firebaseDatabase == null) {
      final FirebaseApp app = await firebaseApp;
      _firebaseDatabase = FirebaseFirestore.instanceFor(app: app);
    }
    return _firebaseDatabase!;
  }

  /// Uploads [dataPoint] as a JSON document to
  /// [FirebaseDatabaseDataEndPoint.collection].
  ///
  /// Returns `false`, without uploading, if no user is authenticated.
  /// The write is not awaited.
  Future<bool> uploadData(DataPoint dataPoint) async {
    assert(dataPoint.data is Datum);
    final datum = dataPoint.data as Datum?;

    User? authenticatedUser = await user;

    if (authenticatedUser != null) {
      final String deviceId = DeviceInfo().deviceID.toString();
      final String dataType = dataPoint.carpHeader.dataFormat.toString();

      final jsonDataString = json.encode(dataPoint);
      Map<String, dynamic> jsonData =
          json.decode(jsonDataString) as Map<String, dynamic>;

      // add json data
      FirebaseFirestore.instance
          .collection(firebaseDatabaseDataEndPoint!.collection)
          .doc(studyDeploymentId) // study deployment id
          .collection(deviceId) // device id
          .doc('upload') // the default upload document is called 'upload'
          .collection(dataType) // data/measure type
          .doc(datum!.id) // data id
          .set(jsonData);

      return true;
    } else {
      warning(
        'Could not upload data in $runtimeType - no user is authenticated.',
      );
    }

    return false;
  }

  void onDataPoint(DataPoint dataPoint) => uploadData(dataPoint);
}

/// A status event from a [FirebaseDataManager].
///
/// See [FirebaseDataManagerEventTypes] for the event types.
class FirebaseDataManagerEvent extends DataManagerEvent {
  /// The full path and filename for the file on the device.
  String? path;

  /// The URI of the file on the Firebase server.
  String? firebaseUri;

  /// Creates an event of [type], with an optional local [path] and [firebaseUri].
  FirebaseDataManagerEvent(String type, [this.path, this.firebaseUri])
      : super(type);

  String toString() =>
      'FirebaseDataManagerEvent - type: $type, path: $path, firebaseUri: $firebaseUri';
}

/// The types of [FirebaseDataManagerEvent]s.
class FirebaseDataManagerEventTypes extends FileDataManagerEventTypes {
  /// A user signed in to Firebase.
  static const String authenticated = 'authenticated';

  /// A file was uploaded to Firebase Storage.
  static const String file_uploaded = 'file_uploaded';
}
