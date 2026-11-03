import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';
import 'package:movesense_plus/movesense_plus.dart' as ms;
import 'package:movesense_plus/movesense_plus_platform_interface.dart';

/// A fake Movesense plugin: connects instantly and answers with the test JSON files.
class _FakePlatform extends MovesensePlatform {
  final events = StreamController<ms.MovesenseConnectionEvent>.broadcast();
  final notifications = <String, ms.MdsNotificationCallback>{};

  @override
  Stream<ms.MovesenseConnectionEvent> get connectionEvents => events.stream;

  @override
  Future<void> connect(String address) async => scheduleMicrotask(
    () => events.add(
      ms.MovesenseConnectionEvent(type: ms.MovesenseConnectionEventType.connected, address: address, serial: '123'),
    ),
  );

  @override
  Future<void> disconnect(String address) async {}

  @override
  Future<ms.MdsResponse> request(ms.MdsRequestMethod method, String uri, String contract) async => ms.MdsResponse(
    body: uri.endsWith('/Info') ? File('test/json/info.json').readAsStringSync() : '{"Content": 0}',
    statusCode: 200,
  );

  @override
  int subscribe(
    String uri,
    String contract, {
    ms.MdsSuccessCallback? onSubscribe,
    ms.MdsErrorCallback? onSubscribeError,
    required ms.MdsNotificationCallback onNotification,
    ms.MdsErrorCallback? onSubscriptionError,
  }) {
    notifications[uri] = onNotification;
    return notifications.length;
  }

  @override
  Future<void> unsubscribe(int subscriptionId) async {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();
  SamplingPackageRegistry().register(MovesenseSamplingPackage());

  test('connects through movesense_plus and streams HR and device info', () async {
    final platform = _FakePlatform();
    MovesensePlatform.instance = platform;

    final manager = MovesenseDeviceManager(MovesenseDevice.DEVICE_TYPE)
      ..configure(MovesenseDevice())
      ..pair(bleAddress: '0C:8C:DC:1B:23:BF', bleName: 'Movesense 233830000816');
    final connected = manager.statusEvents.firstWhere((s) => s == DeviceStatus.connected);
    await manager.connect();
    await connected;

    expect(manager.serial, '123');
    expect(manager.movesenseDeviceType, MovesenseDeviceType.HR2);
    expect(manager.batteryLevel, 80);
    expect(manager.createRegistration().deviceInfo?['hw'], 'H4');

    final hrProbe = MovesenseHRProbe()..deviceManager = manager;
    final hr = hrProbe.stream!.first;
    await pumpEventQueue();
    final hrJson = File('test/json/hr.json').readAsStringSync();
    for (var i = 0; i <= 10; i++) {
      platform.notifications['123/Meas/HR']!(hrJson);
    }
    expect(((await hr).data as MovesenseHR).rr, 976);

    final info = await (MovesenseDeviceProbe()..deviceManager = manager).getMeasurement();
    expect((info!.data as MovesenseDeviceInformation).hardwareType, 'H4');
  });

  test('HR without R-R intervals parses', () {
    final hr = MovesenseHR.fromMovesenseData({
      'Body': {'average': 60.5, 'rrData': <int>[]},
    });
    expect(hr.rr, isNull);
  });
}
