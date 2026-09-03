import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const _notifications = MethodChannel('dexterous.com/flutter/local_notifications');
const _permissions = MethodChannel('flutter.baseflow.com/permissions/methods');

// The values permission_handler sends over its method channel.
const _denied = 0, _granted = 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Fakes Android: records the calls made on both plugin channels.
  List<String> fakeAndroid({bool exactAlarmGranted = false}) {
    final calls = <String>[];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(_notifications, (call) async {
      calls.add(call.method);
      if (call.method == 'zonedSchedule') {
        final specifics = (call.arguments as Map)['platformSpecifics'] as Map;
        calls.add('scheduleMode=${specifics['scheduleMode']}');
      }
      return true;
    });

    messenger.setMockMethodCallHandler(_permissions, (call) async {
      calls.add('permission.${call.method}');
      return exactAlarmGranted ? _granted : _denied;
    });

    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(_notifications, null);
      messenger.setMockMethodCallHandler(_permissions, null);
    });
    return calls;
  }

  test('the plugin is initialized before the permission dialog', () async {
    final calls = fakeAndroid();

    await FlutterLocalNotificationManager().configure();

    // initialize() is what stores the notification icon on Android. Asking
    // first would leave every show() throwing if the dialog is dismissed.
    expect(calls, ['initialize', 'requestNotificationsPermission']);
  });

  test('notifications schedule inexactly without SCHEDULE_EXACT_ALARM',
      () async {
    final calls = fakeAndroid();

    await FlutterLocalNotificationManager().scheduleNotification(
      title: 'test',
      schedule: DateTime.now().add(const Duration(hours: 1)),
    );

    // Exact scheduling throws without the permission, which Android only
    // grants through a settings screen.
    expect(calls, contains('scheduleMode=inexactAllowWhileIdle'));
  });

  test('notifications schedule exactly when the permission is granted',
      () async {
    final calls = fakeAndroid(exactAlarmGranted: true);

    await FlutterLocalNotificationManager().scheduleNotification(
      title: 'test',
      schedule: DateTime.now().add(const Duration(hours: 1)),
    );

    expect(calls, contains('scheduleMode=exactAllowWhileIdle'));
  });
}
