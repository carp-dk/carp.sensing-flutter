/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// A location fix from the phone, in GPS (WGS 84) format.
///
/// Produced by [ConfigurableLocationProbe] for the
/// [ContextSamplingPackage.LOCATION] measure, and returned by
/// [LocationManager.getLocation]. Latitude and longitude are inherited from
/// [Geolocation]. Most other fields are null if the platform does not report
/// them.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Location extends Geolocation {
  /// In meters above the WGS 84 reference ellipsoid.
  /// Derived from GPS information.
  double? altitude;

  /// Estimated horizontal accuracy of this location, radial, in meters.
  double? accuracy;

  /// Estimated vertical accuracy of this location, in meters.
  double? verticalAccuracy;

  /// Estimated movement speed.
  /// In meters/second
  double? speed;

  /// Accuracy in speed estimation.
  /// In meters/second
  double? speedAccuracy;

  /// Horizontal direction of travel of this device, in degrees.
  double? heading;

  /// Estimated bearing accuracy of this location, in degrees.
  /// Only available on Android.
  /// https://developer.android.com/reference/android/location/Location#getBearingAccuracyDegrees()
  double? headingAccuracy;

  /// The time when this location was collected.
  DateTime? time;

  /// Is the location currently mocked?
  ///
  /// Always false on iOS.
  bool? isMock;

  /// The time of this fix, in elapsed real-time since system boot.
  /// Only available on Android.
  /// https://developer.android.com/reference/android/location/Location#getElapsedRealtimeNanos()
  double? elapsedRealtimeNanos;

  /// Estimate of the precision of [elapsedRealtimeNanos], in nanoseconds.
  /// Only available on Android.
  /// https://developer.android.com/reference/android/location/Location#getElapsedRealtimeUncertaintyNanos()
  double? elapsedRealtimeUncertaintyNanos;

  /// The number of satellites used to derive the fix.
  /// Only available on Android.
  /// https://developer.android.com/reference/android/location/Location#getExtras()
  int? satellites;

  /// The location provider.
  /// Only available on Android. Deprecated in API level 31.
  /// Not set by [Location.fromLocationData].
  String? provider;

  Location({
    super.latitude,
    super.longitude,
    this.altitude,
    this.accuracy,
    this.verticalAccuracy,
    this.heading,
    this.headingAccuracy,
    this.speed,
    this.speedAccuracy,
    this.time,
    this.isMock,
    this.elapsedRealtimeNanos,
    this.elapsedRealtimeUncertaintyNanos,
    this.satellites,
    this.provider,
  }) : super();

  /// Creates a [Location] from a `LocationData` from the `location` plugin.
  ///
  /// Missing latitude/longitude become 0.
  Location.fromLocationData(location.LocationData location) : super() {
    latitude = location.latitude ?? 0;
    longitude = location.longitude ?? 0;
    altitude = location.altitude;
    accuracy = location.accuracy;
    verticalAccuracy = location.verticalAccuracy;
    speed = location.speed;
    speedAccuracy = location.speedAccuracy;
    heading = location.heading;
    time = (location.time != null)
        ? DateTime.fromMillisecondsSinceEpoch(location.time!.toInt())
        : null;
    isMock = location.isMock;
    headingAccuracy = location.headingAccuracy;
    elapsedRealtimeNanos = location.elapsedRealtimeNanos;
    elapsedRealtimeUncertaintyNanos = location.elapsedRealtimeUncertaintyNanos;
    satellites = location.satelliteNumber;
  }

  // /// Create a [Location] object based on a [Position] from the `geolocator` plugin.
  // Location.fromPositionData(geolocator.Position position) : super() {
  //   latitude = position.latitude;
  //   longitude = position.longitude;
  //   altitude = position.altitude;
  //   accuracy = position.accuracy;
  //   verticalAccuracy = position.altitudeAccuracy;
  //   speed = position.speed;
  //   speedAccuracy = position.speedAccuracy;
  //   heading = position.heading;
  //   time = position.timestamp.toUtc();
  //   isMock = position.isMocked;
  //   headingAccuracy = position.headingAccuracy;
  // }

  // /// Create a [Location] object based on a [LocationDto] from the
  // /// `carp_background_location` plugin.
  // Location.fromLocationDto(cbl.LocationDto location) : super() {
  //   latitude = location.latitude;
  //   longitude = location.longitude;
  //   altitude = location.altitude;
  //   accuracy = location.accuracy;
  //   speed = location.speed;
  //   speedAccuracy = location.speedAccuracy;
  //   bearing = location.heading;
  //   time = DateTime.fromMillisecondsSinceEpoch(location.time.toInt());
  //   isMock = location.isMocked;
  //   provider = location.provider;
  // }

  @override
  Function get fromJsonFunction => _$LocationFromJson;
  factory Location.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Location>(json);
  @override
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
