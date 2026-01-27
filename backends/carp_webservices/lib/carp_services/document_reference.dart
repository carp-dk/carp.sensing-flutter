/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A [DocumentReference] refers to a document in a CARP collection
/// and can be used to write, read, or delete this document.
///
/// The document with the referenced id may or may not exist.
/// If the document does not yet exist, it will be created.
/// If the collection does not yet exist, it will be created.
///
/// A [DocumentReference] can also be used to create a [CollectionReference]
/// to a sub-collection.
class DocumentReference extends CarpReference {
  final String _studyId;
  int? _id;
  String _path = '';

  DocumentReference._id(CarpService service, this._studyId, this._id)
    : super._(service);

  DocumentReference._path(CarpService service, this._studyId, this._path)
    : super._(service);

  /// The id of the study for this document.
  String get studyId => _studyId;

  /// The unique id of this document.
  /// Returns `null` if the id is unknown.
  int? get id => _id;

  /// The name of this document.
  String get name => _path.split('/').last;

  /// The path to this document
  String get path => _path;

  /// The full CARP Web Service (CAWS) path to this document.
  ///
  /// If the id of this document is known, use the `documents` CARP endpoint,
  /// otherwise use the `collections` endpoint.
  String get cawsPath => (_id != null)
      ? "/api/studies/$studyId/documents/$id"
      : "/api/studies/$studyId/collections/$path";

  /// The full URI for the document endpoint for this document.
  String get documentUri => "${service.app.uri.toString()}$cawsPath";

  /// Writes to the document referred to by this [DocumentReference].
  ///
  /// If the document does not yet exist, it will be created.
  /// If the collection does not yet exist, it will be created.
  /// Returns a [DocumentSnapshot] with the ID generated at the server side.
  Future<DocumentSnapshot> setData(Map<String, dynamic> data) async {
    // Remember that the CARP collection service generated the ID and returns it in a POST.

    // If this document does not already exist on the server (i.e., have an ID), then create it
    if (id == null) {
      final response = await service._post(
        documentUri,
        body: json.encode(data),
      );

      Map<String, dynamic> responseJson =
          service._handleResponse(response) as Map<String, dynamic>;
      return DocumentSnapshot._(path, responseJson);
    } else {
      return updateData(data);
    }
  }

  /// Updates fields in the document referred to by this [DocumentReference].
  ///
  /// If no document exists yet, the update will fail.
  Future<DocumentSnapshot> updateData(Map<String, dynamic> data) async {
    // if we don't have the document ID, get it first.
    if (id == null) _id = (await get())?.id;

    // early out if this document does not exist
    if (_id == null) {
      throw CarpServiceException('No valid document id found.');
    }

    Map<String, dynamic> payload = {'name': name, 'data': data};

    final response = await service._put(
      documentUri,
      body: json.encode(payload),
    );

    Map<String, dynamic> responseJson =
        service._handleResponse(response) as Map<String, dynamic>;
    return DocumentSnapshot._(path, responseJson);
  }

  /// Renames the document referred to by this [DocumentReference].
  @Deprecated('Documents cannot be renamed in CAWS.')
  Future<DocumentSnapshot> rename(String name) async {
    assert(name.isNotEmpty, 'Document path names cannot be empty.');
    assert(
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name),
      'Document name can only contain alphanumeric, hyphen (-), and underscore (_) characters.',
    );

    // if we don't have the document ID, get it first.
    if (id == null) _id = (await get())?.id;
    if (_id == null) {
      // early out if this document does not exist
      throw CarpServiceException('No valid document id found.');
    }

    Map<String, dynamic> payload = {'name': name};
    final response = await service._put(
      Uri.encodeFull(documentUri),
      body: json.encode(payload),
    );

