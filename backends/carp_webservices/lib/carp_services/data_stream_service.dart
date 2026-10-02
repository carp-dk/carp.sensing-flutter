part of 'carp_services.dart';

/// A CARP Core [DataStreamService] that talks to CAWS.
///
/// Uploads collected [Measurement]s to CAWS as [DataStreamBatch]es, and reads
/// them back. Data streams are opened, closed and removed on the server, not
/// by the client.
///
/// Key points:
///  * A singleton; call [configure] (or [configureFrom]) before use.
///  * [appendToDataStreams] gzips the payload by default and posts it to the
///    [DATA_STREAM_ZIP_ENDPOINT_NAME] endpoint.
///  * [openDataStreams], [closeDataStreams] and [removeDataStreams] always
///    throw a [CarpServiceException].
///  * [dataStream] returns a [DataStreamReference] for one study deployment.
///
/// Apps rarely call it directly: the `carp_backend` package uploads data
/// through this service when the protocol uses a CAWS data endpoint.
class CarpDataStreamService extends CarpBaseService
    implements DataStreamService {
  /// The default (uncompressed) RPC endpoint name.
  static const String DATA_STREAM_ENDPOINT_NAME = "data-stream-service";

  /// The endpoint name for gzip-compressed uploads.
  static const String DATA_STREAM_ZIP_ENDPOINT_NAME = "data-stream-service-zip";

  /// The endpoint name used by [getDataStreamBatchesByTime].
  static const String DATA_STREAM_QUERY_BY_TIME_ENDPOINT_NAME =
      "data-stream-service/query-by-time";

  static final CarpDataStreamService _instance = CarpDataStreamService._();

  CarpDataStreamService._();

  /// Returns the singleton default instance of the [CarpDataStreamService].
  /// Before this instance can be used, it must be configured using the
  /// [configure] method.
  factory CarpDataStreamService() => _instance;

  @override
  String get rpcEndpointName => DATA_STREAM_ENDPOINT_NAME;

  /// Gets a [DataStreamReference] for a [studyDeploymentId].
  DataStreamReference dataStream(String studyDeploymentId) =>
      DataStreamReference._(this, studyDeploymentId);

  /// Gets a [DataStreamReference] for a [studyDeploymentId].
  @Deprecated('Use dataStream() instead.')
  DataStreamReference stream(String studyDeploymentId) =>
      dataStream(studyDeploymentId);

  @override
  Future<void> openDataStreams(DataStreamsConfiguration configuration) async =>
      throw CarpServiceException(
        'Opening data streams is not supported from the client side.',
      );

  /// Appends a [batch] of data to the data streams of the study deployment
  /// with [studyDeploymentId].
  ///
  /// If [compress] is true (default), the JSON payload is gzipped before
  /// upload.
  @override
  Future<void> appendToDataStreams(
    String studyDeploymentId,
    List<DataStreamBatch> batch, {
    bool compress = true,
  }) async {
    final payload = AppendToDataStreams(studyDeploymentId, batch);

    if (compress) {
      // compress the payload and POST the byte stream to the zip endpoint
      _endpointName = DATA_STREAM_ZIP_ENDPOINT_NAME;
      var response = await _post(
        Uri.encodeFull(rpcEndpointUri),
        body: zipJson(payload.toJson()),
      );
      // we do not expect any response content but handle exceptions
      _handleResponse(response);
    } else {
      await _rpc(payload, DATA_STREAM_ENDPOINT_NAME);
    }
  }

  @override
  Future<List<DataStreamBatch>> getDataStream(
    DataStreamId dataStream,
    int fromSequenceId, [
    int? toSequenceIdInclusive,
  ]) async {
    dynamic responseJson = await _rpc(
      GetDataStream(dataStream, fromSequenceId, toSequenceIdInclusive),
    );

    return _toDataStreamBatches(responseJson);
  }

  /// Query [dataStream] by its local update time window instead of a
  /// sequence-id range.
  ///
  /// Returns all data points in [dataStream] whose local `updated_at`
  /// timestamp falls within the inclusive [from]-[to] window, as one
  /// [DataStreamBatch] per contiguous run of measurements - a new batch
  /// starts wherever the sequence was interrupted.
  ///
  /// This is a CAWS-specific endpoint (not part of the core
  /// [DataStreamService] interface) and mirrors [getDataStream], but is
  /// useful when the local upload time is more relevant than the sequence id
  /// (e.g., incremental sync of recently uploaded data).
  Future<List<DataStreamBatch>> getDataStreamBatchesByTime(
    DataStreamId dataStream,
    DateTime from,
    DateTime to,
  ) async {
    final url =
        "${app.uri}/api/$DATA_STREAM_QUERY_BY_TIME_ENDPOINT_NAME"
        "?from=${from.toUtc().toIso8601String()}&to=${to.toUtc().toIso8601String()}";

    final response = await _post(
      Uri.encodeFull(url),
      body: json.encode(dataStream.toJson()),
    );

    return _toDataStreamBatches(_handleResponse(response));
  }

  /// Both data stream queries return a JSON list of [DataStreamBatch].
  List<DataStreamBatch> _toDataStreamBatches(dynamic responseJson) =>
      (responseJson as List<dynamic>)
          .map(
            (batch) => DataStreamBatch.fromJson(batch as Map<String, dynamic>),
          )
          .toList();

  @override
  Future<void> closeDataStreams(List<String> studyDeploymentIds) async =>
      throw CarpServiceException(
        'Closing data streams is not supported from the client side.',
      );

  @override
  Future<Set<String>> removeDataStreams(
    List<String> studyDeploymentIds,
  ) async => throw CarpServiceException(
    'Removing data streams is not supported from the client side.',
  );
}
