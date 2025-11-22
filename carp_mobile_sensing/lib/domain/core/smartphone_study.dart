/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../../domain.dart';

/// A study configured to run on a smartphone (i.e., on a [SmartPhoneClientManager]).
class SmartphoneStudy extends Study<SmartphoneDeployment> {
  ExecutorState _samplingStatus = ExecutorState.created;

  /// The unique id of the study in the deployment service.
  String? studyId;

  /// The ID of the participant in this study.
  String? participantId;

  /// The role of the participant in this study.
  String? participantRoleName;

  /// The status of the sampling of this study.
  ExecutorState get samplingStatus => _samplingStatus;
  set samplingStatus(ExecutorState state) {
    _samplingStatus = state;

    debug('$runtimeType - Setting sampling state: $state');

    createEvent(
      SmartphoneStudyStatusEvent(
        this,
        StudyStatusEventTypes.DeploymentUpdated,
        samplingStatus,
      ),
    );
  }

  /// Is this study sampling data?
  bool get isSampling => samplingStatus == ExecutorState.resumed;

  @override
  Stream<SmartphoneStudyStatusEvent> get events => super.events.map(
    (event) => SmartphoneStudyStatusEvent(this, event.event, samplingStatus),
  );

  /// Create a [SmartphoneStudy].
  SmartphoneStudy({
    this.studyId,
    required String studyDeploymentId,
    required String deviceRoleName,
    this.participantId,
    this.participantRoleName,
    DateTime? createdOn,
    StudyDeploymentStatus? deploymentStatus,
    SmartphoneDeployment? deployment,
  }) : super(
         studyDeploymentId,
         deviceRoleName,
         createdOn,
         deploymentStatus,
         deployment,
       );

  /// Create a [SmartphoneStudy] from [invitation].
  SmartphoneStudy.fromInvitation(ActiveParticipationInvitation invitation)
    : this(
        studyId: invitation.studyId,
        studyDeploymentId: invitation.studyDeploymentId,
        deviceRoleName:
            invitation.deviceRoleName ?? Smartphone.DEFAULT_ROLE_NAME,
        participantId: invitation.participantId,
        participantRoleName: invitation.participantRoleName,
      );

  /// Create a [SmartphoneStudy] from a SQL Result Map.
  factory SmartphoneStudy.fromMap(Map<String, Object?> map) {
    final statusJson = map[Persistence.DEPLOYMENT_STATUS_COLUMN] as String?;
    final status = statusJson != null && statusJson != 'null'
        ? StudyDeploymentStatus.fromJson(
            json.decode(statusJson) as Map<String, dynamic>,
          )
        : null;

    final deploymentJson = map[Persistence.DEPLOYMENT_COLUMN] as String?;
    final deployment = deploymentJson != null && deploymentJson != 'null'
        ? SmartphoneDeployment.fromJson(
            json.decode(deploymentJson) as Map<String, dynamic>,
          )
        : null;

    return SmartphoneStudy(
        studyId: map[Persistence.STUDY_ID_COLUMN] as String?,
        studyDeploymentId:
            map[Persistence.STUDY_DEPLOYMENT_ID_COLUMN] as String,
        deviceRoleName: map[Persistence.DEVICE_ROLE_NAME_COLUMN] as String,
        participantId: map[Persistence.PARTICIPANT_ID_COLUMN] as String?,
        participantRoleName:
            map[Persistence.PARTICIPANT_ROLE_NAME_COLUMN] as String?,
        createdOn: map[Persistence.PARTICIPANT_ROLE_NAME_COLUMN] != null
            ? DateTime.tryParse(
                map[Persistence.PARTICIPANT_ROLE_NAME_COLUMN] as String,
              )
            : null,
        deploymentStatus: status,
        deployment: deployment,
      )
      ..samplingStatus =
          ExecutorState.values[map[Persistence.SAMPLING_STATUS_COLUMN] as int];
  }

  @override
  String toString() =>
      '$runtimeType - '
      'studyId: $studyId, '
      'studyDeploymentId: $studyDeploymentId, '
      'device role: $deviceRoleName, '
      'participant id: $participantId, '
      'participant role: $participantRoleName';
}

/// An event related to a running [study]. including its runtime [state].
class SmartphoneStudyStatusEvent extends StudyStatusEvent<SmartphoneStudy> {
  final ExecutorState state;
  const SmartphoneStudyStatusEvent(super.study, super.event, this.state);
  @override
  String toString() => '${super.toString()}, state: $state';
}
