/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// An abstract sensor probe used by all sensor probes to get the [samplingPeriod].
///
/// The sampling interval can be specified ("overridden") by specifying a [IntervalSamplingConfiguration]
/// when configuring a [Measure] in the protocol.
/// Default sampling interval is 200 ms.
///
/// Note that it seems like setting the sampling interval does NOT work on Android.
/// Please see the docs on the [sensor_plus](https://pub.dev/packages/sensors_plus)
/// package and on the [Android sensor documentation](https://developer.android.com/reference/android/hardware/SensorManager#registerListener(android.hardware.SensorEventListener,%20android.hardware.Sensor,%20int)).
abstract class SensorProbe extends StreamProbe {
  Duration get samplingPeriod =>
      samplingConfiguration is IntervalSamplingConfiguration
      ? (samplingConfiguration as IntervalSamplingConfiguration).interval
      : const Duration(milliseconds: 200);
}

/// A probe collecting raw data from the accelerometer.
class AccelerometerProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream =>
      accelerometerEventStream(samplingPeriod: samplingPeriod).map(
        (event) => Measurement.fromData(
          Acceleration(x: event.x, y: event.y, z: event.z),
        ),
      );
}

/// A probe collecting raw data from the user accelerometer.
class UserAccelerometerProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream =>
      userAccelerometerEventStream(samplingPeriod: samplingPeriod).map(
        (event) => Measurement.fromData(
          Acceleration(x: event.x, y: event.y, z: event.z),
        ),
      );
}

/// A probe collecting accelerometer data over a sampling period and calculates
/// a set of features based on the samplings, as represented by a
/// [AccelerationFeatures] data point.
///
/// Configured with a [PeriodicSamplingConfiguration] configuration.
class AccelerometerFeaturesProbe extends BufferingPeriodicStreamProbe {
  List<UserAccelerometerEvent> userAccelerometerEventList = [];
  int sensorStartTime = 0;
  int? sensorEndTime;

  @override
  Stream<dynamic> get bufferingStream => userAccelerometerEventStream();

  @override
  Future<Measurement?> getMeasurement() async =>
      userAccelerometerEventList.isEmpty
      ? null
      : Measurement(
          sensorStartTime: sensorStartTime,
          sensorEndTime: sensorEndTime,
          data: AccelerationFeatures.fromAccelerometerReadings(
            userAccelerometerEventList,
          ),
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

/// A probe collecting raw data from the gyroscope.
class GyroscopeProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream =>
      gyroscopeEventStream(samplingPeriod: samplingPeriod).map(
        (event) =>
            Measurement.fromData(Rotation(x: event.x, y: event.y, z: event.z)),
      );
}

/// A probe collecting raw data from the magnetometer.
class MagnetometerProbe extends SensorProbe {
  @override
  Stream<Measurement> get stream =>
      magnetometerEventStream(samplingPeriod: samplingPeriod).map(
        (event) => Measurement.fromData(
          MagneticField(x: event.x, y: event.y, z: event.z),
        ),
      );
}
