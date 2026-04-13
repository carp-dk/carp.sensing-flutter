/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../deployment.dart';

/// Expected participant [data] for all participants in a study deployment
/// with [studyDeploymentId].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ParticipantData {
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

/// Expected participant [data] for all participants with a specific [roleName].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RoleData {
  String roleName;

  /// Data that is related to this role in the study deployment.
  Map<String, Data?> data;

  RoleData({required this.roleName, this.data = const {}}) : super();

  factory RoleData.fromJson(Map<String, dynamic> json) =>
      _$RoleDataFromJson(json);
  Map<String, dynamic> toJson() => _$RoleDataToJson(this);
}
