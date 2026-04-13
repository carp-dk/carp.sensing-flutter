/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../deployment.dart';

/// A single instantiation of a [StudyProtocol], taking care of common concerns
/// related to devices when 'running' a study.
///
/// I.e., a [StudyDeployment] is responsible for registering the physical
/// devices described in the [StudyProtocol], enabling a connection between them,
/// tracking device connection issues, and assessing data quality.
class StudyDeployment {
  late String _studyDeploymentId;
  late DateTime _creationDate;
  late StudyDeploymentStatus _status;
  late StudyProtocol _protocol;

  /// The list of all registered devices, mapped to their role name
  final Map<String, DeviceRegistration> _registeredDevices = {};

  /// The list of registered devices' configurations, mapped to their role names
  final Map<String, DeviceConfiguration> _registeredDeviceConfigurations = {};
  final Map<DeviceConfiguration, List<DeviceRegistration>>
  _deviceRegistrationHistory = {};

  /// The list of deployed devices, organized by role name
  final Set<String> _deployedDevices = {};
  final Set<DeviceConfiguration> _invalidatedDeployedDevices = {};
  DateTime? _startTime;
  bool _isStopped = false;

  String get studyDeploymentId => _studyDeploymentId;
  DateTime get creationDate => _creationDate;
  StudyProtocol get protocol => _protocol;

  /// All the data streams which are required to run this study deployment.
  DataStreamsConfiguration get requiredDataStreams {
    Set<ExpectedDataStream> streams = {};

    for (var device in protocol.devices) {
      for (var task in protocol.getTasksForDevice(device)) {
        if (task != null) {
          for (var type in task.getAllExpectedDataTypes()) {
            streams.add(
              ExpectedDataStream(
                dataType: type,
                deviceRoleName: device.roleName,
              ),
            );
          }
        }
      }
    }

    return DataStreamsConfiguration(
      studyDeploymentId: studyDeploymentId,
      expectedDataStreams: streams,
    );
  }

  /// The set of devices which are currently registered for this study deployment.
  Map<DeviceConfiguration, DeviceRegistration> get registeredDevices =>
      _registeredDevices.map(
        (key, value) => MapEntry(_registeredDeviceConfigurations[key]!, value),
      );

  /// Per device, a list of all device registrations (included old registrations)
  /// in the order they were registered.
  Map<DeviceConfiguration, List<DeviceRegistration>>
  get deviceRegistrationHistory => _deviceRegistrationHistory;

  /// The set of devices (role names) which have been deployed correctly.
  Set<String?> get deployedDevices => _deployedDevices;
  Set<DeviceConfiguration> get invalidatedDeployedDevices =>
      _invalidatedDeployedDevices;

  /// The time when the study deployment was ready for the first
  /// time (all devices deployed); null otherwise.
  DateTime? get startTime => _startTime;

  /// Determines whether the study deployment has been stopped and no
  /// further modifications are allowed.
  bool get isStopped => _isStopped;

  /// Create a new [StudyDeployment] based on a [StudyProtocol].
  /// [studyDeploymentId] specify the study deployment id.
  /// If not specified, an UUID v1 id is generated.
  StudyDeployment(StudyProtocol protocol, [String? studyDeploymentId]) {
    _studyDeploymentId = studyDeploymentId ?? const Uuid().v1;
    _protocol = protocol;
    _creationDate = DateTime.now();
    _status = StudyDeploymentStatus(studyDeploymentId: _studyDeploymentId);
    _status.createdOn = _creationDate;
  }

  /// Get the status of this [StudyDeployment].
  StudyDeploymentStatus get status {
    // set the status of each device - both primary and connected devices
    _status.deviceStatusList = [];
    for (var deviceDescriptor in protocol.primaryDevices) {
      _status.deviceStatusList.add(getDeviceStatus(deviceDescriptor));
    }
    for (var deviceDescriptor in protocol.connectedDevices!) {
      _status.deviceStatusList.add(getDeviceStatus(deviceDescriptor));
    }

    // TODO - check that all devices are ready, before setting the overall status
    return _status;
  }

