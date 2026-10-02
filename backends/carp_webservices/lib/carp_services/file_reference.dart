part of 'carp_services.dart';

/// A reference to one file in the CAWS file storage of a study.
///
/// Obtained from [CarpService.getFileStorageReference] or
/// [CarpService.getFileStorageReferenceByName]. Used to:
/// - upload a local [File] to CAWS ([upload])
/// - download a CAWS file to a local [File] ([download])
/// - get the [CarpFileResponse] metadata of the file ([get])
/// - delete the file in CAWS ([delete])
///
/// [download], [get] and [delete] need a known [id]; [upload] sets it.
class FileStorageReference extends CarpReference {
  final String _studyId;

  /// The CARP server-side ID of this file.
  ///
  /// -1 if unknown or referencing a file not uploaded yet.
  int id = -1;

  /// The id of the study this file belongs to.
  String get studyId => _studyId;

  FileStorageReference._(CarpService service, this._studyId, [this.id = -1])
    : super._(service);

  /// The URL for the file end point for this [FileStorageReference].
  String get fileEndpointUri =>
      "${service.app.uri.toString()}/api/studies/$studyId/files";

  /// Starts an upload of [file] with optional [metadata] and returns the
  /// running [FileUploadTask].
  ///
  /// The [file] must exist. On success, [id] is set to the server-side ID.
  FileUploadTask upload(File file, [Map<String, String>? metadata]) {
    assert(file.existsSync());
    final FileUploadTask task = FileUploadTask._(this, file, metadata);
    task._start();
    return task;
  }

  /// Starts a download of this file into the local [file] and returns the
  /// running [FileDownloadTask].
  FileDownloadTask download(File file) {
    assert(id > 0);
    final FileDownloadTask task = FileDownloadTask._(this, file);
    task._start();
    return task;
  }

  /// Gets the metadata of this file from CAWS.
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
///
/// Not used by this package; [FileStorageReference.upload] takes a plain
/// `Map<String, String>` instead.
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
