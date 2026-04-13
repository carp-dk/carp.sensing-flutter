// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carp_services.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataPoint _$DataPointFromJson(Map<String, dynamic> json) =>
    DataPoint(
        DataPointHeader.fromJson(json['carp_header'] as Map<String, dynamic>),
      )
      ..id = (json['id'] as num?)?.toInt()
      ..createdByUserId = (json['created_by_user_id'] as num?)?.toInt()
      ..studyId = json['study_id'] as String?
      ..carpBody = json['carp_body'] as Map<String, dynamic>?;

Map<String, dynamic> _$DataPointToJson(DataPoint instance) => <String, dynamic>{
  'id': ?instance.id,
  'created_by_user_id': ?instance.createdByUserId,
  'study_id': ?instance.studyId,
  'carp_header': instance.carpHeader.toJson(),
  'carp_body': ?instance.carpBody,
};

DataPointHeader _$DataPointHeaderFromJson(Map<String, dynamic> json) =>
    DataPointHeader(
        studyId: json['study_id'] as String?,
        userId: json['user_id'] as String?,
        dataFormat: json['data_format'] == null
            ? null
            : DataType.fromJson(json['data_format'] as Map<String, dynamic>),
        deviceRoleName: json['device_role_name'] as String?,
        triggerId: json['trigger_id'] as String?,
        startTime: json['start_time'] == null
            ? null
            : DateTime.parse(json['start_time'] as String),
        endTime: json['end_time'] == null
            ? null
            : DateTime.parse(json['end_time'] as String),
      )
      ..uploadTime = json['upload_time'] == null
          ? null
          : DateTime.parse(json['upload_time'] as String);

Map<String, dynamic> _$DataPointHeaderToJson(DataPointHeader instance) =>
    <String, dynamic>{
      'study_id': ?instance.studyId,
      'device_role_name': ?instance.deviceRoleName,
      'trigger_id': ?instance.triggerId,
      'user_id': ?instance.userId,
      'upload_time': ?instance.uploadTime?.toIso8601String(),
      'start_time': ?instance.startTime?.toIso8601String(),
      'end_time': ?instance.endTime?.toIso8601String(),
      'data_format': ?instance.dataFormat?.toJson(),
    };
