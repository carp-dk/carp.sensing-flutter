/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_firebase_backend;

/// The Google Firebase project and the credentials used to sign in to it.
///
/// Shared by [FirebaseStorageDataEndPoint] and [FirebaseDatabaseDataEndPoint]
/// through [FirebaseDataEndPoint.firebaseEndPoint].
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class FirebaseEndPoint {
  /// The name of the Firebase endpoint.
  ///
  /// Can be anything, but it is recommended to use the name of the Firebase
  /// bucket. Also used as the name of the Firebase app.
  String name;

  /// The URI of the Firebase endpoint, used as the Firebase Storage bucket.
  String uri;

  /// The authentication method used for Firebase.
  ///
  /// One of [FireBaseAuthenticationMethods]. Only
  /// [FireBaseAuthenticationMethods.GOOGLE] and
  /// [FireBaseAuthenticationMethods.PASSWORD] are implemented.
  ///
  /// See [Firebase Authentication](https://firebase.google.com/docs/auth/)
  /// for a list of authentication options.
  String firebaseAuthenticationMethod;

  /// Email (used as username), required for password authentication.
  String? email;

  /// Password, required for password authentication.
  ///
  /// TODO : right now in clear text -- not so good.
  String? password;

  /// Custom token, if using custom auth system integration. Not used yet.
  String? token;

  /// The Firebase project ID (not the Name!).
  /// See Firebase project settings for this ID.
  String projectID;

  /// The Firebase Web API Key.
  /// See Firebase project settings for this ID.
  String webAPIKey;

  /// The Firebase App ID for Android.
  /// Should be set up in the Firebase project settings.
  String androidGoogleAppID;

  /// The Firebase App ID for iOS.
  /// Should be set up in the Firebase project settings.
  String iOSGoogleAppID;

  /// The Firebase GCM (Google Cloud Messaging) Sender ID.
  ///
  /// See the project settings under the 'Cloud Messaging' tab.
  String gcmSenderID;

  /// Creates a [FirebaseEndPoint].
  FirebaseEndPoint({
    required this.name,
    required this.uri,
    required this.firebaseAuthenticationMethod,
    this.email,
    this.password,
    this.token,
    required this.projectID,
    required this.webAPIKey,
    required this.androidGoogleAppID,
    required this.iOSGoogleAppID,
    required this.gcmSenderID,
  }) : super();

  static Function get fromJsonFunction => _$FirebaseEndPointFromJson;
  factory FirebaseEndPoint.fromJson(Map<String, dynamic> json) =>
      _$FirebaseEndPointFromJson(json);
  Map<String, dynamic> toJson() => _$FirebaseEndPointToJson(this);
}

/// A data endpoint that refers to a [FirebaseEndPoint].
///
/// Mixed into [FirebaseStorageDataEndPoint] and [FirebaseDatabaseDataEndPoint].
abstract class FirebaseDataEndPoint {
  /// The Firebase endpoint.
  late FirebaseEndPoint firebaseEndPoint;
}

/// A data endpoint that uploads each measurement as a JSON document to
/// Cloud Firestore.
///
/// Handled by a [FirebaseDatabaseDataManager]. Needs the phone to be online.
/// See [Cloud Firestore](https://firebase.google.com/docs/firestore) for a
/// description of the Firebase cloud database.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class FirebaseDatabaseDataEndPoint extends DataEndPoint
    with FirebaseDataEndPoint {
  /// The name of the Firestore collection that holds the JSON objects.
  ///
  /// JSON objects are stored in `<collection>/<study_deployment_id>/<device_id>/upload/<data_type>`.
  /// For example, if collection = "carp_data", study_deployment_id = "1234" and
  /// device_id = "987234", location data is stored as documents in
  /// "carp_data/1234/987234/upload/location".
  String collection;

  /// Creates a [FirebaseDatabaseDataEndPoint].
  FirebaseDatabaseDataEndPoint(
    FirebaseEndPoint firebaseEndPoint, {
    required this.collection,
  }) : super(type: DataEndPointTypes.FIREBASE_DATABSE) {
    this.firebaseEndPoint = firebaseEndPoint;
  }

  Function get fromJsonFunction => _$FirebaseDatabaseDataEndPointFromJson;
  factory FirebaseDatabaseDataEndPoint.fromJson(Map<String, dynamic> json) =>
      _$FirebaseDatabaseDataEndPointFromJson(json);
  Map<String, dynamic> toJson() => _$FirebaseDatabaseDataEndPointToJson(this);
}

/// A data endpoint that uploads (zipped) JSON files to Firebase Storage.
///
/// Handled by a [FirebaseStorageDataManager], which writes files locally with
/// a [FileDataManager] and uploads each file when it is closed.
/// See [Firebase Storage](https://firebase.google.com/docs/storage) for a
/// description of Firebase file storage.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class FirebaseStorageDataEndPoint extends FileDataEndPoint
    with FirebaseDataEndPoint {
  /// The folder path in Firebase Storage where files are stored.
  ///
  /// May contain sub-folders separated with `/`. Files are stored in
  /// `<path>/<study_deployment_id>/<device_id>/`. For example, if
  /// path = "sensing/data", study_deployment_id = "1234" and device_id = "987234",
  /// files are stored in "sensing/data/1234/987234/".
  String path;

  /// Creates a [FirebaseStorageDataEndPoint].
  FirebaseStorageDataEndPoint(
    FirebaseEndPoint firebaseEndPoint, {
    required this.path,
    required bufferSize,
    zip = false,
    encrypt = false,
    publicKey,
  }) : super(
          type: DataEndPointTypes.FIREBASE_STORAGE,
          bufferSize: bufferSize,
          zip: zip,
          encrypt: encrypt,
        ) {
    this.firebaseEndPoint = firebaseEndPoint;
  }

  Function get fromJsonFunction => _$FirebaseStorageDataEndPointFromJson;
  factory FirebaseStorageDataEndPoint.fromJson(Map<String, dynamic> json) =>
      _$FirebaseStorageDataEndPointFromJson(json);
  Map<String, dynamic> toJson() => _$FirebaseStorageDataEndPointToJson(this);
}

/// The authentication methods in Firebase, used in
/// [FirebaseEndPoint.firebaseAuthenticationMethod].
///
/// Only [GOOGLE] and [PASSWORD] are implemented by [FirebaseDataManager].
class FireBaseAuthenticationMethods {
  static const String PASSWORD = "password";
  static const String GOOGLE = "google";
  static const String FACEBOOK = "facebook";
  static const String TWITTER = "twitter";
  static const String GITHUB = "github";
  static const String PHONE = "phone";
  static const String ANONYMOUSLY = "anonymously";
  static const String CUSTOM = "custom";
}
