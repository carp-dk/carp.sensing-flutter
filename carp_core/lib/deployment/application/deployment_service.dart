/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../deployment.dart';

/// Application service which allows deploying study protocols to participants
/// and retrieving [PrimaryDeviceDeployment]'s for participating primary devices
/// as defined in the protocol.
abstract class DeploymentService {
  static const String API_VERSION = "1.1";

  /// Instantiate a study deployment for a given [StudyProtocol] with participants
  /// defined in [invitations].
  ///
  /// The identities specified in the invitations are used to invite and authenticate
  /// the participants. In case no account is associated to an identity, a new
  /// account is created for it.
  /// An invitation (and account details) is delivered to the person managing
  /// the identity, or should be handed out manually to the relevant participant
  /// by the person managing the identity.
  ///
  /// [id] specifies the study deployment id. If not specified, an UUID v1 id
  /// is generated.
  /// [connectedDevicePreregistrations] lists optional pre-registrations for
  /// connected devices in the study [protocol].
  Future<StudyDeploymentStatus> createStudyDeployment(
    StudyProtocol protocol, [
    List<ParticipantInvitation> invitations = const [],
    String? id,
    Map<String, DeviceRegistration>? connectedDevicePreregistrations,
  ]);

  /// Remove study deployments with the given [studyDeploymentIds].
  /// This also removes all data related to the study deployments.
  ///
  /// Returns the IDs of study deployments which were removed (empty set
  /// if none were removed).
  /// IDs for which no study deployment exists are ignored.
  Future<Set<String>> removeStudyDeployments(Set<String> studyDeploymentIds);

  /// Get the status for a study deployment with the given [studyDeploymentId].
  /// Returns null if [studyDeploymentId] is not found.
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus(
    String studyDeploymentId,
  );

  /// Get the statuses for a set of deployments with the specified [studyDeploymentIds].
  /// Returns null for IDs in [studyDeploymentIds] for which no deployment exists.
  Future<List<StudyDeploymentStatus?>> getStudyDeploymentStatusList(
    List<String> studyDeploymentIds,
  );

  /// Register the device with the specified [deviceRoleName] for the study
  /// deployment with [studyDeploymentId].
  ///
  /// [registration] is a matching configuration for the device with [deviceRoleName].
  /// Returns null if [studyDeploymentId] is not found.
  Future<StudyDeploymentStatus?> registerDevice(
    String studyDeploymentId,
    String deviceRoleName,
    DeviceRegistration registration,
  );

  /// Unregister the device with the specified [deviceRoleName] for the study
  /// deployment with [studyDeploymentId].
  /// Returns null if [studyDeploymentId] is not found.
  Future<StudyDeploymentStatus?> unregisterDevice(
    String studyDeploymentId,
    String deviceRoleName,
  );

  /// Get the deployment configuration for the primary device with
  /// [primaryDeviceRoleName] in the study deployment with [studyDeploymentId].
  /// Returns null if [studyDeploymentId] is not found.
  Future<PrimaryDeviceDeployment?> getDeviceDeploymentFor(
    String studyDeploymentId,
    String primaryDeviceRoleName,
  );

  /// Indicate to stakeholders in the study deployment with [studyDeploymentId]
  /// that the device with [primaryDeviceRoleName] was deployed successfully,
  /// using the deployment with the specified [deviceDeploymentLastUpdatedOn],
  /// i.e., that the study deployment was loaded on the device and that the
  /// necessary runtime is available to run it.
  ///
  /// Returns null when:
  ///
  ///  - a deployment with [studyDeploymentId] does not exist
  ///  - [primaryDeviceRoleName] is not present in the deployment
  ///  - the [deviceDeploymentLastUpdatedOn] does not match the expected date.
  ///    The deployment might be outdated.
  ///  - the deployment cannot be deployed yet, or the deployment has stopped.
  Future<StudyDeploymentStatus?> deviceDeployed(
    String studyDeploymentId,
    String primaryDeviceRoleName,
    DateTime deviceDeploymentLastUpdatedOn,
  );

  /// Permanently stop the study deployment with the specified [studyDeploymentId].
  ///
  /// No further changes to this deployment will be allowed and no more data
  /// can be collected and uploaded to a [DataStreamService].
  /// Returns null if [studyDeploymentId] is not found.
  Future<StudyDeploymentStatus?> stop(String studyDeploymentId);
}
