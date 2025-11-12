part of 'carp_services.dart';

/// Provide a file endpoint reference to a CARP web service. Used to:
/// - upload a local [File] to the CARP server
/// - download a CARP file to a local [File]
/// - get a [CarpFileResponse] file object from the CARP sever
/// - get all file object as a list of [CarpFileResponse]s from the CARP sever
/// - delete a file at CARP
class FileStorageReference extends CarpReference {
  final String _studyId;

  /// The CARP server-side ID of this file.
  ///
  /// -1 if unknown or referencing a file not uploaded yet.
  int id = -1;

  /// The id of the study for this document.
  String get studyId => _studyId;

  FileStorageReference._(CarpService service, this._studyId, [this.id = -1])
    : super._(service);

  /// The URL for the file end point for this [FileStorageReference].
  String get fileEndpointUri =>
      "${service.app.uri.toString()}/api/studies/$studyId/files";

  /// Asynchronously uploads a file to the currently specified
  /// [FileStorageReference], with optional [metadata].
  FileUploadTask upload(File file, [Map<String, String>? metadata]) {
    assert(file.existsSync());
    final FileUploadTask task = FileUploadTask._(this, file, metadata);
    task._start();
    return task;
  }

  /// Asynchronously downloads the object at this [FileStorageReference]
  /// to a specified local file.
  FileDownloadTask download(File file) {
    assert(id > 0);
    final FileDownloadTask task = FileDownloadTask._(this, file);
    task._start();
    return task;
  }

  /// Get the file object at the server for this [FileStorageReference].
  Future<CarpFileResponse> get() async {
    assert(id > 0);
    final String url = "$fileEndpointUri/$id";

    final response = await service._get(url);

    Map<String, dynamic> responseJson =
        service._handleResponse(response) as Map<String, dynamic>;
    return CarpFileResponse._(responseJson);
  }

  /// Deletes the file at this [FileStorageReference].
  Future<void> delete() async {
    assert(id > 0);
    final String url = "$fileEndpointUri/$id";

    await service
        ._delete(url)
        .then((response) => service._handleResponse(response));
  }
}

// TODO - This [FileMetadata] class is not used currently -- only a 'flat' Map is used.
/// Metadata for a [FileStorageReference]. Metadata stores default attributes
/// such as size and content type. Also allow for storing custom metadata.
class FileMetadata {
  FileMetadata({
    this.cacheControl,
    this.contentDisposition,
    this.contentEncoding,
    this.contentLanguage,
    this.contentType,
    Map<String, String>? customMetadata,
  }) : carpServiceName = null,
       path = null,
       name = null,
       sizeBytes = null,
       creationTimeMillis = null,
       updatedTimeMillis = null,
       md5Hash = null,
       customMetadata = (customMetadata == null)
           ? null
           : Map.unmodifiable(customMetadata);

  // FileMetadata._fromMap(Map<dynamic, dynamic> map)
  //     : carpServiceName = map['carpServiceName'],
  //       path = map['path'],
  //       name = map['name'],
  //       sizeBytes = map['sizeBytes'],
  //       creationTimeMillis = map['creationTimeMillis'],
  //       updatedTimeMillis = map['updatedTimeMillis'],
  //       md5Hash = map['md5Hash'],
  //       cacheControl = map['cacheControl'],
  //       contentDisposition = map['contentDisposition'],
  //       contentLanguage = map['contentLanguage'],
  //       contentType = map['contentType'],
  //       contentEncoding = map['contentEncoding'],
  //       customMetadata = map['customMetadata'] == null
  //           ? null
  //           : Map.unmodifiable(map['customMetadata'].cast<String, String>());

  /// The owning CARP Web Service name the [FileStorageReference].
  final String? carpServiceName;

  /// The path of the [FileStorageReference] object.
  final String? path;

  /// A simple name of the [FileStorageReference] object.
  final String? name;

  /// The stored Size in bytes of the [FileStorageReference] object.
  final int? sizeBytes;

  /// The time the [FileStorageReference] was created in milliseconds since the epoch.
  final int? creationTimeMillis;

  /// The time the [FileStorageReference] was last updated in milliseconds since the epoch.
  final int? updatedTimeMillis;

  /// The MD5Hash of the [FileStorageReference] object.
  final String? md5Hash;

  /// The Cache Control setting of the [FileStorageReference].
  final String? cacheControl;

  /// The content disposition of the [FileStorageReference].
  final String? contentDisposition;

  /// The content encoding for the [FileStorageReference].
  final String? contentEncoding;

  /// The content language for the StorageReference, specified as a 2-letter
  /// lowercase language code defined by ISO 639-1.
  final String? contentLanguage;

  /// The content type (MIME type) of the [FileStorageReference].
  final String? contentType;

  /// An unmodifiable map with custom metadata for the [FileStorageReference].
  final Map<String, String>? customMetadata;
}
