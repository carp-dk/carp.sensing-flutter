/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../protocol.dart';

// /// Uniquely identifies a study protocol by the [ownerId] and it's [name].
// @JsonSerializable(includeIfNull: false, explicitToJson: true)
// class StudyProtocolId {
//   String ownerId;
//   String name;
//   StudyProtocolId(this.ownerId, this.name);

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is StudyProtocolId &&
//           runtimeType == other.runtimeType &&
//           ownerId == other.ownerId &&
//           name == other.name;

//   @override
//   int get hashCode => (ownerId + name).hashCode;

//   factory StudyProtocolId.fromJson(Map<String, dynamic> json) =>
//       _$StudyProtocolIdFromJson(json);
//   Map<String, dynamic> toJson() => _$StudyProtocolIdToJson(this);

//   @override
//   String toString() => '$runtimeType - ownerId: $ownerId, name: $name';
// }

/// Specifies a specific version for a [StudyProtocol], identified by a [tag].
///
/// [date] is the date when this version of the protocol was created.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ProtocolVersion {
  String tag;
  late DateTime date;

  ProtocolVersion(this.tag) {
    date = DateTime.now();
  }

  factory ProtocolVersion.fromJson(Map<String, dynamic> json) =>
      _$ProtocolVersionFromJson(json);
  Map<String, dynamic> toJson() => _$ProtocolVersionToJson(this);

  @override
  String toString() => '$runtimeType - tag: $tag, date: $date';
}
