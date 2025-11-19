/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// A factory which can create a [TriggerExecutor] based on the runtime type
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

/// A factory that can create a:
///
///  * [TriggerExecutor] using the [createTriggerExecutor] method
///  * [TaskExecutor] using the [getTaskExecutor] method
///
/// Note that each deployment needs its own set of trigger and task executors.
/// This is because trigger executors needs to be reused across tasks in the same
/// deployment (in the task control), while avoiding them to be reused across
/// deployments (if the trigger or task has the same name).
/// Therefore, the [dispose] methods should be called when starting the execution
/// of a new deployment.
class ExecutorFactory {
  static final ExecutorFactory _instance = ExecutorFactory._();

  final Map<Type, TriggerFactory> _triggerFactories = {};

  final Map<int, TriggerExecutor> _triggerExecutors = {};
  final Map<String, TaskExecutor> _taskExecutors = {};

  /// Get the singleton instance of [ExecutorFactory].
  ///
  /// The [ExecutorFactory] is designed to work as a singleton.
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

  /// Get the [TriggerExecutor] for a [triggerId], if available.
  TriggerExecutor? getTriggerExecutor(int triggerId) =>
      _triggerExecutors[triggerId];

  /// Create a [TriggerExecutor] based on the [trigger] type.
  /// Returns null if [trigger] is not supported by any registered [TriggerFactory]
  /// factories.
  TriggerExecutor? createTriggerExecutor(
    int triggerId,
    TriggerConfiguration trigger,
  ) {
    if (_triggerExecutors[triggerId] == null) {
      TriggerExecutor? executor;

      if (_triggerFactories[trigger.runtimeType] != null) {
        executor = _triggerFactories[trigger.runtimeType]!.create(trigger);
      }

      if (executor != null) {
        _triggerExecutors[triggerId] = executor;
      } else {
        warning(
          "$runtimeType - Unknown trigger type. Cannot find a TriggerExecutor for the trigger of type '${trigger.runtimeType}'.",
        );
        return null;
      }
    }
    return _triggerExecutors[triggerId]!;
  }

  /// Get the [TaskExecutor] for a [task] based on the task name. If the task
  /// executor does not exist, a new one is created based on the type of the task.
  TaskExecutor getTaskExecutor(TaskConfiguration task) {
    if (_taskExecutors[task.name] == null) {
      TaskExecutor executor = BackgroundTaskExecutor();
      if (task is AppTask) executor = AppTaskExecutor();
      if (task is FunctionTask) executor = FunctionTaskExecutor();

      _taskExecutors[task.name] = executor;
    }

    return _taskExecutors[task.name]!;
  }

  /// Dispose of all trigger and task executors.
  ///
  /// Used when a new deployment is to be executed.
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

    warning(
      "Unknown trigger used - cannot find a TriggerExecutor for the trigger of type '${trigger.runtimeType}'. "
      "Using an 'ImmediateTriggerExecutor' instead.",
    );
    return ImmediateTriggerExecutor();
  }
}

// /// A factory that can create a:
// ///
// ///  * [TriggerExecutor] using the [createTriggerExecutor] method
// ///  * [TaskExecutor] using the [getTaskExecutor] method
// ///
// /// Note that each deployment has its own [ExecutorFactory].
// /// This is because trigger executors needs to be reused across tasks in the same
// /// deployment (in the task control), while avoiding them to be reused across
// /// deployments (if the trigger or task has the same name).
// class ExecutorFactory {
//   final Map<int, TriggerExecutor> _triggerExecutors = {};
//   final Map<String, TaskExecutor> _taskExecutors = {};

//   /// Get the [TriggerExecutor] for a [triggerId], if available.
//   TriggerExecutor? getTriggerExecutor(int triggerId) =>
//       _triggerExecutors[triggerId];

//   /// Create a [TriggerExecutor] based on the [trigger] type.
//   TriggerExecutor createTriggerExecutor(
//     int triggerId,
//     TriggerConfiguration trigger,
//   ) {
//     if (_triggerExecutors[triggerId] == null) {
//       TriggerExecutor executor = ImmediateTriggerExecutor();

//       switch (trigger.runtimeType) {
//         case const (ElapsedTimeTrigger):
//           executor = ElapsedTimeTriggerExecutor();
//           break;
//         case const (ScheduledTrigger):
//           warning("ScheduledTrigger is not implemented yet. "
//               "Using an 'ImmediateTriggerExecutor' instead.");
//           executor = ImmediateTriggerExecutor();
//           break;
//         case const (NoOpTrigger):
//           executor = NoOpTriggerExecutor();
//           break;
//         case const (ImmediateTrigger):
//           executor = ImmediateTriggerExecutor();
//           break;
//         case const (OneTimeTrigger):
//           executor = OneTimeTriggerExecutor();
//           break;
//         case const (DelayedTrigger):
//           executor = DelayedTriggerExecutor();
//           break;
//         case const (PeriodicTrigger):
//           executor = PeriodicTriggerExecutor();
//           break;
//         case const (DateTimeTrigger):
//           executor = DateTimeTriggerExecutor();
//           break;
//         case const (RecurrentScheduledTrigger):
//           executor = RecurrentScheduledTriggerExecutor();
//           break;
//         case const (CronScheduledTrigger):
//           executor = CronScheduledTriggerExecutor();
//           break;
//         case const (SamplingEventTrigger):
//           executor = SamplingEventTriggerExecutor();
//           break;
//         case const (ConditionalSamplingEventTrigger):
//           executor = ConditionalSamplingEventTriggerExecutor();
//           break;
//         case const (ConditionalPeriodicTrigger):
//           executor = ConditionalPeriodicTriggerExecutor();
//           break;
//         case const (RandomRecurrentTrigger):
//           executor = RandomRecurrentTriggerExecutor();
//           break;
//         case const (PassiveTrigger):
//           executor = PassiveTriggerExecutor();
//           break;
//         case const (UserTaskTrigger):
//           executor = UserTaskTriggerExecutor();
//           break;
//         default:
//           warning(
//               "Unknown trigger used - cannot find a TriggerExecutor for the trigger of type '${trigger.runtimeType}'. "
//               "Using an 'ImmediateTriggerExecutor' instead.");
//           executor = ImmediateTriggerExecutor();
//       }
//       _triggerExecutors[triggerId] = executor;
//     }
//     return _triggerExecutors[triggerId]!;
//   }

//   /// Get the [TaskExecutor] for a [task] based on the task name. If the task
//   /// executor does not exist, a new one is created based on the type of the task.
//   TaskExecutor getTaskExecutor(TaskConfiguration task) {
//     if (_taskExecutors[task.name] == null) {
//       TaskExecutor executor = BackgroundTaskExecutor();
//       if (task is AppTask) executor = AppTaskExecutor();
//       if (task is FunctionTask) executor = FunctionTaskExecutor();

//       _taskExecutors[task.name] = executor;
//     }

//     return _taskExecutors[task.name]!;
//   }
// }
