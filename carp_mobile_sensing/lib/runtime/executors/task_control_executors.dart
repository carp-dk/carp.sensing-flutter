/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// Responsible for handling the execution of a [TaskControl].
///
/// This executor runs in real-time and triggers the task using timers. This
/// entails that tasks are only triggered if the app is actively running, either
/// in the foreground or in a background process.
class TaskControlExecutor extends AbstractExecutor<TaskControl> {
  final StreamController<Measurement> _controller =
      StreamController<Measurement>.broadcast();
  final StreamGroup<Measurement> _group = StreamGroup.broadcast();

  final TriggerConfiguration _trigger;
  final TaskConfiguration _task;
  final TaskControl _taskControl;
  TriggerExecutor? triggerExecutor;
  TaskExecutor? taskExecutor;

  String get studyDeploymentId => deployment!.studyDeploymentId;
  TriggerConfiguration get trigger => _trigger;
  TaskConfiguration get task => _task;
  TaskControl get taskControl => _taskControl;

  TaskControlExecutor(
    TaskControl taskControl,
    TriggerConfiguration trigger,
    TaskConfiguration task,
  ) : _taskControl = taskControl,
      _trigger = trigger,
      _task = task,
      super();

  @override
  bool onInitialize() {
    _group.add(_controller.stream);

    // get or create the trigger executor and initialize with this task control executor
    triggerExecutor = ExecutorFactory().getTriggerExecutor(
      studyDeploymentId,
      taskControl.triggerId,
    );
    if (triggerExecutor == null) {
      triggerExecutor = ExecutorFactory().createTriggerExecutor(
        studyDeploymentId,
        taskControl.triggerId,
        trigger,
      );
      triggerExecutor?.initialize(trigger, deployment);
    }
    // now start listening on the trigger and trigger events
    triggerExecutor?.triggerEvents.listen((_) => onTrigger());

    // get the task executor and add the measurements it collects to the stream group
    taskExecutor = ExecutorFactory().getTaskExecutor(studyDeploymentId, task);
    if (taskExecutor == null) {
      warning(
        "$runtimeType - Cannot find a TaskExecutor for task type '${task.runtimeType}'.",
      );
      return false;
    }
    taskExecutor?.initialize(task, deployment);
    _group.add(taskExecutor!.measurements);

    return true;
  }

  /// Callback when the [triggerExecutor] triggers.
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
        '$runtimeType - no TriggerExecutor defined - cannot start this task control executor.',
      );
      return false;
    } else if (triggerExecutor?.state != ExecutorState.Resumed &&
        !triggerExecutor!._isResuming) {
      triggerExecutor?.resume();
    }
    return true;
  }

  @override
  Future<bool> onRestart() async => await onPause();

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

  /// Returns a list of the running probes in this task control executor.
  List<Probe> get probes => taskExecutor?.probes ?? [];
}

/// Responsible for handling the execution of a [TaskControl] which contains
/// an [AppTask].
///
/// In contrast to the [TaskControlExecutor] (which runs in the background),
/// this [AppTaskControlExecutor] will try to schedule the [AppTask] using
/// the [AppTaskController]. This means that the [trigger] has to be
/// [Schedulable].
class AppTaskControlExecutor extends TaskControlExecutor {
  AppTaskControlExecutor(
    // super.deploymentExecutor,
    super.taskControl,
    super.trigger,
    super.task,
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
      // Stop since the schedule is empty and there is not more to schedule.
      pause();
    } else {
      info(
        '$runtimeType Buffering ${schedule.length} app tasks ($schedule) for task ${taskExecutor.task.name}',
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
