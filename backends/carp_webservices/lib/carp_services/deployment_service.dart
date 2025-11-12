/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A [DeploymentService] that talks to the CARP Web Services.
class CarpDeploymentService extends CarpBaseService
    implements DeploymentService {
  static final CarpDeploymentService _instance = CarpDeploymentService._();

  CarpDeploymentService._();

  /// Singleton default instance of the [CarpDeploymentService].
  /// Before this instance can be used, it must be configured using the
  /// [configure] method.
  factory CarpDeploymentService() => _instance;

  @override
  String get rpcEndpointName => "deployment-service";

  /// Gets a [DeploymentReference] for a [studyDeploymentId] and [primaryDeviceRoleName].
  /// [studyDeploymentId] and [primaryDeviceRoleName] can be omitted if already
  /// specified as part of this service's [study].
  DeploymentReference deployment([
    String? studyDeploymentId,
    String? primaryDeviceRoleName,
  ]) => DeploymentReference._(
    this,
    getStudyDeploymentId(studyDeploymentId),
    getPrimaryDeviceRoleName(primaryDeviceRoleName),
  );

  @override
  Future<StudyDeploymentStatus> createStudyDeployment(
    StudyProtocol protocol, [
    List<ParticipantInvitation> invitations = const [],
    String? id,
    Map<String, DeviceRegistration>? connectedDevicePreregistrations,
  ]) async => StudyDeploymentStatus.fromJson(
    await _rpc(
          CreateStudyDeployment(
            protocol,
            invitations,
            connectedDevicePreregistrations,
          ),
        )
        as Map<String, dynamic>,
  );

  @override
  Future<Set<String>> removeStudyDeployments(Set<String> studyDeploymentIds) =>
      throw CarpServiceException(
        'Removing study deployments is not supported from the client side.',
      );

  @override
  Future<StudyDeploymentStatus> getStudyDeploymentStatus(
    String studyDeploymentId,
  ) async => StudyDeploymentStatus.fromJson(
    await _rpc(GetStudyDeploymentStatus(studyDeploymentId))
        as Map<String, dynamic>,
  );

  @override
  Future<List<StudyDeploymentStatus>> getStudyDeploymentStatusList(
    List<String> studyDeploymentIds,
  ) async {
    // fast out if not ids specified
    if (studyDeploymentIds.isEmpty) return [];

    Map<String, dynamic> responseJson =
        await _rpc(GetStudyDeploymentStatusList(studyDeploymentIds))
            as Map<String, dynamic>;

    // we expect a list of 'items'
    List<Map<String, dynamic>> items =
        json.decode(responseJson['items'].toString())
            as List<Map<String, dynamic>>;
    List<StudyDeploymentStatus> statusList = [];
    for (var item in items) {
      statusList.add(StudyDeploymentStatus.fromJson(item));
    }

    return statusList;
  }

  @override
  Future<StudyDeploymentStatus> registerDevice(
    String studyDeploymentId,
    String deviceRoleName,
    DeviceRegistration registration,
  ) async => StudyDeploymentStatus.fromJson(
    await _rpc(RegisterDevice(studyDeploymentId, deviceRoleName, registration))
        as Map<String, dynamic>,
  );

  @override
  Future<StudyDeploymentStatus> unregisterDevice(
    String studyDeploymentId,
    String deviceRoleName,
  ) async => StudyDeploymentStatus.fromJson(
    await _rpc(UnregisterDevice(studyDeploymentId, deviceRoleName))
        as Map<String, dynamic>,
  );

  @override
  Future<SmartphoneDeployment> getDeviceDeploymentFor(
    String studyDeploymentId,
    String primaryDeviceRoleName,
  ) async {
    // downloading a PrimaryDeviceDeployment
    var deployment = PrimaryDeviceDeployment.fromJson(
      await _rpc(
            GetDeviceDeploymentFor(studyDeploymentId, primaryDeviceRoleName),
          )
          as Map<String, dynamic>,
    );
    debug('$runtimeType - got deployment: $deployment');

    // converting it to a SmartphoneDeployment
    return SmartphoneDeployment.fromPrimaryDeviceDeployment(
      studyDeploymentId: studyDeploymentId,
      deployment: deployment,
    );
  }

  @override
  Future<StudyDeploymentStatus> deviceDeployed(
    String studyDeploymentId,
    String masterDeviceRoleName,
    DateTime deviceDeploymentLastUpdatedOn,
  ) async => StudyDeploymentStatus.fromJson(
    await _rpc(
          DeviceDeployed(
            studyDeploymentId,
            masterDeviceRoleName,
            deviceDeploymentLastUpdatedOn,
          ),
        )
        as Map<String, dynamic>,
  );

  @override
  Future<StudyDeploymentStatus> stop(String studyDeploymentId) async =>
      StudyDeploymentStatus.fromJson(
        await _rpc(Stop(studyDeploymentId)) as Map<String, dynamic>,
      );
}
