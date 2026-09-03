import 'dart:async';
import 'dart:math';

import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

// The values permission_handler sends over its method channel.
const _denied = 0, _granted = 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Fake the OS: records the calls; grants whatever is asked for, unless
  /// [denyAll] - then the user taps "Don't allow" on every dialog.
  List<String> fakePermissionHandler({
    Set<int> alreadyGranted = const {},
    bool denyAll = false,
  }) {
    final calls = <String>[];
    final granted = {...alreadyGranted};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              return granted.contains(call.arguments as int)
                  ? _granted
                  : _denied;
            case 'requestPermissions':
              final requested = (call.arguments as List).cast<int>();
              calls.add('request(${requested.join(',')})');
              if (denyAll) return {for (final p in requested) p: _denied};
              granted.addAll(requested);
              return {for (final p in requested) p: _granted};
            default:
              return null;
          }
        });

    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );
    return calls;
  }

  String request(Permission p) => 'request(${p.value})';

  test('permissions are requested one at a time, in declared order', () async {
    final calls = fakePermissionHandler();

    await requestPermissionsInOrder([
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ]);

    // One request per permission, in order. Batching them into a single
    // request() would break Android's location ladder: locationAlways is only
    // offered once locationWhenInUse is granted.
    expect(calls, [
      request(Permission.locationWhenInUse),
      request(Permission.locationAlways),
    ]);
  });

  test('locationAlways always climbs the ladder, however declared', () async {
    final calls = fakePermissionHandler();

    await requestPermissionsInOrder([
      Permission.bluetoothScan,
      Permission.locationAlways,
    ]);

    expect(calls, [
      request(Permission.bluetoothScan),
      request(Permission.locationWhenInUse),
      request(Permission.locationAlways),
    ]);
  });

  test('a permission listed twice is only asked for once', () async {
    final calls = fakePermissionHandler();

    await requestPermissionsInOrder([
      Permission.locationAlways,
      Permission.locationWhenInUse, // already covered by the ladder above
    ]);

    expect(calls, [
      request(Permission.locationWhenInUse),
      request(Permission.locationAlways),
    ]);
  });

  test('already granted permissions are not asked for again', () async {
    final calls = fakePermissionHandler(
      alreadyGranted: {Permission.locationWhenInUse.value},
    );

    await requestPermissionsInOrder([
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ]);

    expect(calls, [request(Permission.locationAlways)]);
  });

  test('concurrent permission requests never overlap', () async {
    // Fake an OS whose dialog stays up until the user answers: each request
    // blocks on a completer. Android denies - without showing - any request
    // that arrives while another dialog is up, so at most one may be in flight.
    final dialogs = <Completer<void>>[];
    var inFlight = 0, maxInFlight = 0;
    final granted = <int>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              return granted.contains(call.arguments as int)
                  ? _granted
                  : _denied;
            case 'requestPermissions':
              final dialog = Completer<void>();
              dialogs.add(dialog);
              maxInFlight = max(maxInFlight, ++inFlight);
              await dialog.future;
              inFlight--;
              final asked = (call.arguments as List).cast<int>();
              granted.addAll(asked);
              return {for (final p in asked) p: _granted};
            default:
              return null;
          }
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );

    // Deployment events, probes and devices all ask at once on a normal launch.
    final client = SmartPhoneClientManager();
    final permissions = [Permission.locationWhenInUse, Permission.locationAlways];
    final done = Future.wait([
      client.requestPermissions(permissions),
      client.requestPermissions(permissions),
      client.requestPermissions([Permission.notification]),
    ]);

    // The user answers one dialog at a time; a new one appears only after.
    for (var answered = 0; answered < 3; answered++) {
      await pumpEventQueue();
      expect(dialogs.length, answered + 1, reason: 'exactly one dialog up');
      dialogs[answered].complete();
    }
    await done;

    expect(maxInFlight, 1);
    // The second run found location granted by the first, and asked nothing.
    expect(dialogs.length, 3);
  });

  test('a failed permission request does not block later requests', () async {
    // A request that throws must not poison the queue - a study that fails
    // must not block permissions for every study after it.
    var requests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              return _denied;
            case 'requestPermissions':
              if (++requests == 1) throw PlatformException(code: 'ERROR');
              final asked = (call.arguments as List).cast<int>();
              return {for (final p in asked) p: _granted};
            default:
              return null;
          }
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );

    final client = SmartPhoneClientManager();
    await client.requestPermissions([Permission.notification]); // throws inside
    await client.requestPermissions([Permission.notification]);

    expect(requests, 2);
  });
}
