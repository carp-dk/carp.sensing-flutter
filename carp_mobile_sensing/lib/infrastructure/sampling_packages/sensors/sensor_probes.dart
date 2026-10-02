/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// Base class for the raw sensor probes, providing their [samplingPeriod].
///
/// The sampling interval can be specified ("overridden") by specifying a [IntervalSamplingConfiguration]
/// when configuring a [Measure] in the protocol.
/// Default sampling interval is 200 ms.
///
/// Note that it seems like setting the sampling interval does NOT work on Android.
/// Please see the docs on the [sensors_plus](https://pub.dev/packages/sensors_plus)
/// package and on the [Android sensor documentation](https://developer.android.com/reference/android/hardware/SensorManager#registerListener(android.hardware.SensorEventListener,%20android.hardware.Sensor,%20int)).
abstract class SensorProbe extends StreamProbe {
  /// The interval from the measure's [IntervalSamplingConfiguration], or
  /// 200 ms if none is set.
  Duration get samplingPeriod => samplingConfiguration is IntervalSamplingConfiguration
      ? (samplingConfiguration as IntervalSamplingConfiguration).interval
      : const Duration(milliseconds: 200);
}

/// Collects raw [Acceleration] (including gravity) from the accelerometer.
class AccelerometerProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream => accelerometerEventStream(
    samplingPeriod: samplingPeriod,
  ).map((event) => Measurement.fromData(Acceleration(x: event.x, y: event.y, z: event.z)));
}

/// Collects raw [Acceleration] excluding gravity from the user accelerometer.
class UserAccelerometerProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream => userAccelerometerEventStream(
    samplingPeriod: samplingPeriod,
  ).map((event) => Measurement.fromData(Acceleration(x: event.x, y: event.y, z: event.z)));
}

/// Collects user accelerometer data over a sampling period and calculates
/// a set of features from it, as an [AccelerationFeatures] data point.
///
/// Configured with a [PeriodicSamplingConfiguration] configuration.
class AccelerometerFeaturesProbe extends BufferingPeriodicStreamProbe {
  /// The events buffered in the current sampling period.
  List<UserAccelerometerEvent> userAccelerometerEventList = [];

  /// Start of the current sampling period, in microseconds since epoch.
  int sensorStartTime = 0;

  /// End of the last sampling period, in microseconds since epoch.
  int? sensorEndTime;

  @override
  Stream<dynamic> get bufferingStream => userAccelerometerEventStream();

  @override
  Future<Measurement?> getMeasurement() async => userAccelerometerEventList.isEmpty
      ? null
      : Measurement(
          sensorStartTime: sensorStartTime,
          sensorEndTime: sensorEndTime,
          data: AccelerationFeatures.fromAccelerometerReadings(userAccelerometerEventList),
        );

  @override
  void onSamplingStart() {
    sensorStartTime = DateTime.now().microsecondsSinceEpoch;
    userAccelerometerEventList.clear();
  }

  @override
  void onSamplingEnd() {
    sensorEndTime = DateTime.now().microsecondsSinceEpoch;
  }

  @override
  void onSamplingData(event) {
    if (event is UserAccelerometerEvent) {
      userAccelerometerEventList.add(event);
    }
  }
}

/// Collects raw [Rotation] data from the gyroscope.
class GyroscopeProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream => gyroscopeEventStream(
    samplingPeriod: samplingPeriod,
  ).map((event) => Measurement.fromData(Rotation(x: event.x, y: event.y, z: event.z)));
}

/// Collects raw [MagneticField] data from the magnetometer.
class MagnetometerProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream => magnetometerEventStream(
    samplingPeriod: samplingPeriod,
  ).map((event) => Measurement.fromData(MagneticField(x: event.x, y: event.y, z: event.z)));
}
