/*
 * Copyright 2020-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'runtime.dart';

/// A controller of [UserTask]s which is accessible in the [userTaskQueue].
class AppTaskController {
  static final AppTaskController _instance = AppTaskController._();
  final StreamController<UserTask> _controller = StreamController.broadcast();
  Timer? _garbageCollector;

  /// Should this App Task Controller send notifications to the user.
  bool notificationsEnabled = true;

  final Map<String, UserTask> _userTaskMap = {};

  /// The entire list of all [UserTask]s.
  ///
  /// Note that this list contains all tasks which has already triggered
  /// and which are planned to trigger in the future.
  List<UserTask> get userTasks => _userTaskMap.values.toList();

  /// A buffer of tasks that are not yet scheduled.
  final List<UserTaskBufferItem> _userTaskBuffer = [];

  /// The queue of [UserTask]s that the user need to attend to.
  List<UserTask> get userTaskQueue => _userTaskMap.values
      .where((task) => task.triggerTime.isBefore(DateTime.now()))
      .toList();

  /// A stream of [UserTask] events generate whenever a user task change state,
  /// like enqueued, dequeued, done, and expire.
  ///
  /// This stream is useful in a [StreamBuilder] to listen on
  /// changes to the [userTaskQueue].
  Stream<UserTask> get userTaskEvents => _controller.stream;

  /// The total number of tasks.
  int get taskTotal => userTaskQueue.length;

  /// The number of tasks completed so far.
  int get taskCompleted =>
      userTaskQueue.where((task) => task.state == UserTaskState.done).length;

  /// The number of tasks expired so far.
  int get taskExpired =>
      userTaskQueue.where((task) => task.state == UserTaskState.expired).length;

  /// The number of tasks pending so far.
  int get taskPending => userTaskQueue
      .where((task) => task.state == UserTaskState.enqueued)
      .length;

  /// Get the singleton instance of [AppTaskController].
  ///
  /// The [AppTaskController] is designed to work as a singleton.
  factory AppTaskController() => _instance;

  AppTaskController._() {
    registerUserTaskFactory(SensingUserTaskFactory());
  }

  /// Initialize and set up the app controller.
  ///
  /// If [enableNotifications] is true, a notification will be added to
  /// the phone's notification system when a task is enqueued via the
  /// [enqueue] method.
  Future<void> initialize({
    bool enableNotifications = true,
  }) async {
    // set up a timer which cleans up in the queue once an hour
    _garbageCollector = Timer.periodic(const Duration(hours: 1), (timer) {
      for (var task in userTasks) {
        if (task.expiresIn != null && task.expiresIn!.isNegative) {
          expire(task.id);
        }
      }
    });

    notificationsEnabled = enableNotifications;
    if (notificationsEnabled) {
      await SmartPhoneClientManager().notificationController?.initialize();
    }
  }

  /// Dispose this app task controller.
  ///
  /// No further app tasks can be enqueued to a closed controller.
  void dispose() {
    _garbageCollector?.cancel();
    _controller.close();
  }

  final Map<String, UserTaskFactory> _userTaskFactories = {};

  /// Register a [UserTaskFactory] which can create [UserTask]s
  /// for the specified [AppTask] types.
  void registerUserTaskFactory(UserTaskFactory factory) {
    for (var type in factory.types) {
      _userTaskFactories[type] = factory;
    }
  }

  /// Get an [UserTask] from the [userTasks] based on its [id].
  /// Returns `null` if no task is found.
  UserTask? getUserTask(String id) => _userTaskMap[id];

  /// Put [executor] on the [userTasks] for access by the app.
  ///
  /// [triggerTime] specifies when the task should trigger, i.e., be available.
  /// Notify the user if [sendNotification] and [notificationsEnabled] is true.
  /// If [triggerTime] is null, a notification is send immediately.
  ///
  /// Returns the [UserTask] added to the [userTasks].
  ///
  /// Returns `null` if not successful.
  Future<UserTask?> enqueue(
    AppTaskExecutor executor, {
    DateTime? triggerTime,
    bool sendNotification = true,
  }) async {
    if (_userTaskFactories[executor.task.type] == null) {
      warning(
          '$runtimeType - Could not enqueue AppTask. Could not find a factory for creating '
          "a UserTask for type '${executor.task.type}'");
      return null;
    } else {
      UserTask userTask =
          _userTaskFactories[executor.task.type]!.create(executor);
      userTask.state = UserTaskState.enqueued;
      userTask.enqueued = DateTime.now();
      userTask.triggerTime = triggerTime ?? DateTime.now();
      _userTaskMap[userTask.id] = userTask;
      _controller.sink.add(userTask);
      debug('$runtimeType - Enqueued $userTask');

      if (notificationsEnabled && sendNotification) {
        // create notification
        (triggerTime == null)
            ? await SmartPhoneClientManager()
                .notificationController
                ?.createTaskNotification(userTask)
            : await SmartPhoneClientManager()
                .notificationController
                ?.scheduleTaskNotification(userTask);
      }
      return userTask;
    }
  }

  /// Buffer the [executor] originating from [taskControl] for later scheduling.
  /// The buffered task executors is enqueued by calling [enqueueBufferedTasks].
  void buffer(
    AppTaskExecutor executor,
    TaskControl taskControl, {
    DateTime? triggerTime,
    bool sendNotification = true,
  }) {
    debug('$runtimeType - Buffering task $executor for later scheduling.');
    _userTaskBuffer.add(UserTaskBufferItem(
      taskControl,
      executor,
      sendNotification,
      triggerTime ?? DateTime.now(),
    ));
  }

  /// Enqueue all tasks buffered with [buffer].
  /// This method is called by the [DeploymentExecutor] when a deployment is
  /// finished.
  /// It will sort the tasks based on their trigger time and then schedule
  /// the first N tasks where N is the number of available notification slots.
  Future<void> enqueueBufferedTasks() async {
    _userTaskBuffer.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    var remainingNotifications =
        NotificationController.pendingNotificationLimit -
            (await SmartPhoneClientManager()
                    .notificationController
                    ?.pendingNotificationRequestsCount ??
                0);

    var numberOfTasksToEnqueue =
        min(remainingNotifications, _userTaskBuffer.length);

    // Being mindful of the OS limitations, only schedule however many
    // tasks as remaining notification slots
    List<UserTaskBufferItem> toEnqueue =
        _userTaskBuffer.sublist(0, numberOfTasksToEnqueue);

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

    // Persist the tasks that were just enqueued
    SmartPhoneClientManager().save();
  }

  /// De-queue (remove) an [UserTask] from the [userTasks].
  void dequeue(String id) {
    UserTask? userTask = _userTaskMap[id];
    if (userTask == null) {
      warning(
          "$runtimeType - Could not dequeue AppTask - id is not valid: '$id'");
    } else {
      userTask.state = UserTaskState.dequeued;
      _userTaskMap.remove(id);
      _controller.sink.add(userTask);
      info('$runtimeType - Dequeued $userTask');

      if (notificationsEnabled) {
        SmartPhoneClientManager()
            .notificationController
            ?.cancelTaskNotification(userTask);
      }
    }
  }

  /// Callback when a notification in the OS is clicked.
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
          "$runtimeType - Error in callback from notification - no task with id '$id' found.");
    }
  }

  /// Mark the [UserTask] with [id] as done.
  /// [result] may contain the result obtained from the task.
  /// Note that a done task remains on the queue. If you want to remove a
  /// task from the queue, use the [dequeue] method.
  void done(String id, [Data? result]) {
    UserTask? userTask = _userTaskMap[id];
    if (userTask == null) {
      warning(
          "$runtimeType - Could not find User Task - id is not valid: '$id'");
    } else {
      userTask.state = UserTaskState.done;
      userTask.result = result;
      _controller.sink.add(userTask);
      info('$runtimeType - Marked $userTask as done');

      SmartPhoneClientManager()
          .notificationController
          ?.cancelTaskNotification(userTask);
    }
  }

  /// Expire an [UserTask].
  /// Note that an expired task remains on the queue. If you want to remove a
  /// task from the queue, use the [dequeue] method.
  void expire(String id) {
    UserTask? userTask = _userTaskMap[id];
    if (userTask == null) {
      warning(
          "$runtimeType - Could not expire AppTask - id is not valid: '$id'");
    } else {
      // only expire tasks which are not already done or expired
      if (userTask.state != UserTaskState.done) {
        userTask.state = UserTaskState.expired;
        _controller.sink.add(userTask);
        info('$runtimeType - Expired $userTask');
      }
      SmartPhoneClientManager()
          .notificationController
          ?.cancelTaskNotification(userTask);
    }
  }

  /// Removes all tasks for a study deployment from the queue and cancels
  /// all notifications generated for these tasks.
  void removeStudyDeployment(String studyDeploymentId) {
    final userTasks = _userTaskMap.values
        .where((task) =>
            task.appTaskExecutor.deployment?.studyDeploymentId ==
            studyDeploymentId)
        .toList();

    for (var userTask in userTasks) {
      dequeue(userTask.id);
    }
  }

  /// Restore the queue from persistent storage. Returns `true` if successful.
  Future<bool> restoreQueue() async {
    bool success = true;

    try {
      final snapshots = await Persistence().getUserTasks();

      // now create new AppTaskExecutors, initialize them, and add them to the queue
      for (var snapshot in snapshots) {
        AppTaskExecutor executor = AppTaskExecutor();

        // find the deployment
        SmartphoneDeployment? deployment;
        if (snapshot.studyDeploymentId != null &&
            snapshot.deviceRoleName != null) {
          deployment = SmartPhoneClientManager()
              .lookupStudyRuntime(
                snapshot.studyDeploymentId!,
                snapshot.deviceRoleName!,
              )
              ?.deployment;
        }
        if (deployment == null) {
          warning(
              '$runtimeType - Could not find deployment information based on snapshot: $snapshot');
        } else {
          executor.initialize(snapshot.task, deployment);

          // now put the restored task back on the queue
          if (_userTaskFactories[executor.task.type] == null) {
            warning(
                '$runtimeType - Could not enqueue AppTask. Could not find a factory for creating '
                "a UserTask for type '${executor.task.type}'");
          } else {
            UserTask userTask =
                _userTaskFactories[executor.task.type]!.create(executor);
            userTask.id = snapshot.id;
            userTask.state = snapshot.state;
            userTask.enqueued = snapshot.enqueued;
            userTask.triggerTime = snapshot.triggerTime;

            _userTaskMap[userTask.id] = userTask;
            debug(
                '$runtimeType - Enqueued UserTask from loaded task queue: $userTask');
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

class UserTaskBufferItem {
  AppTaskExecutor<AppTask> taskExecutor;
  TaskControl taskControl;
  DateTime triggerTime;
  bool sendNotification;

  UserTaskBufferItem(this.taskControl, this.taskExecutor, this.sendNotification,
      this.triggerTime);
}

/// A snapshot of a [UserTask] at any given time. Used for saving user tasks
/// persistently across app restart.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class UserTaskSnapshot extends Serializable {
  late String id;
  late AppTask task;
  late UserTaskState state;
  late DateTime enqueued;
  late DateTime triggerTime;
  late bool hasNotificationBeenCreated;
  String? studyDeploymentId;
  String? deviceRoleName;

  UserTaskSnapshot(
    this.id,
    this.task,
    this.state,
    this.enqueued,
    this.triggerTime,
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
    hasNotificationBeenCreated = userTask.hasNotificationBeenCreated;
    studyDeploymentId = userTask.studyDeploymentId;
    deviceRoleName =
        userTask.appTaskExecutor.deployment?.deviceConfiguration.roleName;
  }

  @override
  Function get fromJsonFunction => _$UserTaskSnapshotFromJson;

  factory UserTaskSnapshot.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as UserTaskSnapshot;

  @override
  Map<String, dynamic> toJson() => _$UserTaskSnapshotToJson(this);

  @override
  String toString() =>
      '$runtimeType - id:$id, task: $task, state: $state, enqueued: $enqueued, triggerTime: $triggerTime, studyDeploymentId: $studyDeploymentId, deviceRoleName: $deviceRoleName';
}
