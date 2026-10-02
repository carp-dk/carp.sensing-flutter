part of 'carp_services.dart';

/// Gives access to the CAWS-only ("non-core") endpoints: files, documents
/// and collections.
///
/// Use it to store app resources (like JSON documents) or upload files for a
/// study. It also exposes the legacy informed consent and data point
/// endpoints, which are deprecated in CAWS.
///
/// Key points:
///  * The default constructor returns a shared instance; [CarpService.instance]
///    creates a separately configured one. Call [configure] before use. Other
///    services often copy its setup via [CarpBaseService.configureFrom]. Its
///    requests still use the default [CarpAuthService] for authentication.
///  * Most methods take an optional `studyId`; if omitted, the study ID of
///    [study] is used, or a [CarpServiceException] is thrown.
///  * Returns references ([FileStorageReference], [DocumentReference],
///    [CollectionReference]) that do the actual reads and writes.
///
/// The CARP Core services are reached through [CarpDeploymentService],
/// [CarpProtocolService], [CarpParticipationService] and
/// [CarpDataStreamService] instead.
///
/// ```dart
/// CarpService().configure(app, study);
/// final doc = CarpService().collection('activities').document('running');
/// await doc.setData({'distance': 5.2});
/// ```
class CarpService extends CarpBaseService {
  static final CarpService _instance = CarpService._();
  CarpService._();

  /// Returns the singleton default instance of the [CarpService].
  /// Before this instance can be used, it must be configured using the
  /// [configure] method.
  factory CarpService() => _instance;

  /// Creates a new, separate instance (not the singleton).
  CarpService.instance() : this._();

  // RPC is not used in the CarpService endpoints which are named differently.
  @override
  String get rpcEndpointName => throw UnimplementedError();

  // --------------------------------------------------------------------------
  // FILES
  // --------------------------------------------------------------------------

  /// The URL of the file endpoint for the study with id [studyId].
  String getFileEndpointUri([String? studyId]) =>
      "${app.uri.toString()}/api/studies/${getStudyId(studyId)}/files";

  /// Gets a [FileStorageReference] to the file with [id] in the study with
  /// id [studyId].
  ///
  /// Omit [id] (defaults to -1) for a file that is not uploaded yet.
  /// [studyId] can be omitted if specified as part of this service's [study].
  FileStorageReference getFileStorageReference([
    int id = -1,
    String? studyId,
  ]) => FileStorageReference._(this, getStudyId(studyId), id);

  /// Gets a [FileStorageReference] to the file with the original name [name]
  /// in the study with id [studyId].
  ///
  /// [studyId] can be omitted if specified as part of this service's [study].
  ///
  /// If more than one file with the same name exists, the first one is returned.
  /// If no files with that name exists, `null` is returned.
  Future<FileStorageReference?> getFileStorageReferenceByName(
    String name, {
    String? studyId,
  }) async {
    final List<CarpFileResponse> files = await queryFiles(
      'original_name==$name',
      studyId: getStudyId(studyId),
    );

    return (files.isNotEmpty)
        ? FileStorageReference._(this, getStudyId(studyId), files[0].id)
        : null;
  }

  /// Gets all file objects in the study.
  ///
  /// [studyId] can be omitted if specified as part of this service's [study].
  Future<List<CarpFileResponse>> getAllFiles([String? studyId]) async =>
      await queryFiles(null, studyId: studyId);

  /// Returns file objects in the study based on an RSQL [query], like
  /// `original_name==notes.txt`.
  ///
  /// [studyId] can be omitted if specified as part of this service's [study].
  /// If [query] is null, all file objects are returned.
  Future<List<CarpFileResponse>> queryFiles(
    String? query, {
    String? studyId,
  }) async {
    final String url = (query != null)
        ? "${getFileEndpointUri(studyId)}?query=$query"
        : getFileEndpointUri(studyId);

    http.Response response = await _get(Uri.encodeFull(url));

    // we expect a list of files in the response
    List<dynamic> list = _handleResponse(response) as List<dynamic>;
    List<CarpFileResponse> fileList = [];
    for (var element in list) {
      fileList.add(CarpFileResponse._(element as Map<String, dynamic>));
    }
    return fileList;
  }

  // --------------------------------------------------------------------------
  // DOCUMENTS & COLLECTIONS
  // --------------------------------------------------------------------------

  /// Gets a [DocumentReference] for the specified unique [id] for study with id [studyId].
  ///
  /// [studyId] can be omitted if specified as part of this service's [study].
  DocumentReference documentById(int id, {String? studyId}) =>
      DocumentReference._id(this, getStudyId(studyId), id);

  /// Gets a [DocumentReference] for the specified [path], like
  /// `activities/running`.
  ///
  /// [studyId] can be omitted if specified as part of this service's [study].
  DocumentReference document(String path, {String? studyId}) =>
      DocumentReference._path(this, getStudyId(studyId), path);

