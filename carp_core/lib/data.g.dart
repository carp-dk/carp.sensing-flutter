// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataStreamsConfiguration _$DataStreamsConfigurationFromJson(
  Map<String, dynamic> json,
) => DataStreamsConfiguration(
  studyDeploymentId: json['studyDeploymentId'] as String,
  expectedDataStreams: (json['expectedDataStreams'] as List<dynamic>)
      .map((e) => ExpectedDataStream.fromJson(e as Map<String, dynamic>))
      .toSet(),
);

Map<String, dynamic> _$DataStreamsConfigurationToJson(
  DataStreamsConfiguration instance,
) => <String, dynamic>{
  'studyDeploymentId': instance.studyDeploymentId,
  'expectedDataStreams': instance.expectedDataStreams
      .map((e) => e.toJson())
      .toList(),
};

ExpectedDataStream _$ExpectedDataStreamFromJson(Map<String, dynamic> json) =>
    ExpectedDataStream(
      deviceRoleName: json['deviceRoleName'] as String,
      dataType: json['dataType'] as String,
    );

Map<String, dynamic> _$ExpectedDataStreamToJson(ExpectedDataStream instance) =>
    <String, dynamic>{
      'deviceRoleName': instance.deviceRoleName,
      'dataType': instance.dataType,
    };

DataStreamId _$DataStreamIdFromJson(Map<String, dynamic> json) => DataStreamId(
  studyDeploymentId: json['studyDeploymentId'] as String,
  deviceRoleName: json['deviceRoleName'] as String,
  dataType: json['dataType'] as String,
);

Map<String, dynamic> _$DataStreamIdToJson(DataStreamId instance) =>
    <String, dynamic>{
      'studyDeploymentId': instance.studyDeploymentId,
      'deviceRoleName': instance.deviceRoleName,
      'dataType': instance.dataType,
    };

DataStreamBatch _$DataStreamBatchFromJson(Map<String, dynamic> json) =>
    DataStreamBatch(
      dataStream: DataStreamId.fromJson(
        json['dataStream'] as Map<String, dynamic>,
      ),
      firstSequenceId: (json['firstSequenceId'] as num).toInt(),
      measurements: (json['measurements'] as List<dynamic>)
          .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
          .toList(),
      triggerIds: (json['triggerIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toSet(),
    );

Map<String, dynamic> _$DataStreamBatchToJson(DataStreamBatch instance) =>
    <String, dynamic>{
      'dataStream': instance.dataStream.toJson(),
      'firstSequenceId': instance.firstSequenceId,
      'measurements': instance.measurements.map((e) => e.toJson()).toList(),
      'triggerIds': instance.triggerIds.toList(),
    };

Measurement _$MeasurementFromJson(Map<String, dynamic> json) => Measurement(
  sensorStartTime: (json['sensorStartTime'] as num).toInt(),
  sensorEndTime: (json['sensorEndTime'] as num?)?.toInt(),
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MeasurementToJson(Measurement instance) =>
    <String, dynamic>{
      'sensorStartTime': instance.sensorStartTime,
      'sensorEndTime': ?instance.sensorEndTime,
      'data': instance.data.toJson(),
    };

OpenDataStreams _$OpenDataStreamsFromJson(Map<String, dynamic> json) =>
    OpenDataStreams(
        DataStreamsConfiguration.fromJson(
          json['configuration'] as Map<String, dynamic>,
        ),
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$OpenDataStreamsToJson(OpenDataStreams instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'apiVersion': instance.apiVersion,
      'configuration': instance.configuration.toJson(),
    };

AppendToDataStreams _$AppendToDataStreamsFromJson(Map<String, dynamic> json) =>
    AppendToDataStreams(
        json['studyDeploymentId'] as String,
        (json['batch'] as List<dynamic>)
            .map((e) => DataStreamBatch.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$AppendToDataStreamsToJson(
  AppendToDataStreams instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'apiVersion': instance.apiVersion,
  'studyDeploymentId': instance.studyDeploymentId,
  'batch': instance.batch.map((e) => e.toJson()).toList(),
};

GetDataStream _$GetDataStreamFromJson(Map<String, dynamic> json) =>
    GetDataStream(
        DataStreamId.fromJson(json['dataStream'] as Map<String, dynamic>),
        (json['fromSequenceId'] as num).toInt(),
        (json['toSequenceIdInclusive'] as num?)?.toInt(),
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$GetDataStreamToJson(GetDataStream instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'apiVersion': instance.apiVersion,
      'dataStream': instance.dataStream.toJson(),
      'fromSequenceId': instance.fromSequenceId,
      'toSequenceIdInclusive': ?instance.toSequenceIdInclusive,
    };

CloseDataStreams _$CloseDataStreamsFromJson(Map<String, dynamic> json) =>
    CloseDataStreams(
        (json['studyDeploymentIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$CloseDataStreamsToJson(CloseDataStreams instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'apiVersion': instance.apiVersion,
      'studyDeploymentIds': instance.studyDeploymentIds,
    };

RemoveDataStreams _$RemoveDataStreamsFromJson(Map<String, dynamic> json) =>
    RemoveDataStreams(
        (json['studyDeploymentIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$RemoveDataStreamsToJson(RemoveDataStreams instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'apiVersion': instance.apiVersion,
      'studyDeploymentIds': instance.studyDeploymentIds,
    };
