/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../protocol.dart';

/// A description of how a study is to be executed, defining the type(s) of
/// primary device(s) ([PrimaryDeviceConfiguration]) responsible for
/// aggregating data, the optional devices ([DeviceConfiguration]) connected
/// to them, and the [TaskControl]'s which lead to data collection on
/// said devices.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StudyProtocol extends Snapshot {
  static const String PROTOCOL_NAMESPACE = 'dk.cachet.carp.protocols.domain';

  // maps a task's name and the task
  Map<String, TaskConfiguration>? _taskMapProperty;

  /// Get the map of tasks. Initialize it from the list of [tasks], if not available
  /// (typically after json de-serialization).
  Map<String, TaskConfiguration> get _taskMap {
    if (_taskMapProperty == null) {
      _taskMapProperty = {};
      for (var task in tasks) {
        _taskMapProperty![task.name] = task;
      }
    }
    return _taskMapProperty!;
  }

  /// The entity (e.g., person or group) that created this study pProtocol.
  String ownerId;

  /// A unique descriptive name for the protocol assigned by the protocol owner.
  String name;

  /// An optional description for the study protocol.
  String? description;

  /// Roles which can be assigned to participants in the study and [ParticipantAttribute]s
  /// can be linked to.
  /// If a [ParticipantAttribute] is not linked to any specific participant role,
  /// the participant data can be filled out by all participants in the study deployment.
  Set<ParticipantRole>? participantRoles = {};

  /// The full list of devices part of this configuration.
  Set<DeviceConfiguration> get devices => {
    ...primaryDevices,
    ...connectedDevices!,
  };

  /// The set of devices which are responsible for aggregating and synchronizing
  /// incoming data.
  Set<PrimaryDeviceConfiguration> primaryDevices = {};

  /// The devices this device needs to connect to.
  Set<DeviceConfiguration>? connectedDevices = {};

  /// The connections between [primaryDevices] and [connectedDevices].
  List<DeviceConnection>? connections = [];

  /// Per device role, the participant roles to which the device is assigned.
  /// Unassigned device are assigned to "anyone".
  Map<String, Set<String>>? assignedDevices = {};

  /// The tasks which measure data and/or present output on a device.
  Set<TaskConfiguration> tasks = {};

  /// The list of triggers with assigned IDs which can start or stop tasks in
  /// this study protocol.
  Map<String, TriggerConfiguration> triggers = {};

  /// Stores which tasks need to be started or stopped when the conditions
  /// defined by [triggers] are met.
  Set<TaskControl> taskControls = {};

  Set<ExpectedParticipantData>? expectedParticipantData = {};

  /// Application-specific data to be stored as part of the study protocol
  /// which will be included in all deployments of this study protocol.
  ///
  /// This can be used by infrastructures or concrete applications which require
  /// exchanging additional data between the protocols and clients subsystems,
  /// outside of scope or not yet supported by CARP core.
  Map<String, dynamic>? applicationData;

  /// Create a new protocol. [ownerId] and [name] must be specified.
  StudyProtocol({required this.ownerId, required this.name, this.description})
    : super();

  /// Add a primary device (e.g., a phone) which is responsible for aggregating
  /// and synchronizing incoming data.
  /// Its role name should be unique in the protocol.
  ///
  /// Returns true if the [primaryDevice] has been added; false if it is already
  /// set as a primary device.
  bool addPrimaryDevice(PrimaryDeviceConfiguration primaryDevice) =>
      primaryDevices.add(primaryDevice);

  /// Does this protocol have a primary device with role name [roleName]?
  bool hasPrimaryDevice(String roleName) =>
      primaryDevices
          .firstWhere(
            (device) => device.roleName == roleName,
            orElse: () => PrimaryDeviceConfiguration(roleName: 'not_found'),
          )
          .roleName !=
      'not_found';

  /// The first of all the [primaryDevices].
  ///
  /// This is a convenient method used when there is only one primary device,
  /// which is most of the cases in Flutter where the primary device is typically
  /// the phone.
  PrimaryDeviceConfiguration get primaryDevice => primaryDevices.first;

  /// Add a [device] which is connected to the [primaryDevice].
  /// Its role name should be unique in the protocol.
  ///
  /// Returns true if the [device] has been added; false if it is already connected
  /// to the specified [primaryDevice].
  bool addConnectedDevice(
    DeviceConfiguration device,
    PrimaryDeviceConfiguration primaryDevice,
  ) {
    connections ??= [];
    connections?.add(DeviceConnection(device.roleName, primaryDevice.roleName));
    return connectedDevices!.add(device);
  }

  /// Gets all devices configured to be connected to [primaryDevice].
  List<DeviceConfiguration> getConnectedDevices(
    PrimaryDeviceConfiguration primaryDevice,
  ) {
    final List<DeviceConfiguration> devices = [];
    connections?.forEach((connection) {
      if (connection.roleName == primaryDevice.roleName) {
        var connectedDevice = connectedDevices?.firstWhere(
          (device) => device.roleName == connection.connectedToRoleName,
        );
        if (connectedDevice != null) devices.add(connectedDevice);
      }
    });
    return devices;
  }

  /// Add the [trigger] to this protocol.
  void addTrigger(TriggerConfiguration trigger) {
    // early out if already added
    if (triggers.values.contains(trigger)) return;

    // if source is not defined, use the primary device role name
    trigger.sourceDeviceRoleName ??= primaryDevice.roleName;

    // so much for null-safety "#%"&?
    if (trigger.requiresPrimaryDevice != null &&
        trigger.requiresPrimaryDevice!) {
      assert(
        hasPrimaryDevice(trigger.sourceDeviceRoleName!),
        'The passed trigger cannot be initiated by its specified source device '
        'since it is not a primary device which is part of this protocol.',
      );
    }

    triggers['${triggers.length}'] = trigger;
  }

  /// Returns the index of the [trigger] in the [triggers].
  /// Returns `-1` if not found.
  int indexOfTrigger(TriggerConfiguration trigger) {
    // early out if not in the triggers
    if (!triggers.containsValue(trigger)) return -1;
    int index = -1;
    triggers.forEach((key, value) {
      if (trigger == value) index = int.parse(key);
    });
    return index;
  }

  /// Add a [task] to be started (default) or stopped (determined by [control]) on a
  /// [destinationDevice] once a [trigger] within this protocol is initiated.
  /// In case the [trigger] or [task] are not yet included in this study protocol,
  /// it will be added.
  /// The [destinationDevice] needs to be added prior to this call since it needs
  /// to be set up as either a primary device or connected device.
  /// If [destinationDevice] is not specified, the default primary device
  /// (i.e., [primaryDevice]) is used.
  ///
  /// Throws an error if the [destinationDevice] is not included in this
  /// study protocol.
  /// Returns true if the task control has been added; false if the same control
  /// is already present.
  bool addTaskControl(
    TriggerConfiguration trigger,
    TaskConfiguration task, [
    DeviceConfiguration? destinationDevice,
    Control control = Control.Start,
  ]) {
    destinationDevice ??= primaryDevice;

    assert(
      primaryDevices.contains(destinationDevice) ||
          connectedDevices!.contains(destinationDevice),
      'The passed device to which the task needs to be sent is not included in this study protocol.',
    );

    // Add trigger and task to ensure they are included in the protocol.
    // Set the trigger's destination device if not specified.
    trigger.sourceDeviceRoleName ??= destinationDevice.roleName;
    addTrigger(trigger);
    addTask(task);

    // create and add a task control
    int triggerId = indexOfTrigger(trigger);
    if (triggerId >= 0) {
      taskControls.add(
        TaskControl(
          triggerId: triggerId,
          task: task,
          targetDevice: destinationDevice,
          control: control,
        ),
      );
      return true;
    }
    return false;
  }

  /// Add a list of [tasks] to be started or stopped (determined by [control]) on a
  /// [destinationDevice] once a [trigger] within this protocol is initiated.
  /// In case the [trigger] or [tasks] are not yet included in this study protocol,
  /// it will be added.
  /// The [destinationDevice] needs to be added prior to this call since it needs
  /// to be set up as either a primary device or connected device.
  void addTaskControls(
    TriggerConfiguration trigger,
    List<TaskConfiguration> tasks,
    DeviceConfiguration destinationDevice, [
    Control control = Control.Start,
  ]) {
    for (TaskConfiguration task in tasks) {
      addTaskControl(trigger, task, destinationDevice, control);
    }
  }

  /// Gets all conditions which control that tasks get started or stopped on
  /// devices in this protocol by the specified [trigger].
  ///
  /// Throws an error if [trigger] is not part of this study protocol.
  Set<TaskControl> getTaskControls(TriggerConfiguration trigger) {
    assert(
      triggers.values.contains(trigger),
      'The passed trigger is not part of this study protocol.',
    );
    int triggerId = indexOfTrigger(trigger);

    Set<TaskControl> tt = {};
    // search the list of task controls
    for (var taskControl in taskControls) {
      if (taskControl.triggerId == triggerId) {
        tt.add(taskControl);
      }
    }

    return tt;
  }

  /// Gets all conditions which control that tasks get started or stopped on devices
  /// in this protocol by the trigger with [triggerId].
  ///
  /// Throws an error if a trigger with [triggerId] is not defined in this study protocol.
  Set<TaskControl> getTaskControlsByTriggerId(int triggerId) =>
      getTaskControls(triggers['$triggerId']!);

  /// Add the [task] to this protocol.
  void addTask(TaskConfiguration task) {
    tasks.add(task);
    _taskMap[task.name] = task;
  }

  /// Remove the [task] currently present in this configuration
  /// including removing it from any [TaskControl]'s which initiate it.
  void removeTask(TaskConfiguration task) {
    // Remove all controls which control this task
    for (var taskControl in taskControls) {
      if (taskControl.taskName == task.name) {
        taskControls.remove(taskControl);
      }
    }

    // Remove task itself.
    tasks.remove(task);
    _taskMap.remove(task.name);
  }

  /// Gets all the tasks triggered for the specified [device].
  /// If [device] is not part of either [primaryDevices]
  /// or [connectedDevices], an empty set is returned.
  Set<TaskConfiguration?> getTasksForDevice(DeviceConfiguration device) {
    final Set<TaskConfiguration?> deviceTasks = {};

    for (var taskControl in taskControls) {
      if (taskControl.destinationDeviceRoleName == device.roleName) {
        deviceTasks.add(_taskMap[taskControl.taskName]);
      }
    }

    return deviceTasks;
  }

  /// Gets all the tasks triggered for the specified [deviceRoleName].
  ///
  /// Returns an empty set if the device is not part of [primaryDevices]
  /// or [connectedDevices].
  Set<TaskConfiguration> getTasksForDeviceRoleName(String deviceRoleName) {
    final Set<TaskConfiguration> deviceTasks = {};

    for (var taskControl in taskControls) {
      if (taskControl.destinationDeviceRoleName == deviceRoleName) {
        if (_taskMap.containsKey(taskControl.taskName)) {
          deviceTasks.add(_taskMap[taskControl.taskName]!);
        }
      }
    }
    return deviceTasks;
  }

  /// Add a participant role which can be assigned to participants in the study.
  ///
  /// Returns true if the [role] has been added; false in case the same [role]
  /// has already been added before.
  bool addParticipantRole(ParticipantRole role) =>
      (participantRoles ??= {}).add(role);

  /// Determines whether all participant roles in [assignment] are part of the
  /// [participantRoles] in this protocol.
  bool isValidAssignment(AssignedTo assignment) {
    if (assignment.isAssignedToAll) return true; // assigned to all

    for (var name in assignment.roleNames!) {
      for (var role in participantRoles!) {
        if (role.role == name) return true;
      }
    }
    return false;
  }

  /// Change who the primary [device] is [assignedTo].
  ///
  /// By default, primary devices are all roles so using this method is only
  /// needed if you want to change this default assignment.
  ///
  /// Requires that [device] is part of this protocol and [assignedTo] contains
  /// participant roles which are part of this protocol.
  void changeDeviceAssignment(
    PrimaryDeviceConfiguration device,
    AssignedTo assignedTo,
  ) {
    assignedDevices ??= {};
    assert(
      primaryDevices.contains(device),
      "The device configuration is not part of this protocol.",
    );
    assert(
      isValidAssignment(assignedTo),
      "One of the assigned participant roles is not part of this protocol.",
    );
    assert(
      !assignedTo.isAssignedToAll,
      "Do not use this method to assign a device to all participants. "
      "This is done per default.",
    );

    assignedDevices![device.roleName] = assignedTo.roleNames!;
  }

  /// Remove the primary [device] assignments and hence make it assigned
  /// to all roles.
  ///
  /// Requires that [device] is part of this protocol.
  void removeDeviceAssignment(PrimaryDeviceConfiguration device) {
    assignedDevices ??= {};
    assert(
      primaryDevices.contains(device),
      "The device configuration is not part of this protocol.",
    );

    assignedDevices!.remove(device.roleName);
  }

  /// Add expected participant data to be input by users.
  ///
  /// Returns true if the [expectedData] has been added; false in case the same
  /// [expectedData] has already been added before.
  bool addExpectedParticipantData(ExpectedParticipantData expectedData) =>
      expectedParticipantData!.add(expectedData);

  /// Remove expected participant data to be input by users.
  ///
  /// Returns true if the [expectedData] has been removed;
  /// false if it is not included in this configuration.
  bool removeExpectedParticipantData(ExpectedParticipantData expectedData) =>
      expectedParticipantData!.remove(expectedData);

  /// Add any application-specific [value] with a [key] to this protocol.
  void addApplicationData(String key, dynamic value) {
    applicationData ??= {};
    applicationData![key] = value;
  }

  /// Get any application-specific data with a [key].
  dynamic getApplicationData(String key) => applicationData![key];

  /// Remove any application-specific data with a [key].
  dynamic removeApplicationData(String key) => applicationData!.remove(key);

  Map<String, dynamic> toJson() => _$StudyProtocolToJson(this);
  factory StudyProtocol.fromJson(Map<String, dynamic> json) =>
      _$StudyProtocolFromJson(json);

  @override
  String toString() => '$runtimeType - name: $name, ownerId: $ownerId';
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DeviceConnection {
  String? roleName;
  String? connectedToRoleName;

  DeviceConnection([this.roleName, this.connectedToRoleName]) : super();

  factory DeviceConnection.fromJson(Map<String, dynamic> json) =>
      _$DeviceConnectionFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceConnectionToJson(this);
}
