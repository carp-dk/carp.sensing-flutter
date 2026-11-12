/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A CARP Core [ParticipationService] that talks to CAWS.
///
/// A participant app uses it first: to find the study invitations of the
/// signed-in user, and to read and write participant data (like informed
/// consent or address) for a study deployment.
///
/// Key points:
///  * A singleton; call [configure] (or [configureFrom]) and authenticate
///    with [CarpAuthService] before use.
///  * [getActiveParticipationInvitations] returns the invitations. Showing
///    them to the user is up to the app.
///  * [participation] returns a [ParticipationReference] bound to one study
///    deployment, which is the easier way to handle participant data.
///
/// The selected invitation gives the study deployment used by
/// [CarpDeploymentService] to fetch the deployment.
///
/// ```dart
/// CarpParticipationService().configureFrom(CarpService());
/// final invitations =
///     await CarpParticipationService().getActiveParticipationInvitations();
/// ```
class CarpParticipationService extends CarpBaseService implements ParticipationService {
  static final CarpParticipationService _instance = CarpParticipationService._();

  CarpParticipationService._();

  /// Returns the singleton default instance of the [CarpParticipationService].
  /// Before this instance can be used, it must be configured using the [configure] method.
  factory CarpParticipationService() => _instance;

  @override
  String get rpcEndpointName => "participation-service";

  /// Gets a [ParticipationReference] for a [studyDeploymentId].
  ///
  /// [studyDeploymentId] can be omitted if specified as part of this
  /// service's [study].
  ParticipationReference participation([String? studyDeploymentId]) =>
      ParticipationReference._(this, getStudyDeploymentId(studyDeploymentId));

  /// Gets the list of active participation invitations for an [accountId]
  /// and for an app named [applicationName].
  ///
  /// Note that the [accountId] is the unique CARP account id (and not the
  /// username). The [applicationName] is typically the Flutter application name
  /// specified in the `pubspec.yaml` file.
  ///
  /// If [accountId] is not specified, the account id of the currently
  /// authenticated [CarpUser] is used.
  /// If [applicationName] is not specified, all types of applications are considered.
  /// Otherwise only invitations whose `applicationData` holds a matching
  /// `applicationName` are returned.
  @override
  Future<List<ActiveParticipationInvitation>> getActiveParticipationInvitations({
    String? accountId,
    String? applicationName,
  }) async {
    accountId ??= CarpAuthService().currentUser.id;

    CarpLog.debug("$runtimeType - Getting invitations for '$accountId' for application: '$applicationName'.");

    dynamic responseJson = await _rpc(GetActiveParticipationInvitations(accountId));

    // we expect a list of invitations
    List<dynamic> list = responseJson as List<dynamic>;
    List<ActiveParticipationInvitation> invitations = list
        .map((item) => ActiveParticipationInvitation.fromJson(item as Map<String, dynamic>))
        .toList();

    // if a applicationName is specified, filter on that
    if (applicationName != null) {
      invitations = invitations.where((invitation) {
        if (invitation.invitation.applicationData == null) return false;
        if (invitation.invitation.applicationData is! Map<String, dynamic>) {
          return false;
        }
        return invitation.invitation.applicationData?['applicationName'] == applicationName;
      }).toList();
    }

    return invitations;
  }

  @override
  Future<ParticipantData> getParticipantData(String studyDeploymentId) async =>
      await participation(studyDeploymentId).getParticipantData();

  @override
  Future<List<ParticipantData>> getParticipantDataList(List<String> studyDeploymentIds) async {
    // early out if empty list
    if (studyDeploymentIds.isEmpty) return [];

    dynamic responseJson = await _rpc(GetParticipantDataList(studyDeploymentIds));

    // we expect a list of participant data
    List<dynamic> items = responseJson as List<dynamic>;
    if (items.isEmpty) return [];

    List<ParticipantData> data = [];
    for (var item in items) {
      data.add(ParticipantData.fromJson(item as Map<String, dynamic>));
    }

    return data;
  }

  @override
  Future<ParticipantData> setParticipantData(
    String studyDeploymentId,
    Map<String, Data> data, [
    String? inputByParticipantRole,
  ]) async => await participation(studyDeploymentId).setParticipantData(data, inputByParticipantRole);
}
