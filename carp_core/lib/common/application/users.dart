/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// Describes a participant playing a [role] in a study, and whether this
/// role [isOptional].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ParticipantRole {
  String role;
  bool isOptional;

  ParticipantRole(this.role, [this.isOptional = false]);

  factory ParticipantRole.fromJson(Map<String, dynamic> json) =>
      _$ParticipantRoleFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantRoleToJson(this);
}

/// Describes a participant [attribute] that pertains to all or specified
/// participants in a study.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ExpectedParticipantData {
  ParticipantAttribute? attribute;

  /// Determines whether the attribute can be set by all participants in the study
  /// (one field for all), or an individual attribute can be set by each of
  /// the specified [AssignedTo.Roles] (one field per role).
  late AssignedTo assignedTo;

  ExpectedParticipantData({required this.attribute, AssignedTo? assignedTo}) {
    this.assignedTo = assignedTo ?? AssignedTo.all();
  }

  factory ExpectedParticipantData.fromJson(Map<String, dynamic> json) =>
      _$ExpectedParticipantDataFromJson(json);
  Map<String, dynamic> toJson() => _$ExpectedParticipantDataToJson(this);
}

/// Describes expected data to be input by users related to one or multiple
/// participants in a study.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ParticipantAttribute extends Serializable {
  /// Uniquely identifies the type of data represented by this participant attribute.
  String inputDataType;

  ParticipantAttribute({required this.inputDataType}) : super();

  @override
  Function get fromJsonFunction => _$ParticipantAttributeFromJson;
  factory ParticipantAttribute.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ParticipantAttribute>(json);
  @override
  Map<String, dynamic> toJson() => _$ParticipantAttributeToJson(this);
  @override
  String get jsonType =>
      'dk.cachet.carp.common.application.users.ParticipantAttribute.DefaultParticipantAttribute';
}

/// Determines which participant roles to assign to something.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AssignedTo extends Serializable {
  /// Assign this to the specified [roleNames] in the study protocol.
  /// If null, assign this to all participants in the study protocol.
  Set<String>? roleNames;

  /// Is this role assigned to all participants?
  bool get isAssignedToAll => roleNames == null;

  /// Create a new assignment with the list of [roleNames].
  AssignedTo({this.roleNames}) : super();

  /// Create a new assignment assigned to all participants in the study protocol.
  AssignedTo.all() : this();

  @override
  Function get fromJsonFunction => _$AssignedToFromJson;
  factory AssignedTo.fromJson(Map<String, dynamic> json) => FromJsonFactory()
      .fromJson<AssignedTo>(json, notAvailable: AssignedTo.all());
  @override
  Map<String, dynamic> toJson() => _$AssignedToToJson(this);

  @override
  String get jsonType => isAssignedToAll
      ? 'dk.cachet.carp.common.application.users.AssignedTo.All'
      : 'dk.cachet.carp.common.application.users.AssignedTo.Roles';
}
