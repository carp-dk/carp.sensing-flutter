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

  /// Fake the OS: records the calls, grants whatever is asked for.
  List<String> fakePermissionHandler({Set<int> alreadyGranted = const {}}) {
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

  test('a device without its permissions refuses to connect', () async {
    fakePermissionHandler(); // nothing granted, nothing requested
    final device = _LocationishDeviceManager()
      ..configure(DeviceConfiguration(roleName: 'test'));

    // This is why permissions must be requested *before* connecting: a device
    // that connects first sees no permissions, gives up, and nothing retries.
    expect(await device.hasPermissions(), isFalse);
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
}
