/*
 * Copyright 2018-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A mixin holding smartphone-specific data for a [SmartphoneStudyProtocol] and
/// [SmartphoneDeployment].
mixin SmartphoneProtocolExtension {
  SmartphoneApplicationData _data = SmartphoneApplicationData();

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

  String get description => studyDescription?.description ?? '';

  /// The PI responsible for this protocol.
  @JsonKey(includeFromJson: false, includeToJson: false)
  StudyResponsible? get responsible => studyDescription?.responsible;

  /// Specifies where and how to stored or upload the data collected from this
  /// deployment. If `null`, the sensed data is not stored, but may still be
  /// used in the app.
  @JsonKey(includeFromJson: false, includeToJson: false)
  DataEndPoint? get dataEndPoint => _data.dataEndPoint;
  set dataEndPoint(DataEndPoint? dataEndPoint) =>
      _data.dataEndPoint = dataEndPoint;

  /// The name of a [PrivacySchema] to be used for protecting sensitive data.
  ///
  /// Use [PrivacySchema.DEFAULT] for the default, built-in schema.
  /// If  not specified, no privacy schema is used and data is saved as collected.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get privacySchemaName => _data.privacySchemaName;
  set privacySchemaName(String? name) => _data.privacySchemaName = name;

  void addApplicationData(String key, dynamic value) {
    _data.applicationData ??= {};
    _data.applicationData?[key] = value;
  }

  dynamic getApplicationData(String key) => _data.applicationData?[key];

  void removeApplicationData(String key) => _data.applicationData?.remove(key);
}

/// Holds application-specific configuration for a [SmartphoneStudyProtocol].
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

  /// Specifies where and how to stored or upload the data collected from this
  /// deployment. If `null`, the sensed data is not stored, but may still be
  /// used in the app.
  DataEndPoint? dataEndPoint;

  /// The name of a [PrivacySchema].
  ///
  /// Use [PrivacySchema.DEFAULT] for the default, built-in privacy schema.
  /// If  not specified, no privacy schema is used and data is saved as collected.
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

/// A description of how a study is to be executed on a smartphone.
///
/// A study protocol defines how a study is to be executed, defining the type(s) of
/// primary device(s) ([PrimaryDeviceConfiguration]) responsible for
/// aggregating data, the optional devices ([DeviceConfiguration]) connected
/// to them, and the [TaskControl]'s which lead to data collection on
/// said devices.
///
/// A simple study protocol can be specified like this:
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
/// // battery level. Sampling is delaying by 10 seconds.
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

  // The example app included in the CARP Mobile Sensing framework.
  static const String CAMS_EXAMPLE_APP_NAME = 'carp_mobile_sensing_example';

  // The CARP Mobile Sensing framework demo app.
  static const String CAMS_DEMO_APP_NAME = 'carp_mobile_sensing_app';

  // The Pulmonary Monitor demo app.
  static const String PULMONARY_MONITOR_APP_NAME = 'pulmonary_monitor_app';

  // The CARP Studies app.
  static const String CARP_STUDY_APP_NAME = 'carp_study_app';

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

  /// Create a new [SmartphoneStudyProtocol] with a unique [name].
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
  /// The [dataEndPoint] specifies where and how to stored or upload the data
  /// collected from this deployment. If `null`, the sensed data is not stored, but
  /// may still be used in the app.
  ///
  /// The [privacySchemaName] is the name of a [PrivacySchema] to be used for
  /// protecting sensitive data. Use [PrivacySchema.DEFAULT] for the default,
  /// built-in schema. If  not specified, no privacy schema is used and data is
  /// saved as collected.
  SmartphoneStudyProtocol({
    String? ownerId,
    required super.name,
    String? applicationName,
    StudyDescription? studyDescription,
    DataEndPoint? dataEndPoint,
    String? privacySchemaName,
  }) : super(
         ownerId: ownerId ?? const Uuid().v1,
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

  /// Create a [SmartphoneStudyProtocol] for local data collection
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

  @override
  bool addPrimaryDevice(PrimaryDeviceConfiguration primaryDevice) {
    super.addPrimaryDevice(primaryDevice);
    _addSamplingTaskControl(primaryDevice);

    return true;
  }

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

  /// Get the [DeviceConfiguration] for the device with the given [roleName].
  /// This can be either a primary device or a connected device.
  /// Returns `null` if no such device is found.
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
