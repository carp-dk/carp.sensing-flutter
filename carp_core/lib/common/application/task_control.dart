/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// Specifies that once a condition of the trigger with [triggerId] applies,
/// the task with [taskName] on [destinationDeviceRoleName] should be started
/// or stopped (as specified by the [control] parameter).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TaskControl {
  /// The id of the [TriggerConfiguration].
  int triggerId;

  /// The name of the task to send to [destinationDeviceRoleName] when the
  /// trigger condition is met.
  late String taskName;

  /// The role name of the device to which to send the task with [taskName]
  /// when the trigger condition is met.
  String? destinationDeviceRoleName;

  /// What to do with a task once the condition of a trigger is met.
  Control control;

  /// The time the task have been scheduled until.
  /// Mainly used when scheduling a series of tasks for this trigger.
  DateTime? hasBeenScheduledUntil;

  @JsonKey(includeFromJson: false, includeToJson: false)
  TaskConfiguration? task;

  @JsonKey(includeFromJson: false, includeToJson: false)
  DeviceConfiguration? targetDevice;

  /// Create a [TaskControl].
  TaskControl({
    required this.triggerId,
    this.task,
    this.targetDevice,
    this.control = Control.Start,
  }) : super() {
    if (task != null) taskName = task!.name;
    if (targetDevice != null) {
      destinationDeviceRoleName = targetDevice!.roleName;
    }
  }

  factory TaskControl.fromJson(Map<String, dynamic> json) =>
      _$TaskControlFromJson(json);
  Map<String, dynamic> toJson() => _$TaskControlToJson(this);

  @override
  String toString() =>
      '$runtimeType - triggerId: $triggerId, task: $taskName, targetDeviceRoleName: $destinationDeviceRoleName';
}

/// Determines what to do with a task once the condition of a trigger is met.
enum Control { Start, Stop }
