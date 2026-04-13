/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Holds information about a geofence event of entering, exiting, or dwelling.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Geofence extends Data {
  Geofence({required this.type, required this.name}) : super();

  @override
  Function get fromJsonFunction => _$GeofenceFromJson;
  factory Geofence.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Geofence>(json);
  @override
  Map<String, dynamic> toJson() => _$GeofenceToJson(this);

  /// The name of this geofence.
  String name;

  /// Type of geofence event:
  ///  - ENTER
  ///  - EXIT
  ///  - DWELL
  GeofenceType type;
}

enum GeofenceType { ENTER, EXIT, DWELL }
