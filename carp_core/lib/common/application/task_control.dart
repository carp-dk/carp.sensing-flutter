/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// Links a trigger to a task: when the trigger fires, start or stop the task.
///
/// Once the condition of the trigger with [triggerId] applies, the task with
/// [taskName] on [destinationDeviceRoleName] is started or stopped (as
/// specified by [control]). Task controls are created by
/// [StudyProtocol.addTaskControl]; you rarely create one yourself.
///
/// The JSON holds the trigger id, task name, target device role name, [control]
/// and [hasBeenScheduledUntil]; [task] and [targetDevice] are runtime
/// references that are not part of the JSON.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TaskControl {
  /// The id of the [TriggerConfiguration]; its key in [StudyProtocol.triggers].
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

  /// The task to control. Not serialized; may be null after deserialization.
  @JsonKey(includeFromJson: false, includeToJson: false)
  TaskConfiguration? task;

  /// The device to send the task to. Not serialized; may be null after
  /// deserialization.
  @JsonKey(includeFromJson: false, includeToJson: false)
  DeviceConfiguration? targetDevice;

  /// Create a [TaskControl].
  ///
  /// [taskName] and [destinationDeviceRoleName] are taken from [task] and
  /// [targetDevice] when given. [control] defaults to [Control.Start].
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

/// Determines what to do with a task once the condition of a trigger is met:
/// [Start] or [Stop] it.
enum Control { Start, Stop }
