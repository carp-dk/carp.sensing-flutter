/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */
part of '../../runtime.dart';

/// The sampling state of a [SmartphoneDeploymentExecutor] and its task controls.
///
/// Stored as [SmartphoneStudy.samplingState] so that each task control can be
/// resumed or kept paused after an app restart.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SmartphoneDeploymentExecutorSamplingState extends SamplingState {
  /// The id of the study deployment this state belongs to.
  String studyDeploymentId;

  /// The sampling state of each [TaskControlExecutor] in the deployment.
  List<TaskControlExecutorSamplingState> taskControlSamplingStates = [];
  SmartphoneDeploymentExecutorSamplingState(
    super.state,
    this.studyDeploymentId,
    this.taskControlSamplingStates,
  );

  @override
  Function get fromJsonFunction =>
      _$SmartphoneDeploymentExecutorSamplingStateFromJson;
  factory SmartphoneDeploymentExecutorSamplingState.fromJson(
    Map<String, dynamic> json,
  ) => FromJsonFactory().fromJson<SmartphoneDeploymentExecutorSamplingState>(
    json,
  );
  @override
  Map<String, dynamic> toJson() =>
      _$SmartphoneDeploymentExecutorSamplingStateToJson(this);
}

/// Runs a [SmartphoneDeployment]: the root of the executor tree of a study.
///
/// Each [SmartphoneStudyController] owns one. On [initialize] it creates a
/// [TaskControlExecutor] for each task control in the deployment and tells the
/// target device's [DeviceManager] about it. You rarely use it directly; go
/// through [SmartphoneStudyController] instead.
///
/// Key points:
///  * Task controls with an [AppTask] and a [Schedulable] trigger get an
///    [AppTaskControlExecutor]; [MonitoringTask]s get no executor.
///  * [measurements] merges all measurements of the deployment and adds a
///    [CompletedAppTask] measurement each time a [UserTask] is done.
///  * On resume, each task control is resumed or paused according to the
///    sampling state set with [setSamplingState], if any. Then the buffered
///    app tasks are enqueued in the [AppTaskController].
///
/// See also [Executor] for the lifecycle.
class SmartphoneDeploymentExecutor
    extends AggregateExecutor<SmartphoneDeployment> {
  final StreamController<Measurement> _manualMeasurementController =
      StreamController.broadcast();
  SmartphoneDeploymentExecutorSamplingState? _samplingState;

  @override
  SmartphoneDeploymentExecutorSamplingState get samplingState =>
      SmartphoneDeploymentExecutorSamplingState(
        state,
        configuration!.studyDeploymentId,
        executors
            .whereType<TaskControlExecutor>()
            .map(
              (executor) =>
                  executor.samplingState as TaskControlExecutorSamplingState,
            )
            .toList(),
      );

  /// Sets the sampling state to restore on the next [resume].
  ///
  /// E.g. the state saved before the app was restarted.
  /// Does not change the current [samplingState], which is always computed from
  /// the running executors.
  void setSamplingState(
    SmartphoneDeploymentExecutorSamplingState? samplingState,
  ) => _samplingState = samplingState;

  /// Clears the state set with [setSamplingState].
  ///
  /// The next [resume] then resumes all task controls.
  void clearSamplingStatus() => _samplingState = null;

  @override
  bool onInitialize() {
    if (configuration == null) {
      warning(
        'Trying to initialize a $runtimeType, but the deployment configuration is null. '
        'Cannot initialize study deployment.',
      );
      return false;
    }

    _group.add(_manualMeasurementController.stream);

    for (var taskControl in configuration!.taskControls) {
      // get the trigger and task based on the trigger id and task name
      final trigger = configuration!.triggers['${taskControl.triggerId}']!;
      final task = configuration!.getTaskByName(taskControl.taskName)!;
      final targetDevice = configuration!.getDeviceFromRoleName(
        taskControl.destinationDeviceRoleName!,
      )!;

      // Only create an executor for "real" tasks
      if (task is! MonitoringTask) {
        TaskControlExecutor executor;

        // A TriggeredAppTaskExecutor need BOTH a [Schedulable] trigger and an [AppTask]
        // to schedule
        if (trigger is Schedulable && task is AppTask) {
          executor = AppTaskControlExecutor(
            taskControl,
            trigger,
            task,
            targetDevice,
          );
        } else {
          // All other cases we use the normal background triggering relying on the app
          // running in the background
          executor = TaskControlExecutor(
            taskControl,
            trigger,
            task,
            targetDevice,
          );
        }

        executor.initialize(taskControl, deployment!);
        addExecutor(executor);

        // let the device manger know about this executor
        getDeviceManagerFromRoleName(
          executor.taskControl.destinationDeviceRoleName,
        )?.executors.add(executor);
      }
    }

    // listen for "done" tasks and add them as a [CompletedAppTask] measurement
    AppTaskController().userTaskEvents
        .where((userTask) => userTask.state == UserTaskState.done)
        .listen(
          (userTask) => addMeasurement(
            Measurement.fromData(CompletedAppTask.fromUserTask(userTask)),
          ),
        );

    return true;
  }

  /// Resumes sampling based on the [samplingState] of the deployment.
  ///
  /// If the prior [samplingState] is unknown (null), it simply resumes all executors.
  /// If the prior [samplingState] is known, it resumes or pauses the executors based on
  /// the state of each [TaskControlExecutor] in the [samplingState].
  ///
  /// Finally, the method enqueues all app tasks buffered in the [AppTaskController].
  @override
  Future<bool> onResume() async {
    if (_samplingState == null) {
      await super.onResume();
    } else {
      for (var executor in _executors) {
        if (executor is TaskControlExecutor) {
          var taskControlSamplingState = _samplingState!
              .taskControlSamplingStates
              .firstWhere(
                (state) =>
                    state.triggerId == executor.taskControl.triggerId &&
                    state.taskName == executor.taskControl.taskName,
              );

          if (taskControlSamplingState.state == ExecutorState.Resumed ||
              taskControlSamplingState.state ==
                  ExecutorState.PausedButShouldBeResumed) {
            executor.resume();
          } else if (taskControlSamplingState.state == ExecutorState.Paused) {
            executor.pause();
          }
        }
      }
    }

    await AppTaskController().enqueueBufferedTasks();
    debug(
      '$runtimeType resumed - ${await SmartPhoneClientManager().notificationManager.pendingNotificationRequestsCount} notifications are currently pending.',
    );

    return true;
  }

  @override
  Future<void> onDispose() async {
    await super.onDispose();

    // remove the executors from the device managers
    for (var element in executors) {
      TaskControlExecutor executor = element as TaskControlExecutor;

      getDeviceManagerFromRoleName(
        executor.taskControl.destinationDeviceRoleName,
      )?.executors.remove(executor);
    }
  }

  /// Adds [measurements] to the [measurements] of this deployment executor.
  ///
  /// Used for executors outside the tree, e.g. app tasks restored by the
  /// [AppTaskController].
  void addMeasurements(Stream<Measurement> measurements) =>
      _group.add(measurements);

  /// Returns the [DeviceManager] of the device with [roleName].
  ///
  /// Works for both the primary device and connected devices.
  /// Returns null if no device with [roleName] is found.
  DeviceManager? getDeviceManagerFromRoleName(String? roleName) {
    if (roleName == null) return null;

    var targetDevice = configuration?.getDeviceFromRoleName(roleName);
    return (targetDevice != null)
        ? DeviceController().getDeviceManager(targetDevice.type)
        : null;
  }

  /// All probes in this deployment executor. May be empty.
  List<Probe> get probes {
    List<Probe> probes = [];

    for (var executor in executors) {
      if (executor is TaskControlExecutor) {
        probes.addAll(executor.probes);
      }
    }
    return probes;
  }

  /// Returns all probes of data [type]. Returns an empty list if none are found.
  List<Probe> lookupProbe(String type) {
    List<Probe> retrainedProbes = probes;
    retrainedProbes.retainWhere((probe) => probe.type == type);
    return retrainedProbes;
  }
}
