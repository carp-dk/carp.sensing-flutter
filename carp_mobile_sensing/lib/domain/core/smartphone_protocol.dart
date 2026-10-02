/*
 * Copyright 2018-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Adds the CAMS-specific fields to a [SmartphoneStudyProtocol] and a
/// [SmartphoneDeployment].
///
/// The fields (study description, data endpoint, privacy schema, etc.) are kept
/// in a [SmartphoneApplicationData] object, which is serialized as the
/// `applicationData` of the carp_core [StudyProtocol] / [PrimaryDeviceDeployment].
/// This way a CAMS protocol can be stored and deployed by any CARP backend.
mixin SmartphoneProtocolExtension {
  SmartphoneApplicationData _data = SmartphoneApplicationData();

  /// The [SmartphoneApplicationData] as JSON.
  ///
  /// Setting it to `null` resets all CAMS-specific fields.
  Map<String, dynamic>? get applicationData => _data.toJson();

  set applicationData(Map<String, dynamic>? data) => _data = (data != null)
      ? SmartphoneApplicationData.fromJson(data)
      : SmartphoneApplicationData();

  /// The version tag of the study protocol snapshot.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get protocolVersionTag => _data.protocolVersionTag;

  /// The API level used by this study protocol.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get protocolApiLevel => _data.protocolApiLevel;

  /// The name of the application which will execute this protocol.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get applicationName => _data.applicationName;

  /// The description of this study protocol containing the title, description,
  /// purpose, and the responsible researcher for this study.
  @JsonKey(includeFromJson: false, includeToJson: false)
  StudyDescription? get studyDescription => _data.studyDescription;
  set studyDescription(StudyDescription? description) =>
      _data.studyDescription = description;

  /// The description from [studyDescription], or an empty string if none.
  String get description => studyDescription?.description ?? '';

  /// The PI responsible for this protocol, taken from [studyDescription].
  @JsonKey(includeFromJson: false, includeToJson: false)
  StudyResponsible? get responsible => studyDescription?.responsible;

  /// Where and how to store or upload the data collected in this study.
  ///
  /// If `null`, the data is not stored, but can still be used in the app.
  @JsonKey(includeFromJson: false, includeToJson: false)
  DataEndPoint? get dataEndPoint => _data.dataEndPoint;
  set dataEndPoint(DataEndPoint? dataEndPoint) =>
      _data.dataEndPoint = dataEndPoint;

  /// The name of a [PrivacySchema] to be used for protecting sensitive data.
  ///
  /// Use [PrivacySchema.DEFAULT] for the default, built-in schema.
  /// If not specified, no privacy schema is used and data is saved as collected.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get privacySchemaName => _data.privacySchemaName;
  set privacySchemaName(String? name) => _data.privacySchemaName = name;

  /// Adds app-specific [value] under [key].
  ///
  /// Use this to store your own data in the protocol. It is copied to all
  /// deployments of the protocol and can be read with [getApplicationData].
  void addApplicationData(String key, dynamic value) {
    _data.applicationData ??= {};
    _data.applicationData?[key] = value;
  }

  /// The app-specific value stored under [key], or `null` if none.
  dynamic getApplicationData(String key) => _data.applicationData?[key];

  void removeApplicationData(String key) => _data.applicationData?.remove(key);
}

/// The CAMS-specific data of a [SmartphoneStudyProtocol] or [SmartphoneDeployment].
///
/// Serialized as the `applicationData` of the carp_core protocol and deployment.
/// You normally access these fields through [SmartphoneProtocolExtension].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SmartphoneApplicationData {
  /// The version tag of the study protocol snapshot.
  /// This is typically set by the CAWS backend when a protocol is uploaded.
  String? protocolVersionTag;

  /// The API level used by this study protocol.
  /// This reflects the version of the CARP Mobile Sensing framework as set in
  /// the pubspec.yaml file.
  String? protocolApiLevel = SmartphoneStudyProtocol.CAMS_PROTOCOL_API_LEVEL;

  /// The name of the application which will execute this protocol. This is the
  /// Flutter application name as specified in the pubspec.yaml file of the app
  /// executing this protocol. This is used to filter invitations to studies from
  /// CAWS.
  String? applicationName;

  /// The description of this study protocol containing the title, description,
  /// purpose, and the responsible researcher for this study.
  StudyDescription? studyDescription;

  /// Where and how to store or upload the data collected in this study.
  ///
  /// If `null`, the data is not stored, but can still be used in the app.
  DataEndPoint? dataEndPoint;

  /// The name of a [PrivacySchema].
  ///
  /// Use [PrivacySchema.DEFAULT] for the default, built-in privacy schema.
  /// If not specified, no privacy schema is used and data is saved as collected.
  String? privacySchemaName;

  /// Application-specific data to be stored as part of the study protocol
  /// which will be included in all deployments of this study protocol.
  Map<String, dynamic>? applicationData;

  SmartphoneApplicationData({
    this.applicationName,
    this.studyDescription,
    this.dataEndPoint,
    this.privacySchemaName,
    this.applicationData,
  }) : super();

  factory SmartphoneApplicationData.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneApplicationDataFromJson(json);
  Map<String, dynamic> toJson() => _$SmartphoneApplicationDataToJson(this);
}

/// A study protocol that runs on a smartphone.
///
/// A protocol says *what* to measure and *when*. It holds the primary device
/// ([PrimaryDeviceConfiguration]) that collects data, the connected devices
/// ([DeviceConfiguration]), and the task controls ([TaskControl]) that pair a
/// trigger with a task. CAMS adds a [studyDescription], a [dataEndPoint] that
/// says where data goes, and a [privacySchemaName].
/// You build one in code (or load it from JSON) and add it with
/// [SmartPhoneClientManager.addStudyFromProtocol].
///
/// Key points:
///  * The first device added with [addPrimaryDevice] is the phone running the study.
///  * [addTaskControl] pairs one [TriggerConfiguration] with one [TaskConfiguration].
///  * Adding a device also adds a [MonitoringTask] that collects errors and
///    triggered and completed tasks from that device.
///  * Serializes to JSON, so the same protocol can be deployed from a server.
///  * [SmartphoneStudyProtocol.local] creates a ready-to-use local protocol.
///
/// See also [SmartphoneDeployment], which is created from a protocol, and
/// [SmartphoneDeploymentExecutor], which runs it.
///
/// ```dart
/// // Create a study protocol storing data in a local SQLite database.
/// SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
///   ownerId: 'abc@dtu.dk',
///   name: 'Track patient movement',
///   dataEndPoint: SQLiteDataEndPoint(),
/// );
///
/// // Define which devices are used for data collection.
/// // In this case, its only this smartphone.
/// Smartphone phone = Smartphone();
/// protocol.addPrimaryDevice(phone);
///
/// // Automatically collect step count, ambient light, screen activity, and
/// // battery level. Sampling starts immediately.
/// protocol.addTaskControl(
///   ImmediateTrigger(),
///   BackgroundTask(measures: [
///     Measure(type: SensorSamplingPackage.STEP_COUNT),
///     Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
///     Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
///     Measure(type: DeviceSamplingPackage.BATTERY_STATE),
///   ]),
///   phone,
/// );
/// ```
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SmartphoneStudyProtocol extends StudyProtocol
    with SmartphoneProtocolExtension {
  /// The API level used by study protocols.
  /// This reflects the **major** version of the CARP Mobile Sensing framework
  /// as set in the pubspec.yaml file.
  static const String CAMS_PROTOCOL_API_LEVEL = '2.0';

  // These static app names can be used as [applicationName] in the protocol.
  // It is the name of the Flutter app as specified in the pubspec.yaml file.

  /// The [applicationName] of the example app included in CAMS.
  static const String CAMS_EXAMPLE_APP_NAME = 'carp_mobile_sensing_example';

  /// The [applicationName] of the CARP Mobile Sensing demo app.
  static const String CAMS_DEMO_APP_NAME = 'carp_mobile_sensing_app';

  /// The [applicationName] of the Pulmonary Monitor demo app.
  static const String PULMONARY_MONITOR_APP_NAME = 'pulmonary_monitor_app';

  /// The [applicationName] of the CARP Studies app.
  static const String CARP_STUDY_APP_NAME = 'carp_study_app';

  /// Sets the description in [studyDescription].
  ///
  /// Creates a [StudyDescription] titled with [name] if there is none.
  @override
  set description(String? description) {
    if (studyDescription != null) {
      studyDescription!.description = description;
    } else {
      studyDescription = StudyDescription(
        title: name,
        description: description,
      );
    }
  }

  /// Creates a new [SmartphoneStudyProtocol] with a unique [name].
  ///
  /// The [ownerId] is typically the ID of the user uploading this protocol to CAWS.
  /// If [ownerId] is not specified, a UUID will be generated.
  /// Note, however, that this will be replaced with the ID of the user uploading
  /// the protocol, if uploaded to CAWS.
  ///
  /// The [applicationName] is the name of the application which will execute
  /// this protocol. This is the Flutter application name as specified in the
  /// pubspec.yaml file of the app executing this protocol. This is used to
  /// filter invitations to studies from CAWS.
  ///
  /// The [studyDescription] contains the title, description, purpose, and the
  /// responsible researcher for this study.
  ///
  /// The [dataEndPoint] specifies where and how to store or upload the data
  /// collected in this study. If `null`, the data is not stored, but can still
  /// be used in the app.
  ///
  /// The [privacySchemaName] is the name of a [PrivacySchema] to be used for
  /// protecting sensitive data. Use [PrivacySchema.DEFAULT] for the default,
  /// built-in schema. If not specified, no privacy schema is used and data is
  /// saved as collected.
  SmartphoneStudyProtocol({
    String? ownerId,
    required super.name,
    String? applicationName,
    StudyDescription? studyDescription,
    DataEndPoint? dataEndPoint,
    String? privacySchemaName,
  }) : super(
         ownerId: ownerId ?? const Uuid().v4(),
         description: studyDescription?.description ?? '',
       ) {
    // add the smartphone specific protocol data as application-specific data
    _data = SmartphoneApplicationData(
      applicationName: applicationName,
      studyDescription: studyDescription,
      dataEndPoint: dataEndPoint,
      privacySchemaName: privacySchemaName,
    );
  }

  /// Creates a [SmartphoneStudyProtocol] for local data collection
  /// using this smartphone as the primary device and with just one
  /// participant role called "Participant".
  ///
  /// The data is stored locally using a [SQLiteDataEndPoint].
  ///
  /// This protocol also includes a default background sampling task of
  /// collecting device and application information every time sensing starts.
  ///
  /// Optionally, a list of [measures] can be provided which will be collected
  /// as part of a default background sampling task by this smartphone.
  /// Additional measures can be added later using [addTaskControl], if needed.
  factory SmartphoneStudyProtocol.local({
    String? name,
    List<Measure>? measures,
  }) {
    var protocol =
        SmartphoneStudyProtocol(
            name: name ?? 'Local Smartphone Study Protocol',
            dataEndPoint: SQLiteDataEndPoint(),
          )
          ..addPrimaryDevice(Smartphone())
          ..addParticipantRole(ParticipantRole('Participant'));

    // collect device and application information every time sensing starts
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION),
          Measure(type: DeviceSamplingPackage.APPLICATION_INFORMATION),
        ],
      ),
    );

    // add measures, if any, as a background sampling task
    if (measures != null && measures.isNotEmpty) {
      protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: measures),
      );
    }
    return protocol;
  }

  /// Adds [primaryDevice] and a [MonitoringTask] for it.
  ///
  /// Always returns `true`.
  @override
  bool addPrimaryDevice(PrimaryDeviceConfiguration primaryDevice) {
    super.addPrimaryDevice(primaryDevice);
    _addSamplingTaskControl(primaryDevice);

    return true;
  }

  /// Adds [device] as connected to [primaryDevice], plus a [MonitoringTask]
  /// for it.
  ///
  /// Always returns `true`.
  @override
  bool addConnectedDevice(
    DeviceConfiguration device,
    PrimaryDeviceConfiguration primaryDevice,
  ) {
    super.addConnectedDevice(device, primaryDevice);
    _addSamplingTaskControl(device);

    return true;
  }

  /// Add the trigger, task completed, and error measures to the protocol
  /// since CAMS always collects and upload this data from any device.
  void _addSamplingTaskControl(DeviceConfiguration device) {
    var measures = [
      Measure(type: CarpDataTypes.ERROR),
      Measure(type: CarpDataTypes.TRIGGERED_TASK),
      Measure(type: CarpDataTypes.COMPLETED_TASK),
    ];

    addTaskControl(
      NoOpTrigger(),
      MonitoringTask(name: "Monitoring ${device.roleName}", measures: measures),
      device,
    );
  }

  /// The primary or connected device with [roleName], or `null` if not found.
  DeviceConfiguration? getDeviceByRoleName(String roleName) {
    for (var device in devices) {
      if (device.roleName == roleName) {
        return device;
      }
    }
    return null;
  }

  factory SmartphoneStudyProtocol.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneStudyProtocolFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneStudyProtocolToJson(this);
}
