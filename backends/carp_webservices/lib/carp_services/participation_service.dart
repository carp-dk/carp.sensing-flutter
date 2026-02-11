/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A [ParticipationService] that talks to the CARP backend server(s).
class CarpParticipationService extends CarpBaseService
    implements ParticipationService {
  static final CarpParticipationService _instance =
      CarpParticipationService._();

  CarpParticipationService._();

  /// Returns the singleton default instance of the [CarpParticipationService].
  /// Before this instance can be used, it must be configured using the [configure] method.
  factory CarpParticipationService() => _instance;

  @override
  String get rpcEndpointName => "participation-service";

  /// Gets a [ParticipationReference] for a [studyDeploymentId].
  ParticipationReference participation([String? studyDeploymentId]) =>
      ParticipationReference._(this, getStudyDeploymentId(studyDeploymentId));

  /// Get the list of active participation invitations for an [accountId]
  /// and for a app named [applicationName].
  ///
  /// Note that the [accountId] is the unique CARP account id (and not the
  /// username). The [applicationName] is typically the Flutter application name
  /// specified in the `pubspec.yaml` file.
  ///
  /// If [accountId] is not specified, the account id of the currently
  /// authenticated [CarpUser] is used.
  /// If [applicationName] is not specified, all types of applications are considered.
  @override
  Future<List<ActiveParticipationInvitation>>
  getActiveParticipationInvitations({
    String? accountId,
    String? applicationName,
  }) async {
    accountId ??= CarpAuthService().currentUser.id;

    debug(
      "$runtimeType - Getting invitations for '$accountId' for application: '$applicationName'.",
    );

    dynamic responseJson = await _rpc(
      GetActiveParticipationInvitations(accountId),
    );

    // we expect a list of invitations
    List<dynamic> list = responseJson as List<dynamic>;
    List<ActiveParticipationInvitation> invitations = list
        .map(
          (item) => ActiveParticipationInvitation.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    // if a applicationName is specified, filter on that
    if (applicationName != null) {
      invitations = invitations
          .where(
            (invitation) =>
                (invitation.invitation.applicationData?['applicationName'] ==
                applicationName),
          )
          .toList();
    }

    return invitations;
  }

  /// Get a study invitation from CARP by allowing the user to select from
  /// multiple invitations (if more than one is available).
  ///
  /// Returns the selected invitation. Returns `null` if the user has no invitation(s)
  /// or if the user closes the dialog (if [allowClose] is true).
  ///
  /// If the user is invited to more than one study and [showInvitations] is `true`,
  /// a user-interface dialog for selecting amongst the invitations is shown.
  /// If not, the study id of the first invitation is returned.
  /// If [device] is specified, only invitations for that device are considered.
  /// The [device] is the full namespace of the device, e.g.,
  /// "dk.carp.cams.devices.Smartphone".
  ///
  /// [allowClose] specifies whether the user can close the window without
  /// selecting an invitation.
  Future<ActiveParticipationInvitation?> getStudyInvitation(
    BuildContext context, {
    bool showInvitations = true,
    String? device,
    bool allowClose = false,
  }) async {
    if (!isConfigured) {
      throw CarpServiceException(
        "CARP Service not initialized. Call 'CarpService().configure()' first.",
      );
    }

    if (!CarpAuthService().authenticated) {
      throw CarpServiceException(
        "The current user is not authenticated to CAWS. Call 'CarpAuthService().authenticate...()' first.",
      );
    }

    List<ActiveParticipationInvitation> invitations =
        await getActiveParticipationInvitations(applicationName: device);

    ActiveParticipationInvitation? invitation;

    if (invitations.isEmpty) return null;

    if (invitations.length == 1 || !showInvitations) {
      invitation = invitations[0];
    } else {
      if (context.mounted) {
        invitation = await showDialog<ActiveParticipationInvitation>(
          context: context,
          barrierDismissible: allowClose,
          builder: (BuildContext context) =>
              ActiveParticipationInvitationDialog().build(context, invitations),
        );
      }
    }

    return invitation;
  }

  @override
  Future<ParticipantData> getParticipantData(String studyDeploymentId) async =>
      await participation(studyDeploymentId).getParticipantData();

  @override
  Future<List<ParticipantData>> getParticipantDataList(
    List<String> studyDeploymentIds,
  ) async {
    // early out if empty list
    if (studyDeploymentIds.isEmpty) return [];

    dynamic responseJson = await _rpc(
      GetParticipantDataList(studyDeploymentIds),
    );

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
  ]) async => await participation(
    studyDeploymentId,
  ).setParticipantData(data, inputByParticipantRole);
}
