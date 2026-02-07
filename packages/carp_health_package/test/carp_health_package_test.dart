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

    setUpAll(() {
      WidgetsFlutterBinding.ensureInitialized();
      // Initialization of serialization
      CarpMobileSensing.ensureInitialized();

      // register the context sampling package
      SamplingPackageRegistry().register(HealthSamplingPackage());

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
        // collect every hour
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
        // collect every day at 23:00
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
      String plainJson = File(
        'test/json/study_protocol.json',
      ).readAsStringSync();

      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      expect(protocol.ownerId, 'alex@uni.dk');
      expect(protocol.primaryDevice.roleName, Smartphone.DEFAULT_ROLE_NAME);
      print(toJsonString(protocol));
    });

    test(' HealthSamplingConfiguration -> JSON', () async {
      HealthSamplingConfiguration configuration = HealthSamplingConfiguration(
        healthDataTypes: [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
      );
      print(configuration.toJson());
      print(_encode(configuration));
    });
  });

  group("Data Types", () {
    List<HealthData> healthData = <HealthData>[];

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      CarpMobileSensing.ensureInitialized();
      SamplingPackageRegistry().register(HealthSamplingPackage());

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
            uuid,
            NumericHealthValue(numericValue: value),
            unit,
            type,
            from,
            to,
            platform,
            deviceId,
            sourceId,
            sourceName,
          ),
        )
        ..add(
          HealthData(
            '4321',
            NumericHealthValue(numericValue: 6),
            dasesDataTypeToUnit[DasesHealthDataType.ALCOHOL]?.name ?? '',
            DasesHealthDataType.ALCOHOL.name,
            from,
            to,
            platform,
            '1234',
            '4321',
            '4321',
          ),
        )
        ..add(
          HealthData(
            '4321',
            NumericHealthValue(numericValue: 6),
            dasesDataTypeToUnit[DasesHealthDataType.SLEEP]?.name ?? '',
            DasesHealthDataType.SLEEP.name,
            from,
            to,
            platform,
            '1234',
            '4321',
            '4321',
          ),
        )
        ..add(
          HealthData(
            '4321',
            NumericHealthValue(numericValue: 12),
            dasesDataTypeToUnit[DasesHealthDataType.SMOKED_CIGARETTES]?.name ??
                '',
            DasesHealthDataType.SMOKED_CIGARETTES.name,
            from,
            to,
            platform,
            '1234',
            '4321',
            '4321',
          ),
        )
        ..add(
          HealthData(
            '4321',
            AudiogramHealthValue(
              frequencies: [12, 32],
              leftEarSensitivities: [1, 2, 3, 4],
              rightEarSensitivities: [1, 4, 7],
            ),
            HealthDataUnit.NO_UNIT.name,
            HealthDataType.AUDIOGRAM.name,
            from,
            to,
            platform,
            '1234',
            '4321',
            '4321',
          ),
        )
        ..add(
          HealthData(
            '4321',
            WorkoutHealthValue(
              workoutActivityType: HealthWorkoutActivityType.MARTIAL_ARTS,
              totalEnergyBurned: 8,
              totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
              totalDistance: 1000,
              totalDistanceUnit: HealthDataUnit.METER,
            ),
            HealthDataUnit.NO_UNIT.name,
            HealthDataType.WORKOUT.name,
            from,
            to,
            platform,
            '1234',
            '4321',
            '4321',
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
        final dataFromJson = Measurement.fromJson(
          json.decode(dataJson) as Map<String, dynamic>,
        );
        print(toJsonString(dataFromJson));
        expect(toJsonString(dataFromJson), equals(dataJson));
      }
    });
  });
}
