import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_esense_package/esense.dart';

String _encode(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  late StudyProtocol protocol;
  late Smartphone phone;
  late ESenseDevice eSense;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUpAll(() {
    CarpMobileSensing.ensureInitialized();

    // register the eSense sampling package
    SamplingPackageRegistry().register(ESenseSamplingPackage());

    // Initialization of serialization
    CarpMobileSensing();

    // Create a new study protocol.
    protocol =
        SmartphoneStudyProtocol(
            ownerId: 'alex@uni.dk',
            name: 'eSense package test',
          )
          ..description =
              'Testing the eSense sampling package with a simple study protocol.';

    // Define which devices are used for data collection.
    phone = Smartphone(roleName: 'SM-A320FL');
    eSense = ESenseDevice(roleName: 'eSense earplug', samplingRate: 10);

    protocol
      ..addPrimaryDevice(phone)
      ..addConnectedDevice(eSense, phone);

    // adding all available measures to one one trigger and one task
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..measures = SamplingPackageRegistry().dataTypes
            .map((type) => Measure(type: type.type))
            .toList(),
      phone,
    );

    // Add a background task that immediately starts collecting eSense button and
    // sensor events from the eSense device.
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..addMeasure(Measure(type: ESenseSamplingPackage.ESENSE_BUTTON))
        ..addMeasure(Measure(type: ESenseSamplingPackage.ESENSE_SENSOR)),
      eSense,
    );
  });

  test('CAMSStudyProtocol -> JSON', () async {
    print(protocol);
    print(toJsonString(protocol));
    expect(protocol.ownerId, 'alex@uni.dk');
    await writeToFile(toJsonString(protocol), 'protocol.json');
  });

  test('StudyProtocol -> JSON -> StudyProtocol :: deep assert', () async {
    final studyJson = toJsonString(protocol);
    StudyProtocol protocolFromJson = SmartphoneStudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), studyJson);
  });

  test('JSON File -> StudyProtocol', () async {
    // Read the study protocol from json file
    String plainJson = File('test/json/protocol.json').readAsStringSync();

    StudyProtocol protocol = StudyProtocol.fromJson(
      json.decode(plainJson) as Map<String, dynamic>,
    );

    expect(protocol.ownerId, 'alex@uni.dk');
    expect(protocol.primaryDevice.roleName, phone.roleName);
    expect(protocol.connectedDevices?.first.roleName, eSense.roleName);
    print(toJsonString(protocol));
  });

  test('Measure -> JSON', () async {
    final data = ESenseButton(pressed: true, deviceName: 'eSense-123');

    final measurement = Measurement.fromData(data);
    expect(
      measurement.data.dataType.namespace,
      ESenseSamplingPackage.ESENSE_NAMESPACE,
    );

    print(_encode(measurement.toJson()));
  });

  test('Config types', () async {
    final allData = [
      ESenseDevice(roleName: 'eSense earplug', samplingRate: 10),
      BLEDeviceRegistration(
        bleAddress: '00:11:22:33:44:55',
        bleName: 'eSense 1234',
      ),
    ];

    for (var data in allData) {
      final dataJson = toJsonString(data);
      final dataFromJson = Function.apply(data.fromJsonFunction, [
        json.decode(dataJson) as Map<String, dynamic>,
      ]);
      print(toJsonString(dataFromJson));
      expect(toJsonString(dataFromJson), equals(dataJson));
    }
  });

  test('Data types', () async {
    final allData = [
      ESenseButton(deviceName: 'deviceName', pressed: true),
      ESenseSensor(
        deviceName: 'deviceName',
        packetIndex: 1,
        accel: [1, 2, 3],
        gyro: [4, 5, 6],
      ),
    ];

    for (var data in allData) {
      final dataJson = toJsonString(data);
      final dataFromJson = Function.apply(data.fromJsonFunction, [
        json.decode(dataJson) as Map<String, dynamic>,
      ]);
      print(toJsonString(dataFromJson));
      expect(toJsonString(dataFromJson), equals(dataJson));
    }
  });
}
