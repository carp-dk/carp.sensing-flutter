/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

// Identifiers for CACHET test devices:
//  - Movesense MD : 220330000122 : 0C:8C:DC:3F:B2:CD
//  - Movesense ?? : 233830000687 : 0C:8C:DC:1B:23:3E

/// A [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing)
/// sampling package that collects data from Movesense sensors over Bluetooth
/// Low Energy (BLE).
///
/// Register [MovesenseSamplingPackage] in the [SamplingPackageRegistry], add a
/// [MovesenseDevice] as a connected device to the protocol, and add measures
/// of the types below to a task that runs on that device.
///
/// Measure types (namespace `dk.cachet.carp.movesense`):
///  * `dk.cachet.carp.movesense.deviceinformation` : device information ([MovesenseDeviceInformation]).
///  * `dk.cachet.carp.movesense.state` : state changes, like tapping ([MovesenseStateChange]).
///  * `dk.cachet.carp.movesense.hr` : heart rate and R-R interval ([MovesenseHR]).
///  * `dk.cachet.carp.movesense.ecg` : electrocardiogram (ECG) ([MovesenseECG]).
///  * `dk.cachet.carp.movesense.temperature` : device temperature, Movesense MD only ([MovesenseTemperature]).
///  * `dk.cachet.carp.movesense.imu` : 9-axis Inertial Movement Unit (IMU) ([MovesenseIMU]).
///
/// Platforms: Android and iOS.
///
/// Devices: Movesense Medical (MD), Movesense Active HR+ and HR2. All of them
/// measure single-channel ECG, heart rate, R-R intervals and 9-axis movement
/// (accelerometer, gyroscope, magnetometer). The MD is a Class IIa medical
/// device (EU MDR 2017/745).
///
/// This package uses the Flutter
/// [carp_movesense_flutter](https://pub.dev/packages/carp_movesense_flutter)
/// plugin, which is based on the official
/// [Movesense Mobile API](https://www.movesense.com/docs/mobile/mobile_sw_overview/).
/// As of version 3.0.0 this plugin replaces the `mdsflutter` plugin. The public
/// API of this sampling package is unchanged. Internally, the Movesense MDS
/// calls go through the mdsflutter-compatible [Mds] facade of
/// `carp_movesense_flutter`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_movesense_flutter/carp_movesense_flutter.dart' show Mds;
import 'package:json_annotation/json_annotation.dart';

part 'carp_movesense_package.g.dart';

part 'movesense_data.dart';
part 'movesense_probes.dart';
part 'movesense_device_manager.dart';

/// The sampling package for Movesense devices.
///
/// It tells CARP Mobile Sensing which measure types a Movesense device
/// provides, which [Probe] collects each of them, and which
/// [MovesenseDeviceManager] handles the connection to the device. Register it
/// once, before a study is deployed.
///
/// Key points:
///  * All measures run on a [MovesenseDevice] connected device, not on the phone.
///  * All measures are event-based and need no sampling configuration.
///  * [TEMPERATURE] is only created when the connected device is a Movesense
///    MD; for other devices [create] returns null.
///  * [onRegister] registers the device and data types for JSON
///    deserialization, including the CAMS 1.x device type name.
///
/// ```dart
/// SamplingPackageRegistry().register(MovesenseSamplingPackage());
/// var movesense = MovesenseDevice();
/// protocol.addConnectedDevice(movesense, phone);
/// protocol.addTaskControl(
///   ImmediateTrigger(),
///   BackgroundTask(measures: [Measure(type: MovesenseSamplingPackage.HR)]),
///   movesense,
/// );
/// ```
///
/// See also [SamplingPackage], which this implements.
class MovesenseSamplingPackage implements SamplingPackage {
  /// The namespace of all Movesense measure types.
  static const String MOVESENSE_NAMESPACE = "${NameSpace.CARP}.movesense";

  /// Measure type for device information ([MovesenseDeviceInformation]).
  static const String DEVICE_INFO = "$MOVESENSE_NAMESPACE.deviceinformation";

  /// Measure type for state changes ([MovesenseStateChange]).
  static const String STATE = "$MOVESENSE_NAMESPACE.state";

  /// Measure type for heart rate ([MovesenseHR]).
  static const String HR = "$MOVESENSE_NAMESPACE.hr";

  /// Measure type for ECG ([MovesenseECG]).
  static const String ECG = "$MOVESENSE_NAMESPACE.ecg";

  /// Measure type for device temperature ([MovesenseTemperature]). Movesense MD only.
  static const String TEMPERATURE = "$MOVESENSE_NAMESPACE.temperature";

  /// Measure type for IMU data ([MovesenseIMU]).
  static const String IMU = "$MOVESENSE_NAMESPACE.imu";

  final MovesenseDeviceManager _deviceManager = MovesenseDeviceManager(MovesenseDevice.DEVICE_TYPE);

  @override
  List<DataTypeMetaData> get dataTypes => samplingSchemes.dataTypes;

  @override
  MovesenseDeviceManager get deviceManager => _deviceManager;

  @override
  String get deviceType => MovesenseDevice.DEVICE_TYPE;

  @override
  Probe? create(String type) => switch (type) {
    DEVICE_INFO => MovesenseDeviceProbe(),
    STATE => MovesenseStateChangeProbe(),
    HR => MovesenseHRProbe(),
    ECG => MovesenseECGProbe(),
    // Only the Movesense Medical (MD) device supports temperature measurement.
    TEMPERATURE => deviceManager.movesenseDeviceType == MovesenseDeviceType.MD ? MovesenseTemperatureProbe() : null,
    IMU => MovesenseIMUProbe(),
    _ => null,
  };

  @override
  void onRegister() {
    FromJsonFactory().registerAll([
      MovesenseDevice(),
      MovesenseDeviceInformation(),
      MovesenseStateChange(MovesenseDeviceState.unknown),
      MovesenseHR(55),
      MovesenseECG(0, []),
      MovesenseTemperature(0, 0),
      MovesenseIMU(0, [], [], []),
    ]);

    // Backwards compatibility with CAMS 1.x (protocol API level < 2.0) where
    // the Movesense device used the carp_core device namespace.
    FromJsonFactory().register(MovesenseDevice(), type: '${DeviceConfiguration.DEVICE_NAMESPACE}.MovesenseDevice');
  }

  @override
  DataTypeSamplingSchemeMap get samplingSchemes => DataTypeSamplingSchemeMap.from([
    DataTypeSamplingScheme(
      DataTypeMetaData(type: DEVICE_INFO, displayName: "Device Information", timeType: DataTimeType.POINT),
    ),
    DataTypeSamplingScheme(
      DataTypeMetaData(type: STATE, displayName: "Device State Changes", timeType: DataTimeType.POINT),
    ),
    DataTypeSamplingScheme(DataTypeMetaData(type: HR, displayName: "Heart Rate (HR)", timeType: DataTimeType.POINT)),
    DataTypeSamplingScheme(
      DataTypeMetaData(type: ECG, displayName: "Electrocardiography (ECG)", timeType: DataTimeType.POINT),
    ),
    DataTypeSamplingScheme(
      DataTypeMetaData(type: TEMPERATURE, displayName: "Device Temperature", timeType: DataTimeType.POINT),
    ),
    DataTypeSamplingScheme(
      DataTypeMetaData(type: IMU, displayName: "Inertial Movement Unit (IMU)", timeType: DataTimeType.POINT),
    ),
  ]);
}
