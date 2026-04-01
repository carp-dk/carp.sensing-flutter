/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../client.dart';

/// A study deployment, identified by [studyDeploymentId], which a client
/// device participates in with the role [deviceRoleName].
///
/// A study is a [ChangeNotifier] and updates to a study including its
/// [deploymentStatus], [status], and [deployment] can be listened to.
/// Moreover, the [events] stream emits a [StudyStatusEvent] event every
/// time the status of a study changes.
class Study<TDeviceDeployment extends PrimaryDeviceDeployment>
    with ChangeNotifier {
  final DateTime _createdOn;
  final String _studyDeploymentId;
  final String _deviceRoleName;
  StudyDeploymentStatus? _deploymentStatus;
  TDeviceDeployment? _deployment;
  final StreamController<StudyStatusEvent> _eventController =
      StreamController<StudyStatusEvent>.broadcast();

  /// Create a study uniquely identified by its [studyDeploymentId] and
  /// [deviceRoleName].
  Study(
    String studyDeploymentId,
    String deviceRoleName, [
    DateTime? createdOn,
    StudyDeploymentStatus? deploymentStatus,
    TDeviceDeployment? deployment,
  ]) : _studyDeploymentId = studyDeploymentId,
       _deviceRoleName = deviceRoleName,
       _createdOn = createdOn ?? DateTime.now(),
       _deploymentStatus = deploymentStatus,
       _deployment = deployment;

  /// The ID of the deployed study for which to collect data.
  String get studyDeploymentId => _studyDeploymentId;

  /// The role name of the primary device in the deployment this study runtime participates in.
  String get deviceRoleName => _deviceRoleName;

  /// The date and time when this study was created and added to the [ClientManager].
  DateTime get createdOn => _createdOn;

  /// The deployment status of this study, when known.
  StudyDeploymentStatus? get deploymentStatus => _deploymentStatus;

  /// The deployment for this study, when received from the deployment service.
  TDeviceDeployment? get deployment => _deployment;

  /// The status of this study based on [deploymentStatus].
  StudyStatus get status => switch (deploymentStatus?.status) {
    null => StudyStatus.DeploymentNotAvailable,
    StudyDeploymentStatusTypes.Invited => StudyStatus.DeploymentNotStarted,
    StudyDeploymentStatusTypes.DeployingDevices => StudyStatus.Deploying,
    StudyDeploymentStatusTypes.Running => StudyStatus.Running,
    StudyDeploymentStatusTypes.Stopped => StudyStatus.Stopped,
  };

  /// Stream of study status events.
  Stream<StudyStatusEvent> get events => _eventController.stream;

  /// Create a [StudyStatusEvent] of a specific [type].
  void createEvent(StudyStatusEvent event) => _eventController.add(event);

  /// An updated [deploymentStatus] has been received.
  /// If [deploymentStatus] is not specified, the previously received status is
  /// marked as updated.
  void deploymentStatusReceived([StudyDeploymentStatus? deploymentStatus]) {
    _deploymentStatus ??= deploymentStatus;
    createEvent(
      StudyStatusEvent(this, StudyStatusEventTypes.DeploymentStatusReceived),
    );
    notifyListeners();
  }

  /// A new primary device [deployment] determining what data to collect for
  /// this study has been received.
  /// If [deployment] is not specified, the previously received deployment is
  /// marked as updated.
  void deviceDeploymentReceived([TDeviceDeployment? deployment]) {
    if (deploymentStatus == null) {
      deploymentError(
        "$runtimeType - Deployment status is null. "
        "Can't receive device deployment before having received deployment status.",
      );
      return;
    }

    _deployment ??= deployment;

    // if this is a new deployment, check that the role name matches
    if (deployment != null) {
      if (this.deployment?.deviceConfiguration.roleName != deviceRoleName) {
        deploymentError(
          "$runtimeType - The deployment is intended for a device with a different role name."
          "Was expecting '$deviceRoleName' but got '${this.deployment?.deviceConfiguration.roleName}'.",
        );
        return;
      }
    }

    // Listen to updates to the deployment and notify listeners.
    deployment?.addListener(() => deploymentUpdated());

    createEvent(
      StudyStatusEvent(this, StudyStatusEventTypes.DeviceDeploymentReceived),
    );
    notifyListeners();
  }

  /// Mark the [deployment] as updated.
  /// Print the optional [message] and notify listeners of a deployment update event.
  /// If [deployment] is null, nothing happens.
  void deploymentUpdated([String? message]) {
    if (deployment != null) {
      if (message != null) print(message);
      createEvent(
        StudyStatusEvent(this, StudyStatusEventTypes.DeploymentUpdated),
      );
      notifyListeners();
    }
  }

  /// The deployment is in an error state.
  /// Print the optional [message] and notify listeners of a deployment error event.
  void deploymentError([String? message]) {
    if (message != null) print(message);
    createEvent(StudyStatusEvent(this, StudyStatusEventTypes.DeploymentError));
    notifyListeners();
  }

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

  /// The study is started and ready to sample data on the client.
  Running,

  /// The study has been stopped, either from this client or via the deployment
  /// service.
  Stopped,
}

/// Different types of event that happens to a study while running.
///
/// In contrast to [StudyStatus] which is a permanent state of a study during the
/// deployment process, this [StudyStatusEventTypes] reflects changes to a study
/// on runtime during the [StudyStatus.Running] phase.
enum StudyStatusEventTypes {
  /// Deployment status information has been made available.
  DeploymentStatusReceived,

  /// Deployment information for this study has been received.
  DeviceDeploymentReceived,

  /// The deployment has been updated.
  DeploymentUpdated,

  /// Data sampling state has changed.
  SamplingStateChanged,

  /// An error has occurred during deployment.
  DeploymentError,
}

/// An event related to a running [study].
class StudyStatusEvent<TStudy extends Study> {
  final TStudy study;
  final StudyStatusEventTypes event;
  const StudyStatusEvent(this.study, this.event);
  @override
  String toString() => '$runtimeType - $event ($study)';
}
