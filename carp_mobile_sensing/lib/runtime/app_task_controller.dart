/*
 * Copyright 2020 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// Keeps the queue of [UserTask]s that the user needs to do.
///
/// A singleton. When an [AppTask] is triggered, its [AppTaskExecutor] is
/// wrapped in a [UserTask] by a [UserTaskFactory] and [enqueue]d here. The
/// app shows [userTaskQueue] to the user (e.g., as a task list) and listens to
/// [userTaskEvents] for changes.
///
/// Key points:
///  * Asks the [NotificationManager] to notify about each enqueued task, if
///    notifications are enabled in [initialize].
///  * Tasks from schedulable triggers are first [buffer]ed, then
///    [enqueueBufferedTasks] schedules as many as the OS notification limit
///    allows.
///  * Tasks whose [AppTask.expire] has passed are expired once an hour.
///  * The queue is restored from the [PersistenceService] on [initialize].
///
/// See also [UserTask], whose callbacks the app calls to start and finish a
/// task.
class AppTaskController {
  static final AppTaskController _instance = AppTaskController._();
  final StreamController<UserTask> _controller = StreamController.broadcast();
  Timer? _garbageCollector;
  bool _notificationsEnabled = true;

  /// The map of all [UserTask]s by their id.
  final Map<String, UserTask> _userTaskMap = {};

  /// A buffer of tasks that are not yet scheduled.
  final List<UserTaskBufferItem> _userTaskBuffer = [];

  /// Whether this controller sends notifications to the user.
  ///
  /// Set in [initialize].
  bool get notificationsEnabled => _notificationsEnabled;

  /// The client's notification controller for sending notifications to the user.
  NotificationManager get notificationManager =>
      SmartPhoneClientManager().notificationManager;

  /// All [UserTask]s, including those scheduled to trigger in the future.
  List<UserTask> get userTasks => _userTaskMap.values.toList();

  /// The [UserTask]s whose trigger time has passed.
  ///
  /// These are the tasks to show to the user. Includes done and expired tasks
  /// until they are [dequeue]d.
  List<UserTask> get userTaskQueue => _userTaskMap.values
      .where((task) => task.triggerTime.isBefore(DateTime.now()))
      .toList();

  /// Emits a [UserTask] each time the controller changes it.
  ///
  /// That is, when it is enqueued, dequeued, notified, done or expired.
  /// Other state changes (e.g. started) are only on [UserTask.stateEvents].
  ///
  /// Useful in a [StreamBuilder] to rebuild a task list.
  Stream<UserTask> get userTaskEvents => _controller.stream;

  /// The number of tasks in the [userTaskQueue].
  int get taskTotal => userTaskQueue.length;

  /// The number of done tasks in the [userTaskQueue].
  int get taskCompleted =>
      userTaskQueue.where((task) => task.state == UserTaskState.done).length;

  /// The number of expired tasks in the [userTaskQueue].
  int get taskExpired =>
      userTaskQueue.where((task) => task.state == UserTaskState.expired).length;

  /// The number of [UserTaskState.enqueued] tasks in the [userTaskQueue].
  int get taskPending => userTaskQueue
      .where((task) => task.state == UserTaskState.enqueued)
      .length;

  /// Returns the singleton [AppTaskController].
  factory AppTaskController() => _instance;

  AppTaskController._() {
    registerUserTaskFactory(SensingUserTaskFactory());
  }

  /// Restores the queue of [UserTask]s from persistent storage.
  ///
  /// Also starts the hourly check for expired tasks.
  ///
  /// If [enableNotifications] is true, a notification is shown when a task
  /// is [enqueue]d.
  ///
  /// Called by [SmartPhoneClientManager.configure].
  Future<void> initialize({bool enableNotifications = true}) async {
    _notificationsEnabled = enableNotifications;

    // Restore previous queue from persistent storage.
    await _restoreQueue();

    // set up a timer which expires tasks in the queue once an hour
    _garbageCollector = Timer.periodic(const Duration(hours: 1), (_) {
      for (var task in userTasks) {
        if (task.expiresIn?.isNegative ?? false) expire(task.id);
      }
    });
  }

  /// Stops the expiry check and closes [userTaskEvents].
  ///
  /// No further app tasks can be enqueued afterwards.
  void dispose() {
    _garbageCollector?.cancel();
    _controller.close();
  }

  final Map<String, UserTaskFactory> _userTaskFactories = {};

  /// Registers [factory] for each [AppTask.type] in [UserTaskFactory.types].
  ///
  /// A later factory for the same type replaces an earlier one. A
  /// [SensingUserTaskFactory] is registered by default.
  void registerUserTaskFactory(UserTaskFactory factory) {
    for (var type in factory.types) {
      _userTaskFactories[type] = factory;
    }
  }

  /// Returns the [UserTask] with [id], or `null` if no task is found.
  UserTask? getUserTask(String id) => _userTaskMap[id];

  /// Creates a [UserTask] for the [AppTask] run by [executor] and enqueues it.
  ///
  /// [triggerTime] is when the task becomes available; defaults to now.
  /// If [sendNotification] and [notificationsEnabled] are true, the
  /// [NotificationManager] is asked to show a notification now (if
  /// [triggerTime] is null) or to schedule one for [triggerTime]. It still
  /// skips tasks with [AppTask.notification] off and past trigger times.
  ///
  /// Returns `null` if no [UserTaskFactory] is registered for the task's type.
  Future<UserTask?> enqueue(
    AppTaskExecutor executor, {
    DateTime? triggerTime,
    bool sendNotification = true,
  }) async {
    if (_userTaskFactories[executor.task.type] == null) {
      warning(
        '$runtimeType - Could not enqueue AppTask. Could not find a factory for creating '
        "a UserTask for type '${executor.task.type}'",
      );
      return null;
    } else {
      UserTask userTask = _userTaskFactories[executor.task.type]!.create(
        executor,
      );
      userTask.state = UserTaskState.enqueued;
      userTask.enqueued = DateTime.now();
      userTask.triggerTime = triggerTime ?? DateTime.now();
      _userTaskMap[userTask.id] = userTask;
      _controller.add(userTask);
      debug('$runtimeType - Enqueued $userTask');

      if (notificationsEnabled && sendNotification) {
        // create notification
        (triggerTime == null)
            ? await notificationManager.createTaskNotification(userTask)
            : await notificationManager.scheduleTaskNotification(userTask);
      }
      return userTask;
    }
  }

  /// Buffers [executor] from [taskControl] to be enqueued later.
  ///
  /// The task triggers at [triggerTime], default now.
  ///
  /// Buffered tasks are enqueued by [enqueueBufferedTasks].
  void buffer(
    AppTaskExecutor executor,
    TaskControl taskControl, {
    DateTime? triggerTime,
    bool sendNotification = true,
  }) {
    _userTaskBuffer.add(
      UserTaskBufferItem(
        taskControl,
        executor,
        sendNotification,
        triggerTime ?? DateTime.now(),
      ),
    );
  }

  /// Enqueues the tasks buffered with [buffer], earliest first.
  ///
  /// Only as many tasks are enqueued as there are free notification slots
  /// ([NotificationManager.pendingNotificationLimit] minus pending ones).
  /// The rest are discarded and buffered again on a later resume.
  /// Each enqueued task updates [TaskControl.hasBeenScheduledUntil].
  ///
  /// Called by the [SmartphoneDeploymentExecutor] when it resumes.
  Future<void> enqueueBufferedTasks() async {
    _userTaskBuffer.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    var remainingNotifications =
        NotificationManager.pendingNotificationLimit -
        (await SmartPhoneClientManager()
            .notificationManager
            .pendingNotificationRequestsCount);

    var numberOfTasksToEnqueue = min(
      remainingNotifications,
      _userTaskBuffer.length,
    );

    // Being mindful of the OS limitations, only schedule however many
    // tasks as remaining notification slots
    List<UserTaskBufferItem> toEnqueue = _userTaskBuffer.sublist(
      0,
      numberOfTasksToEnqueue,
    );

    debug('$runtimeType - Enqueuing ${toEnqueue.length} tasks.');

    for (var item in toEnqueue) {
      item.taskControl.hasBeenScheduledUntil = item.triggerTime;
      await enqueue(
        item.taskExecutor,
        triggerTime: item.triggerTime,
        sendNotification: item.sendNotification,
      );
    }

    // Discard the tasks that we couldn't queue, they will be re-queued later.
    _userTaskBuffer.clear();
  }

  /// Removes the [UserTask] with [id] and cancels its notification.
  void dequeue(String id) {
    UserTask? userTask = _userTaskMap[id];
    if (userTask == null) {
      warning(
        "$runtimeType - Could not dequeue AppTask - id is not valid: '$id'",
      );
    } else {
      userTask.state = UserTaskState.dequeued;
      _userTaskMap.remove(id);
      _controller.sink.add(userTask);
      info('$runtimeType - Dequeued $userTask');

      if (notificationsEnabled) {
        notificationManager.cancelTaskNotification(userTask);
      }
    }
  }

  /// Called when the user taps the OS notification of the [UserTask] with [id].
  ///
  /// If the task is enqueued or canceled, moves it to
  /// [UserTaskState.notified] and calls [UserTask.onNotification].
  void onNotification(String id) {
    UserTask? userTask = getUserTask(id);
    if (userTask != null) {
      info('$runtimeType - User Task notification clicked - $userTask');

      // only notify if this task is still active
      if (userTask.state == UserTaskState.enqueued ||
          userTask.state == UserTaskState.canceled) {
        userTask.state = UserTaskState.notified;
        _controller.sink.add(userTask);
        userTask.onNotification();
      }
    } else {
      warning(
        "$runtimeType - Error in callback from notification - no task with id '$id' found.",
      );
    }
  }

  /// Marks the [UserTask] with [id] as done, with an optional [result].
  ///
  /// A done task stays on the queue. Use [dequeue] to remove it.
  /// Usually called through [UserTask.onDone].
  void done(String id, [Data? result]) {
    UserTask? userTask = _userTaskMap[id];
    if (userTask == null) {
      warning(
        "$runtimeType - Could not find User Task - id is not valid: '$id'",
      );
    } else {
      userTask.state = UserTaskState.done;
      userTask.doneTime = DateTime.now();
      userTask.result = result;
      _controller.sink.add(userTask);
      info('$runtimeType - Marked $userTask as done');

      notificationManager.cancelTaskNotification(userTask);
    }
  }

  /// Marks the [UserTask] with [id] as expired, unless it is done.
  ///
  /// Also cancels its notification.
  ///
  /// An expired task stays on the queue. Use [dequeue] to remove it.
  void expire(String id) {
    UserTask? userTask = _userTaskMap[id];
    if (userTask == null) {
      warning(
        "$runtimeType - Could not expire AppTask - id is not valid: '$id'",
      );
    } else {
      // only expire tasks which are not already done or expired
      if (userTask.state != UserTaskState.done) {
        userTask.state = UserTaskState.expired;
        _controller.sink.add(userTask);
        info('$runtimeType - Expired $userTask');
      }
      notificationManager.cancelTaskNotification(userTask);
    }
  }

  /// Removes all tasks of [study] and cancels their notifications.
  void removeStudy(SmartphoneStudy study) {
    final userTasks = _userTaskMap.values
        .where(
          (task) =>
              task.appTaskExecutor.deployment?.studyDeploymentId ==
              study.studyDeploymentId,
        )
        .toList();

    for (var task in userTasks) {
      dequeue(task.id);
    }
  }

  /// Restore the queue from persistent storage for [study].
  /// If [study] is null, restore the queue for all studies.
  ///
  /// Returns true if successful.
  Future<bool> _restoreQueue([SmartphoneStudy? study]) async {
    info('$runtimeType - Restoring User Task Queue');
    bool success = true;

    try {
      final snapshots = await PersistenceService().getUserTasks(study);
      debug(
        '$runtimeType - Found ${snapshots.length} task(s) in persistent storage for ${study?.studyDeploymentId ?? "all studies"}.',
      );

      // now create new AppTaskExecutors, initialize them, and add them to the queue
      for (var snapshot in snapshots) {
        if (snapshot.studyDeploymentId != null &&
            snapshot.deviceRoleName != null) {
          // find the study and deployment based on the snapshot
          SmartphoneStudy? study = SmartPhoneClientManager().getStudy(
            snapshot.studyDeploymentId!,
            snapshot.deviceRoleName!,
          );
          SmartphoneDeployment? deployment = study?.deployment;

          if (study == null || deployment == null) {
            warning(
              '$runtimeType - Could not find study deployment information based on snapshot: $snapshot',
            );
          } else {
            AppTaskExecutor executor = AppTaskExecutor();
            executor.initialize(snapshot.task, deployment);

            // add the stream of measurements to the overall smartphone deployment controller
            // issue => https://github.com/cph-cachet/carp.sensing-flutter/issues/437
            SmartPhoneClientManager()
                .getStudyController(study)
                ?.executor
                .addMeasurements(executor.measurements);

            // now put the restored task back on the queue
            if (_userTaskFactories[executor.task.type] == null) {
              warning(
                '$runtimeType - Could not enqueue AppTask. Could not find a factory for creating '
                "a UserTask for type '${executor.task.type}'",
              );
            } else {
              UserTask userTask = _userTaskFactories[executor.task.type]!
                  .create(executor);
              userTask.id = snapshot.id;
              userTask.state = snapshot.state;
              userTask.enqueued = snapshot.enqueued;
              userTask.triggerTime = snapshot.triggerTime;
              userTask.doneTime = snapshot.doneTime;

              _userTaskMap[userTask.id] = userTask;
              debug(
                '$runtimeType - Enqueued UserTask from loaded task queue: $userTask',
              );
            }
          }
        }
      }
    } catch (exception) {
      success = false;
      warning('$runtimeType - Failed to load task queue - $exception');
    }
    return success;
  }
}

/// An app task waiting in the [AppTaskController] buffer to be enqueued.
///
/// Created by [AppTaskController.buffer].
class UserTaskBufferItem {
  AppTaskExecutor<AppTask> taskExecutor;
  TaskControl taskControl;
  DateTime triggerTime;
  bool sendNotification;

  UserTaskBufferItem(
    this.taskControl,
    this.taskExecutor,
    this.sendNotification,
    this.triggerTime,
  );
}

/// A serializable snapshot of a [UserTask].
///
/// Saved by the [PersistenceService] so the [AppTaskController] can restore
/// its queue after an app restart.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UserTaskSnapshot extends Serializable {
  late String id;
  late AppTask task;
  late UserTaskState state;
  late DateTime enqueued;
  late DateTime triggerTime;
  DateTime? doneTime;
  late bool hasNotificationBeenCreated;
  String? studyDeploymentId;
  String? deviceRoleName;

  UserTaskSnapshot(
    this.id,
    this.task,
    this.state,
    this.enqueued,
    this.triggerTime,
    this.doneTime,
    this.hasNotificationBeenCreated,
    this.studyDeploymentId,
    this.deviceRoleName,
  ) : super();

  UserTaskSnapshot.fromUserTask(UserTask userTask) : super() {
    id = userTask.id;
    task = userTask.task;
    state = userTask.state;
    enqueued = userTask.enqueued;
    triggerTime = userTask.triggerTime;
    doneTime = userTask.doneTime;
    hasNotificationBeenCreated = userTask.hasNotificationBeenCreated;
    studyDeploymentId = userTask.studyDeploymentId;
    deviceRoleName =
        userTask.appTaskExecutor.deployment?.deviceConfiguration.roleName;
  }

  @override
  Function get fromJsonFunction => _$UserTaskSnapshotFromJson;

  factory UserTaskSnapshot.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<UserTaskSnapshot>(json);

  @override
  Map<String, dynamic> toJson() => _$UserTaskSnapshotToJson(this);

  @override
  String toString() =>
      '$runtimeType - id:$id, '
      'task: $task, state: ${state.name}, enqueued: $enqueued, '
      'triggerTime: $triggerTime, doneTime: $doneTime, '
      'studyDeploymentId: $studyDeploymentId, deviceRoleName: $deviceRoleName';
}
