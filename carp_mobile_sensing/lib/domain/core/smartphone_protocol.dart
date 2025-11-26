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
  /// This reflects the version of the CARP Mobile Sensing framework as set in
  /// the pubspec.yaml file.
  static const String CAMS_PROTOCOL_API_LEVEL = '2.0.0';

  /// Create a new [SmartphoneStudyProtocol].
  ///
  /// Provide a unique descriptive [name] for the protocol.
  ///
  /// If [ownerId] is not specified, a UUID will be generated.
  /// Note, however, that this will be replaced with the ID of the user uploading the protocol,
  /// if uploaded to CAWS.
  SmartphoneStudyProtocol({
    String? ownerId,
    required super.name,
    StudyDescription? studyDescription,
    DataEndPoint? dataEndPoint,
    String? privacySchemaName,
  }) : super(
         ownerId: ownerId ?? const Uuid().v1,
         description: studyDescription?.description ?? '',
       ) {
    // add the smartphone specific protocol data as application-specific data
    _data = SmartphoneApplicationData(
      studyDescription: studyDescription,
      dataEndPoint: dataEndPoint,
      privacySchemaName: privacySchemaName,
    );
  }

  @override
  bool addPrimaryDevice(PrimaryDeviceConfiguration primaryDevice) {
    super.addPrimaryDevice(primaryDevice);
    _addSamplingTaskControl(primaryDevice);

    return true;
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

  @override
  bool addConnectedDevice(
    DeviceConfiguration device,
    PrimaryDeviceConfiguration primaryDevice,
  ) {
    super.addConnectedDevice(device, primaryDevice);
    _addSamplingTaskControl(device);

    return true;
  }

  /// Add the trigger, task completed, error, and heartbeat measures to the protocol
  /// since CAMS always collects and upload this data from any device.
  /// If the device is a primary device, also add the [CompletedAppTask] measure.
  void _addSamplingTaskControl(DeviceConfiguration device) {
    var measures = [
      Measure(type: CarpDataTypes.ERROR_TYPE_NAME),
      Measure(type: CarpDataTypes.TRIGGERED_TASK_TYPE_NAME),
      Measure(type: CarpDataTypes.COMPLETED_TASK_TYPE_NAME),
      Measure(type: CamsDataTypes.HEARTBEAT_TYPE_NAME),
    ];
    // issue #521
    if (device is PrimaryDeviceConfiguration) {
      // For primary devices, also add the [CompletedAppTask] measure
      measures.add(Measure(type: CamsDataTypes.COMPLETED_APP_TASK_TYPE_NAME));
    }

    addTaskControl(NoOpTrigger(), MonitoringTask(measures: measures), device);
  }

  factory SmartphoneStudyProtocol.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneStudyProtocolFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneStudyProtocolToJson(this);
}
