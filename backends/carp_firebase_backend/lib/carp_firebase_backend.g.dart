// GENERATED CODE - DO NOT MODIFY BY HAND

part of carp_firebase_backend;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FirebaseEndPoint _$FirebaseEndPointFromJson(Map<String, dynamic> json) {
  return FirebaseEndPoint(
    name: json['name'] as String,
    uri: json['uri'] as String,
    firebaseAuthenticationMethod:
        json['firebase_authentication_method'] as String,
    email: json['email'] as String?,
    password: json['password'] as String?,
    token: json['token'] as String?,
    projectID: json['project_i_d'] as String,
    webAPIKey: json['web_a_p_i_key'] as String,
    androidGoogleAppID: json['android_google_app_i_d'] as String,
    iOSGoogleAppID: json['i_o_s_google_app_i_d'] as String,
    gcmSenderID: json['gcm_sender_i_d'] as String,
  );
}

Map<String, dynamic> _$FirebaseEndPointToJson(FirebaseEndPoint instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'uri': instance.uri,
    'firebase_authentication_method': instance.firebaseAuthenticationMethod,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('email', instance.email);
  writeNotNull('password', instance.password);
  writeNotNull('token', instance.token);
  val['project_i_d'] = instance.projectID;
  val['web_a_p_i_key'] = instance.webAPIKey;
  val['android_google_app_i_d'] = instance.androidGoogleAppID;
  val['i_o_s_google_app_i_d'] = instance.iOSGoogleAppID;
  val['gcm_sender_i_d'] = instance.gcmSenderID;
  return val;
}

FirebaseDatabaseDataEndPoint _$FirebaseDatabaseDataEndPointFromJson(
  Map<String, dynamic> json,
) {
  return FirebaseDatabaseDataEndPoint(
      FirebaseEndPoint.fromJson(
        json['firebase_end_point'] as Map<String, dynamic>,
      ),
      collection: json['collection'] as String,
    )
    ..$type = json[r'$type'] as String?
    ..type = json['type'] as String
    ..dataFormat = json['data_format'] as String;
}

Map<String, dynamic> _$FirebaseDatabaseDataEndPointToJson(
  FirebaseDatabaseDataEndPoint instance,
) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', instance.$type);
  val['type'] = instance.type;
  val['data_format'] = instance.dataFormat;
  val['firebase_end_point'] = instance.firebaseEndPoint;
  val['collection'] = instance.collection;
  return val;
}

FirebaseStorageDataEndPoint _$FirebaseStorageDataEndPointFromJson(
  Map<String, dynamic> json,
) {
  return FirebaseStorageDataEndPoint(
      FirebaseEndPoint.fromJson(
        json['firebase_end_point'] as Map<String, dynamic>,
      ),
      path: json['path'] as String,
      bufferSize: json['buffer_size'],
      zip: json['zip'],
      encrypt: json['encrypt'],
      publicKey: json['public_key'],
    )
    ..$type = json[r'$type'] as String?
    ..type = json['type'] as String
    ..dataFormat = json['data_format'] as String;
}

Map<String, dynamic> _$FirebaseStorageDataEndPointToJson(
  FirebaseStorageDataEndPoint instance,
) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(r'$type', instance.$type);
  val['type'] = instance.type;
  val['data_format'] = instance.dataFormat;
  val['buffer_size'] = instance.bufferSize;
  val['zip'] = instance.zip;
  val['encrypt'] = instance.encrypt;
  writeNotNull('public_key', instance.publicKey);
  val['firebase_end_point'] = instance.firebaseEndPoint;
  val['path'] = instance.path;
  return val;
}
