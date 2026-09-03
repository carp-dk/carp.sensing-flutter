/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// A [NotificationManager] based on the [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
/// Flutter plugin.
///
/// On iOS, remember to edit the AppDelegate.swift file.
/// See https://pub.dev/packages/flutter_local_notifications#general-setup
///
/// On Android, update the AndroidManifest.xml and gradle.build files to add
/// the necessary permissions and service declaration for notifications.
/// Also add an `ic_launcher.png` square png picture in the
/// `<<application_name>>/android/app/src/main/res/drawable/` folder.
/// You can use the default app icon, just make a copy in the drawable folder.
class FlutterLocalNotificationManager implements NotificationManager {
  static final FlutterLocalNotificationManager _instance =
      FlutterLocalNotificationManager._();
  FlutterLocalNotificationManager._() : super();
  final Random _random = Random();

  factory FlutterLocalNotificationManager() => _instance;

  @override
  Future<void> configure() async {
    tz.initializeTimeZones();

    // Registers the notification icon - without it every show() throws on Android.
    await FlutterLocalNotificationsPlugin().initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveNotificationResponse,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Not permission_handler: it never completes its future if the dialog is dismissed.
    var granted = await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    debug('$runtimeType - Notification permission granted: $granted');

    info('$runtimeType configured.');
  }

  final NotificationDetails _platformChannelSpecifics =
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationManager.CHANNEL_ID,
          NotificationManager.CHANNEL_NAME,
          channelDescription: NotificationManager.CHANNEL_DESCRIPTION,
          importance: Importance.max,
          priority: Priority.max,
          ongoing: true,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Exact alarms need `SCHEDULE_EXACT_ALARM`, which Android only grants
  /// through a settings screen - so use them when granted, inexact otherwise.
  Future<AndroidScheduleMode> get _scheduleMode async =>
      await Permission.scheduleExactAlarm.isGranted
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  @override
  Future<int> createNotification({
    int? id,
    required String title,
    String? body,
  }) async {
    id ??= _random.nextInt(1000);
    await FlutterLocalNotificationsPlugin().show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _platformChannelSpecifics,
    );
    return id;
  }

  @override
  Future<int> scheduleNotification({
    int? id,
    required String title,
    String? body,
    required DateTime schedule,
  }) async {
    tz.initializeTimeZones(); // for some strange reason, the time zones are not always initialized when this method is called, so we initialize them here to be sure

    id ??= _random.nextInt(1000);
    final time = tz.TZDateTime.from(
      schedule,
      tz.getLocation(Settings().timezone),
    );

    await FlutterLocalNotificationsPlugin().zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: time,
      notificationDetails: _platformChannelSpecifics,
      androidScheduleMode: await _scheduleMode,
    );

    return id;
  }

  @override
  Future<int> scheduleRecurrentNotifications({
    int? id,
    required String title,
    String? body,
    required RecurrentScheduledTrigger schedule,
  }) async {
    tz.initializeTimeZones(); // for some strange reason, the time zones are not always initialized when this method is called, so we initialize them here to be sure

    id ??= _random.nextInt(1000);
    final time = tz.TZDateTime.from(
      schedule.firstOccurrence,
      tz.getLocation(Settings().timezone),
    );

    DateTimeComponents recurrence = switch (schedule.type) {
      RecurrentType.daily => DateTimeComponents.time,
      RecurrentType.weekly => DateTimeComponents.dayOfWeekAndTime,
      RecurrentType.monthly => DateTimeComponents.dayOfMonthAndTime,
    };

    await FlutterLocalNotificationsPlugin().zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: time,
      notificationDetails: _platformChannelSpecifics,
      androidScheduleMode: await _scheduleMode,
      matchDateTimeComponents: recurrence,
    );

    return id;
  }

  @override
  Future<void> cancelNotification(int id) async =>
      await FlutterLocalNotificationsPlugin().cancel(id: id);

  @override
  Future<void> createTaskNotification(UserTask task) async {
    if (task.notification) {
      await FlutterLocalNotificationsPlugin().show(
        id: task.id.hashCode,
        title: task.title,
        body: task.description,
        notificationDetails: _platformChannelSpecifics,
        payload: task.id,
      );
      info('$runtimeType - Notification created for $task');
    }
  }

  @override
  Future<void> scheduleTaskNotification(UserTask task) async {
    // early out if task should not create a notification when scheduled
    if (!task.notification) return;

    if (task.triggerTime.isAfter(DateTime.now())) {
      tz.initializeTimeZones(); // for some strange reason, the time zones are not always initialized when this method is called, so we initialize them here to be sure

      final time = tz.TZDateTime.from(
        task.triggerTime,
        tz.getLocation(Settings().timezone),
      );

      await FlutterLocalNotificationsPlugin().zonedSchedule(
        id: task.id.hashCode,
        title: task.title,
        body: task.description,
        scheduledDate: time,
        notificationDetails: _platformChannelSpecifics,
        androidScheduleMode: await _scheduleMode,
        payload: task.id,
      );
      task.hasNotificationBeenCreated = true;
      debug('$runtimeType - Notification scheduled for $task at $time');
    } else {
      warning(
        '$runtimeType - Can only schedule a notification in the future. '
        'task trigger time: ${task.triggerTime}.',
      );
    }
  }

  @override
  Future<int> get pendingNotificationRequestsCount async =>
      (await FlutterLocalNotificationsPlugin().pendingNotificationRequests())
          .length;

  @override
  Future<void> cancelTaskNotification(UserTask task) async {
    if (task.notification) {
      await FlutterLocalNotificationsPlugin().cancel(id: task.id.hashCode);
      info('$runtimeType - Notification canceled for $task');
    }
  }
}

/// Callback method called when a notification is clicked in the operating system.
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  String? payload = response.payload;
  debug('NotificationManager - callback on notification, payload: $payload');

  if (payload != null) {
    AppTaskController().onNotification(payload);
  } else {
    warning(
      "NotificationManager - Error in callback from notification - payload is '$payload'",
    );
  }
}
