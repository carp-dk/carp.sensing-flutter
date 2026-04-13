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
  /// This updates the [Study.deploymentStatus] and sets the study [Study.status]
  /// accordingly.
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
  /// the client device using [registration] and verifying the study is
  /// ready for deployment on this device.
  /// In case already deployed, nothing happens.
  ///
  /// Throws [IllegalArgumentException] if:
  /// - a deployment with study deployment ID matching this [study] does not exist
  /// - device role name of [study] is not present in the deployment
  ///   or is already registered and a different [registration] is specified
  /// - [registration] of this client is invalid for the expected device role name
  ///   or has a device ID which is already in use by the registration of a different device.
  Future<void> tryDeployment(
    Study study,
    DeviceRegistration registration,
  ) async {
    final studyDeploymentId = study.studyDeploymentId;
    final deviceRoleName = study.deviceRoleName;
    StudyDeploymentStatus? deploymentStatus;

    // Register the this primary device in the deployment service for this
    // study deployment.
    try {
      deploymentStatus = await deploymentService.registerDevice(
        studyDeploymentId,
        deviceRoleName,
        registration,
      );
    } catch (error) {
      // Note that this device may already be registered, .e.g., in case of app
      // restart or reinstallation. This will throw an exception from the deployment
      // service. But, this should not prevent getting the deployment.
      print(
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

    final deviceStatus = deploymentStatus.getDeviceStatusByRoleName(
      deviceRoleName,
    );

    // The following statement is from CARP Core Kotlin.
    // However, this has been removed here in order to allow for re-deployment,
    // i.e., cases where we want to refresh the deployment information from the
    // deployment service. This is needed on app restart and app reinstallation,
    // where the device might already be registered but the deployment information is lost.
    //
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
      // deploymentStatus = null;
      return;
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

    // Notify the study that the deployment has been received
    study.deviceDeploymentReceived(deployment);

    final remainingDevicesToRegister = deploymentStatus.deviceStatusList
        .map((status) => status.device)
        .where(
          (it) =>
              (deviceStatus.remainingDevicesToRegisterBeforeDeployment ?? [])
                  .contains(it.roleName),
        )
        .toSet();

    // Stop here in case other devices need to be registered before being able to complete deployment.
    if (remainingDevicesToRegister.isNotEmpty) return;

    // Notify deployment service of successful deployment.
    try {
      final deployedStatus = await deploymentService.deviceDeployed(
        studyDeploymentId,
        device.roleName,
        deployment.lastUpdatedOn,
      );

      // Update study with new deployment status and deployment information.
      if (deployedStatus != null) {
        study.deploymentStatusReceived(deployedStatus);
        study.deploymentUpdated(
          "$runtimeType - Deployment '$studyDeploymentId' marked as deployed - status: ${deployedStatus.status?.name}",
        );
      }
    } catch (error) {
      // we only print a warning - there is a bug in CAWS - see issue #561
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
      final deploymentStatus = await deploymentService.stop(
        study.studyDeploymentId,
      );
      if (deploymentStatus != null) {
        study.deploymentStatusReceived(deploymentStatus);
      }
    } catch (error) {
      print(
        "$runtimeType - failed to stop study for study deployment '${study.studyDeploymentId}' "
        "at deployment service '$deploymentService'.\n"
        "Error: $error",
      );
    }
  }
}
