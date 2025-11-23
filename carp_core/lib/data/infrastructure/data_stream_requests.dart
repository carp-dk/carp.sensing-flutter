/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../data.dart';

/// An abstract RPC request to a [DataStreamService].
abstract class DataStreamServiceRequest extends ServiceRequest {
  final String _infrastructurePackageNamespace =
      'dk.cachet.carp.data.infrastructure';

  @override
  String get apiVersion => DataStreamService.API_VERSION;

  DataStreamServiceRequest() : super();

  @override
  String get jsonType =>
      '$_infrastructurePackageNamespace.DataStreamServiceRequest.$runtimeType';
}

/// An RPC request for [DataStreamService.openDataStreams].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OpenDataStreams extends DataStreamServiceRequest {
  DataStreamsConfiguration configuration;
  OpenDataStreams(this.configuration) : super();

  @override
  Function get fromJsonFunction => _$OpenDataStreamsFromJson;
  factory OpenDataStreams.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OpenDataStreams>(json);
  @override
  Map<String, dynamic> toJson() => _$OpenDataStreamsToJson(this);
}

/// An RPC request for [DataStreamService.appendToDataStreams].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppendToDataStreams extends DataStreamServiceRequest {
  String studyDeploymentId;
  List<DataStreamBatch> batch = [];

  AppendToDataStreams(this.studyDeploymentId, this.batch) : super();

  @override
  Function get fromJsonFunction => _$AppendToDataStreamsFromJson;
  factory AppendToDataStreams.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppendToDataStreams>(json);
  @override
  Map<String, dynamic> toJson() => _$AppendToDataStreamsToJson(this);
}

/// An RPC request for [DataStreamService.getDataStream].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetDataStream extends DataStreamServiceRequest {
  DataStreamId dataStream;
  int fromSequenceId;
  int? toSequenceIdInclusive;

  GetDataStream(
    this.dataStream,
    this.fromSequenceId, [
    this.toSequenceIdInclusive,
  ]) : super();

  @override
  Function get fromJsonFunction => _$GetDataStreamFromJson;
  factory GetDataStream.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GetDataStream>(json);
  @override
  Map<String, dynamic> toJson() => _$GetDataStreamToJson(this);
}

/// An RPC request for [DataStreamService.closeDataStreams].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CloseDataStreams extends DataStreamServiceRequest {
  List<String> studyDeploymentIds;
  CloseDataStreams(this.studyDeploymentIds) : super();

  @override
  Function get fromJsonFunction => _$CloseDataStreamsFromJson;
  factory CloseDataStreams.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CloseDataStreams>(json);
  @override
  Map<String, dynamic> toJson() => _$CloseDataStreamsToJson(this);
}

/// An RPC request for [DataStreamService.removeDataStreams].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RemoveDataStreams extends DataStreamServiceRequest {
  List<String> studyDeploymentIds;
  RemoveDataStreams(this.studyDeploymentIds) : super();

  @override
  Function get fromJsonFunction => _$RemoveDataStreamsFromJson;
  factory RemoveDataStreams.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<RemoveDataStreams>(json);
  @override
  Map<String, dynamic> toJson() => _$RemoveDataStreamsToJson(this);
}
