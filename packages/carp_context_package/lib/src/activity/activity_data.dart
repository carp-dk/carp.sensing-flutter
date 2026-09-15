/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Holds an activity event as recognized by the phone Activity Recognition (AR) API.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Activity extends Data {
  /// Mapping of the activity types reported by the AR plugin to the CARP
  /// [ActivityType]s.
  ///
  /// The plugin's `TILTING` and `UNKNOWN` types have no CARP counterpart and
  /// are therefore not part of this map - the [ActivityProbe] discards both.
  static const Map<ar.ActivityType, ActivityType> _activityTypeMap = {
    ar.ActivityType.IN_VEHICLE: ActivityType.IN_VEHICLE,
    ar.ActivityType.ON_BICYCLE: ActivityType.ON_BICYCLE,
    ar.ActivityType.ON_FOOT: ActivityType.ON_FOOT,
    ar.ActivityType.RUNNING: ActivityType.RUNNING,
    ar.ActivityType.STILL: ActivityType.STILL,
    ar.ActivityType.WALKING: ActivityType.WALKING,
  };

  /// Confidence in activity recognition in percent (0-100).
  int confidence;

  /// Type of activity recognized.
  ///
  /// Possible types of activities are:
  /// * IN_VEHICLE - The device is in a vehicle, such as a car.
  /// * ON_BICYCLE - The device is on a bicycle.
  /// * ON_FOOT - The device is on a user who is walking or running.
  /// * WALKING - The device is on a user who is walking.
  /// * RUNNING - The device is on a user who is running.
  /// * STILL - The device is still (not moving).
  ///
  /// The types above are adopted from the Android activity recognition API.
  /// On iOS the following mapping takes place:
  ///
  /// * stationary => STILL
  /// * walking => WALKING
  /// * running => RUNNING
  /// * automotive => IN_VEHICLE
  /// * cycling => ON_BICYCLE
  ///
  /// Note that the [ActivityProbe] discard some AR events, which include:
  ///  * UNKNOWN - when the activity cannot be recognized
  ///  * TILTING - when the phone is tilted (only on Android)
  ///  * Activities with a low confidence level (<50%)
  ActivityType type;

  Activity({required this.type, required this.confidence}) : super();

  @override
  bool equivalentTo(Data other) => other is Activity && type == other.type;

  /// Create an [Activity] from an [ar.ActivityEvent] as reported by the
  /// AR plugin.
  factory Activity.fromActivityEvent(ar.ActivityEvent event) => Activity(
    type: _activityTypeMap[event.type] ?? ActivityType.UNKNOWN,
    confidence: event.confidence,
  );

  @override
  Function get fromJsonFunction => _$ActivityFromJson;
  factory Activity.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Activity>(json);
  @override
  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  /// Activity [type] as a string.
  String get typeString => type.name;
}

/// Defines the type of activity.
enum ActivityType {
  /// The device is in a vehicle, such as a car.
  IN_VEHICLE,

  /// The device is on a bicycle.
  ON_BICYCLE,

  /// The device is on a user who is walking or running.
  ///
  /// This is the parent activity of [WALKING] and [RUNNING] and is reported
  /// when the AR API cannot tell the two apart.
  ON_FOOT,

  /// The device is on a user who is running.
  RUNNING,

  /// The device is still (not moving).
  STILL,

  /// The device is on a user who is walking.
  WALKING,

  /// Unable to detect the current activity.
  UNKNOWN,
}
