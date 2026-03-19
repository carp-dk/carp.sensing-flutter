/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */
part of '../../runtime.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SmartphoneDeploymentExecutorSamplingState extends SamplingState {
  String studyDeploymentId;
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

/// A [SmartphoneDeploymentExecutor] is responsible for executing a [SmartphoneDeployment].
/// For each task control in this deployment, it starts a [TaskControlExecutor].
///
/// Note that the [SmartphoneDeploymentExecutor] in itself is an [Executor] and hence work
/// as a 'super executor'. This - amongst other things - imply that you can listen
/// to all collected measurements from the [measurements] stream and to all state
/// event changes in the [stateEvents] stream.
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

  /// Set the [samplingState] of this [SmartphoneDeploymentExecutor].
  /// This state is used to resume the deployment in the same state as it was before,
  /// e.g. after a restart of the app.
  void setSamplingState(
    SmartphoneDeploymentExecutorSamplingState? samplingState,
  ) => _samplingState = samplingState;

  /// Clear the [samplingState] of this [SmartphoneDeploymentExecutor].
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

  /// Add the stream of [measurements] to the overall stream of measurements
  /// for this deployment executor.
  void addMeasurements(Stream<Measurement> measurements) =>
      _group.add(measurements);

  /// Get the [DeviceManager] based on the [roleName].
  /// This includes both the primary device and the connected devices.
  /// Returns null if no device with [roleName] is found.
  DeviceManager? getDeviceManagerFromRoleName(String? roleName) {
    if (roleName == null) return null;

    var targetDevice = configuration?.getDeviceFromRoleName(roleName);
    return (targetDevice != null)
        ? DeviceController().getDeviceManager(targetDevice.type)
        : null;
  }

  /// A list of the running probes in this study deployment executor.
  /// May be empty.
  List<Probe> get probes {
    List<Probe> probes = [];

    for (var executor in executors) {
      if (executor is TaskControlExecutor) {
        probes.addAll(executor.probes);
      }
    }
    return probes;
  }

  /// Lookup all probes of type [type]. Returns an empty list if none are found.
  List<Probe> lookupProbe(String type) {
    List<Probe> retrainedProbes = probes;
    retrainedProbes.retainWhere((probe) => probe.type == type);
    return retrainedProbes;
  }
}
