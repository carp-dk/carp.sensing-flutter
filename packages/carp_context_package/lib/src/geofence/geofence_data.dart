/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// A geofence event: entering, exiting, or dwelling in a geofence.
///
/// Produced by [GeofenceProbe] for the [ContextSamplingPackage.GEOFENCE]
/// measure. The geofence itself is set in a [GeofenceSamplingConfiguration].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Geofence extends Data {
  Geofence({required this.type, required this.name}) : super();

  @override
  Function get fromJsonFunction => _$GeofenceFromJson;
  factory Geofence.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Geofence>(json);
  @override
  Map<String, dynamic> toJson() => _$GeofenceToJson(this);

  /// The name of this geofence.
  String name;

  /// Type of geofence event.
  GeofenceType type;
}

/// The type of a [Geofence] event.
///
///  * `ENTER`: the phone moved into the geofence.
///  * `EXIT`: the phone moved out of the geofence.
///  * `DWELL`: the phone has stayed inside for the geofence's dwell time.
enum GeofenceType { ENTER, EXIT, DWELL }
