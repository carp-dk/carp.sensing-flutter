/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../../runtime.dart';

/// A factory that holds the set of trigger and task executors used in all
/// deployments. Accessed as a singleton using `ExecutorFactory()`.
///
/// Use [getTaskExecutor] to get or create a new task executor.
/// Use [getTriggerExecutor] to get an existing trigger executor.
/// Use [createTriggerExecutor] to get create a new trigger executor using
/// the available [TriggerFactory]s.
///
/// Note that each deployment needs its own set of trigger and task executors.
/// This is because trigger and task executors can be reused across task controls
/// in the same study deployment.
///
/// Therefore, each [SmartphoneDeploymentExecutor] has its own [ExecutorFactory]
/// in order to avoiding executors to be reused across deployments (if the trigger
/// or task has the same id/name).
class ExecutorFactory {
  static final ExecutorFactory _instance = ExecutorFactory._();

  // type => factory
  final Map<Type, TriggerFactory> _triggerFactories = {};

  // deploymentId -> triggerId => executor
  final Map<String, Map<int, TriggerExecutor>> _triggerExecutors = {};

  // deploymentId -> taskName => executor
  final Map<String, Map<String, TaskExecutor>> _taskExecutors = {};

  /// Get the singleton instance of [ExecutorFactory].
  factory ExecutorFactory() => _instance;

  ExecutorFactory._() {
    registerTriggerFactory(SmartphoneTriggerFactory());
  }

  /// Register [factory] which can create [TriggerExecutor]s
  /// for the specified [TriggerFactory] runtime types.
  ///
  /// This is used in the [createTriggerExecutor] method for creating new
  /// [TriggerExecutor]s.
  void registerTriggerFactory(TriggerFactory factory) {
    for (var type in factory.types) {
      _triggerFactories[type] = factory;
    }
    factory.onRegister();
  }

  /// Get a [TriggerExecutor] based on the [studyDeploymentId] and [triggerId].
  /// Returns null if not found.
  TriggerExecutor? getTriggerExecutor(
    String studyDeploymentId,
    int triggerId,
  ) => _triggerExecutors[studyDeploymentId]?[triggerId];

  /// Create a [TriggerExecutor] based on the [studyDeploymentId] and [triggerId].
  /// Returns null if [trigger] is not supported by any registered [TriggerFactory]
  /// factories.
  TriggerExecutor? createTriggerExecutor(
    String studyDeploymentId,
    int triggerId,
    TriggerConfiguration trigger,
  ) {
    TriggerExecutor? executor;

    if (_triggerFactories[trigger.runtimeType] != null) {
      executor = _triggerFactories[trigger.runtimeType]!.create(trigger);
    }

    if (executor == null) {
      warning(
        "$runtimeType - Cannot create a TriggerExecutor for trigger type '${trigger.runtimeType}'.",
      );
    } else {
      _triggerExecutors[studyDeploymentId] = {};
      _triggerExecutors[studyDeploymentId]?[triggerId] = executor;
    }
    return _triggerExecutors[studyDeploymentId]?[triggerId];
  }

  /// Get the [TaskExecutor] for a [task] based on the task name. If the task
  /// executor does not exist, a new one is created based on the type of the task.
  /// Returns null if the type of [task] is unknown.
  TaskExecutor? getTaskExecutor(
    String studyDeploymentId,
    TaskConfiguration task,
  ) {
    if (_taskExecutors[studyDeploymentId]?[task.name] == null) {
      TaskExecutor? executor = switch (task) {
        BackgroundTask() => BackgroundTaskExecutor(),
        AppTask() => AppTaskExecutor(),
        FunctionTask() => FunctionTaskExecutor(),
        _ => null,
      };
      if (executor != null) {
        _taskExecutors[studyDeploymentId] = {};
        _taskExecutors[studyDeploymentId]?[task.name] = executor;
      }
    }
    return _taskExecutors[studyDeploymentId]?[task.name];
  }

  /// Dispose of all trigger and task executors.
  void dispose() {
    _triggerExecutors.clear();
    _taskExecutors.clear();
  }
}

