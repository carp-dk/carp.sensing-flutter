/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../deployment.dart';

/// Participant data for all participants in a study deployment
/// with [studyDeploymentId].
///
/// Returned by [ParticipationService.getParticipantData]. Values are keyed by
/// input data type (see [InputType]); unset values are null.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ParticipantData {
  /// The study deployment this data belongs to.
  String studyDeploymentId;

  /// Data that is related to everyone in the study deployment.
  Map<String, Data?> common;

  /// Data that is related to specific roles in the study deployment.
  List<RoleData> roles;

  ParticipantData({
    required this.studyDeploymentId,
    this.common = const {},
    this.roles = const [],
  }) : super();

  factory ParticipantData.fromJson(Map<String, dynamic> json) =>
      _$ParticipantDataFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantDataToJson(this);
}

/// Participant [data] for all participants with a specific [roleName].
///
/// Part of [ParticipantData.roles].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RoleData {
  /// The participant role this data belongs to.
  String roleName;

  /// Data that is related to this role in the study deployment.
  Map<String, Data?> data;

  RoleData({required this.roleName, this.data = const {}}) : super();

  factory RoleData.fromJson(Map<String, dynamic> json) =>
      _$RoleDataFromJson(json);
  Map<String, dynamic> toJson() => _$RoleDataToJson(this);
}
