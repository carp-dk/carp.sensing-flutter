/*
 * Copyright 2020 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// A sampling package that collects health data from Apple Health (iOS) or
/// Google Health Connect (Android).
///
/// It wraps the [health](https://pub.dev/packages/health) plugin and provides
/// one measure type, `dk.cachet.carp.health`, which can collect any set of
/// [HealthDataType]s. Data is collected through the [HealthService] connected
/// device.
///
/// Register [HealthSamplingPackage] in the [SamplingPackageRegistry], add a
/// [HealthService] to the protocol, and collect data either in the background
/// (a [Measure] from [HealthSamplingPackage.getHealthMeasure]) or when the user
/// starts a [HealthAppTask]. Each health data point becomes a [HealthData]
/// measurement. The `health` plugin is re-exported.
library;

import 'dart:async';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:health/health.dart';

// Health types like HealthDataType are part of this package's public API
// (e.g. HealthSamplingConfiguration), so consumers get them without depending on health.
export 'package:health/health.dart';

part 'health_domain.dart';
part 'health_probe.dart';
part 'health_service_manager.dart';
part 'health_user_task.dart';

part 'health_package.g.dart';

/// The sampling package for health data from Apple Health or Google Health Connect.
///
/// Provides the single measure type `dk.cachet.carp.health` ([HEALTH]). Which
/// health data to collect is set by a [HealthSamplingConfiguration]; use
/// [getHealthMeasure] to create a [Measure] for a list of [HealthDataType]s.
/// Works on Android and iOS and needs the [HealthService] connected device.
///
/// Key points:
///  * Creates a [HealthProbe] for the [HEALTH] measure type.
///  * Uses a [HealthServiceManager] as its device manager.
///  * On registration, registers its JSON types and a [HealthUserTaskFactory],
///    so a [HealthAppTask] runs as a [HealthUserTask].
///
/// Example of a protocol that collects health data once per hour:
///
/// ```dart
///  final healthService = HealthService();
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
/// Register this package before running a study:
///
/// ```dart
///   SamplingPackageRegistry().register(HealthSamplingPackage());
/// ```
class HealthSamplingPackage extends SmartphoneSamplingPackage {
  /// The namespace of the health measure types, `dk.cachet.carp.health`.
  static const String HEALTH_NAMESPACE = "${NameSpace.CARP}.health";

  /// Generic measure type for collection of health data from Apple Health or
  /// Google Health Connect.
  ///  * One-time measure.
  ///  * Uses the [HealthService] device for data collection.
  ///  * Use a [HealthSamplingConfiguration] for sampling configuration.
  ///
  /// Use [getHealthMeasure] to create a measure for the specific health data
  /// types to collect.
  static const String HEALTH = HEALTH_NAMESPACE;

  /// Returns a [HEALTH] measure that collects the health data [types].
  ///
  /// The first collection fetches data [days] days back in time. Defaults to
  /// 30 days, which is the maximum that Google Health Connect allows. Later
  /// collections start from the last time data was collected.
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

    // Backwards compatibility with CAMS 1.x (protocol API level < 2.0) where
    // the health service used the carp_core device namespace.
    FromJsonFactory().register(
      HealthService(),
      type: '${DeviceConfiguration.DEVICE_NAMESPACE}.HealthService',
    );

    AppTaskController().registerUserTaskFactory(HealthUserTaskFactory());
  }

  @override
  String get deviceType => HealthService.DEVICE_TYPE;

  HealthServiceManager? _deviceManager;

  @override
  DeviceManager get deviceManager => _deviceManager ??= HealthServiceManager();
}
