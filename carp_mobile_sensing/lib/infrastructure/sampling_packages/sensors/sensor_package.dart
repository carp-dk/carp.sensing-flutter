/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// A [SamplingPackage] containing data types, sampling schemas and probes
/// for collecting information from the phone sensors:
///
///  - accelerometer
///  - gyroscope
///  - magnetometer
///  - acceleration features
///  - ambient light
///  - pedometer (step events)
///
class SensorSamplingPackage extends SmartphoneSamplingPackage {
  /// Rate of change in velocity, including gravity, along perpendicular x, y,
  /// and z axes in the device's coordinate system.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * Uses a [IntervalSamplingConfiguration] sampling configuration.
  static const String ACCELERATION = CarpDataTypes.ACCELERATION_TYPE_NAME;

  /// Rate of change in velocity, excluding gravity, along perpendicular x, y,
  /// and z axes in the phone's coordinate system.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * Uses a [IntervalSamplingConfiguration] sampling configuration.
  static const String NON_GRAVITATIONAL_ACCELERATION =
      CarpDataTypes.NON_GRAVITATIONAL_ACCELERATION_TYPE_NAME;

  /// A set of acceleration (non-gravitational) features calculated over a
  /// specific sampling period.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * Uses a [PeriodicSamplingConfiguration] for configuration.
  static const String ACCELERATION_FEATURES =
      '${CarpDataTypes.CARP_NAMESPACE}.accelerationfeatures';

  /// Rotation of the phone in x,y,z (typically measured by a gyroscope).
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * Uses a [IntervalSamplingConfiguration] sampling configuration.
  static const String ROTATION = CarpDataTypes.ROTATION_TYPE_NAME;

  /// Magnetic field around the phone in x,y,z (typically measured by a magnetometer).
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * Uses a [IntervalSamplingConfiguration] sampling configuration.
  static const String MAGNETIC_FIELD = CarpDataTypes.MAGNETIC_FIELD_TYPE_NAME;

  /// Ambient light from the phone's light sensor.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * Uses a [PeriodicSamplingConfiguration] for configuration.
  static const String AMBIENT_LIGHT =
      '${CarpDataTypes.CARP_NAMESPACE}.ambientlight';

  /// Step count events from the phone's pedometer.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * No sampling configuration needed.
  static const String STEP_COUNT = CarpDataTypes.STEP_COUNT_TYPE_NAME;

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.ACCELERATION_TYPE_NAME]!,
          IntervalSamplingConfiguration(
            interval: const Duration(milliseconds: 200),
          ),
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes
              .NON_GRAVITATIONAL_ACCELERATION_TYPE_NAME]!,
          IntervalSamplingConfiguration(
            interval: const Duration(milliseconds: 200),
          ),
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.ROTATION_TYPE_NAME]!,
          IntervalSamplingConfiguration(
            interval: const Duration(milliseconds: 200),
          ),
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.MAGNETIC_FIELD_TYPE_NAME]!,
          IntervalSamplingConfiguration(
            interval: const Duration(milliseconds: 200),
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ACCELERATION_FEATURES,
            displayName: "Accelerometer Features",
            timeType: DataTimeType.TIME_SPAN,
          ),
          PeriodicSamplingConfiguration(
            interval: const Duration(minutes: 1),
            duration: const Duration(seconds: 3),
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData.fromDataTypeMetaData(
            dataTypeMetaData:
                CarpDataTypes().types[CarpDataTypes.STEP_COUNT_TYPE_NAME]!,
            permissions: [Permission.activityRecognition],
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: AMBIENT_LIGHT,
            displayName: "Ambient Light",
            timeType: DataTimeType.TIME_SPAN,
          ),
          PeriodicSamplingConfiguration(
            interval: const Duration(minutes: 5),
            duration: const Duration(seconds: 10),
          ),
        ),
      ]);

  @override
  Probe? create(String type) {
    switch (type) {
      case ACCELERATION:
        return AccelerometerProbe();
      case NON_GRAVITATIONAL_ACCELERATION:
        return UserAccelerometerProbe();
      case ACCELERATION_FEATURES:
        return AccelerometerFeaturesProbe();
      case MAGNETIC_FIELD:
        return MagnetometerProbe();
      case ROTATION:
        return GyroscopeProbe();
      case STEP_COUNT:
        return PedometerProbe();
      case AMBIENT_LIGHT:
        return (Platform.isAndroid) ? LightProbe() : null;
      default:
        return null;
    }
  }
}
