import 'dart:convert';
import 'dart:io';
import 'package:carp_connectivity_package/connectivity.dart';
import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

void main() {
  late StudyProtocol protocol;
  Smartphone phone;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUpAll(() {
    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();

    // register the context sampling package
    SamplingPackageRegistry().register(ConnectivitySamplingPackage());

    // Create a new study protocol.
    protocol = StudyProtocol(
      ownerId: 'alex@uni.dk',
      name: 'Connectivity package test',
    );

    // Define which devices are used for data collection.
    phone = Smartphone();

    protocol.addPrimaryDevice(phone);

    // adding all available measures to one one trigger and one task
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..measures = SamplingPackageRegistry().dataTypes
            .map((type) => Measure(type: type.type))
            .toList(),
      phone,
    );

    // also add a PeriodicSamplingConfiguration
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: ConnectivitySamplingPackage.BLUETOOTH)
            ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
              interval: const Duration(minutes: 10),
              duration: const Duration(seconds: 10),
            ),
        ],
      ),
      phone,
    );

    // also add a BluetoothScanPeriodicSamplingConfiguration
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(
            type: ConnectivitySamplingPackage.BLUETOOTH,
            samplingConfiguration: BluetoothScanPeriodicSamplingConfiguration(
              interval: const Duration(minutes: 10),
              duration: const Duration(seconds: 10),
              withRemoteIds: ['123', '456'],
              withServices: ['service1', 'service2'],
            ),
          ),
        ],
      ),
      phone,
    );

    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(
            type: ConnectivitySamplingPackage.BEACON,
            samplingConfiguration: BeaconRangingPeriodicSamplingConfiguration(
              beaconDistance: 2,
              beaconRegions: [
                BeaconRegion(
                  identifier: 'TestB1',
                  uuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
                ),
              ],
            ),
          ),
        ],
      ),
      phone,
    );
  });

  test('CAMSStudyProtocol -> JSON', () async {
    print(protocol);
    print(toJsonString(protocol));
    expect(protocol.ownerId, 'alex@uni.dk');

    // used in the test below
    await writeToFile(toJsonString(protocol), 'study_protocol.json');
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
    expect(protocol.primaryDevice.roleName, Smartphone.DEFAULT_ROLE_NAME);
    print(toJsonString(protocol));
  });

  test('Bluetooth  -> JSON', () async {
    Bluetooth data = Bluetooth()
      ..addBluetoothDevice(
        BluetoothDevice(
          advertisementName: 'myPhone',
          bluetoothDeviceId: "weg",
          bluetoothDeviceName: "ksjbdf",
          connectable: true,
          txPowerLevel: 314,
          rssi: 567,
        ),
      );

    final measurement = Measurement.fromData(data);

    print(toJsonString(measurement));
  });

  test('Beacon  -> JSON', () async {
    BeaconData data = BeaconData(region: "TestB1")
      ..addBeaconDevice(
        BeaconDevice(
          uuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
          rssi: -60,
          proximity: Proximity.near,
        ),
      );

    final measurement = Measurement.fromData(data);

    print(toJsonString(measurement));
  });

  test('Connectivity  -> JSON', () async {
    Connectivity data = Connectivity()
      ..connectivityStatus = [ConnectivityStatus.bluetooth];

    final measurement = Measurement.fromData(data);

    print(toJsonString(measurement));
  });
  test('Wifi  -> JSON', () async {
    Wifi data = Wifi()
      ..bssid = 'kj'
      ..ip = '127.0.0.1';

    final measurement = Measurement.fromData(data);

    print(toJsonString(measurement));
  });
}
