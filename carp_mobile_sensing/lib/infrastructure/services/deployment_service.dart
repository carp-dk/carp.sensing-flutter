/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// A local (in-memory) implementation of a [DeploymentService] useful in
/// CAMS studies to be deployed locally on this phone.
class SmartphoneDeploymentService implements DeploymentService {
  // key = studyDeploymentId
  final Map<String, StudyDeployment> _repository = {};

  static final SmartphoneDeploymentService _instance =
      SmartphoneDeploymentService._();
  SmartphoneDeploymentService._();

  /// Get the singleton [SmartphoneDeploymentService].
  factory SmartphoneDeploymentService() => _instance;

  /// The device description for this phone.
  Smartphone thisPhone = Smartphone();

  @override
  Future<StudyDeploymentStatus> createStudyDeployment(
    StudyProtocol protocol, [
    List<ParticipantInvitation> invitations = const [],
    String? id,
    Map<String, DeviceRegistration>? connectedDevicePreregistrations,
  ]) async {
    assert(
      protocol is SmartphoneStudyProtocol,
      "$runtimeType only supports the deployment of protocols of type 'SmartphoneStudyProtocol'",
    );

    StudyDeployment deployment = StudyDeployment(protocol, id);
    _repository[deployment.studyDeploymentId] = deployment;

    // always register this phone as a primary device
    deployment.registerDevice(thisPhone, thisPhone.createRegistration());

    // set the deployment status to "invited" as the initial status.
    deployment.status.status = StudyDeploymentStatusTypes.Invited;

    return deployment.status;
  }

  @override
  Future<Set<String>> removeStudyDeployments(
    Set<String> studyDeploymentIds,
  ) async {
    Set<String> removedKeys = {};
    for (var key in studyDeploymentIds) {
      if (_repository.containsKey(key)) {
        _repository.remove(key);
        removedKeys.add(key);
      }
    }
    return removedKeys;
  }

  @override
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus(
    String studyDeploymentId,
  ) async => _repository[studyDeploymentId]?.status;

  @override
  Future<List<StudyDeploymentStatus?>> getStudyDeploymentStatusList(
    List<String> studyDeploymentIds,
  ) async => studyDeploymentIds.map((id) => _repository[id]?.status).toList();

  @override
  Future<StudyDeploymentStatus?> registerDevice(
    String studyDeploymentId,
    String deviceRoleName,
    DeviceRegistration registration,
  ) async {
    if (_repository[studyDeploymentId] == null) return null;

    StudyDeployment deployment = _repository[studyDeploymentId]!;

    // check if already registered - if not register device
    DeviceConfiguration device = deployment.registeredDevices.keys.firstWhere(
      (configuration) => configuration.roleName == deviceRoleName,
      orElse: () => DeviceConfiguration(roleName: deviceRoleName),
    );

    deployment.registerDevice(device, registration);

    return deployment.status;
  }

  @override
  Future<StudyDeploymentStatus?> unregisterDevice(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    if (_repository[studyDeploymentId] == null) return null;
    StudyDeployment deployment = _repository[studyDeploymentId]!;
    DeviceConfiguration device = deployment.registeredDevices.keys.firstWhere(
      (configuration) => configuration.roleName == deviceRoleName,
    );

    deployment.unregisterDevice(device);

    return deployment.status;
  }

  @override
  Future<SmartphoneDeployment?> getDeviceDeploymentFor(
    String studyDeploymentId,
    String primaryDeviceRoleName,
  ) async {
    if (_repository[studyDeploymentId] == null) return null;

    StudyDeployment deployment = _repository[studyDeploymentId]!;
    DeviceConfiguration device = deployment.registeredDevices.keys.firstWhere(
      (configuration) => configuration.roleName == primaryDeviceRoleName,
    );

    assert(
      device is PrimaryDeviceConfiguration,
      "The specified '$primaryDeviceRoleName' device is not registered as a primary device",
    );

    PrimaryDeviceDeployment deviceDeployment = deployment
        .getDeviceDeploymentFor(device as PrimaryDeviceConfiguration);

    return SmartphoneDeployment.fromPrimaryDeviceDeploymentAndSmartphoneStudyProtocol(
      studyDeploymentId: studyDeploymentId,
      deployment: deviceDeployment,
      protocol: deployment.protocol as SmartphoneStudyProtocol,
    );
  }

  /// Get a smartphone deployment configuration for [studyDeploymentId] for
  /// this phone.
  Future<SmartphoneDeployment?> getDeviceDeployment(
    String studyDeploymentId,
  ) async =>
      await getDeviceDeploymentFor(studyDeploymentId, thisPhone.roleName);

  @override
  Future<StudyDeploymentStatus?> deviceDeployed(
    String studyDeploymentId,
    String primaryDeviceRoleName,
    DateTime? deviceDeploymentLastUpdatedOn,
  ) async {
    if (_repository[studyDeploymentId] == null) return null;

    deviceDeploymentLastUpdatedOn ??= DateTime.now();
    StudyDeployment deployment = _repository[studyDeploymentId]!;
    DeviceConfiguration device = deployment.registeredDevices.keys.firstWhere(
      (configuration) => configuration.roleName == primaryDeviceRoleName,
    );

    if (device is! PrimaryDeviceConfiguration) {
      warning(
        "The specified device with role name '$primaryDeviceRoleName' is not a primary device.",
      );
      return null;
    }
    deployment.deviceDeployed(device, deviceDeploymentLastUpdatedOn);

    return deployment.status;
  }

  /// Mark the study deployment with [studyDeploymentId] as deployed successfully
  /// to this primary device (phone), i.e., that the study deployment was loaded
  /// on the device and that the necessary runtime is available to run it.
  Future<StudyDeploymentStatus?> deployed(
    String studyDeploymentId, {
    DateTime? deviceDeploymentLastUpdateDate,
  }) async => deviceDeployed(
    studyDeploymentId,
    thisPhone.roleName,
    deviceDeploymentLastUpdateDate,
  );

  /// Stop the study deployment with [studyDeploymentId].
  @override
  Future<StudyDeploymentStatus?> stop(String studyDeploymentId) async {
    if (_repository[studyDeploymentId] == null) return null;

    StudyDeployment deployment = _repository[studyDeploymentId]!;
    deployment.stop();
    return deployment.status;
  }

  @override
  String toString() => runtimeType.toString();
}
