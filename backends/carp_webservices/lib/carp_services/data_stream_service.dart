part of 'carp_services.dart';

/// A [DataStreamService] that talks to the CARP Web Services.
class CarpDataStreamService extends CarpBaseService
    implements DataStreamService {
  static const String DATA_STREAM_ENDPOINT_NAME = "data-stream-service";
  static const String DATA_STREAM_ZIP_ENDPOINT_NAME = "data-stream-service-zip";

  static final CarpDataStreamService _instance = CarpDataStreamService._();

  CarpDataStreamService._();

  /// Returns the singleton default instance of the [CarpDataStreamService].
  /// Before this instance can be used, it must be configured using the
  /// [configure] method.
  factory CarpDataStreamService() => _instance;

  @override
  String get rpcEndpointName => DATA_STREAM_ENDPOINT_NAME;

  /// Gets a [DataStreamReference] for a [studyDeploymentId].
  DataStreamReference stream(String studyDeploymentId) =>
      DataStreamReference._(this, studyDeploymentId);

  @override
  Future<void> openDataStreams(DataStreamsConfiguration configuration) async =>
      throw CarpServiceException(
        'Opening data streams is not supported from the client side.',
      );

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

    // we expect a list of DataStreamBatch in the response
    List<dynamic> batches = responseJson as List<dynamic>;

    return (batches.isEmpty)
        ? []
        : batches
              .map(
                (batch) =>
                    DataStreamBatch.fromJson(batch as Map<String, dynamic>),
              )
              .toList();
  }

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
