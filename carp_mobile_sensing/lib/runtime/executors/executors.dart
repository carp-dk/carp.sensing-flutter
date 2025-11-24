/*
 * Copyright 2018-2025 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

//-----------------------------------------------------------------------------
//                                        EXECUTORS
//-----------------------------------------------------------------------------

/// The state of an [Executor].
///
/// The runtime state has the following state machine:
///
/// ```
/// +---------------------------------------------------------------+      +-----------+
/// |  +---------+    +-------------+    +---------+     +--------+ |   -> | undefined |
/// |  | created | -> | initialized | -> | resumed | <-> | paused | |      +-----------+
/// |  +---------+    +-------------+    +---------+     +--------+ |   -> | disposed  |
/// +---------------------------------------------------------------+      +-----------+
/// ```
enum ExecutorState {
  /// Created and ready to be initialized.
  Created,

  /// Initialized and ready to be resumed.
  Initialized,

  /// Resumed and actively collecting data.
  Resumed,

  /// Paused not collecting data. Can be resumed in this state.
  Paused,

  /// Permanently disposed. Cannot be used anymore.
  Disposed,

  /// Undefined state.
  ///
  /// Typically an executor becomes undefined if it cannot be initialized
  /// or if this executor (probe) is not supported on the specific phone / OS.
  Undefined,
}

/// A [Executor] is responsible for executing data collection based on a
/// configuration [TConfig].
///
/// The behavior of an executor is controlled by its life-cycle methods: [initialize],
/// [resume], [pause], and [dispose]. A paused executor can be resumed again.
///
/// The [state] property reveals the probe's current state.
/// The [stateEvents] is a stream of state changes which can be listen to as a
/// broadcast stream.
///
/// If an error occurs the state of a probe becomes undefined. This is, for example,
/// used when an exception occurs.
///
/// An Executor returns collected data in the [measurements] stream.
/// This is the main usage of an executor. For example, to listens to all
/// measurements generated in all studies running in a client, use:
///
/// ```
/// SmartPhoneClientManager().measurements.listen(
///    (measurement) => print(measurement),
/// );
/// ```
abstract class Executor<TConfig> {
  /// The deployment that this executor is part of executing.
  SmartphoneDeployment? get deployment;

  /// The configuration of this executor as set in [initialize].
  TConfig? get configuration;

  /// The runtime state of this executor.
  ExecutorState get state;

  /// The runtime state changes of this executor.
  Stream<ExecutorState> get stateEvents;

  /// The stream of [Measurement] collected by this executor.
  Stream<Measurement> get measurements;

  /// Configure and initialize the executor before using it.
  void initialize(TConfig configuration, [SmartphoneDeployment? deployment]);

  /// Resume the executor.
  void resume();

  /// Pause the executor. Paused until [resume] is called.
  void pause();

  /// Dispose of this executor.
  ///
  /// If not already paused, [pause] will be called first.
  ///
  /// Once disposed, the executor cannot be used anymore and nothing will happen
  /// if any of the life cycle methods are called.
  void dispose();
}

/// An abstract implementation of a [Executor] to extend from.
abstract class AbstractExecutor<TConfig> implements Executor<TConfig> {
  final StreamController<Measurement> _measurementsController =
      StreamController.broadcast();
  final StreamController<ExecutorState> _stateEventController =
      StreamController.broadcast();
  late _ExecutorStateMachine _stateMachine;
  SmartphoneDeployment? _deployment;
  TConfig? _configuration;
  // bool _isResuming = false;

  @override
  SmartphoneDeployment? get deployment => _deployment;

  @override
  TConfig? get configuration => _configuration;

  @override
  Stream<ExecutorState> get stateEvents => _stateEventController.stream;

  @override
  Stream<Measurement> get measurements => _measurementsController.stream;

  @override
  ExecutorState get state => _stateMachine.state;

  AbstractExecutor() {
    _stateMachine = _CreatedState(this);
  }

  void _setState(_ExecutorStateMachine state) {
    _stateMachine = state;
    _stateEventController.add(state.state);
  }

  /// Add [measurement] to the [measurements] stream.
  void addMeasurement(Measurement measurement) =>
      _measurementsController.add(measurement);

  /// Add [error] to the [measurements] stream.
  void addError(Object error, [StackTrace? stacktrace]) =>
      _measurementsController.addError(error, stacktrace);

  @override
  @nonVirtual
  void initialize(TConfig configuration, [SmartphoneDeployment? deployment]) {
    info('Initializing $this [$hashCode] - $configuration');
    _deployment = deployment;
    _configuration = configuration;
    _stateMachine.initialize();
  }

  @override
  @nonVirtual
  void resume() {
    // _isResuming = true;
    info('Resuming $this - $configuration');
    _stateMachine.resume();
  }

  @override
  @nonVirtual
  void pause() {
    info('Pausing $this - $configuration');
    _stateMachine.pause();
  }

  @override
  @nonVirtual
  void dispose() {
    info('Disposing $this - $configuration');
    _stateMachine.dispose();
  }

  void error() => _stateMachine.error();

  /// Callback when this executor is initialized.
  /// Returns true if successfully initialized, false otherwise.
  ///
  /// Note that this is a non-async method and should hence be 'light-weight'
  /// and not block execution for a long duration.
  @protected
  bool onInitialize();

  /// Callback when this executor is resumed.
  /// Returns true if successfully resumed, false otherwise.
  @protected
  Future<bool> onResume();

  /// Callback when this executor is paused.
  /// Returns true if successfully paused, false otherwise.
  @protected
  Future<bool> onPause();

  /// Callback when this executor is disposed.
  ///
  /// Subclasses should override this, to implement any cleanup to be
  /// done before disposing.
  @protected
  Future<void> onDispose() async {}

  @override
  String toString() => '$runtimeType [$hashCode] (${state.name})';
}

/// An abstract class used to implement aggregated executors (i.e., executors
/// with a set of underlying executors).
///
/// See [SmartphoneDeploymentExecutor] and [TaskExecutor] for examples.
abstract class AggregateExecutor<TConfig> extends AbstractExecutor<TConfig> {
  static final DeviceInfo deviceInfo = DeviceInfo();
  final StreamGroup<Measurement> _group = StreamGroup.broadcast();
  final Set<Executor<dynamic>> _executors = {};

  Set<Executor<dynamic>> get executors => _executors;

  AggregateExecutor() : super() {
    _group.add(super.measurements);
  }

  @override
  Stream<Measurement> get measurements => _group.stream;

  /// Add the [executor] to the list of [executors] and forwards its measurements
  /// to this aggregate executor's stream of [measurements].
  void addExecutor(Executor<dynamic> executor) {
    _executors.add(executor);
    _group.add(executor.measurements);
  }

  /// Remove the [executor] to the list of [executors].
  void removeExecutor(Executor<dynamic> executor) {
    _group.remove(executor.measurements);
    _executors.remove(executor);
  }

  @override
  Future<bool> onResume() async {
    for (var executor in _executors) {
      executor.resume();
    }
    return true;
  }

  @override
  Future<bool> onPause() async {
    for (var executor in _executors) {
      executor.pause();
    }
    return true;
  }

  @override
  Future<void> onDispose() async {
    for (var executor in _executors) {
      executor.dispose();
    }
    _group.close();
  }
}

// All of the below executor state machine classes are private and only used
// internally, and are therefore not documented.

abstract class _ExecutorStateMachine {
  ExecutorState get state;

  void initialize();
  void resume();
  void pause();
  void dispose();
  void error();
}

abstract class _AbstractExecutorState implements _ExecutorStateMachine {
  AbstractExecutor<dynamic> executor;
  _AbstractExecutorState(this.executor);

  // Default behavior is to print a warning.
  // If a state supports this method, this behavior is overwritten in
  // the state implementation classes below.

  @override
  void initialize() => _printWarning('initialize');

  @override
  void resume() => _printWarning('resume');

  @override
  void pause() => _printWarning('pause');

  // Default dispose behavior. A Executor can be disposed in all states.
  @override
  void dispose() {
    if (state == ExecutorState.Resumed) {
      warning(
        "Trying to dispose a ${executor.runtimeType} in a 'resumed' state."
        "Consider pausing it first.",
      );
    }
    executor.onDispose().then((_) {
      executor._setState(_DisposedState(executor));
    });
  }

  // Default error behavior. A Executor can experience an error and become
  // undefined in all states.
  @override
  void error() {
    warning('Error in ${executor.runtimeType}.');
    executor._setState(_UndefinedState(executor));
  }

  // Print default warning if calling an operation in a wrong state.
  void _printWarning(String operation) => warning(
    "Trying to $operation a ${executor.runtimeType}[${executor.hashCode}] "
    "in a state where this cannot be done - state: '${state.name}'. "
    'Ignoring this.',
  );

  @override
  String toString() => state.name;
}

class _CreatedState extends _AbstractExecutorState
    implements _ExecutorStateMachine {
  _CreatedState(Executor<dynamic> executor)
    : super(executor as AbstractExecutor);

  @override
  ExecutorState get state => ExecutorState.Created;

  @override
  void initialize() {
    try {
      if (executor.onInitialize()) {
        executor._setState(_InitializedState(executor));
      }
    } catch (error) {
      warning('Error initializing ${executor.runtimeType}: $error');
      executor._setState(_UndefinedState(executor));
    }
  }
}

class _InitializedState extends _AbstractExecutorState
    implements _ExecutorStateMachine {
  _InitializedState(Executor<dynamic> executor)
    : super(executor as AbstractExecutor);

  @override
  ExecutorState get state => ExecutorState.Initialized;

  @override
  void resume() {
    executor.onResume().then((resumed) {
      if (resumed) executor._setState(_ResumedState(executor));
      // executor._isResuming = false;
    });
  }
}

class _ResumedState extends _AbstractExecutorState {
  _ResumedState(Executor<dynamic> executor)
    : super(executor as AbstractExecutor);

  @override
  ExecutorState get state => ExecutorState.Resumed;

  // it is ok to re-resume an executor
  @override
  void resume() {
    executor.onResume().then((resumed) {
      if (resumed) executor._setState(_ResumedState(executor));
      // executor._isResuming = false;
    });
  }

  @override
  void pause() {
    executor.onPause().then((paused) {
      if (paused) executor._setState(_PausedState(executor));
    });
  }
}

class _PausedState extends _AbstractExecutorState {
  _PausedState(Executor<dynamic> executor)
    : super(executor as AbstractExecutor);

  @override
  ExecutorState get state => ExecutorState.Paused;

  @override
  void resume() {
    executor.onResume().then((resumed) {
      if (resumed) executor._setState(_ResumedState(executor));
      // executor._isResuming = false;
    });
  }
}

class _DisposedState extends _AbstractExecutorState
    implements _ExecutorStateMachine {
  _DisposedState(Executor<dynamic> executor)
    : super(executor as AbstractExecutor);
  @override
  ExecutorState get state => ExecutorState.Disposed;
}

class _UndefinedState extends _AbstractExecutorState
    implements _ExecutorStateMachine {
  _UndefinedState(Executor<dynamic> executor)
    : super(executor as AbstractExecutor);
  @override
  ExecutorState get state => ExecutorState.Undefined;
}
