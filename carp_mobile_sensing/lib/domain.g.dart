// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmartphoneApplicationData _$SmartphoneApplicationDataFromJson(
  Map<String, dynamic> json,
) =>
    SmartphoneApplicationData(
        applicationName: json['applicationName'] as String?,
        studyDescription: json['studyDescription'] == null
            ? null
            : StudyDescription.fromJson(
                json['studyDescription'] as Map<String, dynamic>,
              ),
        dataEndPoint: json['dataEndPoint'] == null
            ? null
            : DataEndPoint.fromJson(
                json['dataEndPoint'] as Map<String, dynamic>,
              ),
        privacySchemaName: json['privacySchemaName'] as String?,
        applicationData: json['applicationData'] as Map<String, dynamic>?,
      )
      ..protocolVersionTag = json['protocolVersionTag'] as String?
      ..protocolApiLevel = json['protocolApiLevel'] as String?;

Map<String, dynamic> _$SmartphoneApplicationDataToJson(
  SmartphoneApplicationData instance,
) => <String, dynamic>{
  'protocolVersionTag': ?instance.protocolVersionTag,
  'protocolApiLevel': ?instance.protocolApiLevel,
  'applicationName': ?instance.applicationName,
  'studyDescription': ?instance.studyDescription?.toJson(),
  'dataEndPoint': ?instance.dataEndPoint?.toJson(),
  'privacySchemaName': ?instance.privacySchemaName,
  'applicationData': ?instance.applicationData,
};

