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
  /// The minimum confidence (in percent) an AR event must have in order to
  /// be collected.
  static const int minimumConfidence = 50;

  Stream<Measurement>? _stream;

  @override
  Stream<Measurement> get stream => _stream ??= ar.ActivityRecognition()
      // On Android the AR plugin runs a foreground service, which is needed
      // for AR events to keep arriving while the app is in the background.
      // The flag is ignored on iOS.
      .activityStream(runForegroundService: true)
      .where((event) => event.type != ar.ActivityType.UNKNOWN)
      .where((event) => event.type != ar.ActivityType.TILTING)
      .where((event) => event.confidence >= minimumConfidence)
      .map((event) => Measurement.fromData(Activity.fromActivityEvent(event)))
      .asBroadcastStream();
}