  /// The URL of the document endpoint for the study with id [studyId].
  ///
  /// [studyId] can be omitted if specified as part of this service's [study].
  String getDocumentEndpointUri([String? studyId]) =>
      "${app.uri.toString()}/api/studies/${getStudyId(studyId)}/documents";

  /// Gets a list of documents based on a [query].
  ///
  /// The [query] string uses the RSQL query language for RESTful APIs.
  /// See the [RSQL Documentation](https://developer.here.com/documentation/data-client-library/dev_guide/client/rsql.html).
  ///
  /// Can only be accessed by users who are authenticated as researchers.
  Future<List<DocumentSnapshot>> documentsByQuery(
    String query, {
    String? studyId,
  }) async {
    // GET the list of documents in this collection from the CARP web service
    http.Response response = await _get(
      Uri.encodeFull('${getDocumentEndpointUri(studyId)}?query=$query'),
    );

    // we expect a list of documents in the response
    List<dynamic> documentsJson = _handleResponse(response) as List<dynamic>;
    List<DocumentSnapshot> documents = [];
    for (var item in documentsJson) {
      Map<String, dynamic> documentJson = item as Map<String, dynamic>;
      String key = documentJson["name"].toString();
      documents.add(DocumentSnapshot._(key, documentJson));
    }
    return documents;
  }

  /// Gets all documents for the study with id [studyId].
  ///
  /// Can only be accessed by users who are authenticated as researchers.
  ///
  /// Note that this might return a very long list of documents and the
  /// request may time out.
  Future<List<DocumentSnapshot>> documents([String? studyId]) async {
    http.Response response = await _get(
      Uri.encodeFull(getDocumentEndpointUri(studyId)),
    );

    // we expect a list of documents in the response
    List<dynamic> documentsJson = _handleResponse(response) as List<dynamic>;
    List<DocumentSnapshot> documents = [];
    for (var item in documentsJson) {
      Map<String, dynamic> documentJson = item as Map<String, dynamic>;
      String key = documentJson["name"].toString();
      documents.add(DocumentSnapshot._(key, documentJson));
    }
    return documents;
  }

  /// Gets a [CollectionReference] for the [path], like
  /// `activities/running/geopositions`.
  ///
  /// [studyId] can be omitted if specified as part of this service's [study].
  CollectionReference collection(String path, {String? studyId}) =>
      CollectionReference._(this, getStudyId(studyId), path);

  // --------------------------------------------------------------------------
  // CONSENT DOCUMENT
  // --------------------------------------------------------------------------

  /// The URL of the legacy consent document endpoint for [studyDeploymentId].
  String getConsentDocumentEndpointUri([String? studyDeploymentId]) =>
      "${app.uri.toString()}/api/deployments/${getStudyDeploymentId(studyDeploymentId)}/consent-documents";

  /// Creates a new (signed) consent [document].
  ///
  /// Returns the created [ConsentDocument] if the document is uploaded correctly.
  ///
  /// If [studyDeploymentId] is specified use this, otherwise use the study
  /// deployment id from [CarpService.study].
  @Deprecated(
    'The Informed Consent endpoints are deprecated in CAWS. '
    'Informed Consent is uploaded as [InformedConsentInput] participant input '
    'data using a [ParticipationReference].',
  )
  Future<ConsentDocument> createConsentDocument(
    Map<String, dynamic> document, {
    String? studyDeploymentId,
  }) async {
    http.Response response = await _post(
      getConsentDocumentEndpointUri(studyDeploymentId),
      body: json.encode(document),
    );

    return ConsentDocument._(_handleResponse(response) as Map<String, dynamic>);
  }

  /// Gets a previously uploaded (signed) consent document with document [id].
  ///
  /// If [studyDeploymentId] is specified use this, otherwise use the study
  /// deployment id from [CarpService.study].
  @Deprecated(
    'The Informed Consent endpoints are deprecated in CAWS. '
    'Informed Consent is uploaded as [InformedConsentInput] participant input '
    'data using a [ParticipationReference].',
  )
  Future<ConsentDocument> getConsentDocument(
    int id, {
    String? studyDeploymentId,
  }) async {
    String url = "${getConsentDocumentEndpointUri(studyDeploymentId)}/$id";
    http.Response response = await _get(Uri.encodeFull(url));
    return ConsentDocument._(_handleResponse(response) as Map<String, dynamic>);
  }

  // --------------------------------------------------------------------------
  // DATA POINT
  // --------------------------------------------------------------------------

  /// Creates a [DataPointReference] for the study deployment with
  /// [studyDeploymentId], or the deployment of [study] if omitted.
  @Deprecated(
    'The DataPoint endpoints is deprecated in CAWS. '
    'Data should be uploaded using the CARP-Core Data Stream endpoint.',
  )
  DataPointReference dataPointReference([String? studyDeploymentId]) =>
      DataPointReference._(this, getStudyDeploymentId(studyDeploymentId));
}
