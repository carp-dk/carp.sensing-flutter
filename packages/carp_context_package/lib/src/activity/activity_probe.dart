/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Collects activity information from the underlying OS's activity recognition
/// API. It generates an [Activity] every time an activity is detected.
///
/// Since the AR on both Android and iOS generates a lot of 'useless' events, the
/// following AR event are ignored:
///  * UNKNOWN - when the activity cannot be recognized
///  * TILTING - when the phone is tilted (only on Android)
///  * Activities with a low confidence level (<50%)
class ActivityProbe extends StreamProbe {
  Stream<Measurement>? _stream;

  @override
  Stream<Measurement> get stream => _stream ??= ar
      .FlutterActivityRecognition
      .instance
      .activityStream
      .where((event) => event.type != ar.ActivityType.UNKNOWN)
      .where((event) => event.confidence != ar.ActivityConfidence.LOW)
      .map((activity) => Measurement.fromData(Activity.fromActivity(activity)))
      .asBroadcastStream();
}
