import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_movesense_package/carp_movesense_package.dart';

String _encode(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  late StudyProtocol protocol;
  late Smartphone phone;
  late MovesenseDevice movesense;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    CarpMobileSensing.ensureInitialized();

    // register the Movesense sampling package
    SamplingPackageRegistry().register(MovesenseSamplingPackage());

    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();

    // Create a new study protocol.
    protocol = StudyProtocol(
      ownerId: 'alex@uni.dk',
      name: 'Context package test',
    );
    // Define which devices are used for data collection.
    phone = Smartphone(roleName: 'SM-A320FL');
    movesense = MovesenseDevice();

    protocol
      ..addPrimaryDevice(phone)
      ..addConnectedDevice(movesense, phone);

    // adding all available measures to one one trigger and one task
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..measures = SamplingPackageRegistry().dataTypes
            .map((type) => Measure(type: type.type))
            .toList(),
      phone,
    );

    // Add a background task that immediately starts collecting data from the
    // Movesense device.
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: MovesenseSamplingPackage.DEVICE_INFO),
          Measure(type: MovesenseSamplingPackage.STATE),
          Measure(type: MovesenseSamplingPackage.HR),
          Measure(type: MovesenseSamplingPackage.ECG),
          Measure(type: MovesenseSamplingPackage.TEMPERATURE),
          Measure(type: MovesenseSamplingPackage.IMU),
        ],
      ),
      movesense,
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

    StudyProtocol protocolFromJson = StudyProtocol.fromJson(
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
    expect(protocol.connectedDevices?.first.roleName, movesense.roleName);
    print(toJsonString(protocol));
  });

  test('Accelerometer Measurement -> JSON', () {
    List<MovesenseAccelerometerSample> samples = [];

    samples.add(MovesenseAccelerometerSample(1, 2, 3));
    samples.add(MovesenseAccelerometerSample(1, 2, 3));
    samples.add(MovesenseAccelerometerSample(1, 2, 3));
    samples.add(MovesenseAccelerometerSample(1, 2, 3));

    var data = MovesenseIMU(DateTime.now().millisecond, samples, [], []);

    var measurement = Measurement.fromData(data);
    expect(measurement.dataType.toString(), measurement.data.jsonType);

    print(_encode(measurement.toJson()));
  });

  test('Parsing Movesense JSON data format', () {
    String hrJson = File('test/json/hr.json').readAsStringSync();
    var hr = Measurement.fromData(
      MovesenseHR.fromMovesenseData(json.decode(hrJson)),
    );
    expect(hr.dataType.toString(), MovesenseSamplingPackage.HR);
    print(_encode(hr.toJson()));

    String ecgJson = File('test/json/ecg.json').readAsStringSync();
    var ecg = Measurement.fromData(
      MovesenseECG.fromMovesenseData(json.decode(ecgJson)),
    );
    expect(ecg.dataType.toString(), MovesenseSamplingPackage.ECG);
    print(_encode(ecg.toJson()));

    String imuJson = File('test/json/imu.json').readAsStringSync();
    var imu = Measurement.fromData(
      MovesenseIMU.fromMovesenseData(json.decode(imuJson)),
    );
    expect(imu.dataType.toString(), MovesenseSamplingPackage.IMU);
    print(_encode(imu.toJson()));

    String infoJson = File('test/json/info.json').readAsStringSync();
    var info = Measurement.fromData(
      MovesenseDeviceInformation.fromMovesenseData(json.decode(infoJson)),
    );
    expect(info.dataType.toString(), MovesenseSamplingPackage.DEVICE_INFO);
    print(_encode(info.toJson()));

    String stateJson = File('test/json/state.json').readAsStringSync();
    var state = Measurement.fromData(
      MovesenseStateChange.fromMovesenseData(json.decode(stateJson)),
    );
    expect(state.dataType.toString(), MovesenseSamplingPackage.STATE);
    print(_encode(state.toJson()));
  });

  test('Parsing config types', () async {
    String infoJson = File('test/json/info.json').readAsStringSync();
    final dataContent = json.decode(infoJson);
    var deviceInfo = dataContent["Content"] as Map<String, dynamic>;

    final allData = [
      MovesenseDevice(roleName: 'Movesense HR monitor'),
      MovesenseDeviceRegistration(
        bleAddress: '00:11:22:33:44:55',
        movesenseDeviceType: MovesenseDeviceType.HR2,
        deviceInfo: deviceInfo,
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
