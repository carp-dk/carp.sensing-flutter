import 'dart:convert';

import 'package:carp_core/carp_core.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => Core.ensureInitialized());

  final phone = Smartphone(roleName: 'phone');
  final tablet = Smartphone(roleName: 'tablet');
  final heartRateMonitor = AltBeacon(roleName: 'heart_rate_monitor');
  final bike = AltBeacon(roleName: 'bike');

  // A protocol with two primary devices. One connected device is connected to
  // 'phone' and one to 'tablet'.
  StudyProtocol familyProtocol() {
    final protocol = StudyProtocol(ownerId: 'owner', name: 'protocol')
      ..addPrimaryDevice(phone)
      ..addPrimaryDevice(tablet)
      ..addConnectedDevice(heartRateMonitor, phone)
      ..addConnectedDevice(bike, tablet);

    // addConnectedDevice stores the connection as
    // DeviceConnection(connectedDevice.roleName, primaryDevice.roleName).
    expect(
      protocol.connections,
      containsAll([
        isA<DeviceConnection>()
            .having((c) => c.roleName, 'roleName', 'heart_rate_monitor')
            .having((c) => c.connectedToRoleName, 'connectedToRoleName', 'phone'),
        isA<DeviceConnection>()
            .having((c) => c.roleName, 'roleName', 'bike')
            .having((c) => c.connectedToRoleName, 'connectedToRoleName', 'tablet'),
      ]),
    );

    return protocol;
  }

  group('StudyProtocol.getConnectedDevices', () {
    test('returns the devices connected to the given primary device', () {
      final protocol = familyProtocol();

      expect(protocol.getConnectedDevices(phone), [heartRateMonitor]);
      expect(protocol.getConnectedDevices(tablet), [bike]);
    });

    test('returns an empty list for a primary device without connected devices', () {
      final protocol = StudyProtocol(ownerId: 'owner', name: 'protocol')
        ..addPrimaryDevice(phone)
        ..addPrimaryDevice(tablet)
        ..addConnectedDevice(heartRateMonitor, phone);

      expect(protocol.getConnectedDevices(tablet), isEmpty);
    });

    test('returns an empty list when no devices are connected', () {
      final protocol = StudyProtocol(ownerId: 'owner', name: 'protocol')..addPrimaryDevice(phone);

      expect(protocol.getConnectedDevices(phone), isEmpty);
    });

    test('works on a protocol restored from JSON', () {
      final json = jsonDecode(jsonEncode(familyProtocol().toJson())) as Map<String, dynamic>;
      final protocol = StudyProtocol.fromJson(json);

      final restoredPhone = protocol.primaryDevices.firstWhere((device) => device.roleName == 'phone');
      expect(protocol.getConnectedDevices(restoredPhone).map((device) => device.roleName), ['heart_rate_monitor']);
    });
  });
}
