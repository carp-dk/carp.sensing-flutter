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

// Health types like HealthDataType are part of this package's public API
// (e.g. HealthSamplingConfiguration), so consumers get them without depending on health.
export 'package:health/health.dart';

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
