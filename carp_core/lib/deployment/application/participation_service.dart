/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../deployment.dart';

/// Application service which allows inviting participants, retrieving participation
/// invitations for study deployments, and managing data related to participants
/// which is input by users.
abstract class ParticipationService {
  static const String API_VERSION = "1.0";

  /// Get all invitations of active study deployments the account
  /// with the given [accountId] has been invited to.
  Future<List<ActiveParticipationInvitation>>
  getActiveParticipationInvitations({String? accountId});

  /// Get currently set data for all expected participant data in the study
  /// deployment with [studyDeploymentId].
  /// Data which is not set equals null.
  Future<ParticipantData> getParticipantData(String studyDeploymentId);

  /// Get currently set data for all expected participant data for a set of study
  /// deployments with [studyDeploymentIds].
  /// Data which is not set equals null.
  Future<List<ParticipantData>> getParticipantDataList(
    List<String> studyDeploymentIds,
  );

  /// Set [data] that was [inputByParticipantRole] in the study deployment with
  /// [studyDeploymentId].
  ///
  /// If [inputByParticipantRole] is null, all roles can set it.
  /// If you want to set data that was assigned to a specific participant role,
  /// [inputByParticipantRole] needs to be set.
  ///
  /// Returns all data for the specified study deployment, including the newly
  /// set data.
  Future<ParticipantData> setParticipantData(
    String studyDeploymentId,
    Map<String, Data> data, [
    String? inputByParticipantRole,
  ]);
}
