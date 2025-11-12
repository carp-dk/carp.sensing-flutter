/*
 * Copyright 2025 Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// A [SamplingPackage] containing data types, sampling schemas and probes
/// for monitoring data sampling:
///
///  - errors
///  - heartbeat
///  - task triggering
///  - task completion, including [AppTask] completion
///
class MonitoringSamplingPackage extends SmartphoneSamplingPackage {
  /// Collect errors occurring during data collection
  static const String ERROR = CarpDataTypes.ERROR_TYPE_NAME;

  /// Collect data on a triggered [TaskConfiguration].
  static const String TRIGGERED_TASK = CarpDataTypes.TRIGGERED_TASK_TYPE_NAME;

  /// Collect a heartbeat from a primary or connected device.
  static const String HEARTBEAT = CamsDataTypes.HEARTBEAT_TYPE_NAME;

  /// Collect data whenever any [TaskConfiguration] has been completed.
  static const String COMPLETED_TASK = CarpDataTypes.COMPLETED_TASK_TYPE_NAME;

  /// Collect data whenever an [AppTask] has been completed.
  static const String COMPLETED_APP_TASK =
      CamsDataTypes.COMPLETED_APP_TASK_TYPE_NAME;

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.ERROR_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.TRIGGERED_TASK_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.COMPLETED_TASK_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CamsDataTypes.HEARTBEAT_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CamsDataTypes.COMPLETED_APP_TASK_TYPE_NAME]!,
        ),
      ]);

  @override
  Probe? create(String type) => StubProbe(); // No probes created - these types of measures are handled in the core sampling logic

  @override
  void onRegister() {
    FromJsonFactory().registerAll([
      Error(message: ''),
      TriggeredTask(
        triggerId: 0,
        taskName: '',
        destinationDeviceRoleName: '',
        control: Control.Start,
      ),
      CompletedTask(taskName: ''),
      Heartbeat(period: 5, deviceType: '', deviceRoleName: ''),
      CompletedAppTask(taskName: '', taskType: ''),
    ]);
  }
}