    Map<String, dynamic> responseJson =
        service._handleResponse(response) as Map<String, dynamic>;
    return DocumentSnapshot._(path, responseJson);
  }

  /// Reads the document referenced by this [DocumentReference].
  ///
  /// If no document exists, the read will return `null`.
  Future<DocumentSnapshot?> get() async {
    final response = await service._get(documentUri);

    try {
      Map<String, dynamic> responseJson =
          service._handleResponse(response) as Map<String, dynamic>;

      _id = responseJson['id'] as int;
      return DocumentSnapshot._(path, responseJson);
    } on CarpNotFoundException catch (error) {
      warning("$runtimeType - Document ´$id´not found: $error");
      return null;
    }
  }

  /// Deletes the document referred to by this [DocumentReference].
  Future<void> delete() async {
    // if we don't have the document ID, get it first.
    if (id == null) _id = (await get())?.id;
    if (_id == null) return; // early out if this document does not exist

    await service
        ._delete(documentUri)
        // we don't need the response for anything, but check for exceptions
        .then((response) => service._handleResponse(response));
  }

  /// Returns the reference of a collection contained inside of this document.
  CollectionReference collection(String name) =>
      (service as CarpService).collection("$path/$name", studyId: studyId);

  // TODO - this is deprecated and not working for now.
  //  /// Fetch the list of collections (names) in this collection.
  //  Future<List<String>> get collections async {
  //    final rest_headers = await headers;
  //
  //    // GET the list of collections from the CARP web service
  //    // Note that it seems like we can only get a list of collections at the root of the CARP web service, i.e. when [path] == ""
  //    http.Response response = await http.get(Uri.encodeFull(collectionUri), headers: rest_headers);
  //
  //    int httpStatusCode = response.statusCode;
  //
  //    switch (httpStatusCode) {
  //      case HttpStatus.ok:
  //        {
  //          List<dynamic> server_list = json.decode(response.body);
  //          List<String> collections = new List<String>();
  //          server_list.forEach((c) => collections.add(c.toString()));
  //          return collections;
  //        }
  //      default:
  //        // All other cases are treated as an error.
  //        {
  //          Map<String, dynamic> responseJson = json.decode(response.body);
  //          final String error = responseJson["error"];
  //          final String description = responseJson["message"];
  //          throw CarpServiceException(error,
  //              description: description, httpStatus: HTTPStatus(httpStatusCode, response.reasonPhrase));
  //        }
  //    }
  //  }

  @override
  String toString() => 'DocumentReference - id: $id, path: $path';
}

/// A [DocumentSnapshot] contains data read from a collection in the CARP web service
///
/// The data can be extracted with the [data] property or by using subscript
/// syntax to access a specific field.
class DocumentSnapshot {
  DocumentSnapshot._(this._path, this._snapshot);

  final String _path;
  final Map<String, dynamic> _snapshot;

  /// The full data snapshot
  Map<String, dynamic> get snapshot => _snapshot;

  /// The full path to this document
  String get path => _path;

  /// The ID of the snapshot's document
  int get id => _snapshot['id'] as int;

  /// The name of the snapshot's document
  String get name => _snapshot['name'].toString();

  /// The id of the collection this document belongs to
  int get collectionId => _snapshot['collection_id'] as int;

  /// The id of the user who created this document
  String get createdByUserId => _snapshot['created_by_user_id'].toString();

  /// The timestamp of creation of this document
  DateTime get createdAt => DateTime.parse(_snapshot['created_at'].toString());

  /// The timestamp of latest update of this document
  DateTime get updatedAt => DateTime.parse(_snapshot['updated_at'].toString());

  /// The list of collections nested inside this document.
  List<String?> get collections {
    List<String?> collections = [];

    if (_snapshot['collections'] != null) {
      List<dynamic> items = _snapshot['collections'] as List<dynamic>;
      for (var item in items) {
        String? key = item["name"].toString();
        collections.add(key);
      }
    }
    return collections;
  }

  /// Contains all the data of this snapshot
  Map<String, dynamic> get data => _snapshot['data'] != null
      ? _snapshot['data'] as Map<String, dynamic>
      : {};

  /// Reads individual data values from the snapshot
  dynamic operator [](String key) => data[key];

  /// Returns `true` if the document exists.
  // bool get exists => data != null;

  @override
  String toString() =>
      "$runtimeType - id: $id, name: $name, path: $path, size: ${data.length}";
}
