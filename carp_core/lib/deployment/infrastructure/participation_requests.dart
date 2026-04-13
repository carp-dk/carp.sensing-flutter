/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../deployment.dart';

// -----------------------------------------------------
// Participation Service Requests
// See https://github.com/carp-dk/carp.core-kotlin/blob/develop/carp.deployment.core/src/commonMain/kotlin/dk/cachet/carp/deployment/infrastructure/ParticipationServiceRequest.kt
// -----------------------------------------------------

/// A [ParticipationServiceRequest] and its sub-classes contain the data for
/// sending a participant request to the CARP web service.
///
/// All participant requests to the CARP Service is defined in
/// [carp.core-kotlin](https://github.com/carp-dk/carp.core-kotlin/blob/develop/carp.deployment.core/src/commonMain/kotlin/dk/cachet/carp/deployment/infrastructure/ParticipationServiceRequest.kt)
abstract class ParticipationServiceRequest extends DeploymentServiceRequest {
  final String _serviceRequestPackageNamespace =
      'dk.cachet.carp.deployments.infrastructure.ParticipationServiceRequest';

  @override
  String get apiVersion => ParticipationService.API_VERSION;

  ParticipationServiceRequest([super.studyDeploymentId]);

  @override
  String get jsonType => '$_serviceRequestPackageNamespace.$runtimeType';
}

/// A request for getting the deployment invitations for an account id.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetActiveParticipationInvitations extends ParticipationServiceRequest {
  GetActiveParticipationInvitations(this.accountId) : super();

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  // ignore: overridden_fields
  String? studyDeploymentId;

  /// The CARP account (user) ID.
  String accountId;

  @override
  Function get fromJsonFunction => _$GetActiveParticipationInvitationsFromJson;
  factory GetActiveParticipationInvitations.fromJson(
    Map<String, dynamic> json,
  ) => FromJsonFactory().fromJson<GetActiveParticipationInvitations>(json);
  @override
  Map<String, dynamic> toJson() =>
      _$GetActiveParticipationInvitationsToJson(this);

  @override
  String toString() => '$runtimeType - accountId: $accountId';
}

/// A request for getting the status of a study deployment.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetParticipantData extends ParticipationServiceRequest {
  GetParticipantData(super.studyDeploymentId);

  @override
  Function get fromJsonFunction => _$GetParticipantDataFromJson;
  factory GetParticipantData.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GetParticipantData>(json);
  @override
  Map<String, dynamic> toJson() => _$GetParticipantDataToJson(this);
}

/// A request for getting the list of participant data for this a list
/// of [studyDeploymentIds].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetParticipantDataList extends ParticipationServiceRequest {
  List<String> studyDeploymentIds;
  GetParticipantDataList(this.studyDeploymentIds) : super();

  @override
  Function get fromJsonFunction => _$GetParticipantDataListFromJson;
  factory GetParticipantDataList.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GetParticipantDataList>(json);
  @override
  Map<String, dynamic> toJson() => _$GetParticipantDataListToJson(this);
}

/// A request for adding data for a participant.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SetParticipantData extends ParticipationServiceRequest {
  SetParticipantData(
    super.studyDeploymentId, [
    this.data,
    this.inputByParticipantRole,
  ]);

  /// The participant role who filled out [data]; null if all roles can set it.
  String? inputByParticipantRole;

  /// The data to be set.
  Map<String, Data?>? data;

  @override
  Function get fromJsonFunction => _$SetParticipantDataFromJson;
  factory SetParticipantData.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SetParticipantData>(json);
  @override
  Map<String, dynamic> toJson() => _$SetParticipantDataToJson(this);

  @override
  String toString() =>
      '${super.toString()}, inputByParticipantRole: $inputByParticipantRole';
}
