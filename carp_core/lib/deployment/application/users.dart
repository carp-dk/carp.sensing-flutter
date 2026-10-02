/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../deployment.dart';

/// The information which needs to be provided when inviting a participant to
/// a deployment.
///
/// Passed to [DeploymentService.createStudyDeployment].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ParticipantInvitation {
  /// An ID for the participant, uniquely assigned by the calling service.
  /// A random UUID (v4) if not specified.
  late String participantId;

  /// The participant roles in the study protocol which the participant is assigned to.
  AssignedTo assignedRoles;

  /// The identity used to authenticate and invite the participant.
  AccountIdentity identity;

  /// A description of the study which is shared with the participant.
  StudyInvitation invitation;

  ParticipantInvitation({
    String? participantId,
    required this.assignedRoles,
    required this.identity,
    required this.invitation,
  }) : super() {
    this.participantId = participantId ?? const Uuid().v4();
  }

  factory ParticipantInvitation.fromJson(Map<String, dynamic> json) =>
      _$ParticipantInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantInvitationToJson(this);
}

/// Uniquely identifies the participation of an account in a study deployment.
///
/// Part of an [ActiveParticipationInvitation].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Participation {
  /// The CARP study deployment ID.
  String studyDeploymentId;

  /// Unique id for the participant in this participation.
  String participantId;

  /// The participant roles in the study protocol which the participant
  /// is assigned to.
  AssignedTo assignedRoles;

  Participation(this.studyDeploymentId, this.participantId, this.assignedRoles)
    : super();

  factory Participation.fromJson(Map<String, dynamic> json) =>
      _$ParticipationFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipationToJson(this);

  @override
  String toString() =>
      '${super.toString()}, participantId: $participantId, studyDeploymentId: $studyDeploymentId';
}

/// A description of a study, shared with participants once they are invited to a study.
///
/// Part of a [ParticipantInvitation] and an [ActiveParticipationInvitation].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StudyInvitation {
  /// A descriptive name for the study to be shown to participants.
  String name;

  /// A description of the study clarifying to participants what it is about.
  String? description;

  /// Application-specific data to be shared with clients when they are invited
  /// to a study.
  ///
  /// This can be used by infrastructures or concrete applications which require
  /// exchanging additional data between the study and client subsystems,
  /// outside of scope or not yet supported by CARP core.
  /// The CARP web services put the study id here, either as a plain string or
  /// as a JSON map with a `studyId` key; see
  /// [ActiveParticipationInvitation.studyId].
  dynamic applicationData;

  StudyInvitation(this.name, [this.description, this.applicationData])
    : super();

  factory StudyInvitation.fromJson(Map<String, dynamic> json) =>
      _$StudyInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$StudyInvitationToJson(this);

  @override
  String toString() =>
      '$runtimeType - name: $name, description: $description, applicationData: $applicationData';
}

/// An [invitation] to participate in an active study deployment using the
/// [assignedDevices].
///
/// Returned by [ParticipationService.getActiveParticipationInvitations]. A
/// participant app shows these to let the user pick a study, and then
/// creates a [Study] from [studyDeploymentId] and [deviceRoleName].
/// Some of the devices which the participant is invited to might already be
/// registered. If the participant wants to use a different device, they will
/// need to unregister the existing device first.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ActiveParticipationInvitation {
  /// Who participates in which study deployment.
  Participation participation;

  /// The study description shown to the participant.
  StudyInvitation invitation;

  /// The primary devices the participant is invited to use.
  List<AssignedPrimaryDevice>? assignedDevices;

  // The following are user-friendly getters for the most used info in an invitation.

  String? _studyId;

  /// The ID of the study; null if not available.
  ///
  /// The study ID is extracted from [StudyInvitation.applicationData] of the
  /// [invitation], either as a plain string or as the `studyId` field of a map.
  String? get studyId {
    if (_studyId != null) return _studyId;
    if (invitation.applicationData == null) return null;

    if (invitation.applicationData is String) {
      // The application data is a plain String, so we can return it directly.
      _studyId = invitation.applicationData as String;
    } else {
      if (invitation.applicationData is Map<String, dynamic>) {
        // The application data is JSON, so we can to parse it.
        final appData = invitation.applicationData! as Map<String, dynamic>;
        _studyId = appData['studyId'] as String?;
      }
    }
    return _studyId;
  }

  /// The study deployment ID.
  String get studyDeploymentId => participation.studyDeploymentId;

  /// The study name.
  String? get studyName => invitation.name;

  /// The study description.
  String? get studyDescription => invitation.description;

  /// The role name of the first assigned device; null if [assignedDevices] is
  /// null. Throws a [StateError] if the list is empty.
  String? get deviceRoleName => assignedDevices?.first.device.roleName;

  /// The ID of the participant.
  String get participantId => participation.participantId;

  /// The first role name of the participant; null if assigned to all roles.
  String? get participantRoleName =>
      participation.assignedRoles.roleNames?.first;

  ActiveParticipationInvitation(this.participation, this.invitation) : super();

  factory ActiveParticipationInvitation.fromJson(Map<String, dynamic> json) =>
      _$ActiveParticipationInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveParticipationInvitationToJson(this);

  @override
  String toString() =>
      '$runtimeType - participation: $participation, invitation: $invitation, devices size: ${assignedDevices!.length}';
}

/// The status of a participant in a study deployment.
///
/// Part of [StudyDeploymentStatus.participantStatusList].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ParticipantStatus {
  /// Unique id of the participant in the study deployment.
  String participantId;

  /// The participant roles the participant is assigned to.
  AssignedTo assignedParticipantRoles;

  /// Role names of the primary devices the participant uses.
  Set<String> assignedPrimaryDeviceRoleNames;

  ParticipantStatus(
    this.participantId,
    this.assignedParticipantRoles,
    this.assignedPrimaryDeviceRoleNames,
  ) : super();
  factory ParticipantStatus.fromJson(Map<String, dynamic> json) =>
      _$ParticipantStatusFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantStatusToJson(this);
}
