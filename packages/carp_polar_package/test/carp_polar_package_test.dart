import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:polar/polar.dart';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_polar_package/carp_polar_package.dart';

String _encode(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  late StudyProtocol protocol;
  late Smartphone phone;
  late PolarDevice polar;
  String deviceId = 'G24R';

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    CarpMobileSensing.ensureInitialized();

    // register the Polar sampling package
    SamplingPackageRegistry().register(PolarSamplingPackage());

    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();

    // Create a new study protocol.
    protocol = StudyProtocol(
      ownerId: 'alex@uni.dk',
      name: 'Context package test',
    );
    // Define which devices are used for data collection.
    phone = Smartphone(roleName: 'SM-A320FL');
    polar = PolarDevice(
      roleName: 'Polar H10 HR monitor',
      identifier: deviceId,
      name: 'H10',
      deviceType: PolarDeviceType.H10,
    );

    protocol
      ..addPrimaryDevice(phone)
      ..addConnectedDevice(polar, phone);

    // // adding all available measures to one one trigger and one task
    // protocol.addTaskControl(
    //   ImmediateTrigger(),
    //   BackgroundTask()
    //     ..measures = SamplingPackageRegistry().dataTypes
    //         .map((type) => Measure(type: type.type))
    //         .toList(),
    //   phone,
    // );

    // Add a background task that immediately starts collecting eSense button and
    // sensor events from the eSense device.
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: PolarSamplingPackage.ACCELEROMETER),
          Measure(type: PolarSamplingPackage.GYROSCOPE),
          Measure(type: PolarSamplingPackage.MAGNETOMETER),
          Measure(type: PolarSamplingPackage.ECG),
          Measure(type: PolarSamplingPackage.HR),
          Measure(type: PolarSamplingPackage.PPG),
          Measure(type: PolarSamplingPackage.PPI),
        ],
      ),
      polar,
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
    expect(toJsonString(protocolFromJson), equals(studyJson));
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
    expect(protocol.connectedDevices?.first.roleName, polar.roleName);
    print(toJsonString(protocol));
  });

  test('Accelerometer Measurement -> JSON', () async {
    List<PolarAccSample> samples = [];

    samples.add(PolarAccSample(timeStamp: DateTime.now(), x: 1, y: 2, z: 3));
    samples.add(PolarAccSample(timeStamp: DateTime.now(), x: 1, y: 2, z: 3));

    PolarAccData data = PolarAccData(samples: samples);

    var measurement = Measurement.fromData(
      PolarAccelerometer.fromPolarData(data),
    );
    expect(measurement.dataType.toString(), measurement.data.jsonType);

    print(_encode(measurement.toJson()));
  });
}
