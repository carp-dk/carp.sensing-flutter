/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_services.dart';

/// Provides a reference to the data stream endpoint in a CARP web service.
///
/// Used to:
/// - append data to the stream.
/// - get data from the stream.
class DataStreamReference extends RPCCarpReference {
  /// The CARP study deployment ID.
  String studyDeploymentId;

  @override
  CarpDataStreamService get service => super.service as CarpDataStreamService;

  DataStreamReference._(CarpDataStreamService service, this.studyDeploymentId)
    : super._(service);

  /// The URL for the data stream service endpoint.
  ///
  /// {{PROTOCOL}}://{{SERVER_HOST}}:{{SERVER_PORT}}/api/data-stream-service
  @override
  String get rpcEndpointUri =>
      "${service.app.uri.toString()}/api/data-stream-service";

  /// Append a [batch] of data measures to this data stream.
  /// If [compress] is true, the data is compressed before upload.
  Future<void> append(
    List<DataStreamBatch> batch, {
    bool compress = true,
  }) async => await service.appendToDataStreams(
    studyDeploymentId,
    batch,
    compress: compress,
  );

  /// Get all data points in [dataStream] with sequence numbers between
  /// [fromSequenceId] and [toSequenceIdInclusive].
  Future<List<DataStreamBatch>> get(
    DataStreamId dataStream,
    int fromSequenceId, [
    int? toSequenceIdInclusive,
  ]) async => await service.getDataStream(
    dataStream,
    fromSequenceId,
    toSequenceIdInclusive,
  );
}
