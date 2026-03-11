/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../../domain.dart';

/// A study configured to run on a smartphone (i.e., on a [SmartPhoneClientManager]).
class SmartphoneStudy extends Study<SmartphoneDeployment> {
  SmartphoneDeploymentExecutorSamplingState? _samplingState;

  /// The unique id of the study in the deployment service.
  String? studyId;

  /// The ID of the participant in this study.
  String? participantId;

  /// The role of the participant in this study.
  String? participantRoleName;

  /// The sampling state of this study.
  SmartphoneDeploymentExecutorSamplingState? get samplingState =>
      _samplingState;
  set samplingState(SmartphoneDeploymentExecutorSamplingState? state) {
    _samplingState = state;

    createEvent(
      SmartphoneStudyStatusEvent(
        this,
        StudyStatusEventTypes.SamplingStateChanged,
        samplingState,
      ),
    );
  }

  /// Is this study deployed?
  bool get isDeployed => deployment != null;

  /// Is this study sampling data?
  bool get isSampling =>
      (samplingState?.state ?? ExecutorState.Undefined) ==
      ExecutorState.Resumed;

  @override
  Stream<SmartphoneStudyStatusEvent> get events => super.events.map(
    (event) => SmartphoneStudyStatusEvent(this, event.event, samplingState),
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
    final statusJson =
        map[PersistenceService.DEPLOYMENT_STATUS_COLUMN] as String?;
    final status = statusJson != null && statusJson != 'null'
        ? StudyDeploymentStatus.fromJson(
            json.decode(statusJson) as Map<String, dynamic>,
          )
        : null;

    final deploymentJson = map[PersistenceService.DEPLOYMENT_COLUMN] as String?;
    final deployment = deploymentJson != null && deploymentJson != 'null'
        ? SmartphoneDeployment.fromJson(
            json.decode(deploymentJson) as Map<String, dynamic>,
          )
        : null;

    final samplingStateJson =
        map[PersistenceService.SAMPLING_STATUS_COLUMN] as String?;
    final samplingState =
        samplingStateJson != null && samplingStateJson != 'null'
        ? SmartphoneDeploymentExecutorSamplingState.fromJson(
            json.decode(samplingStateJson) as Map<String, dynamic>,
          )
        : null;

    return SmartphoneStudy(
      studyId: map[PersistenceService.STUDY_ID_COLUMN] as String?,
      studyDeploymentId:
          map[PersistenceService.STUDY_DEPLOYMENT_ID_COLUMN] as String,
      deviceRoleName: map[PersistenceService.DEVICE_ROLE_NAME_COLUMN] as String,
      participantId: map[PersistenceService.PARTICIPANT_ID_COLUMN] as String?,
      participantRoleName:
          map[PersistenceService.PARTICIPANT_ROLE_NAME_COLUMN] as String?,
      createdOn: map[PersistenceService.CREATED_ON_COLUMN] != null
          ? DateTime.tryParse(
              map[PersistenceService.CREATED_ON_COLUMN] as String,
            )
          : null,
      deploymentStatus: status,
      deployment: deployment,
    )..samplingState = samplingState;
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

/// An event related to a running [study], including its runtime [state].
class SmartphoneStudyStatusEvent extends StudyStatusEvent<SmartphoneStudy> {
  final SmartphoneDeploymentExecutorSamplingState? state;
  const SmartphoneStudyStatusEvent(super.study, super.event, [this.state]);
  @override
  String toString() => '${super.toString()}, state: $state';
}
