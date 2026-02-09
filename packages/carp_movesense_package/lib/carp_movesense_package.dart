/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

// Identifiers for CACHET test devices:
//  - Movesense MD : 220330000122 : 0C:8C:DC:3F:B2:CD
//  - Movesense ?? : 233830000687 : 0C:8C:DC:1B:23:3E

/// A [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing)
/// sampling package for collecting data from the Movesense MD and Active
/// (HR+ and HR2) heart rate sensors. From these sensors, this package can
/// collect the following measures:
///
/// * `dk.cachet.carp.movesense.state` : State changes (like moving, tapping, etc.)
/// * `dk.cachet.carp.movesense.hr` : Heart rate
/// * `dk.cachet.carp.movesense.ecg` : Electrocardiogram (ECG)
/// * `dk.cachet.carp.movesense.temperature` : Device temperature
/// * `dk.cachet.carp.movesense.imu` : 9-axis Inertial Movement Unit (IMU)
///
/// **Movesense Active (HR+ & HR2)r**
///
/// Optimized for exercise and daily activities, Movesense Active is an ideal
/// platform for creating new smart wearables for well-being and sports.
///
/// With integrated heart rate, movement measurement, and an open API, Movesense
/// Active can provide new insights into all sports in the world.
///
/// Features:
///
///  * Movement measurement (9-axis IMU: accelerometer, gyroscope, magnetometer)
///  * Heart rate (bpm), R-R intervals, single channel ECG (non-medical),
///  * Bluetooth heart rate profile
///  * Small and lightweight (9.4g/0.33oz with battery)
///  * Wireless data transmission with Bluetooth Low Energy
///  * Memory for data logging and for custom sensor apps
///  * User replaceable CR 2025 battery
///  * Swim and shock proof
///
/// **Movesense Medical**
///
/// Wearable ECG monitor and movement sensor for health wearables.
/// Class IIa certified for medical use, Movesense Medical sensor is an essential
/// building block to transform your big idea into a new healthcare solution.
///
/// Key features:
///  * Single channel ECG, heart rate, R-R intervals
///  * Movement measurement (9-axis IMU: accelerometer, gyroscope, magnetometer)
///  * Wireless data transmission with Bluetooth Low Energy
///  * Small and lightweight (9.4g/0.33oz with battery)
///  * User replaceable CR 2025 battery
///  * Class IIa Medical Device, EU Medical Device Regulation MDR 2017/745
///
/// This package uses the Flutter [mdsflutter](https://pub.dev/packages/mdsflutter) plugin,
/// which again is based on the official [Movesense Mobile API](https://www.movesense.com/docs/mobile/mobile_sw_overview/).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:json_annotation/json_annotation.dart';

part 'carp_movesense_package.g.dart';

part 'movesense_data.dart';
part 'movesense_probes.dart';
part 'movesense_device_manager.dart';

class MovesenseSamplingPackage implements SamplingPackage {
  static const String MOVESENSE_NAMESPACE = "${NameSpace.CARP}.movesense";

  static const String DEVICE_INFO = "$MOVESENSE_NAMESPACE.deviceinformation";
  static const String STATE = "$MOVESENSE_NAMESPACE.state";
  static const String HR = "$MOVESENSE_NAMESPACE.hr";
  static const String ECG = "$MOVESENSE_NAMESPACE.ecg";
  static const String TEMPERATURE = "$MOVESENSE_NAMESPACE.temperature";
  static const String IMU = "$MOVESENSE_NAMESPACE.imu";

  final MovesenseDeviceManager _deviceManager = MovesenseDeviceManager(
    MovesenseDevice.DEVICE_TYPE,
  );

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
    TEMPERATURE =>
      deviceManager.movesenseDeviceType == MovesenseDeviceType.MD
          ? MovesenseTemperatureProbe()
          : null,
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
  }

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: DEVICE_INFO,
            displayName: "Device Information",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: STATE,
            displayName: "Device State Changes",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: HR,
            displayName: "Heart Rate (HR)",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ECG,
            displayName: "Electrocardiography (ECG)",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: TEMPERATURE,
            displayName: "Device Temperature",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: IMU,
            displayName: "Inertial Movement Unit (IMU)",
            timeType: DataTimeType.POINT,
          ),
        ),
      ]);
}
