/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Manages user notifications, including creating, scheduling, and canceling
/// notifications.
///
/// This manager serves two purposes:
///
/// 1. It is used by the [AppTaskController] to create notification about
/// [UserTask]s (which are created based on [AppTask] in the [StudyProtocol]).
/// This happens automatically, if the app task is configured to
/// send a notification.
///
/// 2. It can be used by the app to create, schedule, and cancel app-specific
/// notifications. This is done using the [createNotification], [scheduleNotification],
/// and [scheduleRecurrentNotifications] methods, which
/// creates an immediate, scheduled, or recurrent notification, respectively.
abstract class NotificationManager {
  /// The upper limit of scheduled notification, platform dependent.
  static final pendingNotificationLimit = Platform.isIOS ? 64 : 500;

  /// The id of the notification channel.
  static const CHANNEL_ID = 'carp_mobile_sensing_notifications';

  /// The name of the notification channel as shown in the Settings
  /// on Android phones.
  static const CHANNEL_NAME = 'CARP Basic Notifications';

  /// The description of the notification channel as shown in the Settings
  /// on Android phones.
  static const CHANNEL_DESCRIPTION =
      'Notifications about tasks that the user has to do.';

  /// The id of the notification channel.
  static const SCHEDULED_CHANNEL_ID =
      'carp_mobile_sensing_scheduled_notifications';

  /// The name of the notification channel as shown in the Settings
  /// on Android phones.
  static const SCHEDULED_CHANNEL_NAME = 'CARP Scheduled Notifications';

  /// The description of the notification channel as shown in the Settings
  /// on Android phones.
  static const SCHEDULED_CHANNEL_DESCRIPTION =
      'Notifications about scheduled tasks that the user has to do.';

  /// Configure and set up the notification manager.
  /// Also tries to get permissions to send notifications.
  Future<void> configure();

  /// Create an immediate notification with [id], [title], and [body].
  /// If the [id] is not specified, a random id will be generated.
  ///
  /// Returns the id of the notification created.
  Future<int> createNotification({
    int? id,
    required String title,
    String? body,
  });

  /// Schedule a notification with [id], [title], and [body] at the [schedule] time.
  /// If the [id] is not specified, a random id will be generated.
  ///
  /// Returns the id of the notification created.
  Future<int> scheduleNotification({
    int? id,
    required String title,
    String? body,
    required DateTime schedule,
  });

  /// Schedule recurrent notifications with [id], [title], and [body] at the
  /// [schedule] time.
  ///
  /// Allows for daily, weekly, and monthly recurrence according to the [schedule].
  ///
  /// Note that [RecurrentScheduledTrigger.separationCount] and
  /// [RecurrentScheduledTrigger.end] are **not used**, i.e. days /
  /// weeks / months cannot be skipped in the scheduled and the notifications
  /// keeps recurring indefinitely. If you want to stop a recurrent notification
  /// schedule, use the [cancelNotification] method.
  ///
  /// If the [id] is not specified, a random id will be generated.
  ///
  /// Returns the id of the notification created.
  Future<int> scheduleRecurrentNotifications({
    int? id,
    required String title,
    String? body,
    required RecurrentScheduledTrigger schedule,
  });

  /// Cancel (i.e., remove) the notification with [id].
  Future<void> cancelNotification(int id);

  /// Create an immediate notification for a [task].
  Future<void> createTaskNotification(UserTask task);

  /// Schedule a notification for a [task] at the [task.triggerTime].
  Future<void> scheduleTaskNotification(UserTask task);

  /// Cancel (i.e., remove) the notification for the [task].
  Future<void> cancelTaskNotification(UserTask task);

  /// The number of pending notifications.
  ///
  /// Note that on iOS there is a limit of 64 pending notifications.
  /// See https://pub.dev/packages/flutter_local_notifications#ios-pending-notifications-limit
  Future<int> get pendingNotificationRequestsCount;
}

/// A no-operation notification manager that does nothing.
class NoOpNotificationManager implements NotificationManager {
  @override
  Future<void> configure() async {}

  @override
  Future<int> createNotification({
    int? id,
    required String title,
    String? body,
  }) async => 0;

  @override
  Future<int> scheduleNotification({
    int? id,
    required String title,
    String? body,
    required DateTime schedule,
  }) async => 0;

  @override
  Future<int> scheduleRecurrentNotifications({
    int? id,
    required String title,
    String? body,
    required RecurrentScheduledTrigger schedule,
  }) async => 0;

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> scheduleTaskNotification(UserTask task) async {}

  @override
  Future<void> createTaskNotification(UserTask task) async {}

  @override
  Future<void> cancelTaskNotification(UserTask task) async {}

  @override
  Future<int> get pendingNotificationRequestsCount async => 0;
}
