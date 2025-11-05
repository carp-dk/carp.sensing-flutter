/*
 * Copyright 2025 Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// Reflects a heart beat data send every [period] minute.
/// Useful for calculating sampling coverage over time.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Heartbeat extends Data {
  static const dataType = CamsDataTypes.HEARTBEAT_TYPE_NAME;

  /// The period of heartbeats per minute.
  int period;

  /// The type of device.
  String deviceType;

  /// The role name of the device in the protocol.
  String deviceRoleName;

  Heartbeat({
    required this.period,
    required this.deviceType,
    required this.deviceRoleName,
  }) : super();

  @override
  Function get fromJsonFunction => _$HeartbeatFromJson;
  factory Heartbeat.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Heartbeat>(json);
  @override
  Map<String, dynamic> toJson() => _$HeartbeatToJson(this);
}

/// Data about an [AppTask] that has been completed.
///
/// [taskName] is the name of the completed app task.
/// [taskType] indicates the type of task completed.
/// [completedAt] is the time this task was completed (in UTC).
/// [taskData] holds the result of the task, or null if no result is collected.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CompletedAppTask extends CompletedTask {
  static const dataType = CamsDataTypes.COMPLETED_APP_TASK_TYPE_NAME;

  /// The type of task which was completed, if specified.
  ///
  /// Known types are:
  ///  - informed_consent - a task collecting informed consent from the user
  ///  - survey - a survey task
  ///  - cognition - a cognitive assessment task
  ///  - audio - an audio task
  ///  - video - a video task
  ///  - image - an image task
  ///  - health - a task collecting health data
  ///  - sensing - a task collecting sensing data
  String taskType;

  /// The time when the task was completed in UTC.
  late DateTime completedAt;

  CompletedAppTask({
    required super.taskName,
    required this.taskType,
    super.taskData,
  }) : super() {
    completedAt = DateTime.now().toUtc();
  }

  @override
  bool equivalentTo(Data other) =>
      other is CompletedAppTask &&
      taskName == other.taskName &&
      taskType == other.taskType;

  @override
  Function get fromJsonFunction => _$CompletedAppTaskFromJson;
  factory CompletedAppTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CompletedAppTask>(json);
  @override
  Map<String, dynamic> toJson() => _$CompletedAppTaskToJson(this);
}
