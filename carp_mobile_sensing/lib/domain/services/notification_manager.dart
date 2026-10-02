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
///
/// The [SmartPhoneClientManager] uses [FlutterLocalNotificationManager],
/// available as [SmartPhoneClientManager.notificationManager].
abstract class NotificationManager {
  /// The maximum number of pending scheduled notifications: 64 on iOS and
  /// 500 on Android.
  static final pendingNotificationLimit = Platform.isIOS ? 64 : 500;

  /// The id of the notification channel for immediate notifications.
  static const CHANNEL_ID = 'carp_mobile_sensing_notifications';

  /// The name of the notification channel as shown in the Settings
  /// on Android phones.
  static const CHANNEL_NAME = 'CARP Basic Notifications';

  /// The description of the notification channel as shown in the Settings
  /// on Android phones.
  static const CHANNEL_DESCRIPTION = 'Notifications about tasks that the user has to do.';

  /// The id of the notification channel for scheduled notifications.
  static const SCHEDULED_CHANNEL_ID = 'carp_mobile_sensing_scheduled_notifications';

  /// The name of the notification channel as shown in the Settings
  /// on Android phones.
  static const SCHEDULED_CHANNEL_NAME = 'CARP Scheduled Notifications';

  /// The description of the notification channel as shown in the Settings
  /// on Android phones.
  static const SCHEDULED_CHANNEL_DESCRIPTION = 'Notifications about scheduled tasks that the user has to do.';

  /// Configures and sets up the notification manager.
  ///
  /// Also tries to get permission to send notifications.
  Future<void> configure();

  /// Creates an immediate notification with [id], [title], and [body].
  /// If the [id] is not specified, a random id will be generated.
  /// When tapped, [payload] is emitted on [notificationTaps].
  ///
  /// Returns the id of the notification created.
  Future<int> createNotification({int? id, required String title, String? body, String? payload});

  /// The payloads of tapped notifications created with [createNotification].
  /// Taps on task notifications are handled by the [AppTaskController].
  Stream<String> get notificationTaps;

  /// Schedules a notification with [id], [title], and [body] at the [schedule] time.
  /// If the [id] is not specified, a random id will be generated.
  ///
  /// Returns the id of the notification created.
  Future<int> scheduleNotification({int? id, required String title, String? body, required DateTime schedule});

  /// Schedules recurrent notifications with [id], [title], and [body] at the
  /// [schedule] time.
  ///
  /// Allows for daily, weekly, and monthly recurrence according to the [schedule].
  ///
  /// Note that [RecurrentScheduledTrigger.separationCount] and
  /// [RecurrentScheduledTrigger.end] are **not used**, i.e. days /
  /// weeks / months cannot be skipped in the schedule and the notifications
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

  /// Cancels (i.e., removes) the notification with [id].
  Future<void> cancelNotification(int id);

  /// Creates an immediate notification for a [task].
  Future<void> createTaskNotification(UserTask task);

  /// Schedules a notification for a [task] at its [UserTask.triggerTime].
  Future<void> scheduleTaskNotification(UserTask task);

  /// Cancels (i.e., removes) the notification for the [task].
  Future<void> cancelTaskNotification(UserTask task);

  /// The number of pending notifications.
  ///
  /// Note that on iOS there is a limit of 64 pending notifications.
  /// See https://pub.dev/packages/flutter_local_notifications#ios-pending-notifications-limit
  Future<int> get pendingNotificationRequestsCount;
}

/// A [NotificationManager] that does nothing.
///
/// Use it, e.g. in tests, where no notifications should be shown. All methods
/// return at once; the create and schedule methods return id 0.
class NoOpNotificationManager implements NotificationManager {
  @override
  Future<void> configure() async {}

  @override
  Future<int> createNotification({int? id, required String title, String? body, String? payload}) async => 0;

  @override
  Stream<String> get notificationTaps => const Stream.empty();

  @override
  Future<int> scheduleNotification({int? id, required String title, String? body, required DateTime schedule}) async =>
      0;

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
