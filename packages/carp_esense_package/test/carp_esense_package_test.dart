import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_esense_package/esense.dart';

String _encode(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  late StudyProtocol protocol;
  late Smartphone phone;
  late ESenseDevice eSense;

  setUpAll(() {
    CarpMobileSensing.ensureInitialized();

    // register the eSense sampling package
    SamplingPackageRegistry().register(ESenseSamplingPackage());

    // Initialization of serialization
    CarpMobileSensing();

    // Create a new study protocol.
    protocol = StudyProtocol(
      ownerId: 'alex@uni.dk',
      name: 'Context package test',
    );
    // Define which devices are used for data collection.
    phone = Smartphone(roleName: 'SM-A320FL');
    eSense = ESenseDevice(
      roleName: 'eSense earplug',
      deviceName: 'eSense-0223',
      samplingRate: 10,
    );

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
  });

  test('StudyProtocol -> JSON -> StudyProtocol :: deep assert', () async {
    print('#1 : $protocol');
    final studyJson = toJsonString(protocol);

    StudyProtocol protocolFromJson = StudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), studyJson);
    print('#2 : $protocolFromJson');
  });

  test('JSON File -> StudyProtocol', () async {
    // Read the study protocol from json file
    String plainJson = File('test/json/study_protocol.json').readAsStringSync();

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
}
