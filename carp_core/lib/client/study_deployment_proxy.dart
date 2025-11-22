/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../client.dart';

/// Perform deployment actions for a [Study] on a client device.
class StudyDeploymentProxy {
  final DeploymentService deploymentService;

  StudyDeploymentProxy(this.deploymentService);

  /// Get the deployment status for the [study] from the deployment service.
  /// This updates the [deploymentStatus] and sets the study [status] accordingly.
  ///
  /// Returns null if the deployment status could not be retrieved from the
  /// deployment service.
  Future<StudyDeploymentStatus?> getStudyDeploymentStatus(Study study) async {
    StudyDeploymentStatus? deploymentStatus;
    // try to get the deployment status from the deployment service
    try {
      deploymentStatus = await deploymentService.getStudyDeploymentStatus(
        study.studyDeploymentId,
      );
    } catch (error) {
      study.deploymentError(
        "$runtimeType - Could not get deployment status with id '${study.studyDeploymentId}' "
        "from the deployment service: $deploymentService."
        "\nError: $error",
      );
      deploymentStatus = null;
    }

    // Update study with new deployment status.
    if (deploymentStatus != null) {
      study.deploymentStatusReceived(deploymentStatus);
    }

    return deploymentStatus;
  }

  /// Tries to deploy the [study] if it's ready to be deployed by registering
  /// the client device using [deviceRegistration] and verifying the study is
  /// ready for deployment on this device.
  /// In case already deployed, nothing happens.
  ///
  /// Throws [IllegalArgumentException] if:
  /// - a deployment with study deployment ID matching this [study] does not exist
  /// - device role name of [study] is not present in the deployment
  ///   or is already registered and a different [deviceRegistration] is specified
  /// - [deviceRegistration] of this client is invalid for the expected device role name
  ///   or has a device ID which is already in use by the registration of a different device.
  Future<void> tryDeployment(
    Study study,
    DeviceRegistration deviceRegistration,
  ) async {
    final studyDeploymentId = study.studyDeploymentId;
    final deviceRoleName = study.deviceRoleName;
    StudyDeploymentStatus? deploymentStatus;

    // Register the client device in the study deployment.
    try {
      deploymentStatus = await deploymentService.registerDevice(
        studyDeploymentId,
        deviceRoleName,
        deviceRegistration,
      );
    } catch (error) {
      // Note that this device may already be registered which will throw an
      // exception from the deployment service. But, this should not prevent
      // getting the deployment.
      study.deploymentError(
        "$runtimeType - Error registering '${study.deviceRoleName}' as primary device.\n$error",
      );
      deploymentStatus = null;
    }

    // If we didn't get a deployment status from registration, try to get it directly.
    deploymentStatus ??= await getStudyDeploymentStatus(study);

    // If we still don't have a deployment status, mark this as an error and exit.
    if (deploymentStatus == null) {
      study.deploymentError(
        "No study deployment with ID '$studyDeploymentId' found when trying to register device "
        "with role name '$deviceRoleName'.",
      );
      return;
    }

    // Update study with new deployment status.
    study.deploymentStatusReceived(deploymentStatus);
    final studyStatus = deploymentStatus;
    final deviceStatus = studyStatus.getDeviceStatusByRoleName(deviceRoleName);

    // The following statement is from CARP Core Kotlin.
    // However, this has been removed here in order to allow for re-deployment,
    // i.e., cases where we want to refresh the deployment information from the
    // deployment service.
    // // Early out in case state indicates the device is already deployed.
    // if (deviceStatus.status == DeviceDeploymentStatusTypes.Deployed) return;

    // Early out in case state indicates that deployment cannot yet be obtained.
    if (!deviceStatus.canObtainDeviceDeployment) return;

    // Get deployment information.
    final device = deviceStatus.device;
    PrimaryDeviceDeployment? deployment;
    try {
      deployment = await deploymentService.getDeviceDeploymentFor(
        studyDeploymentId,
        deviceRoleName,
      );
    } catch (error) {
      study.deploymentError(
        "$runtimeType - Error getting deployment information.\n$error",
      );
      deploymentStatus = null;
    }

    if (deployment == null) {
      study.deploymentError(
        "$runtimeType - Deployment for device role name '$deviceRoleName' "
        "in study deployment '$studyDeploymentId' is not available.",
      );
      return;
    }

    if (deployment.deviceConfiguration.roleName != deviceRoleName) {
      study.deploymentError(
        "The device role name of the deployment is '${deployment.deviceConfiguration.roleName}', "
        "which does not match the requested device role name '$deviceRoleName'.",
      );
      return;
    }

    // notify the study that the deployment has been received
    study.deviceDeploymentReceived(deployment);

    final remainingDevicesToRegister = studyStatus.deviceStatusList
        .map((status) => status.device)
        .where(
          (it) =>
              (deviceStatus.remainingDevicesToRegisterBeforeDeployment ?? [])
                  .contains(it.roleName),
        )
        .toSet();

    // Stop here in case devices need to be registered before being able to complete deployment.
    if (remainingDevicesToRegister.isNotEmpty) return;

    // Notify deployment service of successful deployment.
    try {
      final deployedStatus = await deploymentService.deviceDeployed(
        studyDeploymentId,
        device.roleName,
        deployment.lastUpdatedOn,
      );
      if (deployedStatus != null) {
        study.deploymentStatusReceived(deployedStatus);
      }
    } catch (error) {
      // we only print a warning
      // see issue #50 - there is a bug in CAWS
      print(
        "$runtimeType - Error marking deployment '$studyDeploymentId' as deployed.\n$error",
      );
    }
  }

  /// Permanently stop this [study].
  ///
  /// Note that will mark the study as stopped in the deployment service.
  /// Once stopped, a study cannot be restarted.
  @mustCallSuper
  Future<void> stop(Study study) async {
    // Early out in case study has already been stopped.
    if (study.deploymentStatus?.status == StudyDeploymentStatusTypes.Stopped) {
      return;
    }

    try {
      final deploymentStatus = (await deploymentService.stop(
        study.studyDeploymentId,
      ));
      if (deploymentStatus != null) {
        study.deploymentStatusReceived(deploymentStatus);
      }
    } catch (error) {
      print(
        "$runtimeType - failed to stop study for study deployment '${study.studyDeploymentId}' "
        "at deployment service '$deploymentService'.\n"
        "Stopping the study locally only.\n"
        "Error: $error",
      );
    }
  }
}
