import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

// The values permission_handler sends over its method channel.
const _denied = 0, _granted = 1;

/// A device needing location, which Android grants in two steps.
class _LocationishDeviceManager
    extends DeviceManager<DeviceConfiguration, DeviceRegistration> {
  _LocationishDeviceManager() : super('test.LocationishDevice');

  @override
  List<Permission> get permissions => [
    Permission.locationWhenInUse,
    Permission.locationAlways,
  ];

  @override
  void onConfigure() {}
  @override
  bool get canConnect => true;
  @override
  Future<DeviceStatus> onConnect() async => DeviceStatus.connected;
  @override
  Future<bool> onDisconnect() async => true;
  @override
  DeviceRegistration createRegistration() => DeviceRegistration();
  String get id => 'test';
  @override
  String? get displayName => 'Test device';
}

/// A deployment of [protocol], ready to be asked what permissions it needs.
SmartphoneDeployment deploymentOf(SmartphoneStudyProtocol protocol) =>
    SmartphoneDeployment.fromSmartphoneStudyProtocol(
      studyDeploymentId: 'test',
      primaryDeviceRoleName: protocol.primaryDevice.roleName,
      protocol: protocol,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();

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
              final permission = call.arguments as int;
              calls.add('check($permission)');
              return granted.contains(permission) ? _granted : _denied;
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

  test('permissions are requested one at a time, in declared order', () async {
    final calls = fakePermissionHandler();

    await requestPermissionsInOrder(_LocationishDeviceManager().permissions);

    // One request per permission, in order. Batching them into a single
    // request() would break Android's location ladder: locationAlways is only
    // offered once locationWhenInUse is granted.
    expect(calls.where((call) => call.startsWith('request')), [
      'request(${Permission.locationWhenInUse.value})',
      'request(${Permission.locationAlways.value})',
    ]);
  });

  test('locationAlways always climbs the ladder, however declared', () async {
    // A sampling package really does declare it this way, without the
    // 'when in use' step Android requires first.
    final calls = fakePermissionHandler();

    await requestPermissionsInOrder([
      Permission.bluetoothScan,
      Permission.locationAlways,
    ]);

    expect(calls.where((call) => call.startsWith('request')), [
      'request(${Permission.bluetoothScan.value})',
      'request(${Permission.locationWhenInUse.value})',
      'request(${Permission.locationAlways.value})',
    ]);
  });

  test('a permission listed twice is only asked for once', () async {
    final calls = fakePermissionHandler();

    await requestPermissionsInOrder([
      Permission.locationAlways,
      Permission.locationWhenInUse, // already covered by the ladder above
    ]);

    expect(calls.where((call) => call.startsWith('request')), [
      'request(${Permission.locationWhenInUse.value})',
      'request(${Permission.locationAlways.value})',
    ]);
  });

  test('already granted permissions are not asked for again', () async {
    final calls = fakePermissionHandler(
      alreadyGranted: {Permission.locationWhenInUse.value},
    );

    await requestPermissionsInOrder(_LocationishDeviceManager().permissions);

    expect(calls.where((call) => call.startsWith('request')), [
      'request(${Permission.locationAlways.value})',
    ]);
  });

  test('a study with a notifying task needs notification permission', () {
    final protocol = SmartphoneStudyProtocol(
      ownerId: 'test',
      name: 'Notifying protocol',
    )..addPrimaryDevice(Smartphone());

    expect(deploymentOf(protocol).hasNotifyingTask, isFalse);

    protocol.addTaskControl(
      ImmediateTrigger(),
      AppTask(type: 'test', notification: true),
      protocol.primaryDevice,
      Control.Start,
    );

    // Android 13+ needs Permission.notification, and a task that notifies is
    // the only reason to ask for it.
    expect(deploymentOf(protocol).hasNotifyingTask, isTrue);
  });

  test('concurrent permission requests never overlap', () async {
    final calls = fakePermissionHandler();

    // Deployment events, probes and devices all ask at once on a normal launch.
    // Android shows one dialog at a time and denies - without showing - any
    // request that arrives while another is up, so these must not overlap.
    final client = SmartPhoneClientManager();
    final permissions = _LocationishDeviceManager().permissions;
    await Future.wait([
      client.requestPermissions(permissions),
      client.requestPermissions(permissions),
    ]);

    // The later runs find them granted by the first, and ask for nothing.
    expect(calls.where((call) => call.startsWith('request')), [
      'request(${Permission.locationWhenInUse.value})',
      'request(${Permission.locationAlways.value})',
    ]);
  });

  test('a failed permission request does not block later requests', () async {
    // A request that throws must not poison the request queue - a study that
    // fails must not block permissions for every study after it.
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

    final client = SmartPhoneClientManager();
    await client.requestPermissions([Permission.notification]); // throws inside
    await client.requestPermissions([Permission.notification]);

    expect(requests, 2);
  });

  test('auto-connect never asks - an ungranted device stays disconnected', () async {
    final calls = fakePermissionHandler(); // nothing granted yet
    final device = _LocationishDeviceManager()
      ..configure(DeviceConfiguration(roleName: 'test'));

    // CAMS connects devices automatically on deployment and task start. Those
    // paths must not trigger a dialog - the device just stays disconnected
    // until the user connects it from the app.
    expect(await device.connect(), DeviceStatus.disconnected);
    expect(calls.where((call) => call.startsWith('request')), isEmpty);
  });

  test('the user connecting a device asks first, then connects', () async {
    final calls = fakePermissionHandler(); // nothing granted yet
    final device = _LocationishDeviceManager()
      ..configure(DeviceConfiguration(roleName: 'test'));

    // The app's connect button: ask, then connect.
    await device.requestPermissions();
    expect(await device.connect(), DeviceStatus.connected);

    expect(calls.where((call) => call.startsWith('request')), [
      'request(${Permission.locationWhenInUse.value})',
      'request(${Permission.locationAlways.value})',
    ]);
  });

  test('a device denied its permissions refuses to connect', () async {
    fakePermissionHandler(denyAll: true);
    final device = _LocationishDeviceManager()
      ..configure(DeviceConfiguration(roleName: 'test'));

    await device.requestPermissions(); // user taps connect, denies the dialog
    expect(await device.connect(), DeviceStatus.disconnected);
  });

  test('a device with its permissions connects', () async {
    fakePermissionHandler(
      alreadyGranted: {
        Permission.locationWhenInUse.value,
        Permission.locationAlways.value,
      },
    );
    final device = _LocationishDeviceManager()
      ..configure(DeviceConfiguration(roleName: 'test'));

    expect(await device.hasPermissions(), isTrue);
    expect(await device.connect(), DeviceStatus.connected);
  });

  test("notifications are asked for - that permission is the app's, not a "
      "device's", () async {
    final calls = fakePermissionHandler();

    // Every other permission moved to the device that needs it. Notification
    // is the app's own - no device declares it - so the client manager asks
    // for it when configuring, which is what this stands in for. Android 13+
    // shows no notification at all until something does.
    expect(
      SamplingPackageRegistry().packages
          .expand((package) => package.deviceManager.permissions),
      isNot(contains(Permission.notification)),
    );

    await SmartPhoneClientManager().requestPermissions([
      Permission.notification,
    ]);

    expect(calls, contains('request(${Permission.notification.value})'));
  });
}
