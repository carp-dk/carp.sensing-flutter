/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// The sampling state of one [TaskControlExecutor].
///
/// Identified by its [triggerId] and [taskName].
/// Part of a [SmartphoneDeploymentExecutorSamplingState].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TaskControlExecutorSamplingState extends SamplingState {
  /// The [TaskControl.triggerId] of the task control.
  int triggerId;

  /// The [TaskControl.taskName] of the task control.
  String taskName;

  TaskControlExecutorSamplingState(super.state, this.triggerId, this.taskName);

  @override
  Function get fromJsonFunction => _$TaskControlExecutorSamplingStateFromJson;
  factory TaskControlExecutorSamplingState.fromJson(
    Map<String, dynamic> json,
  ) => FromJsonFactory().fromJson<TaskControlExecutorSamplingState>(json);
  @override
  Map<String, dynamic> toJson() =>
      _$TaskControlExecutorSamplingStateToJson(this);
}

/// Runs a [TaskControl]: starts or stops a task each time its trigger fires.
///
/// Created by the [SmartphoneDeploymentExecutor]. It gets its [TriggerExecutor]
/// and [TaskExecutor] from the [ExecutorFactory]. On each trigger event, it adds
/// a [TriggeredTask] measurement and resumes or pauses the task executor,
/// depending on [TaskControl.control].
///
/// Key points:
///  * Runs in real time using timers, so tasks only trigger while the app runs,
///    in the foreground or in a background process.
///  * Resuming fails while the [targetDevice] is not connected. The
///    [DeviceManager] of the target device resumes it once connected.
///  * Every measurement it emits has [Measurement.taskControl] set.
///
/// See [AppTaskControlExecutor] for app tasks with schedulable triggers.
class TaskControlExecutor extends AbstractExecutor<TaskControl> {
  final StreamController<Measurement> _controller =
      StreamController<Measurement>.broadcast();
  final StreamGroup<Measurement> _group = StreamGroup.broadcast();

  final TriggerConfiguration _trigger;
  final TaskConfiguration _task;
  final TaskControl _taskControl;
  final DeviceConfiguration _targetDevice;
  TriggerExecutor? _triggerExecutor;
  TaskExecutor? _taskExecutor;

  String get studyDeploymentId => deployment!.studyDeploymentId;
  TriggerConfiguration get trigger => _trigger;
  TaskConfiguration get task => _task;
  TaskControl get taskControl => _taskControl;
  DeviceConfiguration get targetDevice => _targetDevice;
  TriggerExecutor? get triggerExecutor => _triggerExecutor;
  TaskExecutor? get taskExecutor => _taskExecutor;

  /// The [DeviceManager] of [targetDevice], or null if none is available.
  DeviceManager? get targetDeviceManager => SmartPhoneClientManager()
      .deviceController
      .getDeviceManager(_targetDevice.type);

  /// Creates an executor for [taskControl].
  ///
  /// It links [trigger] and [task] on [targetDevice].
  TaskControlExecutor(
    TaskControl taskControl,
    TriggerConfiguration trigger,
    TaskConfiguration task,
    DeviceConfiguration targetDevice,
  ) : _taskControl = taskControl,
      _trigger = trigger,
      _task = task,
      _targetDevice = targetDevice,
      super();

  @override
  SamplingState get samplingState => TaskControlExecutorSamplingState(
    state,
    taskControl.triggerId,
    taskControl.taskName,
  );

  @override
  bool onInitialize() {
    _group.add(_controller.stream);

    // Get or create the trigger executor and initialize with this task control executor
    _triggerExecutor = ExecutorFactory().getTriggerExecutor(
      studyDeploymentId,
      taskControl.triggerId,
    );
    if (_triggerExecutor == null) {
      _triggerExecutor = ExecutorFactory().createTriggerExecutor(
        studyDeploymentId,
        taskControl.triggerId,
        trigger,
      );

      _triggerExecutor?.initialize(trigger, deployment);
    }

    // now start listening on the trigger and trigger events
    _triggerExecutor?.triggerEvents.listen((_) => onTrigger());
    // get the task executor and add the measurements it collects to the stream group
    _taskExecutor = ExecutorFactory().getTaskExecutor(studyDeploymentId, task);
    if (_taskExecutor == null) {
      warning(
        "$runtimeType - Cannot find a TaskExecutor for task type '${task.runtimeType}'.",
      );
      return false;
    }
    _taskExecutor?.initialize(task, deployment);
    _group.add(_taskExecutor!.measurements);

    return true;
  }

