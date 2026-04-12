import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide TimeOfDay;

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:health/health.dart';
import 'package:test/test.dart';

String _encode(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  group("Protocol", () {
    late StudyProtocol protocol;
    Smartphone phone;

    Future<void> writeToFile(String json, String fileName) async =>
        await File('test/json/$fileName').writeAsString(json);

    setUpAll(() {
      WidgetsFlutterBinding.ensureInitialized();
      // Initialization of serialization
      CarpMobileSensing.ensureInitialized();

      // register the context sampling package
      SamplingPackageRegistry().register(HealthSamplingPackage());

      Health();

      // Create a new study protocol.
      protocol = StudyProtocol(
        ownerId: 'alex@uni.dk',
        name: 'Context package test',
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

      protocol.addTaskControl(
        PeriodicTrigger(period: Duration(minutes: 60)),
        BackgroundTask()..addMeasure(
          Measure(type: HealthSamplingPackage.HEALTH)
            ..overrideSamplingConfiguration = HealthSamplingConfiguration(
              healthDataTypes: [
                HealthDataType.BLOOD_GLUCOSE,
                HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
                HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
                HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
                HealthDataType.HEART_RATE,
                HealthDataType.STEPS,
              ],
            ),
        ),
        phone,
      );

      protocol.addTaskControl(
        RecurrentScheduledTrigger(
          type: RecurrentType.daily,
          time: TimeOfDay(hour: 23, minute: 00),
        ),
        BackgroundTask()..addMeasure(
          Measure(type: HealthSamplingPackage.HEALTH)
            ..overrideSamplingConfiguration = HealthSamplingConfiguration(
              healthDataTypes: [HealthDataType.WEIGHT],
            ),
        ),
        phone,
      );

      protocol.addTaskControl(
        PeriodicTrigger(period: Duration(hours: 24)),
        HealthAppTask(
          name: 'Health App Task',
          title: "Press here to collect your physical health data",
          description:
              "This will collect your weight, exercise time, steps, and sleep "
              "time from the Health database on the phone.",
          types: [
            HealthDataType.WEIGHT,
            HealthDataType.STEPS,
            HealthDataType.BASAL_ENERGY_BURNED,
            HealthDataType.SLEEP_SESSION,
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
      await writeToFile(toJsonString(protocol), 'protocol.json');
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
      String plainJson = File('test/json/protocol.json').readAsStringSync();

      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      expect(protocol.ownerId, 'alex@uni.dk');
      expect(protocol.primaryDevice.roleName, Smartphone.DEFAULT_ROLE_NAME);
      print(toJsonString(protocol));
    });

    test(' HealthSamplingConfiguration -> JSON -> Object', () async {
      HealthSamplingConfiguration configuration = HealthSamplingConfiguration(
        past: Duration(minutes: 60),
        healthDataTypes: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      );
      final dataJson = toJsonString(configuration);
      print(toJsonString(configuration));
      final dataFromJson = HealthSamplingConfiguration.fromJson(
        json.decode(dataJson) as Map<String, dynamic>,
      );
      print(toJsonString(dataFromJson));
      expect(toJsonString(dataFromJson), equals(dataJson));
    });
  });

  group("Data Types", () {
    List<HealthData> healthData = <HealthData>[];

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      CarpMobileSensing.ensureInitialized();
      SamplingPackageRegistry().register(HealthSamplingPackage());

      // Initialization of JSON serialization in Health plugin
      Health();

      DateTime to = DateTime.now();
      DateTime from = to.subtract(Duration(milliseconds: 10000));
      double value = 500;
      String unit =
          dasesDataTypeToUnit[DasesHealthDataType.CALORIES_INTAKE]?.name ?? '';
      String type = DasesHealthDataType.CALORIES_INTAKE.name;
      HealthPlatform platform = HealthPlatform.APPLE_HEALTH;
      String deviceId = '1234';
      String uuid = "4321";
      String sourceId = "AH";
      String sourceName = "AppleHealth";

      healthData
        ..add(
          HealthData(
            uuid: uuid,
            value: NumericHealthValue(numericValue: value),
            unit: unit,
            healthDataType: type,
            dateFrom: from,
            dateTo: to,
            platform: platform,
            deviceId: deviceId,
            sourceId: sourceId,
            sourceName: sourceName,
          ),
        )
        ..add(
          HealthData(
            uuid: '4321',
            value: NumericHealthValue(numericValue: 6),
            unit: dasesDataTypeToUnit[DasesHealthDataType.ALCOHOL]?.name ?? '',
            healthDataType: DasesHealthDataType.ALCOHOL.name,
            dateFrom: from,
            dateTo: to,
            platform: platform,
          ),
        )
        ..add(
          HealthData(
            uuid: '4321',
            value: NumericHealthValue(numericValue: 6),
            unit: dasesDataTypeToUnit[DasesHealthDataType.SLEEP]?.name ?? '',
            healthDataType: DasesHealthDataType.SLEEP.name,
            dateFrom: from,
            dateTo: to,
            platform: platform,
          ),
        )
        ..add(
          HealthData(
            uuid: '4321',
            value: NumericHealthValue(numericValue: 12),
            unit:
                dasesDataTypeToUnit[DasesHealthDataType.SMOKED_CIGARETTES]
                    ?.name ??
                '',
            healthDataType: DasesHealthDataType.SMOKED_CIGARETTES.name,
            dateFrom: from,
            dateTo: to,
            platform: platform,
          ),
        )
        ..add(
          HealthData(
            uuid: '4321',
            value: AudiogramHealthValue(
              frequencies: [12, 32],
              leftEarSensitivities: [1, 2, 3, 4],
              rightEarSensitivities: [1, 4, 7],
            ),
            unit: HealthDataUnit.NO_UNIT.name,
            healthDataType: HealthDataType.AUDIOGRAM.name,
            dateFrom: from,
            dateTo: to,
            platform: platform,
          ),
        )
        ..add(
          HealthData(
            uuid: '4321',
            value: WorkoutHealthValue(
              workoutActivityType: HealthWorkoutActivityType.MARTIAL_ARTS,
              totalEnergyBurned: 8,
              totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
              totalDistance: 1000,
              totalDistanceUnit: HealthDataUnit.METER,
            ),
            unit: HealthDataUnit.NO_UNIT.name,
            healthDataType: HealthDataType.WORKOUT.name,
            dateFrom: from,
            dateTo: to,
            platform: platform,
          ),
        );
    });

    test(' - toJson', () {
      for (var data in healthData) {
        final measurement = Measurement.fromData(data);
        print(_encode(measurement));
        expect(
          measurement.data.dataType.toString(),
          HealthSamplingPackage.HEALTH,
        );
        expect(measurement.data, isA<HealthData>());
        // expect(
        //   (measurement.data as HealthData).healthDataType,
        //   DasesHealthDataType.CALORIES_INTAKE.name,
        // );
      }
    });

    test(' - fromJson', () {
      for (var data in healthData) {
        final measurement = Measurement.fromData(data);
        final dataJson = toJsonString(measurement);
        print(dataJson);
        final dataFromJson = Measurement.fromJson(
          json.decode(dataJson) as Map<String, dynamic>,
        );
        print(toJsonString(dataFromJson));
        expect(toJsonString(dataFromJson), equals(dataJson));
      }
    });
  });
}
