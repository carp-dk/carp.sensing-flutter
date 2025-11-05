/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// The pedometer probe listens to the hardware step counter sensor.
///
/// It samples step counts directly from the native OS and reports step counts
/// as they are sensed, typically for each step taken.
///
/// Note that the 'pedometer' plugin returns the total steps taken since last
/// system boot.
class PedometerProbe extends StreamProbe {
  // @override
  // Future<bool> onStart() async {
  //   // Ask for permission before starting probe.
  //   // Only relevant for Android - on iOS permission is automatically requested.
  //   var status = Platform.isAndroid
  //       ? await Permission.activityRecognition.request()
  //       : PermissionStatus.granted;

  //   return (status == PermissionStatus.granted)
  //       ? super.onStart()
  //       : Future.value(false);
  // }

  @override
  Stream<Measurement> get stream => pedometer.Pedometer.stepCountStream.map(
    (pedometer.StepCount count) => Measurement.fromData(
      StepCount(steps: count.steps),
      count.timeStamp.microsecondsSinceEpoch,
    ),
  );
}
