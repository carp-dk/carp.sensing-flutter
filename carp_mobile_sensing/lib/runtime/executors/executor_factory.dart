/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../../runtime.dart';

/// Creates and caches the trigger and task executors of all deployments.
///
/// A singleton used by [TaskControlExecutor]. Executors are cached per study
/// deployment: task controls in the same deployment that share a trigger id or
/// task name share one executor, while deployments never share executors.
///
/// Use [getTaskExecutor] to get or create a task executor.
/// Use [getTriggerExecutor] to get an existing trigger executor, and
/// [createTriggerExecutor] to create a new one with the registered
/// [TriggerFactory]s. Sampling packages with their own triggers register a
/// factory with [registerTriggerFactory].
class ExecutorFactory {
  static final ExecutorFactory _instance = ExecutorFactory._();

  // type => factory
  final Map<Type, TriggerFactory> _triggerFactories = {};

  // deploymentId -> triggerId => executor
  final Map<String, Map<int, TriggerExecutor>> _triggerExecutors = {};

  // deploymentId -> taskName => executor
  final Map<String, Map<String, TaskExecutor>> _taskExecutors = {};

  /// Returns the singleton [ExecutorFactory].
  factory ExecutorFactory() => _instance;

  ExecutorFactory._() {
    registerTriggerFactory(SmartphoneTriggerFactory());
  }

  /// Registers [factory] for all trigger types in [TriggerFactory.types].
  ///
  /// Also calls [TriggerFactory.onRegister].
  /// A later factory for the same type replaces an earlier one.
  /// Used by [createTriggerExecutor].
  void registerTriggerFactory(TriggerFactory factory) {
    for (var type in factory.types) {
      _triggerFactories[type] = factory;
    }
    factory.onRegister();
  }

  /// Returns the cached [TriggerExecutor] for [triggerId], or null if none.
  ///
  /// Executors are cached per [studyDeploymentId].
  TriggerExecutor? getTriggerExecutor(String studyDeploymentId, int triggerId) =>
      _triggerExecutors[studyDeploymentId]?[triggerId];

  /// Creates a [TriggerExecutor] for [trigger] and caches it.
  ///
  /// The cache key is [studyDeploymentId] and [triggerId].
  /// Returns null if no registered [TriggerFactory] supports the runtime type
  /// of [trigger].
  TriggerExecutor? createTriggerExecutor(String studyDeploymentId, int triggerId, TriggerConfiguration trigger) {
    TriggerExecutor? executor;

    if (_triggerFactories[trigger.runtimeType] != null) {
      executor = _triggerFactories[trigger.runtimeType]!.create(trigger);
    }

    if (executor == null) {
      warning("$runtimeType - Cannot create a TriggerExecutor for trigger type '${trigger.runtimeType}'.");
    } else {
      _triggerExecutors[studyDeploymentId] ??= {};
      _triggerExecutors[studyDeploymentId]?[triggerId] = executor;
    }
    return _triggerExecutors[studyDeploymentId]?[triggerId];
  }

  /// Returns the [TaskExecutor] for [task] in [studyDeploymentId].
  ///
  /// Executors are keyed by task name. Creates one if needed: a [BackgroundTaskExecutor], [AppTaskExecutor] or
  /// [FunctionTaskExecutor] depending on the task type.
  /// Returns null if the type of [task] is unknown.
  TaskExecutor? getTaskExecutor(String studyDeploymentId, TaskConfiguration task) {
    if (_taskExecutors[studyDeploymentId]?[task.name] == null) {
      TaskExecutor? executor = switch (task) {
        BackgroundTask() => BackgroundTaskExecutor(),
        AppTask() => AppTaskExecutor(),
        FunctionTask() => FunctionTaskExecutor(),
        _ => null,
      };
      if (executor != null) {
        _taskExecutors[studyDeploymentId] ??= {};
        _taskExecutors[studyDeploymentId]?[task.name] = executor;
      }
    }
    return _taskExecutors[studyDeploymentId]?[task.name];
  }

  /// Clears the cache of trigger and task executors.
  ///
  /// The executors themselves are not disposed.
  void dispose() {
    _triggerExecutors.clear();
    _taskExecutors.clear();
  }
}

/// Creates a [TriggerExecutor] for a [TriggerConfiguration] by runtime type.
///
/// Sampling packages that define their own triggers implement one and register
/// it with [ExecutorFactory.registerTriggerFactory].
/// See [SmartphoneTriggerFactory] for the built-in triggers.
abstract class TriggerFactory {
  /// The [TriggerConfiguration] runtime types this factory supports.
  Set<Type> get types => {};

  /// Called when this factory is registered in the [ExecutorFactory].
  ///
  /// Typically used to register the triggers' JSON deserializers.
  void onRegister();

  /// Create a [TriggerExecutor] based on [trigger].
  /// Returns null if [trigger] is not supported by this factory.
  TriggerExecutor? create(TriggerConfiguration trigger);
}

/// The [TriggerFactory] for all triggers that come with CAMS.
///
/// Registered in the [ExecutorFactory] by default. [ScheduledTrigger] is not
/// supported yet; [create] returns null for it.
class SmartphoneTriggerFactory implements TriggerFactory {
  /// Mapping of available [TriggerConfiguration] types to corresponding
  /// [TriggerExecutor] constructors.
  final Map<Type, TriggerExecutor Function()> _triggers = {
    NoOpTrigger: () => NoOpTriggerExecutor(),
    ImmediateTrigger: () => ImmediateTriggerExecutor(),
    OneTimeTrigger: () => OneTimeTriggerExecutor(),
    DelayedTrigger: () => DelayedTriggerExecutor(),
    PeriodicTrigger: () => PeriodicTriggerExecutor(),
    DateTimeTrigger: () => DateTimeTriggerExecutor(),
    ScheduledTrigger: () => ImmediateTriggerExecutor(),
    RecurrentScheduledTrigger: () => RecurrentScheduledTriggerExecutor(),
    CronScheduledTrigger: () => CronScheduledTriggerExecutor(),
    SamplingEventTrigger: () => SamplingEventTriggerExecutor(),
    ConditionalSamplingEventTrigger: () => ConditionalSamplingEventTriggerExecutor(),
    ConditionalPeriodicTrigger: () => ConditionalPeriodicTriggerExecutor(),
    RandomRecurrentTrigger: () => RandomRecurrentTriggerExecutor(),
    PassiveTrigger: () => PassiveTriggerExecutor(),
    UserTaskTrigger: () => UserTaskTriggerExecutor(),
    NoUserTaskTrigger: () => NoUserTaskTriggerExecutor(),
    AppLifecycleTrigger: () => AppLifecycleTriggerExecutor(),
    ElapsedTimeTrigger: () => ElapsedTimeTriggerExecutor(),
  };

  @override
  Set<Type> get types => _triggers.keys.toSet();

  @override
  void onRegister() => {}; // All trigger are registered in carp_mobile_sensing.json.dart - so don't need to do anything here.

  @override
  TriggerExecutor<TriggerConfiguration>? create(TriggerConfiguration trigger) {
    debug('$runtimeType - Creating trigger executor for trigger type ${trigger.runtimeType}');
    // TODO: implement specific handling of ScheduledTrigger
    if (trigger is ScheduledTrigger) {
      warning("ScheduledTrigger is not implemented yet.");
      return null;
    }

    try {
      if (_triggers.containsKey(trigger.runtimeType)) {
        return _triggers[trigger.runtimeType]!();
      }
    } catch (e) {
      warning("$runtimeType - Failed to instantiate trigger executor for trigger type '${trigger.runtimeType}': $e");
    }
    return null;
  }
}
