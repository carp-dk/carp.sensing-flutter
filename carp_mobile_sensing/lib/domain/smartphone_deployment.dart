/*
 * Copyright 2021-2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../domain.dart';

/// A study configured to run on a smartphone (i.e., on a [SmartPhoneClientManager]).
class SmartphoneStudy extends Study {
  /// The unique id of the study in the deployment service.
  String? studyId;

  /// The ID of the participant in this study.
  String? participantId;

  /// The role of the participant in this study.
  String? participantRoleName;

  /// Create a [SmartphoneStudy].
  SmartphoneStudy({
    this.studyId,
    required String studyDeploymentId,
    required String deviceRoleName,
    this.participantId,
    this.participantRoleName,
    DateTime? createdOn,
    StudyDeploymentStatus? deploymentStatus,
    PrimaryDeviceDeployment? deployment,
  }) : super(
         studyDeploymentId,
         deviceRoleName,
         createdOn,
         deploymentStatus,
         deployment,
       );

  /// Create a [SmartphoneStudy] from [invitation].
  SmartphoneStudy.fromInvitation(ActiveParticipationInvitation invitation)
    : this(
        studyId: invitation.studyId,
        studyDeploymentId: invitation.studyDeploymentId,
        deviceRoleName:
            invitation.deviceRoleName ?? Smartphone.DEFAULT_ROLE_NAME,
        participantId: invitation.participantId,
        participantRoleName: invitation.participantRoleName,
      );

  /// Create a [SmartphoneStudy] from a SQL Result Map.
  factory SmartphoneStudy.fromMap(Map<String, Object?> map) {
    final statusJson = map[Persistence.DEPLOYMENT_STATUS_COLUMN] as String;
    final status = StudyDeploymentStatus.fromJson(
      json.decode(statusJson) as Map<String, dynamic>,
    );

    final deploymentJson = map[Persistence.DEPLOYMENT_COLUMN] as String;
    final deployment = SmartphoneDeployment.fromJson(
      json.decode(deploymentJson) as Map<String, dynamic>,
    );

    return SmartphoneStudy(
      studyId: map[Persistence.STUDY_ID_COLUMN] as String,
      studyDeploymentId: map[Persistence.STUDY_DEPLOYMENT_ID_COLUMN] as String,
      deviceRoleName: map[Persistence.DEVICE_ROLE_NAME_COLUMN] as String,
      participantId: map[Persistence.PARTICIPANT_ID_COLUMN] as String,
      participantRoleName:
          map[Persistence.PARTICIPANT_ROLE_NAME_COLUMN] as String,
      createdOn: DateTime.tryParse(
        map[Persistence.PARTICIPANT_ROLE_NAME_COLUMN] as String,
      ),
      deploymentStatus: status,
      deployment: deployment,
    );
  }

  @override
  String toString() =>
      '$runtimeType - '
      'studyId: $studyId, '
      'studyDeploymentId: $studyDeploymentId, '
      'device role: $deviceRoleName, '
      'participant id: $participantId, '
      'participant role: $participantRoleName';
}

/// Contains the entire description and configuration for a study deployment on
/// a smartphone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SmartphoneDeployment extends PrimaryDeviceDeployment
    with SmartphoneProtocolExtension {
  late String _studyDeploymentId;

  /// The unique id of the study that this deployment is part of.
  /// Is `null` if this is a local deployment running only on this phone.
  String? studyId;

  /// The unique id of this study deployment.
  String get studyDeploymentId => _studyDeploymentId;

  /// The role name of this smartphone device.
  String? get deviceRoleName => deviceConfiguration.roleName;

  /// The ID of the participant in this deployment.
  String? participantId;

  /// The role name of the participant in this deployment.
  String? participantRoleName;

  /// All devices this deployment is using.
  ///
  /// This set combines the [deviceConfiguration] with all [connectedDevices].
  Set<DeviceConfiguration> get devices =>
      Set.from(connectedDevices)..add(deviceConfiguration);

  /// The timestamp (in UTC) when this deployment was deployed on this smartphone.
  /// Is `null` if not deployed yet.
  DateTime? deployed;

  /// The unique id of the user that this deployment collects data from.
  ///
  /// This [userId] may, or may not, be identical to the [participantId] or to
  /// the user who is logged into an app or uploads data.
  ///
  /// By being able to separate who collects (and potentially uploads) a data
  /// point from who the data point belongs to, allows for one user to collect
  /// data on behalf of another user. For example, a parent on behalf of a child.
  // String? userId;

  /// The status of this study deployment.
  StudyDeploymentStatusTypes status = StudyDeploymentStatusTypes.Invited;

  /// Create a new [SmartphoneDeployment].
  ///
  /// [studyDeploymentId] is a unique id for this deployment. If not specified,
  /// a unique id will be generated.
  SmartphoneDeployment({
    this.studyId,
    String? studyDeploymentId,
    required super.deviceConfiguration,
    required super.registration,
    super.connectedDevices,
    super.connectedDeviceRegistrations,
    super.tasks,
    super.triggers,
    super.taskControls,
    super.expectedParticipantData,
    this.participantId,
    this.participantRoleName,
    StudyDescription? studyDescription,
    DataEndPoint? dataEndPoint,
    String? privacySchemaName,
  }) {
    _studyDeploymentId = studyDeploymentId ?? const Uuid().v1;
    _data = SmartphoneApplicationData(
      studyDescription: studyDescription,
      dataEndPoint: dataEndPoint,
      privacySchemaName: privacySchemaName,
    );
  }

  /// Create a [SmartphoneDeployment] based on a [PrimaryDeviceDeployment].
  SmartphoneDeployment.fromPrimaryDeviceDeployment({
    this.studyId,
    String? studyDeploymentId,
    this.participantId,
    this.participantRoleName,
    required PrimaryDeviceDeployment deployment,
  }) : super(
         deviceConfiguration: deployment.deviceConfiguration,
         registration: deployment.registration,
         connectedDevices: deployment.connectedDevices,
         connectedDeviceRegistrations: deployment.connectedDeviceRegistrations,
         tasks: deployment.tasks,
         triggers: deployment.triggers,
         taskControls: deployment.taskControls,
         expectedParticipantData: deployment.expectedParticipantData,
       ) {
    _studyDeploymentId = studyDeploymentId ?? const Uuid().v1;

    // check if this deployment has mapped study description in the application
    // data, i.e., a protocol generated from CAMS
    if (deployment.applicationData != null &&
        deployment.applicationData!.containsKey('studyDescription')) {
      var data = SmartphoneApplicationData.fromJson(
        deployment.applicationData!,
      );
      _data.studyDescription = data.studyDescription;
      _data.dataEndPoint = data.dataEndPoint;
      _data.privacySchemaName = data.privacySchemaName;
      _data.applicationData = data.applicationData;
    } else {
      _data.applicationData = deployment.applicationData ?? {};
    }
  }

  /// Create a [SmartphoneDeployment] that combines a [PrimaryDeviceDeployment] and
  /// a [SmartphoneStudyProtocol].
  ///
  /// It takes the deployment information from the [deployment] (such as device
  /// configuration, device registration, and what devices are connected) and
  /// takes the data collection configuration from the [protocol] (such as
  /// task, triggers, task controls, and expected participant data).
  SmartphoneDeployment.fromPrimaryDeviceDeploymentAndSmartphoneStudyProtocol({
    this.studyId,
    String? studyDeploymentId,
    this.participantId,
    this.participantRoleName,
    required PrimaryDeviceDeployment deployment,
    required SmartphoneStudyProtocol protocol,
  }) : super(
         deviceConfiguration: deployment.deviceConfiguration,
         registration: deployment.registration,
         connectedDevices:
             protocol.connectedDevices ?? deployment.connectedDevices,
         connectedDeviceRegistrations: deployment.connectedDeviceRegistrations,
         tasks: protocol.tasks,
         triggers: protocol.triggers,
         taskControls: protocol.taskControls,
         expectedParticipantData:
             protocol.expectedParticipantData ??
             deployment.expectedParticipantData,
       ) {
    _studyDeploymentId = studyDeploymentId ?? const Uuid().v1;
    _data.studyDescription = protocol.studyDescription;
    _data.dataEndPoint = protocol.dataEndPoint;
    _data.privacySchemaName = protocol.privacySchemaName;
    _data.applicationData = protocol._data.applicationData;
  }

  /// Create a [SmartphoneDeployment] based on a [SmartphoneStudyProtocol].
  /// This method basically makes a 1:1 mapping from the [protocol] to the
  /// deployment using a [Smartphone] as the primary device with the
  /// specified [primaryDeviceRoleName].
  SmartphoneDeployment.fromSmartphoneStudyProtocol({
    this.studyId,
    String? studyDeploymentId,
    this.participantId,
    this.participantRoleName,
    required String primaryDeviceRoleName,
    required SmartphoneStudyProtocol protocol,
  }) : super(
         deviceConfiguration: Smartphone(roleName: primaryDeviceRoleName),
         registration: DefaultDeviceRegistration(),
         connectedDevices: protocol.connectedDevices ?? {},
         connectedDeviceRegistrations: {},
         tasks: protocol.tasks,
         triggers: protocol.triggers,
         taskControls: protocol.taskControls,
         expectedParticipantData: protocol.expectedParticipantData ?? {},
       ) {
    _studyDeploymentId = studyDeploymentId ?? const Uuid().v1;
    _data.studyDescription = protocol.studyDescription;
    _data.dataEndPoint = protocol.dataEndPoint;
    _data.privacySchemaName = protocol.privacySchemaName;
    _data.applicationData = protocol._data.applicationData;
  }

  /// Get the list of all measures in this study deployment.
  List<Measure> get measures {
    final List<Measure> measures = [];
    for (var task in tasks) {
      if (task.measures != null) measures.addAll(task.measures!);
    }
    return measures;
  }

  /// Get the [DeviceConfiguration] based on the [roleName].
  /// This includes both the primary device and the connected devices.
  /// Returns null if no device with [roleName] is found.
  DeviceConfiguration? getDeviceFromRoleName(String roleName) {
    if (deviceConfiguration.roleName == roleName) return deviceConfiguration;
    try {
      return connectedDevices.firstWhere(
        (device) => device.roleName == roleName,
      );
    } catch (_) {
      return null;
    }
  }

  factory SmartphoneDeployment.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneDeploymentFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneDeploymentToJson(this);

  @override
  String toString() =>
      '$runtimeType - '
      'studyId: $studyId, '
      'studyDeploymentId: $studyDeploymentId, '
      'device role: $deviceRoleName, '
      'participant id: $participantId, '
      'participant role: $participantRoleName, '
      'title: ${studyDescription?.title}, '
      'responsible: ${responsible?.name}';
}
