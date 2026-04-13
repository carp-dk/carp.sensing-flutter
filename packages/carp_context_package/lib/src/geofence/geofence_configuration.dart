/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Position coordinated in Degrees (i.e. GPS-style).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GeoPosition extends Serializable {
  /// Earth radius in km.
  static const double earthRadius = 6371000.0;

  /// Latitude in GPS coordinates.
  final double latitude;

  /// Longitude in GPS coordinates.
  final double longitude;

  /// Convert degrees to radians.
  double degToRad(num deg) => deg * (math.pi / 180.0);

  /// Convert radians to degrees.
  double radToDeg(num rad) => rad * (180.0 / math.pi);

  GeoPosition(this.latitude, this.longitude);

  GeoPosition.fromLocation(Location location)
    : latitude = location.latitude,
      longitude = location.longitude,
      super();

  /// Returns the approximate distance in meters between this location and the given location.
  ///
  /// For distance calculations we use the  'haversine' formula to calculate the great-circle distance between two points.
  /// See http://www.movable-type.co.uk/scripts/latlong.html for details on how to
  /// calculate distance, bearing and more between latitude/longitude points.
  double distanceTo(GeoPosition destination) {
    final sDLat = math.sin(
      (degToRad(destination.latitude) - degToRad(latitude)) / 2,
    );
    final sDLng = math.sin(
      (degToRad(destination.longitude) - degToRad(longitude)) / 2,
    );
    final a =
        sDLat * sDLat +
        sDLng *
            sDLng *
            math.cos(degToRad(latitude)) *
            math.cos(degToRad(destination.latitude));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  Function get fromJsonFunction => _$GeoPositionFromJson;
  factory GeoPosition.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GeoPosition>(json);
  @override
  Map<String, dynamic> toJson() => _$GeoPositionToJson(this);

  @override
  String toString() => 'GeoPosition (latitude:$latitude, longitude:$longitude)';

  @override
  int get hashCode => latitude.hashCode + longitude.hashCode;

  @override
  bool operator ==(Object other) =>
      other is GeoPosition &&
      latitude == other.latitude &&
      longitude == other.longitude;
}

/// Specify the configuration of a circular geofence measure, specifying the:
///  - center
///  - radius
///  - name
/// of the geofence.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GeofenceSamplingConfiguration extends PersistentSamplingConfiguration {
  /// The center of the geofence as a GPS location.
  GeoPosition center;

  /// The radius of the geofence in meters.
  double radius;

  /// The dwell time of this geofence.
  Duration dwell;

  /// A label for this geofence.
  String name;

  GeofenceSamplingConfiguration({
    required this.center,
    required this.radius,
    required this.dwell,
    required this.name,
  }) : super();

  @override
  Function get fromJsonFunction => _$GeofenceSamplingConfigurationFromJson;
  @override
  Map<String, dynamic> toJson() => _$GeofenceSamplingConfigurationToJson(this);
  factory GeofenceSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GeofenceSamplingConfiguration>(json);
}
