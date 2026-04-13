/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// The [LightProbe] listens to the phone's light sensor typically located
/// near the front camera.
/// Every value is in the SI unit Lux and is stored in a [AmbientLight] object.
///
/// This probe is only available on Android.
class LightProbe extends BufferingPeriodicStreamProbe {
  final List<num> _luxValues = [];
  int _sensorStartTime = 0;
  int? _sensorEndTime;

  late Stream<dynamic> _bufferingStream;

  @override
  Stream<dynamic> get bufferingStream => _bufferingStream;

  @override
  bool onInitialize() {
    _bufferingStream = Light().lightSensorStream;
    return true;
  }

  @override
  Future<Measurement?> getMeasurement() async => (_luxValues.isEmpty)
      ? null
      : Measurement(
          sensorStartTime: _sensorStartTime,
          sensorEndTime: _sensorEndTime,
          data: AmbientLight.fromLuxReadings(_luxValues),
        );

  @override
  void onSamplingStart() {
    _sensorStartTime = DateTime.now().microsecondsSinceEpoch;
    _luxValues.clear();
  }

  @override
  void onSamplingEnd() {
    _sensorEndTime = DateTime.now().microsecondsSinceEpoch;
  }

  @override
  void onSamplingData(event) {
    if (event is num) _luxValues.add(event);
  }
}
