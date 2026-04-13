/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_services.dart';

/// Provide a collection reference to a CARP web service.
///
/// The Collections endpoint allows you to store and query custom documents to
/// suit your specific application's needs.
///
/// Note that the collection / document structure is like this:
///
/// `collection/document/collection/document/...`
///
/// I.e., that a collection holds a list of documents, which each can hold a list of collections, etc.
/// For example, the following
///
/// `activities/running/geopositions/pos_1`
///
/// is a reference to the geoposition document `pos_1` in the collection `geopositions` in the document `running`
/// in the collection `activities`.
class CollectionReference extends CarpReference {
  final String _studyId;
  int? _id;
  String _path;

  /// Creates a [CollectionReference] based on the path to the
  /// collection, relative to the root of the web service.
  ///
  /// Note that [path] should be relative and NOT start with `/`.
  /// For example; `activities/running/geopositions`
  CollectionReference._(CarpBaseService service, this._studyId, this._path)
    : super._(service) {
    assert(!(_path.startsWith('/')) || _path.isEmpty);
  }

  /// The id of the study for this document.
  String get studyId => _studyId;

  /// ID of the referenced collection.
  ///
  /// Returns null if this collection is not available on the server.
  /// It might not have been created yet, or has been deleted.
  int? get id => _id;

  /// The name of the referenced collection.
  String get name => path.split('/').last;

  /// Returns the path of this collection (relative to the root of the web service).
  String get path => _path;

  /// The full CARP Web Service (CAWS) path to this collection.
  String get cawsPath => '/api/studies/$studyId/collections/$path';

  /// The full URI for the collection endpoint for this [CollectionReference].
  String get collectionUri => "${service.app.uri.toString()}$cawsPath";

  /// The full URI for the collection endpoint for this [CollectionReference] by its unique [id].
  String get collectionUriByID =>
      '${service.app.uri.toString()}/api/studies/$studyId/collections/id/$id';

  /// Reads the collection referenced by this [CollectionReference] from the
  /// server.
  ///
  /// If no collection exists on the server (yet), this local [CollectionReference]
  /// is returned.
  Future<CollectionReference> get() async {
    final response = await service._get(collectionUri);
    Map<String, dynamic> responseJson =
        service._handleResponse(response) as Map<String, dynamic>;

    return this
      .._id = responseJson['id'] as int
      .._path = responseJson['name'].toString();
  }

  /// Get the documents in this collection.
  Future<List<DocumentSnapshot>> get documents async {
    final response = await service._get(collectionUri);

    // we expect a collection map with a list of documents in the response
    Map<String, dynamic> responseJson =
        service._handleResponse(response) as Map<String, dynamic>;
    List<dynamic> documentsJson = responseJson['documents'] as List<dynamic>;

    List<DocumentSnapshot> documents = [];
    for (var documentJson in documentsJson) {
      if (documentJson is Map<String, dynamic>) {
        final key = documentJson['name'].toString();
        documents.add(DocumentSnapshot._('$path/$key', documentJson));
      }
    }
    return documents;
  }

  /// Returns a [DocumentReference] with the provided name in this collection.
  ///
  /// If no [name] is provided, an auto-generated name is used.
  DocumentReference document([String? name]) {
    String documentPath;
    if (name == null) {
      final key = PushIdGenerator.generatePushChildName();
      documentPath = '$path/$key';
    } else {
      documentPath = '$path/$name';
    }

    return DocumentReference._path(
      service as CarpService,
      studyId,
      documentPath,
    );
  }

  /// Add a data document to this collection and returns a [DocumentReference]
  /// to this document.
  ///
  /// If no [name] is provided, an auto-generated name is used.
  /// If no [data] is provided, this can be set later using the [DocumentReference.setData()]
  /// method.
  Future<DocumentReference> add([
    String? name,
    Map<String, dynamic>? data,
  ]) async {
    final newDocument = document(name);
    if (data != null) await newDocument.setData(data);
    return newDocument;
  }

  /// Rename this collection.
  Future<void> rename(String newName) async {
    // PUT the new name of this collection to the CARP web service
    final response = await service._put(
      collectionUriByID,
      body: '{"name":"$newName"}',
    );

    // we don't need the response for anything, but check for errors
    service._handleResponse(response);

    // renaming path, i.e. the last part of the path
    int start = _path.length - _path.split('/').last.length;
    _path = _path.replaceRange(start, _path.length, newName);
  }

  /// Deletes the collection referred to by this [CollectionReference].
  Future<void> delete() async {
    final response = await service._delete(collectionUriByID);

    // we don't need the response for anything, but check for errors
    service._handleResponse(response);
    _id = -1;
  }

  @override
  String toString() => "CollectionReference - id: '$id', path: '$path'";
}
