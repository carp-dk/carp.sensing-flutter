/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_services.dart';

/// Provides a reference to the deployment endpoint in a CARP web service that can
/// handle a specific [PrimaryDeviceDeployment].
///
/// According to CARP core, the protocol for using the
/// [deployment sub-system](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-deployment.md) is:
///
///   - [getStatus()] - get the study deployment status of this deployment.
///   - [registerDevice()] - register this device - and connected devices - in this deployment
///   - [get()] - get the deployment for this master device
///   - [deployed()] - report the deployment as deployed
///   - [unRegisterDevice()] - unregister this - or other - device if no longer used
class DeploymentReference extends RPCCarpReference {
  final String _studyDeploymentId;
  final String _deviceRoleName;
  PrimaryDeviceDeployment? _deployment;
  StudyDeploymentStatus? _status;

  DeploymentReference._(
    CarpDeploymentService service,
    this._studyDeploymentId,
    this._deviceRoleName,
  ) : super._(service);

  /// The CARP study deployment ID.
  String get studyDeploymentId => _studyDeploymentId;

  /// The role name of the primary device in this deployment.
  String get deviceRoleName => _deviceRoleName;

  /// The latest known deployment status for this master device fetched from CAWS.
  /// Returns `null` if status is not yet known.
  StudyDeploymentStatus? get status => _status;

  /// The deployment for this master device, once fetched from CAWS.
  /// Returns `null` if the deployment is not yet known.
  PrimaryDeviceDeployment? get deployment => _deployment;

  /// The URL for the deployment endpoint.
  ///
  /// {{PROTOCOL}}://{{SERVER_HOST}}:{{SERVER_PORT}}/api/deployment-service
  @override
  String get rpcEndpointUri =>
      "${service.app.uri.toString()}/api/deployment-service";

  String? _registeredDeviceId;

  /// A unique id for this device as registered at CARP.
  ///
  /// Uses the phone's unique hardware id, if available.
  /// Otherwise uses a v4 UUID.
  String get registeredDeviceId =>
      _registeredDeviceId ??= DeviceInfoService().deviceID ?? const Uuid().v1;

  /// Refresh the deployment status for this [DeploymentReference] from CAWS.
  Future<StudyDeploymentStatus> getStatus() async =>
      _status = StudyDeploymentStatus.fromJson(
        await _rpc(GetStudyDeploymentStatus(studyDeploymentId))
            as Map<String, dynamic>,
      );

  /// Register this device with [deviceRoleName] with [registration] for this
  /// deployment at the CARP server.
  /// If [registration] is `null`, a default registration will be created
  ///
  /// Returns the updated study deployment status if the registration is successful.
  /// Throws a [CarpServiceException] if not.
  Future<StudyDeploymentStatus> registerDevice([
    DeviceRegistration? registration,
  ]) async {
    assert(
      deviceRoleName.isNotEmpty,
      'deviceRoleName has to be specified when registering a device in CARP.',
    );

    registration ??= DefaultDeviceRegistration(
      deviceId: DeviceInfoService().deviceID,
      deviceDisplayName: DeviceInfoService().toString(),
    );

    return _status = StudyDeploymentStatus.fromJson(
      await _rpc(
            RegisterDevice(studyDeploymentId, deviceRoleName, registration),
          )
          as Map<String, dynamic>,
    );
  }

  /// Unregister [deviceRoleName] for this deployment at the CARP server.
  ///
  /// Returns the updated study deployment status if the registration is successful.
  /// Throws a [CarpServiceException] if not.
  Future<StudyDeploymentStatus> unRegisterDevice() async =>
      _status = StudyDeploymentStatus.fromJson(
        await _rpc(UnregisterDevice(studyDeploymentId, deviceRoleName))
            as Map<String, dynamic>,
      );

  /// Get the deployment for this [DeploymentReference] for the specified
  /// [studyDeploymentId].
  Future<SmartphoneDeployment> get() async {
    if (status == null) await getStatus();

    // downloading a PrimaryDeviceDeployment
    var downloaded = PrimaryDeviceDeployment.fromJson(
      await _rpc(GetDeviceDeploymentFor(studyDeploymentId, deviceRoleName))
          as Map<String, dynamic>,
    );

    // converting it to a SmartphoneDeployment and saving it
    return _deployment = SmartphoneDeployment.fromPrimaryDeviceDeployment(
      studyDeploymentId: studyDeploymentId,
      deployment: downloaded,
    );
  }

  /// Mark this deployment as a deployed on the server.
  ///
  /// Returns the updated study deployment status if successful.
  /// Throws a [CarpServiceException] if not.
  Future<StudyDeploymentStatus> deployed() async {
    assert(
      deployment != null,
      'The deployment needs to be fetched before marking it as deployed. '
      'Use the get() method to get the primary device deployment.',
    );

    return _status = StudyDeploymentStatus.fromJson(
      await _rpc(
            DeviceDeployed(
              studyDeploymentId,
              deviceRoleName,
              deployment!.lastUpdatedOn,
            ),
          )
          as Map<String, dynamic>,
    );
  }
}
