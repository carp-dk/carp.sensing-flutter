/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// Runs a [TaskConfiguration] when its trigger fires.
///
/// Created by the [ExecutorFactory] and started or stopped by a
/// [TaskControlExecutor]. Each task type has its own executor:
/// [BackgroundTaskExecutor], [AppTaskExecutor] and [FunctionTaskExecutor].
abstract class TaskExecutor<TConfig extends TaskConfiguration>
    extends AggregateExecutor<TConfig> {
  final StreamGroup<ExecutorState> _statesGroup = StreamGroup.broadcast();

  /// The [TaskConfiguration] for this task executor.
  TConfig get task => configuration!;

  /// The probes in this task executor. Empty for tasks without measures.
  List<Probe> get probes;

  /// The merged state events of all [probes] in this task executor.
  Stream<ExecutorState> get states => _statesGroup.stream;
}

/// Runs a [BackgroundTask] by creating and running one [Probe] per measure.
///
/// Probes are created with [SamplingPackageRegistry.create]; measures with no
/// probe on this phone are skipped with a warning. On resume, the devices of
/// the probes are connected. If the task has a duration, the executor pauses
/// itself after that duration. It also pauses when all its probes have paused.
class BackgroundTaskExecutor extends TaskExecutor<BackgroundTask> {
  StreamSubscription<ExecutorState>? _subscription;

  @override
  List<Probe> get probes =>
      executors.map((executor) => executor as Probe).toList();

  /// Are all [probes] in a paused state?
  bool get haveAllProbesPaused =>
      !probes.any((probe) => probe.state != ExecutorState.Paused);

  @override
  bool onInitialize() {
    if (task.measures != null) {
      for (Measure measure in task.measures!) {
        // create a new probe for each measure - this ensures that we can have
        // multiple measures of the same type, each using its own probe instance
        Probe? probe = SamplingPackageRegistry().create(measure.type);
        if (probe != null) {
          addExecutor(probe);
          _statesGroup.add(probe.stateEvents);

          probe.initialize(measure, deployment!);
        } else {
          warning(
            "A probe for measure type '${measure.type}' could not be created. "
            'This may be because this probe is not available on the operating system '
            'of this phone (primary device) or on the connected device. '
            'Or it may be because the sampling package containing this probe has not '
            'been registered in the SamplingPackageRegistry.',
          );
        }
      }
    }
    return true;
  }

  @override
  Future<bool> onResume() async {
    // Early out if no probes.
    if (probes.isEmpty) return true;

    // Early out if already running (this is a background task)
    if (state == ExecutorState.Resumed) {
      warning(
        '$runtimeType - Trying to resume $this but it is already resumed. Ignoring this.',
      );
      return false;
    }

    // Listen to pause this background executor when all of its underlying
    // probes have paused - Issue #384
    _subscription = states
        .where((event) => event == ExecutorState.Paused)
        .listen((_) {
          if (haveAllProbesPaused && state == ExecutorState.Resumed) {
            debug(
              '$runtimeType - All probes are paused - pausing this $this too.',
            );
            pause();
          }
        });

    // Check if the devices for this task is connected.
    await connectAllConnectableDevices();

    if (configuration?.duration != null) {
      // If the task has a duration (optional), stop it again after this duration has passed.
      Timer(
        Duration(seconds: configuration!.duration!.inSeconds.truncate()),
        () => pause(),
      );
    }

    // Now - finally - we can start the probes.
    return await super.onResume();
  }

  /// Starts connecting the devices of all [probes].
  ///
  /// Skips devices already connecting. Does not wait for the connections.
  Future<void> connectAllConnectableDevices() async {
    debug(
      '$runtimeType - Trying to connect to all connectable devices for this background executor.',
    );

    probes
        .where((probe) => !probe.deviceManager.isConnecting)
        .forEach((probe) async => await probe.deviceManager.connect());
  }

  @override
  Future<bool> onPause() async {
    _subscription?.cancel();
    return await super.onPause();
  }
}

/// Runs a [FunctionTask] by calling its function each time it is resumed.
class FunctionTaskExecutor extends TaskExecutor<FunctionTask> {
  @override
  List<Probe> get probes => [];

  @override
  bool onInitialize() => true;

  @override
  Future<bool> onResume() async {
    if (configuration?.function != null) {
      Function.apply(configuration!.function!, []);
    }
    return true;
  }
}

/// Runs an [AppTask] by putting it on the [AppTaskController] queue.
///
/// Each time it is resumed (e.g. by a [PeriodicTrigger]), the executor is
/// wrapped in a new [UserTask] and enqueued. The app then starts, cancels or
/// finishes the task with [UserTask.onStart], [UserTask.onCancel] and
/// [UserTask.onDone]. The executor pauses itself again after 5 seconds, so it
/// can be resumed by the next trigger.
///
/// Special-purpose [UserTask]s are created by a [UserTaskFactory] registered
/// with [AppTaskController.registerUserTaskFactory].
class AppTaskExecutor<TConfig extends AppTask> extends TaskExecutor<TConfig> {
  @override
  List<Probe> get probes => []; // an AppTask itself does not have probes.

  @override
  bool onInitialize() => true;

  @override
  Future<bool> onResume() async {
    // when an app task is started, create a new UserTask by adding it to the queue
    UserTask? userTask = await AppTaskController().enqueue(this);

    // automatically stop this executor again to be reused later
    // issue => https://github.com/cph-cachet/carp.sensing-flutter/issues/429
    Future.delayed(const Duration(seconds: 5), () => pause());

    return userTask != null;
  }

  // does nothing when pausing an app task
  @override
  Future<bool> onPause() async => true;
}