  /// Get the status of a device in this [StudyDeployment].
  DeviceDeploymentStatus getDeviceStatus(DeviceConfiguration device) {
    DeviceDeploymentStatus deviceStatus = DeviceDeploymentStatus(
      device: device,
    );

    deviceStatus.status = DeviceDeploymentStatusTypes.Unregistered;
    if (_registeredDevices.containsKey(device.roleName)) {
      deviceStatus.status = DeviceDeploymentStatusTypes.Registered;
    }
    if (_deployedDevices.contains(device.roleName)) {
      deviceStatus.status = DeviceDeploymentStatusTypes.Deployed;
    }

    return deviceStatus;
  }

  /// Register the specified [device] for this deployment using the [registration]
  /// options.
  void registerDevice(
    DeviceConfiguration device,
    DeviceRegistration registration,
  ) {
    // Mark this deployment as deploying if not already done.
    if (_status.status == StudyDeploymentStatusTypes.Invited) {
      _status.status = StudyDeploymentStatusTypes.DeployingDevices;
    }

    // Add device to currently registered devices and also store it in registration history.
    _registeredDeviceConfigurations[device.roleName] = device;
    _registeredDevices[device.roleName] = registration;

    if (_deviceRegistrationHistory[device] == null) {
      _deviceRegistrationHistory[device] = [];
    }
    _deviceRegistrationHistory[device]!.add(registration);
  }

  /// Remove the current device registration for the [device] in this deployment.
  void unregisterDevice(DeviceConfiguration device) {
    _deployedDevices.remove(device.roleName);
    _registeredDeviceConfigurations.remove(device.roleName);
    _registeredDevices.remove(device.roleName);
  }

  /// Get the deployment configuration for the specified primary [device] in
  /// this study deployment.
  PrimaryDeviceDeployment getDeviceDeploymentFor(
    PrimaryDeviceConfiguration device,
  ) {
    // Verify whether the specified device is part of the protocol of this
    // deployment and has been registered.
    assert(
      _protocol.hasPrimaryDevice(device.roleName),
      "The specified primary device with role name '${device.roleName}' is not part of the protocol of this deployment.",
    );
    assert(
      _registeredDevices.containsKey(device.roleName),
      "The specified primary device with role name '${device.roleName}' has not been registered to this deployment.",
    );

    // TODO - Verify whether the specified device is ready to be deployed.

    DeviceRegistration registration = _registeredDevices[device.roleName]!;

    // mark all registered devices as deployed
    _deployedDevices.addAll(_registeredDevices.keys);

    // determine which devices this device needs to connect to
    // TODO - only retrieve configuration for preregistered devices
    Set<DeviceConfiguration> connectedDevices = _protocol.connectedDevices!;

    // create a map of device registration for the connected devices
    Map<String, DeviceRegistration?> connectedDeviceConfigurations = {};
    for (var descriptor in connectedDevices) {
      connectedDeviceConfigurations[descriptor.roleName] =
          _registeredDevices[descriptor.roleName];
    }

    Set<TaskConfiguration> tasks = {};

    // get all tasks which need to be executed on this primary device
    tasks.addAll(protocol.getTasksForDeviceRoleName(device.roleName));

    // .. and connected devices
    // note that connected devices need NOT to be registered to be included
    for (var descriptor in connectedDevices) {
      tasks.addAll(protocol.getTasksForDeviceRoleName(descriptor.roleName));
    }

    // Get all trigger information for this and connected devices.
    // TODO - this implementation just returns all triggers and triggered tasks.
    //      - but should check which devices are available
    Map<String, TriggerConfiguration>? usedTriggers = _protocol.triggers;
    Set<TaskControl>? triggeredTasks = _protocol.taskControls;

    _status.status = StudyDeploymentStatusTypes.Running;

    return PrimaryDeviceDeployment(
      deviceConfiguration: device,
      registration: registration,
      connectedDevices: connectedDevices,
      connectedDeviceRegistrations: connectedDeviceConfigurations,
      tasks: tasks,
      triggers: usedTriggers,
      taskControls: triggeredTasks,
    );
  }

