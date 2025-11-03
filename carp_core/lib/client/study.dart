/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_core_client.dart';

/// A study deployment, identified by [studyDeploymentId], which a client
/// device participates in with the role [deviceRoleName].
class Study {
  /// The ID of the deployed study for which to collect data.
  String studyDeploymentId;

  /// The role name of the device in the deployment this study runtime participates in.
  String deviceRoleName;

  /// The status of this study.
  StudyStatus status = StudyStatus.DeploymentNotStarted;

  Study(this.studyDeploymentId, this.deviceRoleName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Study &&
          runtimeType == other.runtimeType &&
          studyDeploymentId == other.studyDeploymentId &&
          deviceRoleName == other.deviceRoleName;

  @override
  int get hashCode => (studyDeploymentId + deviceRoleName).hashCode;

  @override
  String toString() =>
      '$runtimeType - studyDeploymentId: $studyDeploymentId, deviceRoleName: $deviceRoleName';
}

/// Describes the status of a [Study].
///
/// This is based on the [state diagram for Study State](https://github.com/carp-dk/carp.core-kotlin/blob/develop/docs/carp-clients.md#study-state)
/// However, all the "Deploying" states have been collapsed into a single
/// [Deploying] state.
///
/// If a study is in the [Deploying] state, the client can query the
/// [DeviceDeploymentStatus.remainingDevicesToRegisterToObtainDeployment] or the
/// [DeviceDeploymentStatus.remainingDevicesToRegisterBeforeDeployment]
/// of this device with [deviceRoleName] to understand what is holding the
/// deployment back.
enum StudyStatus {
  /// The study deployment process hasn't been started yet.
  DeploymentNotStarted,

  /// The study has been deployed in the deployment service and its status is
  /// available.
  DeploymentStatusAvailable,

  /// The study deployment is not available.
  DeploymentNotAvailable,

  /// The study deployment process is ongoing, but not yet completed.
  ///
  /// According to the [state diagram for Study State](https://github.com/carp-dk/carp.core-kotlin/blob/develop/docs/carp-clients.md#study-state),
  /// this state combines the following states:
  ///
  ///  * AwaitingOtherDeviceRegistrations - Deployment information for this
  ///    primary device cannot be retrieved yet since other primary devices in
  ///    the study deployment need to be registered first.
  ///  * AwaitingDeviceDeployment -  The deployment service is ready to deliver
  ///    the deployment information to this primary device.
  ///  * DeviceDeploymentReceived - Deployment information has been received.
  ///  * RegisteringDevices - Deployment can complete after all devices have been
  ///    registered.
  ///  * AwaitingOtherDeviceDeployments - Deployment for this primary device
  ///    has completed, but awaiting deployment of other devices in this study
  ///    deployment.
  Deploying,

  /// Deployment has been successfully completed.
  /// The [PrimaryDeviceDeployment] has been retrieved and ready to execute
  /// the study.
  Deployed,

  /// The study is started and is sampling data.
  Running,

  /// The study has been stopped, either from this client or via the deployment
  /// service.
  Stopped,
}
