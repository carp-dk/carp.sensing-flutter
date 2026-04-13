// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'runtime.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmartphoneDeploymentExecutorSamplingState
_$SmartphoneDeploymentExecutorSamplingStateFromJson(
  Map<String, dynamic> json,
) => SmartphoneDeploymentExecutorSamplingState(
  $enumDecode(_$ExecutorStateEnumMap, json['state']),
  json['studyDeploymentId'] as String,
  (json['taskControlSamplingStates'] as List<dynamic>)
      .map(
        (e) => TaskControlExecutorSamplingState.fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$SmartphoneDeploymentExecutorSamplingStateToJson(
  SmartphoneDeploymentExecutorSamplingState instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'state': _$ExecutorStateEnumMap[instance.state]!,
  'studyDeploymentId': instance.studyDeploymentId,
  'taskControlSamplingStates': instance.taskControlSamplingStates
      .map((e) => e.toJson())
      .toList(),
};

const _$ExecutorStateEnumMap = {
  ExecutorState.Created: 'Created',
  ExecutorState.Initialized: 'Initialized',
  ExecutorState.Resumed: 'Resumed',
  ExecutorState.Paused: 'Paused',
  ExecutorState.PausedButShouldBeResumed: 'PausedButShouldBeResumed',
  ExecutorState.Disposed: 'Disposed',
  ExecutorState.Undefined: 'Undefined',
};

SamplingState _$SamplingStateFromJson(Map<String, dynamic> json) =>
    SamplingState($enumDecode(_$ExecutorStateEnumMap, json['state']))
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$SamplingStateToJson(SamplingState instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'state': _$ExecutorStateEnumMap[instance.state]!,
    };

TaskControlExecutorSamplingState _$TaskControlExecutorSamplingStateFromJson(
  Map<String, dynamic> json,
) => TaskControlExecutorSamplingState(
  $enumDecode(_$ExecutorStateEnumMap, json['state']),
  (json['triggerId'] as num).toInt(),
  json['taskName'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$TaskControlExecutorSamplingStateToJson(
  TaskControlExecutorSamplingState instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'state': _$ExecutorStateEnumMap[instance.state]!,
  'triggerId': instance.triggerId,
  'taskName': instance.taskName,
};

UserTaskSnapshot _$UserTaskSnapshotFromJson(Map<String, dynamic> json) =>
    UserTaskSnapshot(
      json['id'] as String,
      AppTask.fromJson(json['task'] as Map<String, dynamic>),
      $enumDecode(_$UserTaskStateEnumMap, json['state']),
      DateTime.parse(json['enqueued'] as String),
      DateTime.parse(json['triggerTime'] as String),
      json['doneTime'] == null
          ? null
          : DateTime.parse(json['doneTime'] as String),
      json['hasNotificationBeenCreated'] as bool,
      json['studyDeploymentId'] as String?,
      json['deviceRoleName'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$UserTaskSnapshotToJson(UserTaskSnapshot instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'id': instance.id,
      'task': instance.task.toJson(),
      'state': _$UserTaskStateEnumMap[instance.state]!,
      'enqueued': instance.enqueued.toIso8601String(),
      'triggerTime': instance.triggerTime.toIso8601String(),
      'doneTime': ?instance.doneTime?.toIso8601String(),
      'hasNotificationBeenCreated': instance.hasNotificationBeenCreated,
      'studyDeploymentId': ?instance.studyDeploymentId,
      'deviceRoleName': ?instance.deviceRoleName,
    };

const _$UserTaskStateEnumMap = {
  UserTaskState.initialized: 'initialized',
  UserTaskState.enqueued: 'enqueued',
  UserTaskState.dequeued: 'dequeued',
  UserTaskState.notified: 'notified',
  UserTaskState.started: 'started',
  UserTaskState.canceled: 'canceled',
  UserTaskState.done: 'done',
  UserTaskState.expired: 'expired',
  UserTaskState.undefined: 'undefined',
};
