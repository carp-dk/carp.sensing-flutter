/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_services.dart';

/// A reference to one primary device in a study deployment in CAWS.
///
/// Obtained from [CarpDeploymentService.deployment]. It remembers the study
/// deployment ID, the device role name, and the latest [status] and
/// [deployment] it fetched. Following the CARP Core
/// [deployment sub-system](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-deployments.md),
/// a client calls, in order:
///
///   - [getStatus] - get the study deployment status of this deployment.
///   - [registerDevice] - register this device in this deployment.
///   - [get] - get the deployment for this primary device.
///   - [deployed] - report the deployment as deployed.
///   - [unRegisterDevice] - unregister this device if no longer used.
///
/// ```dart
/// final reference = CarpDeploymentService().deployment(studyDeploymentId);
/// await reference.registerDevice();
/// final deployment = await reference.get();
/// await reference.deployed();
/// ```
class DeploymentReference extends RPCCarpReference {
  final String _studyDeploymentId;
  final String _deviceRoleName;
  PrimaryDeviceDeployment? _deployment;
  StudyDeploymentStatus? _status;

  DeploymentReference._(CarpDeploymentService service, this._studyDeploymentId, this._deviceRoleName)
    : super._(service);

  /// The CARP study deployment ID.
  String get studyDeploymentId => _studyDeploymentId;

  /// The role name of the primary device in this deployment.
  String get deviceRoleName => _deviceRoleName;

  /// The latest known deployment status for this primary device fetched from CAWS.
  /// Returns `null` if status is not yet known.
  StudyDeploymentStatus? get status => _status;

  /// The deployment for this primary device, once fetched by [get].
  /// Returns `null` if the deployment is not yet known.
  PrimaryDeviceDeployment? get deployment => _deployment;

  /// The URL for the deployment endpoint.
  ///
  /// {{PROTOCOL}}://{{SERVER_HOST}}:{{SERVER_PORT}}/api/deployment-service
  @override
  String get rpcEndpointUri => "${service.app.uri.toString()}/api/deployment-service";

  /// Fetches the deployment status from CAWS and stores it in [status].
  Future<StudyDeploymentStatus> getStatus() async => _status = StudyDeploymentStatus.fromJson(
    await _rpc(GetStudyDeploymentStatus(studyDeploymentId)) as Map<String, dynamic>,
  );

  /// Registers this device as [deviceRoleName] with [registration] for this
  /// deployment in CAWS.
  ///
  /// If [registration] is `null`, a [DefaultDeviceRegistration] with a random
  /// device ID is used.
  ///
  /// Returns the updated study deployment status if the registration is successful.
  /// Throws a [CarpServiceException] if not.
  Future<StudyDeploymentStatus> registerDevice([DeviceRegistration? registration]) async {
    assert(deviceRoleName.isNotEmpty, 'deviceRoleName has to be specified when registering a device in CARP.');

    return _status = await CarpDeploymentService().registerDevice(
      studyDeploymentId,
      deviceRoleName,
      registration ?? DefaultDeviceRegistration(),
    );
  }

  /// Unregisters [deviceRoleName] for this deployment in CAWS.
  ///
  /// Returns the updated study deployment status if successful.
  /// Throws a [CarpServiceException] if not.
  Future<StudyDeploymentStatus> unRegisterDevice() async => _status = StudyDeploymentStatus.fromJson(
    await _rpc(UnregisterDevice(studyDeploymentId, deviceRoleName)) as Map<String, dynamic>,
  );

  /// Downloads the deployment for this primary device and stores it in
  /// [deployment].
  ///
  /// Fetches [status] first if it is not yet known.
  Future<PrimaryDeviceDeployment> get() async {
    if (status == null) await getStatus();

    return _deployment = PrimaryDeviceDeployment.fromJson(
      await _rpc(GetDeviceDeploymentFor(studyDeploymentId, deviceRoleName)) as Map<String, dynamic>,
    );
  }

  /// Marks this deployment as deployed in CAWS.
  ///
  /// Call [get] first; the [deployment] timestamp is sent to CAWS.
  /// Returns the updated study deployment status if successful.
  /// Throws a [CarpServiceException] if not.
  Future<StudyDeploymentStatus> deployed() async {
    assert(
      deployment != null,
      'The deployment needs to be fetched before marking it as deployed. '
      'Use the get() method to get the primary device deployment.',
    );

    return _status = StudyDeploymentStatus.fromJson(
      await _rpc(DeviceDeployed(studyDeploymentId, deviceRoleName, deployment!.lastUpdatedOn)) as Map<String, dynamic>,
    );
  }
}
