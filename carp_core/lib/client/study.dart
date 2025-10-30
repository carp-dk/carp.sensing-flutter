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
enum StudyStatus {
  /// The study deployment process hasn't been started yet.
  DeploymentNotStarted,

  /// Once a deployment for this study has started, and [StudyRuntime.status] is
  /// available, regardless of whether the deployment is now [Running] or [Stopped].
  DeploymentStatusAvailable,

  /// The study deployment process is ongoing, but not yet completed.
  Deploying,

  /// Deployment information for this primary device cannot be retrieved yet since
  /// other primary devices in the study deployment need to be registered first.
  AwaitingOtherDeviceRegistrations,

  /// The study deployment is ready to deliver the deployment information to
  /// this primary device.
  AwaitingDeviceDeployment,

  /// Deployment information has been received.
  DeviceDeploymentReceived,

  /// Deployment can complete after all devices have been registered.
  RegisteringDevices,

  /// Device deployment for this primary device has completed,
  /// but awaiting deployment of other devices in this study deployment.
  AwaitingOtherDeviceDeployments,

  /// Study runtime status when deployment has been successfully completed.
  /// The [PrimaryDeviceDeployment] has been retrieved and all necessary plugins
  /// to execute the study have been loaded.
  Deployed,

  /// The study is resumed and is sampling data.
  Running,

  /// The study has been stopped, either by this client or researcher.
  Stopped,

  /// The study deployment is not available.
  DeploymentNotAvailable,
}
