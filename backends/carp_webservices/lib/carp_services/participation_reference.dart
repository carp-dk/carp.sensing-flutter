/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// Provide a participation endpoint reference to a CARP web service.
///
/// According to CARP core, the protocol for using the
/// [deployment sub-system](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-deployment.md) is:
///
///   - [getParticipantData()] - get participation data from this deployment.
///   - [setParticipantData()] - set participation data in this deployment.
///
/// Also contains convenient methods for setting, getting, and deleting an
/// informed consent document as participant data.
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

  /// Resolve role name of a participant.
  ///
  /// Returns [roleName] if not null. Otherwise returns the role name
  /// specified in the [service]'s [deployment], if available.
  /// Throws an error if the role name cannot be resolved.
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

  /// Get currently set data for all expected participant data in this study
  /// deployment with [studyDeploymentId].
  /// Data which is not set equals null.
  Future<ParticipantData> getParticipantData() async =>
      ParticipantData.fromJson(
        await _rpc(GetParticipantData(studyDeploymentId))
            as Map<String, dynamic>,
      );

  /// Set participant [data] for the given [inputByParticipantRole] in this
  /// study deployment.
  /// If [inputByParticipantRole] is null, all roles can set it.
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

  /// Get informed consent data for all participants (by role name) in this study
  /// deployment with [studyDeploymentId].
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

  /// Get the informed consent uploaded by a participant with [roleName] in
  /// this study deployment with [studyDeploymentId].
  ///
  /// If [roleName] is not specified, the role of the participant
  /// in the current [deployment] is used.
  ///
  /// Returns null if not available.
  Future<InformedConsentInput?> getInformedConsentByRole([
    String? roleName,
  ]) async => (await getInformedConsent())[getParticipantRoleName(roleName)];

  /// Set informed [consent] for the given [inputByParticipantRole] in this
  /// study deployment.
  /// If [inputByParticipantRole] is not specified, the role of the participant
  /// in the current [deployment] is used.
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

  /// Remove the informed for the given [inputByParticipantRole] in this
  /// study deployment.
  /// If [inputByParticipantRole] is not specified, the role of the participant
  /// in the current [deployment] is used.
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