  /// Called when the [triggerExecutor] fires.
  ///
  /// Adds a [TriggeredTask] measurement, then resumes the [taskExecutor] for
  /// [Control.Start] or pauses it for [Control.Stop].
  void onTrigger() {
    // first, add the trigger task measurement to the measurements stream
    _controller.add(
      Measurement.fromData(
        TriggeredTask(
          triggerId: taskControl.triggerId,
          taskName: taskControl.taskName,
          destinationDeviceRoleName: taskControl.destinationDeviceRoleName!,
          control: taskControl.control,
        ),
      ),
    );

    // then "control" the task by either resuming or pausing it
    if (taskControl.control == Control.Start) {
      taskExecutor?.resume();
    } else if (taskControl.control == Control.Stop) {
      taskExecutor?.pause();
    }
  }

  @override
  Future<bool> onResume() async {
    if (triggerExecutor == null) {
      warning(
        '$runtimeType - No TriggerExecutor found - call initialize() before resume this task control executor.',
      );
      return false;
    }

    if (!(targetDeviceManager?.isConnected ?? false)) {
      warning(
        '$runtimeType - Device for task control ${taskControl.taskName} is not connected. '
        'Cannot resume sampling for this task control.',
      );
      return false;
    }

    if (triggerExecutor?.state != ExecutorState.Resumed &&
        !triggerExecutor!._isResuming) {
      triggerExecutor?.resume();
    }
    return true;
  }

  @override
  Future<bool> onPause() async {
    // stop the trigger executor so it don't trigger any more.
    triggerExecutor?.pause();

    // stop the task executor
    taskExecutor?.pause();

    return true;
  }

  @override
  Future<void> onDispose() async {
    // dispose both trigger and task executors so it don't trigger any more.
    triggerExecutor?.dispose();
    taskExecutor?.dispose();
  }

  @override
  Stream<Measurement> get measurements => _group.stream.map(
    (measurement) => measurement..taskControl = taskControl,
  );

  /// The probes of the [taskExecutor]. Empty if there is none.
  List<Probe> get probes => taskExecutor?.probes ?? [];
}

/// Runs a [TaskControl] with an [AppTask] and a [Schedulable] trigger.
///
/// Unlike [TaskControlExecutor], it does not wait for the trigger to fire.
/// On resume it computes the trigger's schedule for the next 15 days and
/// buffers one app task per time in the [AppTaskController], which schedules
/// them as notifications. It then pauses, and resumes again when the last
/// scheduled time has passed, if the app is still running.
class AppTaskControlExecutor extends TaskControlExecutor {
  AppTaskControlExecutor(
    super.taskControl,
    super.trigger,
    super.task,
    super.targetDevice,
  );

  @override
  AppTaskExecutor get taskExecutor => super.taskExecutor as AppTaskExecutor;

  @override
  SchedulableTriggerExecutor get triggerExecutor =>
      super.triggerExecutor as SchedulableTriggerExecutor;

  @override
  Future<bool> onResume() async {
    debug(
      '$runtimeType - ${taskControl.taskName} hasBeenScheduledUntil: ${taskControl.hasBeenScheduledUntil}',
    );
    final from = taskControl.hasBeenScheduledUntil ?? DateTime.now();
    final to = DateTime.now().add(const Duration(days: 15)); // 15 days ahead
    // get all the instances where the task should be scheduled in the given range
    final schedule = triggerExecutor.getSchedule(from, to);

    if (schedule.isEmpty) {
      // Pause since the schedule is empty and there is not more to schedule.
      info(
        '$runtimeType - No scheduled app tasks for task ${taskExecutor.task.name} - pausing executor again.',
      );
      pause();
    } else {
      info(
        '$runtimeType - Buffering ${schedule.length} app tasks ($schedule) for task ${taskExecutor.task.name}',
      );

      Iterator<DateTime> it = schedule.iterator;
      DateTime current = DateTime.now();
      while (it.moveNext()) {
        current = it.current;
        AppTaskController().buffer(
          taskExecutor,
          taskControl,
          triggerTime: current,
        );
      }

      // Now stop since the schedule has all been enqueued.
      pause();

      // .. but start again when the scheduled time has passed.
      // This in the case where the app keeps running in the background
      var duration =
          current.millisecondsSinceEpoch -
          DateTime.now().millisecondsSinceEpoch;

      Timer(Duration(milliseconds: duration), () => resume());
    }

    return true;
  }

  @override
  Future<bool> onPause() async => true; // do nothing
}
