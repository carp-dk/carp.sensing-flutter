/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of 'carp_core_client.dart';

/// A study deployment, identified by [studyDeploymentId], which a client
/// device participates in with the role [deviceRoleName].
///
/// A study is a [ChangeNotifier] and updates to a study including its
/// [deploymentStatus], [status], and [deployment] can be listened to.
/// Moreover, the [events] stream emits a [StudyStatusEvent] event every
/// time the status of a study changes.
class Study with ChangeNotifier {
  final DateTime _createdOn;
  final String _studyDeploymentId;
  final String _deviceRoleName;
  StudyDeploymentStatus? _deploymentStatus;
  PrimaryDeviceDeployment? _deployment;

  final StreamController<StudyStatusEvent> _eventController =
      StreamController<StudyStatusEvent>.broadcast();

  /// Create a study uniquely identified by its [studyDeploymentId] and
  /// [deviceRoleName].
  Study(
    String studyDeploymentId,
    String deviceRoleName, [
    DateTime? createdOn,
    StudyDeploymentStatus? deploymentStatus,
    PrimaryDeviceDeployment? deployment,
  ]) : _studyDeploymentId = studyDeploymentId,
       _deviceRoleName = deviceRoleName,
       _createdOn = createdOn ?? DateTime.now(),
       _deploymentStatus = deploymentStatus,
       _deployment = deployment {
    // print events for logging purpose
    // TODO: remove later
    events.listen((event) => print);
  }

  /// The ID of the deployed study for which to collect data.
  String get studyDeploymentId => _studyDeploymentId;

  /// The role name of the device in the deployment this study runtime participates in.
  String get deviceRoleName => _deviceRoleName;

  /// The date and time when this study was created and added to the [ClientManager].
  DateTime get createdOn => _createdOn;

  /// The deployment status of this study, when known.
  StudyDeploymentStatus? get deploymentStatus => _deploymentStatus;

  /// The deployment for this study, when received from the deployment service.
  PrimaryDeviceDeployment? get deployment => _deployment;

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

  /// An updated [deploymentStatus] has been received.
  void deploymentStatusReceived(StudyDeploymentStatus deploymentStatus) {
    _deploymentStatus = deploymentStatus;
    _eventController.add(
      StudyStatusEvent(this, StudyStatusEventTypes.DeploymentStatusReceived),
    );
    notifyListeners();
  }

  /// A new primary device [deployment] determining what data to collect for
  /// this study has been received.
  void deviceDeploymentReceived(PrimaryDeviceDeployment deployment) {
    if (deploymentStatus == null) {
      deploymentError(
        "Can't receive device deployment before having received deployment status.",
      );
      return;
    }

    if (deployment.deviceConfiguration.roleName != deviceRoleName) {
      deploymentError(
        "The deployment is intended for a device with a different role name.",
      );
    }

    _deployment = deployment;
    _eventController.add(
      StudyStatusEvent(this, StudyStatusEventTypes.DeviceDeploymentReceived),
    );
    notifyListeners();
  }

  /// Mark the [deployment] as updated. If [deployment] is null, nothing happens.
  void deploymentUpdated() {
    if (deployment != null) {
      _eventController.add(
        StudyStatusEvent(this, StudyStatusEventTypes.DeploymentUpdated),
      );
      notifyListeners();
    }
  }

  /// The deployment is i an error state.
  void deploymentError([String? message]) {
    if (message != null) print(message);
    _eventController.add(
      StudyStatusEvent(this, StudyStatusEventTypes.DeploymentError),
    );
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

  /// The study is started and is sampling data.
  Running,

  /// The study has been stopped, either from this client or via the deployment
  /// service.
  Stopped,
}

enum StudyStatusEventTypes {
  /// Deployment status information has been made available.
  DeploymentStatusReceived,

  /// Deployment information for this study has been received.
  DeviceDeploymentReceived,

  /// The deployment has been updated.
  ///
  /// This event type is not included in CARP Core in Kotlin, but added to this
  /// Dart package in order to handle deployment updates more gracefully in a
  /// Flutter client.
  DeploymentUpdated,

  /// An error has occurred during deployment.
  ///
  /// This event type is not included in CARP Core in Kotlin, but added to this
  /// Dart package in order to handle deployment error more gracefully in a
  /// Flutter client.
  DeploymentError,
}

/// An event related to a changes to a [Study].
class StudyStatusEvent {
  final Study study;
  final StudyStatusEventTypes event;
  const StudyStatusEvent(this.study, this.event);
  @override
  String toString() => '$runtimeType - $event ($study)';
}
