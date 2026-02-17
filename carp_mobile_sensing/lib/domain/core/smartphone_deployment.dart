/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../../domain.dart';

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
  String get deviceRoleName => deviceConfiguration.roleName;

  /// All devices this deployment is using.
  ///
  /// This set combines the primary [deviceConfiguration] with all [connectedDevices].
  Set<DeviceConfiguration> get devices =>
      Set.from(connectedDevices)..add(deviceConfiguration);

  /// The timestamp (in UTC) when this deployment was deployed on this smartphone.
  DateTime deployed = DateTime.now().toUtc();

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
    _data.protocolVersionTag = protocol.protocolVersionTag;
    _data.protocolApiLevel = protocol.protocolApiLevel;
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
    try {
      return devices.firstWhere((device) => device.roleName == roleName);
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
      'title: ${studyDescription?.title}, '
      'responsible: ${responsible?.name}';
}
