/*
 * Copyright 2020 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// A CAMS sampling package for collecting health information from Apple Health
/// or Google Health Connect.
/// Is using the [health](https://pub.dev/packages/health) plugin.
/// Can be configured to collect the different [HealthDataType](https://pub.dev/documentation/health/latest/health/HealthDataType-class.html).
library;

import 'dart:async';
import 'dart:io';
import 'package:json_annotation/json_annotation.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:health/health.dart';

part 'health_domain.dart';
part 'health_probe.dart';
part 'health_service_manager.dart';
part 'health_user_task.dart';

part 'health_package.g.dart';

/// The health sampling package supports the following overall measure type:
///
///  * `dk.cachet.carp.health`
///
/// In order to specify which health data to collect, a factory method called
/// `getHealthMeasure` can be used.
///
/// An example of a configuration of a study protocol using a health service to
/// collect a set of health data once pr. hours is:
///
/// ```dart
///  final healthService = HealthService(types: healthDataTypes);
///  protocol.addConnectedDevice(healthService, phone);
///
///  protocol.addTaskControl(
///      PeriodicTrigger(period: Duration(minutes: 60)),
///      BackgroundTask(measures: [
///        HealthSamplingPackage.getHealthMeasure([
///          HealthDataType.STEPS,
///          HealthDataType.BASAL_ENERGY_BURNED,
///          HealthDataType.WEIGHT,
///          HealthDataType.SLEEP_SESSION,
///        ])
///      ]),
///      healthService);
/// ```
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry.register(HealthSamplingPackage());
/// ```
class HealthSamplingPackage extends SmartphoneSamplingPackage {
  static const String HEALTH_NAMESPACE = "${NameSpace.CARP}.health";

  /// Generic measure type for collection of health data from Apple Health or
  /// Google Health Connect.
  ///  * One-time measure.
  ///  * Uses the [HealthService] device for data collection.
  ///  * Use a [HealthSamplingConfiguration] for sampling configuration.
  ///
  /// Use [getHealthMeasure] to get specific health measure
  /// type to collect.
  static const String HEALTH = HEALTH_NAMESPACE;

  /// Returns a health measure for the specified list of health data [types].
  ///
  /// Data will be collected [days] days back in time. If not specified,
  /// data will be collected for the last 30 days, which is the maximum
  /// that Google Health Connect allow.
  static Measure getHealthMeasure(
    List<HealthDataType> types, [
    int days = 30,
  ]) =>
      Measure(type: HealthSamplingPackage.HEALTH)
        ..overrideSamplingConfiguration = HealthSamplingConfiguration(
          past: Duration(days: days),
          healthDataTypes: types,
        );

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: HEALTH,
            displayName: "Health Data",
            timeType: DataTimeType.TIME_SPAN,
          ),
          HealthSamplingConfiguration(
            past: Duration(days: 30),
            healthDataTypes: [HealthDataType.STEPS],
          ),
        ),
      ]);

  @override
  Probe? create(String type) => type == HEALTH ? HealthProbe() : null;

  @override
  void onRegister() {
    FromJsonFactory().registerAll([
      HealthService(),
      HealthSamplingConfiguration(healthDataTypes: []),
      HealthAppTask(type: ''),
      HealthData(
        uuid: '',
        value: NumericHealthValue(numericValue: 6),
        unit: '',
        healthDataType: '',
        dateFrom: DateTime.now(),
        dateTo: DateTime.now(),
        platform: HealthPlatform.APPLE_HEALTH,
      ),
    ]);
    AppTaskController().registerUserTaskFactory(HealthUserTaskFactory());
  }

  @override
  String get deviceType => HealthService.DEVICE_TYPE;

  HealthServiceManager? _deviceManager;

  @override
  DeviceManager get deviceManager => _deviceManager ??= HealthServiceManager();
}

/// Data types available on iOS via Apple Health.
const List<HealthDataType> dataTypesIOS = [
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.AUDIOGRAM,
  HealthDataType.BASAL_ENERGY_BURNED,
  HealthDataType.BLOOD_GLUCOSE,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  HealthDataType.BODY_FAT_PERCENTAGE,
  HealthDataType.BODY_MASS_INDEX,
  HealthDataType.BODY_TEMPERATURE,
  HealthDataType.DIETARY_CARBS_CONSUMED,
  HealthDataType.DIETARY_CAFFEINE,
  HealthDataType.DIETARY_ENERGY_CONSUMED,
  HealthDataType.DIETARY_FATS_CONSUMED,
  HealthDataType.DIETARY_PROTEIN_CONSUMED,
  HealthDataType.ELECTRODERMAL_ACTIVITY,
  HealthDataType.FORCED_EXPIRATORY_VOLUME,
  HealthDataType.HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_SDNN,
  HealthDataType.HEIGHT,
  HealthDataType.RESPIRATORY_RATE,
  HealthDataType.PERIPHERAL_PERFUSION_INDEX,
  HealthDataType.STEPS,
  HealthDataType.WAIST_CIRCUMFERENCE,
  HealthDataType.WEIGHT,
  HealthDataType.FLIGHTS_CLIMBED,
  HealthDataType.DISTANCE_WALKING_RUNNING,
  HealthDataType.MINDFULNESS,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_IN_BED,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_REM,
  HealthDataType.WATER,
  HealthDataType.EXERCISE_TIME,
  HealthDataType.WORKOUT,
  HealthDataType.HEADACHE_NOT_PRESENT,
  HealthDataType.HEADACHE_MILD,
  HealthDataType.HEADACHE_MODERATE,
  HealthDataType.HEADACHE_SEVERE,
  HealthDataType.HEADACHE_UNSPECIFIED,
  HealthDataType.LEAN_BODY_MASS,
  HealthDataType.ELECTROCARDIOGRAM,
  HealthDataType.HIGH_HEART_RATE_EVENT,
  HealthDataType.IRREGULAR_HEART_RATE_EVENT,
  HealthDataType.LOW_HEART_RATE_EVENT,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.WALKING_HEART_RATE,
  HealthDataType.ATRIAL_FIBRILLATION_BURDEN,
  HealthDataType.NUTRITION,
  HealthDataType.GENDER,
  HealthDataType.BLOOD_TYPE,
  HealthDataType.BIRTH_DATE,
  HealthDataType.MENSTRUATION_FLOW,
  HealthDataType.WATER_TEMPERATURE,
  HealthDataType.UNDERWATER_DEPTH,
  HealthDataType.UV_INDEX,
];

/// Data types available on Android via the Google Health Connect API.
const List<HealthDataType> dataTypesAndroid = [
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.BASAL_ENERGY_BURNED,
  HealthDataType.BLOOD_GLUCOSE,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  HealthDataType.BODY_FAT_PERCENTAGE,
  HealthDataType.HEIGHT,
  HealthDataType.WEIGHT,
  HealthDataType.LEAN_BODY_MASS,
  HealthDataType.BODY_MASS_INDEX,
  HealthDataType.BODY_TEMPERATURE,
  HealthDataType.HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.RESPIRATORY_RATE,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_AWAKE_IN_BED,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_OUT_OF_BED,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_UNKNOWN,
  HealthDataType.SLEEP_SESSION,
  HealthDataType.WATER,
  HealthDataType.WORKOUT,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.FLIGHTS_CLIMBED,
  HealthDataType.NUTRITION,
  HealthDataType.TOTAL_CALORIES_BURNED,
  HealthDataType.MENSTRUATION_FLOW,
];