/// A [TriggerFactory] for all triggers coming with CAMS.
class SmartphoneTriggerFactory implements TriggerFactory {
  final Set<Serializable> _triggers = {
    NoOpTrigger(),
    ImmediateTrigger(),
    OneTimeTrigger(),
    DelayedTrigger(delay: const Duration()),
    PeriodicTrigger(period: const Duration()),
    DateTimeTrigger(schedule: DateTime.now()),
    RecurrentScheduledTrigger(
      type: RecurrentType.daily,
      time: const TimeOfDay(),
    ),
    SamplingEventTrigger(measureType: ''),
    ConditionalPeriodicTrigger(period: const Duration()),
    ConditionalSamplingEventTrigger(measureType: ''),
    CronScheduledTrigger(),
    RandomRecurrentTrigger(
      startTime: const TimeOfDay(hour: 1),
      endTime: const TimeOfDay(hour: 2),
    ),
    UserTaskTrigger(taskName: 'ignored', triggerCondition: UserTaskState.done),
    NoUserTaskTrigger(taskName: 'ignored'),
    AppLifecycleTrigger(),
  };

  @override
  Set<Type> get types => _triggers.map((e) => e.runtimeType).toSet();

  @override
  void onRegister() {
    FromJsonFactory().registerAll(_triggers.toList());
  }

  @override
  TriggerExecutor<TriggerConfiguration> create(TriggerConfiguration trigger) {
    if (trigger is ElapsedTimeTrigger) return ElapsedTimeTriggerExecutor();

    if (trigger is ScheduledTrigger) {
      warning(
        "ScheduledTrigger is not implemented yet. "
        "Using an 'ImmediateTriggerExecutor' instead.",
      );
      return ImmediateTriggerExecutor();
    }

    if (trigger is NoOpTrigger) return NoOpTriggerExecutor();
    if (trigger is ImmediateTrigger) return ImmediateTriggerExecutor();
    if (trigger is OneTimeTrigger) return OneTimeTriggerExecutor();
    if (trigger is DelayedTrigger) return DelayedTriggerExecutor();
    if (trigger is PeriodicTrigger) return PeriodicTriggerExecutor();
    if (trigger is DateTimeTrigger) return DateTimeTriggerExecutor();
    if (trigger is RecurrentScheduledTrigger) {
      return RecurrentScheduledTriggerExecutor();
    }
    if (trigger is CronScheduledTrigger) return CronScheduledTriggerExecutor();
    if (trigger is SamplingEventTrigger) return SamplingEventTriggerExecutor();
    if (trigger is ConditionalSamplingEventTrigger) {
      return ConditionalSamplingEventTriggerExecutor();
    }
    if (trigger is ConditionalPeriodicTrigger) {
      return ConditionalPeriodicTriggerExecutor();
    }
    if (trigger is RandomRecurrentTrigger) {
      return RandomRecurrentTriggerExecutor();
    }
    if (trigger is PassiveTrigger) return PassiveTriggerExecutor();
    if (trigger is UserTaskTrigger) return UserTaskTriggerExecutor();
    if (trigger is NoUserTaskTrigger) return NoUserTaskTriggerExecutor();
    if (trigger is AppLifecycleTrigger) return AppLifecycleTriggerExecutor();

    warning(
      "Unknown trigger used - cannot find a TriggerExecutor for the trigger of type '${trigger.runtimeType}'. "
      "Using an 'ImmediateTriggerExecutor' instead.",
    );
    return ImmediateTriggerExecutor();
  }
}

/// A factory which can [create] a [TriggerExecutor] based on the runtime type
/// of an [TriggerConfiguration].
abstract class TriggerFactory {
  /// The set of supported [TriggerConfiguration] runtime types.
  Set<Type> get types => {};

  /// Callback method when this package is being registered.
  void onRegister();

  /// Create a [TriggerExecutor] based on [trigger].
  /// Returns null if [trigger] is not supported by this factory.
  TriggerExecutor? create(TriggerConfiguration trigger);
}
