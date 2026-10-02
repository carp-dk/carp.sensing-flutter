/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_services.dart';

/// A reference to the data streams of one study deployment in CAWS.
///
/// Obtained from [CarpDataStreamService.dataStream]. Used to append data to
/// the streams and to read data back, without passing the study deployment
/// ID on every call.
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

  /// Appends a [batch] of measurements to the data streams of this deployment.
  /// If [compress] is true, the data is compressed before upload.
  Future<void> append(
    List<DataStreamBatch> batch, {
    bool compress = true,
  }) async => await service.appendToDataStreams(
    studyDeploymentId,
    batch,
    compress: compress,
  );

  /// Gets all data in [dataStream] with sequence numbers between
  /// [fromSequenceId] and [toSequenceIdInclusive].
  /// If [toSequenceIdInclusive] is null, all data from [fromSequenceId] is
  /// returned.
  Future<List<DataStreamBatch>> get(
    DataStreamId dataStream,
    int fromSequenceId, [
    int? toSequenceIdInclusive,
  ]) async => await service.getDataStream(
    dataStream,
    fromSequenceId,
    toSequenceIdInclusive,
  );

  /// Gets all data in [dataStream] whose local update time falls
  /// within the inclusive [from]-[to] window, as one [DataStreamBatch] per
  /// contiguous run of measurements.
  Future<List<DataStreamBatch>> getDataStreamBatchesByTime(
    DataStreamId dataStream,
    DateTime from,
    DateTime to,
  ) async => await service.getDataStreamBatchesByTime(dataStream, from, to);
}
