/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A reference to the participant data of one study deployment in CAWS.
///
/// Obtained from [CarpParticipationService.participation]. Following the CARP
/// Core [deployment sub-system](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-deployments.md),
/// it is used to:
///
///   - [getParticipantData] - get participant data from this deployment.
///   - [setParticipantData] - set participant data in this deployment.
///
/// It also has methods for setting, getting, and removing an
/// [InformedConsentInput] as participant data. This replaces the deprecated
/// consent endpoints of [CarpService].
class ParticipationReference extends RPCCarpReference {
  final String _studyDeploymentId;

  /// The CARP study deployment ID.
  String get studyDeploymentId => _studyDeploymentId;

  ParticipationReference._(
    CarpParticipationService service,
    this._studyDeploymentId,
  ) : super._(service);

  /// The URL for the participation endpoint.
  ///
  /// {{PROTOCOL}}://{{SERVER_HOST}}:{{SERVER_PORT}}/api/participation-service
  @override
  String get rpcEndpointUri =>
      "${service.app.uri.toString()}/api/participation-service";

  /// Resolves the role name of a participant.
  ///
  /// Returns [roleName] if not null. Otherwise returns the participant role
  /// name of the [CarpBaseService.study] of [service], if available.
  /// Throws a [CarpServiceException] if the role name cannot be resolved.
  String getParticipantRoleName(String? roleName) {
    if (roleName != null) {
      return roleName;
    } else if (service.study != null &&
        service.study?.participantRoleName != null) {
      return service.study!.participantRoleName!;
    } else {
      throw CarpServiceException(
        'No participant role name specified for CAWS endpoint.',
      );
    }
  }

  /// Gets currently set data for all expected participant data in this study
  /// deployment.
  /// Data which is not set equals null.
  Future<ParticipantData> getParticipantData() async =>
      ParticipantData.fromJson(
        await _rpc(GetParticipantData(studyDeploymentId))
            as Map<String, dynamic>,
      );

  /// Sets participant [data] for the given [inputByParticipantRole] in this
  /// study deployment.
  /// The keys of [data] are input data types, like [InputType.INFORMED_CONSENT].
  /// If [inputByParticipantRole] is null, the data is shared input that any
  /// participant role may supply. Specify the role to set input assigned to one
  /// participant role.
  ///
  /// Returns all data for the specified study deployment, including the newly set data.
  Future<ParticipantData> setParticipantData(
    Map<String, Data> data, [
    String? inputByParticipantRole,
  ]) async => ParticipantData.fromJson(
    await _rpc(
          SetParticipantData(studyDeploymentId, data, inputByParticipantRole),
        )
        as Map<String, dynamic>,
  );

  /// Gets informed consent data for all participants (by role name) in this
  /// study deployment.
  /// Informed consent which is not set equals null.
  Future<Map<String, InformedConsentInput?>> getInformedConsent() async {
    Map<String, InformedConsentInput?> map = {};

    ParticipantData data = ParticipantData.fromJson(
      await _rpc(GetParticipantData(studyDeploymentId)) as Map<String, dynamic>,
    );

    for (var roleData in data.roles) {
      if (roleData.data.containsKey(InputType.INFORMED_CONSENT)) {
        map[roleData.roleName] =
            roleData.data[InputType.INFORMED_CONSENT] != null
            ? roleData.data[InputType.INFORMED_CONSENT] as InformedConsentInput
            : null;
      } else {
        map[roleData.roleName] = null;
      }
    }

    return map;
  }

  /// Gets the informed consent uploaded by a participant with [roleName] in
  /// this study deployment.
  ///
  /// If [roleName] is not specified, it is resolved by
  /// [getParticipantRoleName].
  ///
  /// Returns null if not available.
  Future<InformedConsentInput?> getInformedConsentByRole([
    String? roleName,
  ]) async => (await getInformedConsent())[getParticipantRoleName(roleName)];

  /// Sets informed [consent] for the given [inputByParticipantRole] in this
  /// study deployment.
  /// If [inputByParticipantRole] is not specified, it is resolved by
  /// [getParticipantRoleName].
  Future<void> setInformedConsent(
    InformedConsentInput consent, [
    String? inputByParticipantRole,
  ]) async {
    ParticipantData.fromJson(
      await _rpc(
            SetParticipantData(studyDeploymentId, {
              InputType.INFORMED_CONSENT: consent,
            }, getParticipantRoleName(inputByParticipantRole)),
          )
          as Map<String, dynamic>,
    );
  }

  /// Removes the informed consent for the given [inputByParticipantRole] in
  /// this study deployment.
  /// If [inputByParticipantRole] is not specified, it is resolved by
  /// [getParticipantRoleName].
  Future<void> removeInformedConsent([String? inputByParticipantRole]) async {
    ParticipantData.fromJson(
      await _rpc(
            SetParticipantData(studyDeploymentId, {
              InputType.INFORMED_CONSENT: null,
            }, getParticipantRoleName(inputByParticipantRole)),
          )
          as Map<String, dynamic>,
    );
  }
}
