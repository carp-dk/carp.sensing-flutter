/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A CARP Core [DeploymentService] that talks to CAWS.
///
/// A participant app uses it to register the phone as the primary device of a
/// study deployment, download the [SmartphoneDeployment] that says what to
/// measure, and report it as deployed. Researcher tools can also create
/// study deployments from a protocol.
///
/// Key points:
///  * A singleton; call [configure] (or [configureFrom]) before use.
///  * [deployment] returns a [DeploymentReference] that remembers the study
///    deployment and device role, and is the easier way to run the steps above.
///  * Removing deployments is not supported from the client and throws a
///    [CarpServiceException].
///
/// The study deployment ID usually comes from an invitation found by
/// [CarpParticipationService]. The downloaded deployment is run by the
/// CARP Mobile Sensing runtime.
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

  /// Creates a study deployment for a given [protocol] with participants
  /// defined in [invitations].
  ///
  /// The identities specified in the invitations are used to invite and
  /// authenticate the participants.
  /// In case no account is associated to an identity, a new account is created for it.
  /// An invitation (and account details) is delivered to the person managing
  /// the identity, or should be handed out manually to the relevant participant
  /// by the person managing the identity.
  ///
  /// Note that [id] is currently not sent to CAWS, which assigns the
  /// deployment ID itself.
  ///
  /// CAWS throws IllegalArgumentException when:
  ///  - [protocol] is invalid
  ///  - [invitations] is empty
  ///  - any of the assigned device roles in [invitations] is not part of the
  ///    study [protocol]
  ///  - not all necessary primary devices part of the study [protocol] have
  ///    been assigned a participant
  ///
  /// Returns the [StudyDeploymentStatus] of the newly created study deployment.
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

  /// Not supported from the client side; always throws a
  /// [CarpServiceException].
  @override
  Future<Set<String>> removeStudyDeployments(Set<String> studyDeploymentIds) =>
      throw CarpServiceException(
        'Removing study deployments is not supported from the client side.',
      );

  /// Gets the status for a study deployment with the given [studyDeploymentId].
  ///
  /// CAWS throws IllegalArgumentException when a deployment with [studyDeploymentId]
  /// does not exist.
  @override
  Future<StudyDeploymentStatus> getStudyDeploymentStatus(
    String studyDeploymentId,
  ) async => StudyDeploymentStatus.fromJson(
    await _rpc(GetStudyDeploymentStatus(studyDeploymentId))
        as Map<String, dynamic>,
  );

  /// Gets the status for a set of deployments with the specified [studyDeploymentIds].
  /// If [studyDeploymentIds] is empty, an empty list is returned.
  ///
  /// CAWS throws IllegalArgumentException when [studyDeploymentIds] contains an
  /// ID for which no deployment exists.
  @override
  Future<List<StudyDeploymentStatus>> getStudyDeploymentStatusList(
    List<String> studyDeploymentIds,
  ) async {
    // fast out if not ids specified
    if (studyDeploymentIds.isEmpty) return [];

    // we expect a list of JSON objects
    var items =
        await _rpc(GetStudyDeploymentStatusList(studyDeploymentIds))
            as List<dynamic>;

    final List<StudyDeploymentStatus> statusList = [];
    for (var item in items) {
      statusList.add(
        StudyDeploymentStatus.fromJson(item as Map<String, dynamic>),
      );
    }

    return statusList;
  }

  /// Registers the device with the specified [deviceRoleName] for the study
  /// deployment with [studyDeploymentId]. The [registration] contains a
  /// matching configuration for the device with [deviceRoleName].
  ///
  /// A [CamsDeviceRegistration] is sent as a [DefaultDeviceRegistration]
  /// (workaround for CAWS issue #561).
  ///
  /// CAWS throws IllegalArgumentException when:
  /// - a deployment with [studyDeploymentId] does not exist
  /// - [deviceRoleName] is not present in the deployment or is already registered
  ///   and a different [registration] is specified than a previous request
  /// - [registration] is invalid for the specified device or uses a device ID
  ///   which has already been used as part of registration of a different device
  ///
  /// CAWS throws IllegalStateException when this deployment has stopped.
  @override
  Future<StudyDeploymentStatus> registerDevice(
    String studyDeploymentId,
    String deviceRoleName,
    DeviceRegistration registration,
  ) async {
    // => StudyDeploymentStatus.fromJson( await _rpc(RegisterDevice(studyDeploymentId, deviceRoleName, registration))
    //     as Map<String, dynamic>,);

    // TODO - due to issue #561 in CAWS, we need to only use a [DefaultDeviceRegistration] for now.

    if (registration is CamsDeviceRegistration) {
      registration = registration.toDefaultDeviceRegistration();
    }

    return StudyDeploymentStatus.fromJson(
      await _rpc(
            RegisterDevice(studyDeploymentId, deviceRoleName, registration),
          )
          as Map<String, dynamic>,
    );
  }

  /// Unregisters the device with the specified [deviceRoleName] for the study
  /// deployment with [studyDeploymentId].
  ///
  /// CAWS throws IllegalArgumentException when:
  /// - a deployment with [studyDeploymentId] does not exist
  /// - [deviceRoleName] is not present in the deployment
  ///
  /// CAWS throws IllegalStateException when this deployment has stopped.
  @override
  Future<StudyDeploymentStatus> unregisterDevice(
    String studyDeploymentId,
    String deviceRoleName,
  ) async => StudyDeploymentStatus.fromJson(
    await _rpc(UnregisterDevice(studyDeploymentId, deviceRoleName))
        as Map<String, dynamic>,
  );

  /// Gets the deployment for the primary device with
  /// [primaryDeviceRoleName] in the study deployment with [studyDeploymentId].
  ///
  /// The [PrimaryDeviceDeployment] from CAWS is returned as a
  /// [SmartphoneDeployment].
  ///
  /// CAWS throws IllegalArgumentException when:
  /// - a deployment with [studyDeploymentId] does not exist
  /// - [primaryDeviceRoleName] is not present in the deployment
  /// - the device with [primaryDeviceRoleName] has not yet been registered
  ///
  /// CAWS throws IllegalStateException when the deployment for the requested
  /// primary device is not yet available.
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

    // converting it to a SmartphoneDeployment
    return SmartphoneDeployment.fromPrimaryDeviceDeployment(
      studyDeploymentId: studyDeploymentId,
      deployment: deployment,
    );
  }

  /// Tells stakeholders in the study deployment with [studyDeploymentId]
  /// that the device with [primaryDeviceRoleName] was deployed successfully,
  /// using the device deployment with timestamp [deviceDeploymentLastUpdatedOn],
  /// i.e., that the study deployment was loaded on the device and that the necessary
  /// runtime is available to run it.
  ///
  /// CAWS throws IllegalArgumentException when:
  /// - a deployment with [studyDeploymentId] does not exist
  /// - [primaryDeviceRoleName] is not present in the deployment
  /// - the [deviceDeploymentLastUpdatedOn] does not match the expected timestamp
  ///   of the deployment, indicating that the deployment on the device is outdated
  ///   and needs to be updated before it can be deployed.
  ///
  /// CAWS throws IllegalStateException when the deployment cannot be deployed yet,
  /// or the deployment has stopped.
  @override
  Future<StudyDeploymentStatus> deviceDeployed(
    String studyDeploymentId,
    String primaryDeviceRoleName,
    DateTime deviceDeploymentLastUpdatedOn,
  ) async {
    return StudyDeploymentStatus.fromJson(
      await _rpc(
            DeviceDeployed(
              studyDeploymentId,
              primaryDeviceRoleName,
              deviceDeploymentLastUpdatedOn,
            ),
          )
          as Map<String, dynamic>,
    );
  }

  /// Asks CAWS to stop the study deployment with the specified
  /// [studyDeploymentId] and returns its updated status. This call does not
  /// itself stop data collection in the local sensing runtime.
  ///
  /// CAWS throws IllegalArgumentException when a deployment with
  /// [studyDeploymentId] does not exist.
  @override
  Future<StudyDeploymentStatus> stop(String studyDeploymentId) async =>
      StudyDeploymentStatus.fromJson(
        await _rpc(Stop(studyDeploymentId)) as Map<String, dynamic>,
      );
}
