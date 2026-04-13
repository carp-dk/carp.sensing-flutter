// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RPAppTask _$RPAppTaskFromJson(Map<String, dynamic> json) => RPAppTask(
  name: json['name'] as String?,
  type: json['type'] as String,
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  instructions: json['instructions'] as String? ?? '',
  minutesToComplete: (json['minutesToComplete'] as num?)?.toInt(),
  expire: json['expire'] == null
      ? null
      : Duration(microseconds: (json['expire'] as num).toInt()),
  notification: json['notification'] as bool? ?? false,
  measures: (json['measures'] as List<dynamic>?)
      ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
      .toList(),
  rpTask: RPTask.fromJson(json['rpTask'] as Map<String, dynamic>),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$RPAppTaskToJson(RPAppTask instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'name': instance.name,
  'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
  'type': instance.type,
  'title': instance.title,
  'description': instance.description,
  'instructions': instance.instructions,
  'minutesToComplete': ?instance.minutesToComplete,
  'expire': ?instance.expire?.inMicroseconds,
  'notification': instance.notification,
  'rpTask': instance.rpTask.toJson(),
};

RPTaskResultData _$RPTaskResultDataFromJson(Map<String, dynamic> json) =>
    RPTaskResultData(
      $enumDecodeNullable(_$SurveyStatusEnumMap, json['status']) ??
          SurveyStatus.unknown,
      json['result'] == null
          ? null
          : RPTaskResult.fromJson(json['result'] as Map<String, dynamic>),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$RPTaskResultDataToJson(RPTaskResultData instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'status': _$SurveyStatusEnumMap[instance.status]!,
      'result': ?instance.result?.toJson(),
    };

const _$SurveyStatusEnumMap = {
  SurveyStatus.unknown: 'unknown',
  SurveyStatus.submitted: 'submitted',
  SurveyStatus.canceled: 'canceled',
};