SmartphoneStudyProtocol _$SmartphoneStudyProtocolFromJson(
  Map<String, dynamic> json,
) =>
    SmartphoneStudyProtocol(
        ownerId: json['ownerId'] as String?,
        name: json['name'] as String,
      )
      ..applicationData = json['applicationData'] as Map<String, dynamic>?
      ..id = json['id'] as String
      ..createdOn = DateTime.parse(json['createdOn'] as String)
      ..version = (json['version'] as num).toInt()
      ..participantRoles = (json['participantRoles'] as List<dynamic>?)
          ?.map((e) => ParticipantRole.fromJson(e as Map<String, dynamic>))
          .toSet()
      ..primaryDevices = (json['primaryDevices'] as List<dynamic>)
          .map(
            (e) => PrimaryDeviceConfiguration<DeviceRegistration>.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toSet()
      ..connectedDevices = (json['connectedDevices'] as List<dynamic>?)
          ?.map(
            (e) => DeviceConfiguration<DeviceRegistration>.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toSet()
      ..connections = (json['connections'] as List<dynamic>?)
          ?.map((e) => DeviceConnection.fromJson(e as Map<String, dynamic>))
          .toList()
      ..assignedDevices = (json['assignedDevices'] as Map<String, dynamic>?)
          ?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toSet(),
            ),
          )
      ..tasks = (json['tasks'] as List<dynamic>)
          .map((e) => TaskConfiguration.fromJson(e as Map<String, dynamic>))
          .toSet()
      ..triggers = (json['triggers'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          TriggerConfiguration.fromJson(e as Map<String, dynamic>),
        ),
      )
      ..taskControls = (json['taskControls'] as List<dynamic>)
          .map((e) => TaskControl.fromJson(e as Map<String, dynamic>))
          .toSet()
      ..expectedParticipantData =
          (json['expectedParticipantData'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ExpectedParticipantData.fromJson(e as Map<String, dynamic>),
              )
              .toSet();

Map<String, dynamic> _$SmartphoneStudyProtocolToJson(
  SmartphoneStudyProtocol instance,
) => <String, dynamic>{
  'applicationData': ?instance.applicationData,
  'id': instance.id,
  'createdOn': instance.createdOn.toIso8601String(),
  'version': instance.version,
  'ownerId': instance.ownerId,
  'name': instance.name,
  'participantRoles': ?instance.participantRoles
      ?.map((e) => e.toJson())
      .toList(),
  'primaryDevices': instance.primaryDevices.map((e) => e.toJson()).toList(),
  'connectedDevices': ?instance.connectedDevices
      ?.map((e) => e.toJson())
      .toList(),
  'connections': ?instance.connections?.map((e) => e.toJson()).toList(),
  'assignedDevices': ?instance.assignedDevices?.map(
    (k, e) => MapEntry(k, e.toList()),
  ),
  'tasks': instance.tasks.map((e) => e.toJson()).toList(),
  'triggers': instance.triggers.map((k, e) => MapEntry(k, e.toJson())),
  'taskControls': instance.taskControls.map((e) => e.toJson()).toList(),
  'expectedParticipantData': ?instance.expectedParticipantData
      ?.map((e) => e.toJson())
      .toList(),
};

StudyDescription _$StudyDescriptionFromJson(Map<String, dynamic> json) =>
    StudyDescription(
      title: json['title'] as String,
      description: json['description'] as String?,
      purpose: json['purpose'] as String?,
      studyDescriptionUrl: json['studyDescriptionUrl'] as String?,
      privacyPolicyUrl: json['privacyPolicyUrl'] as String?,
      responsible: json['responsible'] == null
          ? null
          : StudyResponsible.fromJson(
              json['responsible'] as Map<String, dynamic>,
            ),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$StudyDescriptionToJson(StudyDescription instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'title': instance.title,
      'description': ?instance.description,
      'purpose': ?instance.purpose,
      'studyDescriptionUrl': ?instance.studyDescriptionUrl,
      'privacyPolicyUrl': ?instance.privacyPolicyUrl,
      'responsible': ?instance.responsible?.toJson(),
    };

StudyResponsible _$StudyResponsibleFromJson(Map<String, dynamic> json) =>
    StudyResponsible(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String?,
      email: json['email'] as String?,
      affiliation: json['affiliation'] as String?,
      address: json['address'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$StudyResponsibleToJson(StudyResponsible instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'id': instance.id,
      'name': instance.name,
      'title': ?instance.title,
      'email': ?instance.email,
      'address': ?instance.address,
      'affiliation': ?instance.affiliation,
    };

DataEndPoint _$DataEndPointFromJson(Map<String, dynamic> json) => DataEndPoint(
  type: json['type'] as String,
  dataFormat: json['dataFormat'] as String? ?? NameSpace.CARP,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$DataEndPointToJson(DataEndPoint instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'type': instance.type,
      'dataFormat': instance.dataFormat,
    };

FileDataEndPoint _$FileDataEndPointFromJson(Map<String, dynamic> json) =>
    FileDataEndPoint(
        dataFormat: json['dataFormat'] as String? ?? NameSpace.CARP,
        bufferSize: (json['bufferSize'] as num?)?.toInt() ?? 500 * 1000,
        zip: json['zip'] as bool? ?? true,
        encrypt: json['encrypt'] as bool? ?? false,
        publicKey: json['publicKey'] as String?,
      )
      ..$type = json['__type'] as String?
      ..type = json['type'] as String;

Map<String, dynamic> _$FileDataEndPointToJson(FileDataEndPoint instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'type': instance.type,
      'dataFormat': instance.dataFormat,
      'bufferSize': instance.bufferSize,
      'zip': instance.zip,
      'encrypt': instance.encrypt,
      'publicKey': ?instance.publicKey,
    };

SQLiteDataEndPoint _$SQLiteDataEndPointFromJson(Map<String, dynamic> json) =>
    SQLiteDataEndPoint(
        dataFormat: json['dataFormat'] as String? ?? NameSpace.CARP,
      )
      ..$type = json['__type'] as String?
      ..type = json['type'] as String;

Map<String, dynamic> _$SQLiteDataEndPointToJson(SQLiteDataEndPoint instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'type': instance.type,
      'dataFormat': instance.dataFormat,
    };

PersistentSamplingConfiguration _$PersistentSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => PersistentSamplingConfiguration()
  ..$type = json['__type'] as String?
  ..lastTime = json['lastTime'] == null
      ? null
      : DateTime.parse(json['lastTime'] as String);

Map<String, dynamic> _$PersistentSamplingConfigurationToJson(
  PersistentSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'lastTime': ?instance.lastTime?.toIso8601String(),
};

HistoricSamplingConfiguration _$HistoricSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) =>
    HistoricSamplingConfiguration(
        past: json['past'] == null
            ? null
            : Duration(microseconds: (json['past'] as num).toInt()),
        future: json['future'] == null
            ? null
            : Duration(microseconds: (json['future'] as num).toInt()),
      )
      ..$type = json['__type'] as String?
      ..lastTime = json['lastTime'] == null
          ? null
          : DateTime.parse(json['lastTime'] as String);

Map<String, dynamic> _$HistoricSamplingConfigurationToJson(
  HistoricSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'lastTime': ?instance.lastTime?.toIso8601String(),
  'past': instance.past.inMicroseconds,
  'future': instance.future.inMicroseconds,
};

IntervalSamplingConfiguration _$IntervalSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => IntervalSamplingConfiguration(
  interval: Duration(microseconds: (json['interval'] as num).toInt()),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$IntervalSamplingConfigurationToJson(
  IntervalSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'interval': instance.interval.inMicroseconds,
};

PeriodicSamplingConfiguration _$PeriodicSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => PeriodicSamplingConfiguration(
  interval: Duration(microseconds: (json['interval'] as num).toInt()),
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$PeriodicSamplingConfigurationToJson(
  PeriodicSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'interval': instance.interval.inMicroseconds,
  'duration': instance.duration.inMicroseconds,
};

Smartphone _$SmartphoneFromJson(Map<String, dynamic> json) =>
    Smartphone(
        roleName: json['roleName'] as String? ?? Smartphone.DEFAULT_ROLE_NAME,
      )
      ..$type = json['__type'] as String?
      ..isOptional = json['isOptional'] as bool?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          )
      ..isPrimaryDevice = json['isPrimaryDevice'] as bool;

Map<String, dynamic> _$SmartphoneToJson(Smartphone instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
      'isPrimaryDevice': instance.isPrimaryDevice,
    };

BLEDevice<TRegistration> _$BLEDeviceFromJson<
  TRegistration extends BLEDeviceRegistration
>(Map<String, dynamic> json) =>
    BLEDevice<TRegistration>(
        roleName: json['roleName'] as String,
        isOptional: json['isOptional'] as bool? ?? true,
        serviceUuids: (json['serviceUuids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        namePrefix: json['namePrefix'] as String?,
        minRssi: (json['minRssi'] as num?)?.toInt(),
        allowDuplicates: json['allowDuplicates'] as bool? ?? true,
        timeout: json['timeout'] == null
            ? null
            : Duration(microseconds: (json['timeout'] as num).toInt()),
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$BLEDeviceToJson<
  TRegistration extends BLEDeviceRegistration
>(BLEDevice<TRegistration> instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'roleName': instance.roleName,
  'isOptional': ?instance.isOptional,
  'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'serviceUuids': instance.serviceUuids,
  'namePrefix': ?instance.namePrefix,
  'minRssi': ?instance.minRssi,
  'allowDuplicates': instance.allowDuplicates,
  'timeout': ?instance.timeout?.inMicroseconds,
};

BLEHeartRateDevice _$BLEHeartRateDeviceFromJson(Map<String, dynamic> json) =>
    BLEHeartRateDevice(
        roleName: json['roleName'] as String,
        isOptional: json['isOptional'] as bool? ?? true,
        serviceUuids: (json['serviceUuids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        namePrefix: json['namePrefix'] as String?,
        minRssi: (json['minRssi'] as num?)?.toInt(),
        allowDuplicates: json['allowDuplicates'] as bool? ?? true,
        timeout: json['timeout'] == null
            ? null
            : Duration(microseconds: (json['timeout'] as num).toInt()),
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$BLEHeartRateDeviceToJson(BLEHeartRateDevice instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
      'serviceUuids': instance.serviceUuids,
      'namePrefix': ?instance.namePrefix,
      'minRssi': ?instance.minRssi,
      'allowDuplicates': instance.allowDuplicates,
      'timeout': ?instance.timeout?.inMicroseconds,
    };

ServiceConfiguration<TRegistration> _$ServiceConfigurationFromJson<
  TRegistration extends ServiceRegistration
>(Map<String, dynamic> json) =>
    ServiceConfiguration<TRegistration>(
        roleName: json['roleName'] as String,
        isOptional: json['isOptional'] as bool? ?? true,
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$ServiceConfigurationToJson<
  TRegistration extends ServiceRegistration
>(ServiceConfiguration<TRegistration> instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'roleName': instance.roleName,
  'isOptional': ?instance.isOptional,
  'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
};

HardwareDeviceRegistration _$HardwareDeviceRegistrationFromJson(
  Map<String, dynamic> json,
) => HardwareDeviceRegistration(
  deviceId: json['deviceId'] as String?,
  deviceDisplayName: json['deviceDisplayName'] as String?,
  registrationCreatedOn: json['registrationCreatedOn'] == null
      ? null
      : DateTime.parse(json['registrationCreatedOn'] as String),
  isConnected: json['isConnected'] as bool? ?? false,
  batteryChargingState:
      $enumDecodeNullable(
        _$BatteryChargingStateEnumMap,
        json['batteryChargingState'],
      ) ??
      BatteryChargingState.unknown,
  hardwareName: json['hardwareName'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$HardwareDeviceRegistrationToJson(
  HardwareDeviceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'isConnected': instance.isConnected,
  'batteryChargingState':
      _$BatteryChargingStateEnumMap[instance.batteryChargingState]!,
  'hardwareName': ?instance.hardwareName,
};

const _$BatteryChargingStateEnumMap = {
  BatteryChargingState.unknown: 'unknown',
  BatteryChargingState.full: 'full',
  BatteryChargingState.normal: 'normal',
  BatteryChargingState.low: 'low',
  BatteryChargingState.critical: 'critical',
};

SmartphoneRegistration _$SmartphoneRegistrationFromJson(
  Map<String, dynamic> json,
) =>
    SmartphoneRegistration(
        deviceId: json['deviceId'] as String?,
        deviceDisplayName: json['deviceDisplayName'] as String?,
        registrationCreatedOn: json['registrationCreatedOn'] == null
            ? null
            : DateTime.parse(json['registrationCreatedOn'] as String),
        isConnected: json['isConnected'] as bool? ?? true,
        batteryChargingState:
            $enumDecodeNullable(
              _$BatteryChargingStateEnumMap,
              json['batteryChargingState'],
            ) ??
            BatteryChargingState.unknown,
        hardwareName: json['hardwareName'] as String?,
        platform: json['platform'] as String?,
        deviceName: json['deviceName'] as String?,
        deviceManufacturer: json['deviceManufacturer'] as String?,
        deviceModel: json['deviceModel'] as String?,
        operatingSystem: json['operatingSystem'] as String?,
        sdk: json['sdk'] as String?,
        release: json['release'] as String?,
      )
      ..$type = json['__type'] as String?
      ..hardware = json['hardware'] as String?;

Map<String, dynamic> _$SmartphoneRegistrationToJson(
  SmartphoneRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'isConnected': instance.isConnected,
  'batteryChargingState':
      _$BatteryChargingStateEnumMap[instance.batteryChargingState]!,
  'hardwareName': ?instance.hardwareName,
  'platform': ?instance.platform,
  'hardware': ?instance.hardware,
  'deviceName': ?instance.deviceName,
  'deviceManufacturer': ?instance.deviceManufacturer,
  'deviceModel': ?instance.deviceModel,
  'operatingSystem': ?instance.operatingSystem,
  'sdk': ?instance.sdk,
  'release': ?instance.release,
};

BLEDeviceRegistration _$BLEDeviceRegistrationFromJson(
  Map<String, dynamic> json,
) =>
    BLEDeviceRegistration(
        deviceDisplayName: json['deviceDisplayName'] as String?,
        registrationCreatedOn: json['registrationCreatedOn'] == null
            ? null
            : DateTime.parse(json['registrationCreatedOn'] as String),
        isConnected: json['isConnected'] as bool? ?? false,
        batteryChargingState:
            $enumDecodeNullable(
              _$BatteryChargingStateEnumMap,
              json['batteryChargingState'],
            ) ??
            BatteryChargingState.unknown,
        hardwareName: json['hardwareName'] as String?,
        bleAddress: json['bleAddress'] as String,
        bleName: json['bleName'] as String?,
      )
      ..$type = json['__type'] as String?
      ..deviceId = json['deviceId'] as String;

Map<String, dynamic> _$BLEDeviceRegistrationToJson(
  BLEDeviceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'isConnected': instance.isConnected,
  'batteryChargingState':
      _$BatteryChargingStateEnumMap[instance.batteryChargingState]!,
  'hardwareName': ?instance.hardwareName,
  'bleAddress': instance.bleAddress,
  'bleName': ?instance.bleName,
};

ServiceRegistration _$ServiceRegistrationFromJson(Map<String, dynamic> json) =>
    ServiceRegistration(
      deviceId: json['deviceId'] as String?,
      deviceDisplayName: json['deviceDisplayName'] as String?,
      registrationCreatedOn: json['registrationCreatedOn'] == null
          ? null
          : DateTime.parse(json['registrationCreatedOn'] as String),
      isConnected: json['isConnected'] as bool? ?? false,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$ServiceRegistrationToJson(
  ServiceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'isConnected': instance.isConnected,
};

SmartphoneDeployment _$SmartphoneDeploymentFromJson(
  Map<String, dynamic> json,
) =>
    SmartphoneDeployment(
        studyId: json['studyId'] as String?,
        studyDeploymentId: json['studyDeploymentId'] as String?,
        deviceConfiguration:
            PrimaryDeviceConfiguration<DeviceRegistration>.fromJson(
              json['deviceConfiguration'] as Map<String, dynamic>,
            ),
        registration: DeviceRegistration.fromJson(
          json['registration'] as Map<String, dynamic>,
        ),
        connectedDevices:
            (json['connectedDevices'] as List<dynamic>?)
                ?.map(
                  (e) => DeviceConfiguration<DeviceRegistration>.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toSet() ??
            const {},
        connectedDeviceRegistrations:
            (json['connectedDeviceRegistrations'] as Map<String, dynamic>?)
                ?.map(
                  (k, e) => MapEntry(
                    k,
                    e == null
                        ? null
                        : DeviceRegistration.fromJson(
                            e as Map<String, dynamic>,
                          ),
                  ),
                ) ??
            const {},
        tasks:
            (json['tasks'] as List<dynamic>?)
                ?.map(
                  (e) => TaskConfiguration.fromJson(e as Map<String, dynamic>),
                )
                .toSet() ??
            const {},
        triggers:
            (json['triggers'] as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(
                k,
                TriggerConfiguration.fromJson(e as Map<String, dynamic>),
              ),
            ) ??
            const {},
        taskControls:
            (json['taskControls'] as List<dynamic>?)
                ?.map((e) => TaskControl.fromJson(e as Map<String, dynamic>))
                .toSet() ??
            const {},
        expectedParticipantData:
            (json['expectedParticipantData'] as List<dynamic>?)
                ?.map(
                  (e) => ExpectedParticipantData.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toSet() ??
            const {},
      )
      ..applicationData = json['applicationData'] as Map<String, dynamic>?
      ..deployed = DateTime.parse(json['deployed'] as String)
      ..status = $enumDecode(
        _$StudyDeploymentStatusTypesEnumMap,
        json['status'],
      );

Map<String, dynamic> _$SmartphoneDeploymentToJson(
  SmartphoneDeployment instance,
) => <String, dynamic>{
  'applicationData': ?instance.applicationData,
  'deviceConfiguration': instance.deviceConfiguration.toJson(),
  'registration': instance.registration.toJson(),
  'connectedDevices': instance.connectedDevices.map((e) => e.toJson()).toList(),
  'connectedDeviceRegistrations': instance.connectedDeviceRegistrations.map(
    (k, e) => MapEntry(k, e?.toJson()),
  ),
  'tasks': instance.tasks.map((e) => e.toJson()).toList(),
  'triggers': instance.triggers.map((k, e) => MapEntry(k, e.toJson())),
  'taskControls': instance.taskControls.map((e) => e.toJson()).toList(),
  'expectedParticipantData': instance.expectedParticipantData
      .map((e) => e.toJson())
      .toList(),
  'studyId': ?instance.studyId,
  'studyDeploymentId': instance.studyDeploymentId,
  'deployed': instance.deployed.toIso8601String(),
  'status': _$StudyDeploymentStatusTypesEnumMap[instance.status]!,
};

const _$StudyDeploymentStatusTypesEnumMap = {
  StudyDeploymentStatusTypes.Invited: 'Invited',
  StudyDeploymentStatusTypes.DeployingDevices: 'DeployingDevices',
  StudyDeploymentStatusTypes.Running: 'Running',
  StudyDeploymentStatusTypes.Stopped: 'Stopped',
};

AppTask _$AppTaskFromJson(Map<String, dynamic> json) => AppTask(
  name: json['name'] as String?,
  measures: (json['measures'] as List<dynamic>?)
      ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
      .toList(),
  type: json['type'] as String,
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  instructions: json['instructions'] as String? ?? '',
  minutesToComplete: (json['minutesToComplete'] as num?)?.toInt(),
  expire: json['expire'] == null
      ? null
      : Duration(microseconds: (json['expire'] as num).toInt()),
  notification: json['notification'] as bool? ?? false,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AppTaskToJson(AppTask instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'name': instance.name,
  'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
  'type': instance.type,
  'title': instance.title,
  'description': instance.description,
  'instructions': instance.instructions,
  'minutesToComplete': ?instance.minutesToComplete,
  'expire': ?instance.expire?.inMicroseconds,
  'notification': instance.notification,
};

FunctionTask _$FunctionTaskFromJson(Map<String, dynamic> json) =>
    FunctionTask(
        name: json['name'] as String?,
        description: json['description'] as String?,
      )
      ..$type = json['__type'] as String?
      ..measures = (json['measures'] as List<dynamic>?)
          ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$FunctionTaskToJson(FunctionTask instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'name': instance.name,
      'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
      'description': ?instance.description,
    };

NoOpTrigger _$NoOpTriggerFromJson(Map<String, dynamic> json) => NoOpTrigger()
  ..$type = json['__type'] as String?
  ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$NoOpTriggerToJson(NoOpTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
    };

ImmediateTrigger _$ImmediateTriggerFromJson(Map<String, dynamic> json) =>
    ImmediateTrigger()
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$ImmediateTriggerToJson(ImmediateTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
    };

OneTimeTrigger _$OneTimeTriggerFromJson(Map<String, dynamic> json) =>
    OneTimeTrigger()
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?
      ..triggerTimestamp = json['triggerTimestamp'] == null
          ? null
          : DateTime.parse(json['triggerTimestamp'] as String);

Map<String, dynamic> _$OneTimeTriggerToJson(OneTimeTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'triggerTimestamp': ?instance.triggerTimestamp?.toIso8601String(),
    };

PassiveTrigger _$PassiveTriggerFromJson(Map<String, dynamic> json) =>
    PassiveTrigger()
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$PassiveTriggerToJson(PassiveTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
    };

DelayedTrigger _$DelayedTriggerFromJson(Map<String, dynamic> json) =>
    DelayedTrigger(
        delay: json['delay'] == null
            ? const Duration()
            : Duration(microseconds: (json['delay'] as num).toInt()),
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$DelayedTriggerToJson(DelayedTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'delay': instance.delay.inMicroseconds,
    };

PeriodicTrigger _$PeriodicTriggerFromJson(Map<String, dynamic> json) =>
    PeriodicTrigger(
        period: Duration(microseconds: (json['period'] as num).toInt()),
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$PeriodicTriggerToJson(PeriodicTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'period': instance.period.inMicroseconds,
    };

DateTimeTrigger _$DateTimeTriggerFromJson(Map<String, dynamic> json) =>
    DateTimeTrigger(schedule: DateTime.parse(json['schedule'] as String))
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$DateTimeTriggerToJson(DateTimeTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'schedule': instance.schedule.toIso8601String(),
    };

RecurrentScheduledTrigger _$RecurrentScheduledTriggerFromJson(
  Map<String, dynamic> json,
) =>
    RecurrentScheduledTrigger(
        type:
            $enumDecodeNullable(_$RecurrentTypeEnumMap, json['type']) ??
            RecurrentType.daily,
        time: json['time'] == null
            ? const TimeOfDay()
            : TimeOfDay.fromJson(json['time'] as Map<String, dynamic>),
        end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
        separationCount: (json['separationCount'] as num?)?.toInt() ?? 0,
        maxNumberOfSampling: (json['maxNumberOfSampling'] as num?)?.toInt(),
        dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
        weekOfMonth: (json['weekOfMonth'] as num?)?.toInt(),
        dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$RecurrentScheduledTriggerToJson(
  RecurrentScheduledTrigger instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
  'type': _$RecurrentTypeEnumMap[instance.type]!,
  'time': instance.time.toJson(),
  'end': ?instance.end?.toIso8601String(),
  'separationCount': instance.separationCount,
  'maxNumberOfSampling': ?instance.maxNumberOfSampling,
  'dayOfWeek': ?instance.dayOfWeek,
  'weekOfMonth': ?instance.weekOfMonth,
  'dayOfMonth': ?instance.dayOfMonth,
};

const _$RecurrentTypeEnumMap = {
  RecurrentType.daily: 'daily',
  RecurrentType.weekly: 'weekly',
  RecurrentType.monthly: 'monthly',
};

CronScheduledTrigger _$CronScheduledTriggerFromJson(
  Map<String, dynamic> json,
) => CronScheduledTrigger()
  ..$type = json['__type'] as String?
  ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?
  ..cronExpression = json['cronExpression'] as String;

Map<String, dynamic> _$CronScheduledTriggerToJson(
  CronScheduledTrigger instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
  'cronExpression': instance.cronExpression,
};

SamplingEventTrigger _$SamplingEventTriggerFromJson(
  Map<String, dynamic> json,
) =>
    SamplingEventTrigger(
        measureType: json['measureType'] as String,
        triggerCondition: json['triggerCondition'] == null
            ? null
            : Data.fromJson(json['triggerCondition'] as Map<String, dynamic>),
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$SamplingEventTriggerToJson(
  SamplingEventTrigger instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
  'measureType': instance.measureType,
  'triggerCondition': ?instance.triggerCondition?.toJson(),
};

ConditionalSamplingEventTrigger _$ConditionalSamplingEventTriggerFromJson(
  Map<String, dynamic> json,
) => ConditionalSamplingEventTrigger(measureType: json['measureType'] as String)
  ..$type = json['__type'] as String?
  ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$ConditionalSamplingEventTriggerToJson(
  ConditionalSamplingEventTrigger instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
  'measureType': instance.measureType,
};

ConditionalPeriodicTrigger _$ConditionalPeriodicTriggerFromJson(
  Map<String, dynamic> json,
) =>
    ConditionalPeriodicTrigger(
        period: Duration(microseconds: (json['period'] as num).toInt()),
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$ConditionalPeriodicTriggerToJson(
  ConditionalPeriodicTrigger instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
  'period': instance.period.inMicroseconds,
};

RandomRecurrentTrigger _$RandomRecurrentTriggerFromJson(
  Map<String, dynamic> json,
) =>
    RandomRecurrentTrigger(
        minNumberOfTriggers:
            (json['minNumberOfTriggers'] as num?)?.toInt() ?? 0,
        maxNumberOfTriggers:
            (json['maxNumberOfTriggers'] as num?)?.toInt() ?? 1,
        startTime: json['startTime'] == null
            ? const TimeOfDay(hour: 8)
            : TimeOfDay.fromJson(json['startTime'] as Map<String, dynamic>),
        endTime: json['endTime'] == null
            ? const TimeOfDay(hour: 20)
            : TimeOfDay.fromJson(json['endTime'] as Map<String, dynamic>),
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?
      ..lastTriggerTimestamp = json['lastTriggerTimestamp'] == null
          ? null
          : DateTime.parse(json['lastTriggerTimestamp'] as String);

Map<String, dynamic> _$RandomRecurrentTriggerToJson(
  RandomRecurrentTrigger instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
  'startTime': instance.startTime.toJson(),
  'endTime': instance.endTime.toJson(),
  'minNumberOfTriggers': instance.minNumberOfTriggers,
  'maxNumberOfTriggers': instance.maxNumberOfTriggers,
  'lastTriggerTimestamp': ?instance.lastTriggerTimestamp?.toIso8601String(),
};

AppLifecycleTrigger _$AppLifecycleTriggerFromJson(Map<String, dynamic> json) =>
    AppLifecycleTrigger(
        (json['states'] as List<dynamic>?)
            ?.map((e) => $enumDecode(_$AppLifecycleStateEnumMap, e))
            .toSet(),
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$AppLifecycleTriggerToJson(
  AppLifecycleTrigger instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
  'states': instance.states.map((e) => _$AppLifecycleStateEnumMap[e]!).toList(),
};

const _$AppLifecycleStateEnumMap = {
  AppLifecycleState.detached: 'detached',
  AppLifecycleState.resumed: 'resumed',
  AppLifecycleState.inactive: 'inactive',
  AppLifecycleState.hidden: 'hidden',
  AppLifecycleState.paused: 'paused',
};

UserTaskTrigger _$UserTaskTriggerFromJson(Map<String, dynamic> json) =>
    UserTaskTrigger(
        taskName: json['taskName'] as String,
        triggerCondition:
            $enumDecodeNullable(
              _$UserTaskStateEnumMap,
              json['triggerCondition'],
            ) ??
            UserTaskState.done,
      )
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$UserTaskTriggerToJson(UserTaskTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'taskName': instance.taskName,
      'triggerCondition': _$UserTaskStateEnumMap[instance.triggerCondition]!,
    };

const _$UserTaskStateEnumMap = {
  UserTaskState.initialized: 'initialized',
  UserTaskState.enqueued: 'enqueued',
  UserTaskState.dequeued: 'dequeued',
  UserTaskState.notified: 'notified',
  UserTaskState.started: 'started',
  UserTaskState.canceled: 'canceled',
  UserTaskState.done: 'done',
  UserTaskState.expired: 'expired',
  UserTaskState.undefined: 'undefined',
};

NoUserTaskTrigger _$NoUserTaskTriggerFromJson(Map<String, dynamic> json) =>
    NoUserTaskTrigger(taskName: json['taskName'] as String)
      ..$type = json['__type'] as String?
      ..sourceDeviceRoleName = json['sourceDeviceRoleName'] as String?;

Map<String, dynamic> _$NoUserTaskTriggerToJson(NoUserTaskTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'taskName': instance.taskName,
    };

FileData _$FileDataFromJson(Map<String, dynamic> json) =>
    FileData(
        filename: json['filename'] as String,
        upload: json['upload'] as bool? ?? true,
      )
      ..$type = json['__type'] as String?
      ..path = json['path'] as String?
      ..metadata = (json['metadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      );

Map<String, dynamic> _$FileDataToJson(FileData instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'path': ?instance.path,
  'filename': instance.filename,
  'upload': instance.upload,
  'metadata': ?instance.metadata,
};

CompletedAppTask _$CompletedAppTaskFromJson(Map<String, dynamic> json) =>
    CompletedAppTask(
        taskName: json['taskName'] as String,
        taskType: json['taskType'] as String,
        taskData: json['taskData'] == null
            ? null
            : Data.fromJson(json['taskData'] as Map<String, dynamic>),
      )
      ..$type = json['__type'] as String?
      ..completedAt = DateTime.parse(json['completedAt'] as String);

Map<String, dynamic> _$CompletedAppTaskToJson(CompletedAppTask instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'taskName': instance.taskName,
      'taskData': ?instance.taskData?.toJson(),
      'taskType': instance.taskType,
      'completedAt': instance.completedAt.toIso8601String(),
    };