  /// Indicate that the specified primary [device] was deployed successfully using
  /// the deployment with the specified [deviceDeploymentLastUpdateDate].
  void deviceDeployed(
    PrimaryDeviceConfiguration device,
    DateTime deviceDeploymentLastUpdateDate,
  ) {
    // assert(_protocol.primaryDevices.contains(device),
    //     'The specified primary device is not part of the protocol of this deployment.');
    _status.status = StudyDeploymentStatusTypes.Running;
    _startTime = deviceDeploymentLastUpdateDate;
  }

  /// Stop this study deployment. No further changes to this deployment
  /// are allowed and no more data should be collected.
  void stop() {
    _isStopped = true;
    _status.status = StudyDeploymentStatusTypes.Stopped;
  }
}

/// The types of study deployment status.
enum StudyDeploymentStatusTypes {
  /// Initial study deployment status, indicating the invited participants
  /// have not yet acted on the invitation.
  Invited,

  /// Participants have started registering devices, but remaining primary
  /// devices still need to be deployed.
  DeployingDevices,

  /// All primary devices have been successfully deployed and data collection
  /// has started on the time specified by [StudyDeploymentStatus.startedOn].
  Running,

  /// The study deployment has been stopped and no more data should be collected.
  Stopped,
}

/// A [StudyDeploymentStatus] represents the status of a deployment as returned
/// from the CARP web service.
///
/// See [StudyDeploymentStatus.kt](https://github.com/carp-dk/carp.core-kotlin/blob/develop/carp.deployment.core/src/commonMain/kotlin/dk/cachet/carp/deployment/domain/StudyDeploymentStatus.kt).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StudyDeploymentStatus extends Serializable {
  /// The status of this device deployment:
  /// * Invited
  /// * DeployingDevices
  /// * Running
  /// * Stopped
  // @JsonKey(includeFromJson: true, includeToJson: true)
  StudyDeploymentStatusTypes? status = StudyDeploymentStatusTypes.Invited;

  /// The time when the deployment was created.
  late DateTime createdOn;

  /// The CARP study deployment ID.
  String studyDeploymentId;

  /// The list of all devices part of this study deployment and their status.
  List<DeviceDeploymentStatus> deviceStatusList;

  /// The list of all participants and their status in this study deployment.
  List<ParticipantStatus> participantStatusList = [];

  /// The time when the study deployment was ready for the first
  /// time (all devices deployed); null otherwise.
  DateTime? startedOn;

  /// Get the status of a [device] in this study deployment.
  DeviceDeploymentStatus getDeviceStatus(DeviceConfiguration device) =>
      deviceStatusList.firstWhere((status) => status.device == device);

  /// Get the status of a device with the given [roleName] in this study deployment.
  DeviceDeploymentStatus getDeviceStatusByRoleName(String roleName) =>
      deviceStatusList.firstWhere(
        (status) => status.device.roleName == roleName,
      );

  StudyDeploymentStatus({
    required this.studyDeploymentId,
    this.deviceStatusList = const [],
  }) : super();

  @override
  Function get fromJsonFunction => _$StudyDeploymentStatusFromJson;

  factory StudyDeploymentStatus.fromJson(Map<String, dynamic> json) {
    StudyDeploymentStatus status = FromJsonFactory()
        .fromJson<StudyDeploymentStatus>(json);

    // When this object was create from json deserialization, from CARP Core Kotlin,
    // the last part of the $type reflects the status:
    //   "__type": "dk.cachet.carp.deployments.application.StudyDeploymentStatus.Invited"
    status.status ??= switch (status.$type?.split('.').last) {
      'Invited' => StudyDeploymentStatusTypes.Invited,
      'DeployingDevices' => StudyDeploymentStatusTypes.DeployingDevices,
      'Running' => StudyDeploymentStatusTypes.Running,
      'Stopped' => StudyDeploymentStatusTypes.Stopped,
      _ => StudyDeploymentStatusTypes.Invited,
    };
    return status;
  }

  @override
  Map<String, dynamic> toJson() => _$StudyDeploymentStatusToJson(this);

  @override
  String get jsonType => 'dk.cachet.carp.deployment.domain.$runtimeType';

  @override
  String toString() =>
      '$runtimeType - deploymentId: $studyDeploymentId, status: ${status?.name}';
}
