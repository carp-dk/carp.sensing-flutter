/*
 * Copyright 2020 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// Creates a [UserTask] for an [AppTask], based on [AppTask.type].
///
/// Packages that add app task types (e.g., surveys) implement one and
/// register it with [AppTaskController.registerUserTaskFactory].
abstract class UserTaskFactory {
  /// The [AppTask.type]s this factory supports.
  List<String> types = [];

  /// Create a [UserTask] that wraps [executor].
  UserTask create(AppTaskExecutor executor);
}

/// The default [UserTaskFactory], for [AppTask.SENSING_TYPE] app tasks.
///
/// Creates a [BackgroundSensingUserTask].
class SensingUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [AppTask.SENSING_TYPE];

  @override
  UserTask create(AppTaskExecutor executor) =>
      BackgroundSensingUserTask(executor);
}

/// A task the user needs to do, e.g. fill in a survey.
///
/// It is shown in the app's task list. A user task is the runtime form of an [AppTask]. It is created by a
/// [UserTaskFactory] each time the app task is triggered, and put on the
/// [AppTaskController] queue. The app shows it to the user and calls
/// [onStart], [onCancel], [onDone] or [onExpired] as the user acts on it.
///
/// Key points:
///  * [state] follows [UserTaskState]; changes are emitted on [stateEvents].
///    Changes made by the controller are also on
///    [AppTaskController.userTaskEvents].
///  * The measures of [AppTask.backgroundTask] are collected by
///    [backgroundTaskExecutor], initialized when [onStart] is called.
///  * Subclasses can provide a [widget] for the task's UI.
///  * When done, a [CompletedAppTask] measurement with the [result] is added
///    to the study's measurements.
abstract class UserTask {
  late AppTaskExecutor _executor;
  UserTaskState _state = UserTaskState.initialized;
  final StreamController<UserTaskState> _stateController =
      StreamController.broadcast();

  /// The [AppTask] this user task was created from.
  AppTask get task => _executor.task;

  /// The id of the study deployment this task belongs to.
  ///
  /// Null if the executor has no deployment.
  String? get studyDeploymentId =>
      appTaskExecutor.deployment?.studyDeploymentId;

  /// A unique id of this user task, a v4 UUID.
  late String id;
  String get type => task.type;
  String get name => task.name;
  String get title => task.title;
  String get description => task.description;
  String get instructions => task.instructions;

  /// Whether a notification should be shown for this task.
  bool get notification => task.notification;

  /// The time this task should trigger (typically becoming visible to the user).
  late DateTime triggerTime;

  /// The time this task was added to the queue.
  late DateTime enqueued;

  /// The time this task was marked as done in the [onDone] method.
  DateTime? doneTime;

  /// The time left until this task expires, based on [AppTask.expire].
  ///
  /// Negative if this task has expired. `null` if it never expires.
  Duration? get expiresIn => (task.expire != null)
      ? triggerTime.add(task.expire!).difference(DateTime.now())
      : null;

  /// The state of this task. Setting it emits the new state on [stateEvents].
  UserTaskState get state => _state;
  set state(UserTaskState state) {
    _state = state;
    _stateController.add(state);
  }

  /// Whether the user can do this task now.
  ///
  /// True if it is enqueued, notified or canceled.
  bool get availableForUser =>
      (_state == UserTaskState.enqueued ||
      _state == UserTaskState.canceled ||
      _state == UserTaskState.notified);

  /// Whether the [NotificationManager] has created a notification for it.
  bool hasNotificationBeenCreated = false;

  /// A stream of state changes of this user task.
  ///
  /// This stream is useful in a [StreamBuilder] to listen on
  /// changes to a [UserTask].
  Stream<UserTaskState> get stateEvents => _stateController.stream;

  /// The [AppTaskExecutor] this user task wraps.
  AppTaskExecutor get appTaskExecutor => _executor;

  /// Collects the measures of [AppTask.backgroundTask] once started.
  ///
  /// Its measurements are forwarded through [appTaskExecutor].
  BackgroundTaskExecutor backgroundTaskExecutor = BackgroundTaskExecutor();

  /// The result of this task, set by [onDone]. Null until then.
  Data? result;

  /// Creates a user task wrapping [executor], with a new [id].
  UserTask(AppTaskExecutor executor) {
    _executor = executor;
    id = const Uuid().v4();
    // add the events from the background executor to the overall stream of events
    _executor.addExecutor(backgroundTaskExecutor);
  }

  /// Whether this task has a [widget] to show to the user. False by default.
  bool get hasWidget => false;

  /// The widget to be shown to the user as part of this task, if any.
  /// Note that the user interface may not be available before the [onStart]
  /// method has been called.
  Widget? get widget => null;

  /// Called by the app when the user starts this task.
  ///
  /// Initializes [backgroundTaskExecutor] and sets [state] to
  /// [UserTaskState.started].
  @mustCallSuper
  void onStart() {
    // initialize the background task which holds any measures added to the app task
    backgroundTaskExecutor.initialize(
      task.backgroundTask,
      _executor.deployment,
    );

    state = UserTaskState.started;
  }

  /// Called by the app when the user cancels this task.
  ///
  /// If [dequeue] is `true` the task is removed from the queue.
  /// Otherwise, it is kept on the queue with state [UserTaskState.canceled].
  @mustCallSuper
  void onCancel({bool dequeue = false}) {
    state = UserTaskState.canceled;
    if (dequeue) AppTaskController().dequeue(id);
  }

  /// Called by the app when this task expires.
  ///
  /// If [dequeue] is `true` (the default) the task is removed from the queue,
  /// which also deletes it from persistent storage. Pass `false` to keep it on
  /// the queue with state [UserTaskState.expired], so it still counts in
  /// [AppTaskController.taskExpired].
  @mustCallSuper
  void onExpired({bool dequeue = true}) {
    AppTaskController().expire(id);
    if (dequeue) AppTaskController().dequeue(id);
  }

  /// Called by the app when the user has finished this task.
  ///
  /// Sets [result], [doneTime] and [state], and marks the task as done in the
  /// [AppTaskController]. If [dequeue] is `true` the task is also removed
  /// from the queue.
  @mustCallSuper
  void onDone({bool dequeue = false, Data? result}) {
    this.result = result;
    doneTime = DateTime.now();
    state = UserTaskState.done;
    AppTaskController().done(id, result);
    if (dequeue) AppTaskController().dequeue(id);
  }

  /// Called by the [AppTaskController] when the user taps the notification.
  ///
  /// Does nothing by default; subclasses can override it.
  @mustCallSuper
  @protected
  void onNotification() {}

  @override
  String toString() =>
      '$runtimeType - id: $id, type: $type, name: $name, title: $title, '
      'state: ${state.name}, triggerTime: $triggerTime. doneTime: $doneTime';
}

/// The states of a [UserTask].
enum UserTaskState {
  /// Created, not yet on the queue.
  initialized,

  /// Put on the [AppTaskController] queue.
  enqueued,

  /// Removed from the [AppTaskController] queue.
  dequeued,

  /// The user has tapped the notification of this task.
  notified,

  /// Started by the user.
  started,

  /// Canceled by the user.
  canceled,

  /// Done by the user.
  done,

  /// Expired, i.e. [AppTask.expire] has passed before it was done.
  expired,

  /// An undefined state and cannot be used.
  /// Task should be ignored.
  undefined,
}

/// A user task without UI that collects sensor data in the background.
///
/// E.g. noise.
///
/// Sensing starts on [onStart] and stops on [onDone]. Created by the
/// [SensingUserTaskFactory] for app tasks of type [AppTask.SENSING_TYPE].
class BackgroundSensingUserTask extends UserTask {
  BackgroundSensingUserTask(super.executor);

  @override
  void onStart() {
    super.onStart();
    backgroundTaskExecutor.resume();
  }

  @override
  void onDone({dequeue = false, Data? result}) {
    super.onDone(dequeue: dequeue, result: result);
    backgroundTaskExecutor.pause();
  }

  /// Starts the background sensing when the user taps the notification.
  ///
  /// When the background sensing pauses, the task is marked as done.
  @mustCallSuper
  @override
  void onNotification() {
    super.onNotification();
    onStart();

    // Listen to when the background sensing pauses.
    // We do this because this background sensing task is never explicitly
    // marked as done - it just runs until the background sensing pauses.
    backgroundTaskExecutor.stateEvents
        .where((state) => state == ExecutorState.Paused)
        .listen((state) {
          debug(
            '$runtimeType - Background sensing has paused - making this user task done.',
          );
          onDone();
        });
  }
}
