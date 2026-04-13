// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: json['id'] as String?,
  identity: AccountIdentity.fromJson(json['identity'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'identity': instance.identity.toJson(),
  'id': instance.id,
};

AccountIdentity _$AccountIdentityFromJson(Map<String, dynamic> json) =>
    AccountIdentity()..$type = json['__type'] as String?;

Map<String, dynamic> _$AccountIdentityToJson(AccountIdentity instance) =>
    <String, dynamic>{'__type': ?instance.$type};

EmailAccountIdentity _$EmailAccountIdentityFromJson(
  Map<String, dynamic> json,
) =>
    EmailAccountIdentity(json['emailAddress'] as String)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$EmailAccountIdentityToJson(
  EmailAccountIdentity instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'emailAddress': instance.emailAddress,
};

UsernameAccountIdentity _$UsernameAccountIdentityFromJson(
  Map<String, dynamic> json,
) =>
    UsernameAccountIdentity(json['username'] as String)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$UsernameAccountIdentityToJson(
  UsernameAccountIdentity instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'username': instance.username,
};

ParticipantRole _$ParticipantRoleFromJson(Map<String, dynamic> json) =>
    ParticipantRole(
      json['role'] as String,
      json['isOptional'] as bool? ?? false,
    );

Map<String, dynamic> _$ParticipantRoleToJson(ParticipantRole instance) =>
    <String, dynamic>{'role': instance.role, 'isOptional': instance.isOptional};

ExpectedParticipantData _$ExpectedParticipantDataFromJson(
  Map<String, dynamic> json,
) => ExpectedParticipantData(
  attribute: json['attribute'] == null
      ? null
      : ParticipantAttribute.fromJson(
          json['attribute'] as Map<String, dynamic>,
        ),
  assignedTo: json['assignedTo'] == null
      ? null
      : AssignedTo.fromJson(json['assignedTo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ExpectedParticipantDataToJson(
  ExpectedParticipantData instance,
) => <String, dynamic>{
  'attribute': ?instance.attribute?.toJson(),
  'assignedTo': instance.assignedTo.toJson(),
};

ParticipantAttribute _$ParticipantAttributeFromJson(
  Map<String, dynamic> json,
) =>
    ParticipantAttribute(inputDataType: json['inputDataType'] as String)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$ParticipantAttributeToJson(
  ParticipantAttribute instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'inputDataType': instance.inputDataType,
};

AssignedTo _$AssignedToFromJson(Map<String, dynamic> json) => AssignedTo(
  roleNames: (json['roleNames'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toSet(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AssignedToToJson(AssignedTo instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleNames': ?instance.roleNames?.toList(),
    };

Measure _$MeasureFromJson(Map<String, dynamic> json) =>
    Measure(type: json['type'] as String)
      ..$type = json['__type'] as String?
      ..overrideSamplingConfiguration =
          json['overrideSamplingConfiguration'] == null
          ? null
          : SamplingConfiguration.fromJson(
              json['overrideSamplingConfiguration'] as Map<String, dynamic>,
            );

Map<String, dynamic> _$MeasureToJson(Measure instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'type': instance.type,
  'overrideSamplingConfiguration': ?instance.overrideSamplingConfiguration
      ?.toJson(),
};

TaskConfiguration _$TaskConfigurationFromJson(Map<String, dynamic> json) =>
    TaskConfiguration(
      name: json['name'] as String?,
      description: json['description'] as String?,
      measures: (json['measures'] as List<dynamic>?)
          ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$TaskConfigurationToJson(TaskConfiguration instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'name': instance.name,
      'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
      'description': ?instance.description,
    };

MonitoringTask _$MonitoringTaskFromJson(Map<String, dynamic> json) =>
    MonitoringTask(
      name: json['name'] as String?,
      description: json['description'] as String?,
      measures: (json['measures'] as List<dynamic>?)
          ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MonitoringTaskToJson(MonitoringTask instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'name': instance.name,
      'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
      'description': ?instance.description,
    };

BackgroundTask _$BackgroundTaskFromJson(Map<String, dynamic> json) =>
    BackgroundTask(
      name: json['name'] as String?,
      description: json['description'] as String?,
      measures: (json['measures'] as List<dynamic>?)
          ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
          .toList(),
      duration: _$IsoDurationFromJson(json['duration'] as String?),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$BackgroundTaskToJson(BackgroundTask instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'name': instance.name,
      'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
      'description': ?instance.description,
      'duration': ?_$IsoDurationToJson(instance.duration),
    };

CustomProtocolTask _$CustomProtocolTaskFromJson(Map<String, dynamic> json) =>
    CustomProtocolTask(
        name: json['name'] as String?,
        description: json['description'] as String?,
        studyProtocol: json['studyProtocol'] as String,
      )
      ..$type = json['__type'] as String?
      ..measures = (json['measures'] as List<dynamic>?)
          ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$CustomProtocolTaskToJson(CustomProtocolTask instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'name': instance.name,
      'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
      'description': ?instance.description,
      'studyProtocol': instance.studyProtocol,
    };

WebTask _$WebTaskFromJson(Map<String, dynamic> json) => WebTask(
  name: json['name'] as String?,
  description: json['description'] as String?,
  measures: (json['measures'] as List<dynamic>?)
      ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
      .toList(),
  url: json['url'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$WebTaskToJson(WebTask instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'name': instance.name,
  'measures': ?instance.measures?.map((e) => e.toJson()).toList(),
  'description': ?instance.description,
  'url': instance.url,
};

TaskControl _$TaskControlFromJson(Map<String, dynamic> json) =>
    TaskControl(
        triggerId: (json['triggerId'] as num).toInt(),
        control:
            $enumDecodeNullable(_$ControlEnumMap, json['control']) ??
            Control.Start,
      )
      ..taskName = json['taskName'] as String
      ..destinationDeviceRoleName = json['destinationDeviceRoleName'] as String?
      ..hasBeenScheduledUntil = json['hasBeenScheduledUntil'] == null
          ? null
          : DateTime.parse(json['hasBeenScheduledUntil'] as String);

Map<String, dynamic> _$TaskControlToJson(
  TaskControl instance,
) => <String, dynamic>{
  'triggerId': instance.triggerId,
  'taskName': instance.taskName,
  'destinationDeviceRoleName': ?instance.destinationDeviceRoleName,
  'control': _$ControlEnumMap[instance.control]!,
  'hasBeenScheduledUntil': ?instance.hasBeenScheduledUntil?.toIso8601String(),
};

const _$ControlEnumMap = {Control.Start: 'Start', Control.Stop: 'Stop'};

DeviceConfiguration<TRegistration> _$DeviceConfigurationFromJson<
  TRegistration extends DeviceRegistration
>(Map<String, dynamic> json) =>
    DeviceConfiguration<TRegistration>(
        roleName: json['roleName'] as String,
        isOptional: json['isOptional'] as bool?,
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$DeviceConfigurationToJson<
  TRegistration extends DeviceRegistration
>(DeviceConfiguration<TRegistration> instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'roleName': instance.roleName,
  'isOptional': ?instance.isOptional,
  'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
};

DefaultDeviceConfiguration _$DefaultDeviceConfigurationFromJson(
  Map<String, dynamic> json,
) =>
    DefaultDeviceConfiguration(
        roleName: json['roleName'] as String,
        isOptional: json['isOptional'] as bool?,
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$DefaultDeviceConfigurationToJson(
  DefaultDeviceConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'roleName': instance.roleName,
  'isOptional': ?instance.isOptional,
  'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
};

PrimaryDeviceConfiguration<TRegistration> _$PrimaryDeviceConfigurationFromJson<
  TRegistration extends DeviceRegistration
>(Map<String, dynamic> json) =>
    PrimaryDeviceConfiguration<TRegistration>(
        roleName: json['roleName'] as String,
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

Map<String, dynamic> _$PrimaryDeviceConfigurationToJson<
  TRegistration extends DeviceRegistration
>(PrimaryDeviceConfiguration<TRegistration> instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'roleName': instance.roleName,
  'isOptional': ?instance.isOptional,
  'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'isPrimaryDevice': instance.isPrimaryDevice,
};

CustomProtocolDevice _$CustomProtocolDeviceFromJson(
  Map<String, dynamic> json,
) =>
    CustomProtocolDevice(
        roleName:
            json['roleName'] as String? ??
            CustomProtocolDevice.DEFAULT_ROLE_NAME,
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

Map<String, dynamic> _$CustomProtocolDeviceToJson(
  CustomProtocolDevice instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'roleName': instance.roleName,
  'isOptional': ?instance.isOptional,
  'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'isPrimaryDevice': instance.isPrimaryDevice,
};

DeviceRegistration _$DeviceRegistrationFromJson(Map<String, dynamic> json) =>
    DeviceRegistration(
      deviceId: json['deviceId'] as String?,
      deviceDisplayName: json['deviceDisplayName'] as String?,
      registrationCreatedOn: json['registrationCreatedOn'] == null
          ? null
          : DateTime.parse(json['registrationCreatedOn'] as String),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$DeviceRegistrationToJson(DeviceRegistration instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'deviceId': instance.deviceId,
      'deviceDisplayName': ?instance.deviceDisplayName,
      'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
    };

DefaultDeviceRegistration _$DefaultDeviceRegistrationFromJson(
  Map<String, dynamic> json,
) => DefaultDeviceRegistration(
  deviceId: json['deviceId'] as String?,
  deviceDisplayName: json['deviceDisplayName'] as String?,
  registrationCreatedOn: json['registrationCreatedOn'] == null
      ? null
      : DateTime.parse(json['registrationCreatedOn'] as String),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$DefaultDeviceRegistrationToJson(
  DefaultDeviceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
};

MACAddressDeviceRegistration _$MACAddressDeviceRegistrationFromJson(
  Map<String, dynamic> json,
) => MACAddressDeviceRegistration(
  deviceId: json['deviceId'] as String?,
  deviceDisplayName: json['deviceDisplayName'] as String?,
  registrationCreatedOn: json['registrationCreatedOn'] == null
      ? null
      : DateTime.parse(json['registrationCreatedOn'] as String),
  macAddress: json['macAddress'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MACAddressDeviceRegistrationToJson(
  MACAddressDeviceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'macAddress': instance.macAddress,
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

PersonalComputer _$PersonalComputerFromJson(Map<String, dynamic> json) =>
    PersonalComputer(
        roleName:
            json['roleName'] as String? ?? PersonalComputer.DEFAULT_ROLE_NAME,
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

Map<String, dynamic> _$PersonalComputerToJson(PersonalComputer instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
      'isPrimaryDevice': instance.isPrimaryDevice,
    };

PersonalComputerRegistration _$PersonalComputerRegistrationFromJson(
  Map<String, dynamic> json,
) => PersonalComputerRegistration(
  deviceId: json['deviceId'] as String?,
  deviceDisplayName: json['deviceDisplayName'] as String?,
  registrationCreatedOn: json['registrationCreatedOn'] == null
      ? null
      : DateTime.parse(json['registrationCreatedOn'] as String),
  platform: json['platform'] as String?,
  computerName: json['computerName'] as String?,
  memorySize: (json['memorySize'] as num?)?.toInt(),
  deviceModel: json['deviceModel'] as String?,
  operatingSystem: json['operatingSystem'] as String?,
  version: json['version'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$PersonalComputerRegistrationToJson(
  PersonalComputerRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'platform': ?instance.platform,
  'computerName': ?instance.computerName,
  'memorySize': ?instance.memorySize,
  'deviceModel': ?instance.deviceModel,
  'operatingSystem': ?instance.operatingSystem,
  'version': ?instance.version,
};

WebBrowser _$WebBrowserFromJson(Map<String, dynamic> json) =>
    WebBrowser(
        roleName: json['roleName'] as String? ?? WebBrowser.DEFAULT_ROLE_NAME,
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

Map<String, dynamic> _$WebBrowserToJson(WebBrowser instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
      'isPrimaryDevice': instance.isPrimaryDevice,
    };

WebBrowserRegistration _$WebBrowserRegistrationFromJson(
  Map<String, dynamic> json,
) => WebBrowserRegistration(
  deviceId: json['deviceId'] as String?,
  deviceDisplayName: json['deviceDisplayName'] as String?,
  registrationCreatedOn: json['registrationCreatedOn'] == null
      ? null
      : DateTime.parse(json['registrationCreatedOn'] as String),
  browserName: json['browserName'] as String?,
  deviceMemory: (json['deviceMemory'] as num?)?.toInt(),
  language: json['language'] as String?,
  vendor: json['vendor'] as String?,
  maxTouchPoints: (json['maxTouchPoints'] as num?)?.toInt(),
  hardwareConcurrency: (json['hardwareConcurrency'] as num?)?.toInt(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$WebBrowserRegistrationToJson(
  WebBrowserRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'browserName': ?instance.browserName,
  'deviceMemory': ?instance.deviceMemory,
  'language': ?instance.language,
  'vendor': ?instance.vendor,
  'maxTouchPoints': ?instance.maxTouchPoints,
  'hardwareConcurrency': ?instance.hardwareConcurrency,
};

AltBeacon _$AltBeaconFromJson(Map<String, dynamic> json) =>
    AltBeacon(roleName: json['roleName'] as String? ?? 'Beacon')
      ..$type = json['__type'] as String?
      ..isOptional = json['isOptional'] as bool?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$AltBeaconToJson(AltBeacon instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'roleName': instance.roleName,
  'isOptional': ?instance.isOptional,
  'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration?.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
};

AltBeaconDeviceRegistration _$AltBeaconDeviceRegistrationFromJson(
  Map<String, dynamic> json,
) => AltBeaconDeviceRegistration(
  deviceId: json['deviceId'] as String?,
  deviceDisplayName: json['deviceDisplayName'] as String?,
  registrationCreatedOn: json['registrationCreatedOn'] == null
      ? null
      : DateTime.parse(json['registrationCreatedOn'] as String),
  manufacturerId: (json['manufacturerId'] as num?)?.toInt(),
  organizationId: json['organizationId'] as String?,
  majorId: (json['majorId'] as num?)?.toInt(),
  minorId: (json['minorId'] as num?)?.toInt(),
  referenceRssi: (json['referenceRssi'] as num?)?.toInt(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AltBeaconDeviceRegistrationToJson(
  AltBeaconDeviceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'manufacturerId': ?instance.manufacturerId,
  'organizationId': ?instance.organizationId,
  'majorId': ?instance.majorId,
  'minorId': ?instance.minorId,
  'referenceRssi': ?instance.referenceRssi,
};

BLEHeartRateDevice _$BLEHeartRateDeviceFromJson(Map<String, dynamic> json) =>
    BLEHeartRateDevice(
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

Map<String, dynamic> _$BLEHeartRateDeviceToJson(BLEHeartRateDevice instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
    };

TriggerConfiguration _$TriggerConfigurationFromJson(
  Map<String, dynamic> json,
) => TriggerConfiguration(
  sourceDeviceRoleName: json['sourceDeviceRoleName'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$TriggerConfigurationToJson(
  TriggerConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
};

ElapsedTimeTrigger _$ElapsedTimeTriggerFromJson(Map<String, dynamic> json) =>
    ElapsedTimeTrigger(
      sourceDeviceRoleName: json['sourceDeviceRoleName'] as String?,
      elapsedTime: _$IsoDurationFromJson(json['elapsedTime'] as String?),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$ElapsedTimeTriggerToJson(ElapsedTimeTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'elapsedTime': ?_$IsoDurationToJson(instance.elapsedTime),
    };

ManualTrigger _$ManualTriggerFromJson(Map<String, dynamic> json) =>
    ManualTrigger(
      sourceDeviceRoleName: json['sourceDeviceRoleName'] as String?,
      label: json['label'] as String?,
      description: json['description'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$ManualTriggerToJson(ManualTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'label': ?instance.label,
      'description': ?instance.description,
    };

ScheduledTrigger _$ScheduledTriggerFromJson(Map<String, dynamic> json) =>
    ScheduledTrigger(
      sourceDeviceRoleName: json['sourceDeviceRoleName'] as String?,
      time: TimeOfDay.fromJson(json['time'] as Map<String, dynamic>),
      recurrenceRule: RecurrenceRule.fromJson(
        json['recurrenceRule'] as Map<String, dynamic>,
      ),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$ScheduledTriggerToJson(ScheduledTrigger instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sourceDeviceRoleName': ?instance.sourceDeviceRoleName,
      'time': instance.time.toJson(),
      'recurrenceRule': instance.recurrenceRule.toJson(),
    };

TimeOfDay _$TimeOfDayFromJson(Map<String, dynamic> json) => TimeOfDay(
  hour: (json['hour'] as num?)?.toInt() ?? 0,
  minute: (json['minute'] as num?)?.toInt() ?? 0,
  second: (json['second'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TimeOfDayToJson(TimeOfDay instance) => <String, dynamic>{
  'hour': instance.hour,
  'minute': instance.minute,
  'second': instance.second,
};

RecurrenceRule _$RecurrenceRuleFromJson(Map<String, dynamic> json) =>
    RecurrenceRule(
      $enumDecode(_$FrequencyEnumMap, json['frequency']),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      end: json['end'] == null
          ? null
          : End.fromJson(json['end'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RecurrenceRuleToJson(RecurrenceRule instance) =>
    <String, dynamic>{
      'frequency': _$FrequencyEnumMap[instance.frequency]!,
      'interval': instance.interval,
      'end': instance.end.toJson(),
    };

const _$FrequencyEnumMap = {
  Frequency.SECONDLY: 'SECONDLY',
  Frequency.MINUTELY: 'MINUTELY',
  Frequency.HOURLY: 'HOURLY',
  Frequency.DAILY: 'DAILY',
  Frequency.WEEKLY: 'WEEKLY',
  Frequency.MONTHLY: 'MONTHLY',
  Frequency.YEARLY: 'YEARLY',
};

End _$EndFromJson(Map<String, dynamic> json) => End(
  $enumDecode(_$EndTypeEnumMap, json['type']),
  elapsedTime: json['elapsedTime'] == null
      ? null
      : Duration(microseconds: (json['elapsedTime'] as num).toInt()),
  count: (json['count'] as num?)?.toInt(),
);

Map<String, dynamic> _$EndToJson(End instance) => <String, dynamic>{
  'type': _$EndTypeEnumMap[instance.type]!,
  'elapsedTime': ?instance.elapsedTime?.inMicroseconds,
  'count': ?instance.count,
};

const _$EndTypeEnumMap = {
  EndType.UNTIL: 'UNTIL',
  EndType.COUNT: 'COUNT',
  EndType.NEVER: 'NEVER',
};

SamplingConfiguration _$SamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => SamplingConfiguration()..$type = json['__type'] as String?;

Map<String, dynamic> _$SamplingConfigurationToJson(
  SamplingConfiguration instance,
) => <String, dynamic>{'__type': ?instance.$type};

NoOptionsSamplingConfiguration _$NoOptionsSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => NoOptionsSamplingConfiguration()..$type = json['__type'] as String?;

Map<String, dynamic> _$NoOptionsSamplingConfigurationToJson(
  NoOptionsSamplingConfiguration instance,
) => <String, dynamic>{'__type': ?instance.$type};

BatteryAwareSamplingConfiguration _$BatteryAwareSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => BatteryAwareSamplingConfiguration(
  normal: SamplingConfiguration.fromJson(
    json['normal'] as Map<String, dynamic>,
  ),
  low: SamplingConfiguration.fromJson(json['low'] as Map<String, dynamic>),
  critical: json['critical'] == null
      ? null
      : SamplingConfiguration.fromJson(
          json['critical'] as Map<String, dynamic>,
        ),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$BatteryAwareSamplingConfigurationToJson(
  BatteryAwareSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'normal': instance.normal.toJson(),
  'low': instance.low.toJson(),
  'critical': ?instance.critical?.toJson(),
};

GranularitySamplingConfiguration _$GranularitySamplingConfigurationFromJson(
  Map<String, dynamic> json,
) => GranularitySamplingConfiguration(
  $enumDecode(_$GranularityEnumMap, json['granularity']),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$GranularitySamplingConfigurationToJson(
  GranularitySamplingConfiguration instance,
) => <String, dynamic>{
  '__type': instance.$type,
  'granularity': _$GranularityEnumMap[instance.granularity]!,
};

const _$GranularityEnumMap = {
  Granularity.Detailed: 'Detailed',
  Granularity.Balanced: 'Balanced',
  Granularity.Coarse: 'Coarse',
};

DataType _$DataTypeFromJson(Map<String, dynamic> json) =>
    DataType(json['namespace'] as String, json['name'] as String);

Map<String, dynamic> _$DataTypeToJson(DataType instance) => <String, dynamic>{
  'namespace': instance.namespace,
  'name': instance.name,
};

Data _$DataFromJson(Map<String, dynamic> json) =>
    Data()..$type = json['__type'] as String?;

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
  '__type': ?instance.$type,
};

Acceleration _$AccelerationFromJson(Map<String, dynamic> json) =>
    Acceleration(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        z: (json['z'] as num?)?.toDouble() ?? 0,
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$AccelerationToJson(Acceleration instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };

Rotation _$RotationFromJson(Map<String, dynamic> json) =>
    Rotation(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        z: (json['z'] as num?)?.toDouble() ?? 0,
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$RotationToJson(Rotation instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'x': instance.x,
  'y': instance.y,
  'z': instance.z,
};

MagneticField _$MagneticFieldFromJson(Map<String, dynamic> json) =>
    MagneticField(
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        z: (json['z'] as num?)?.toDouble() ?? 0,
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$MagneticFieldToJson(MagneticField instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };

Geolocation _$GeolocationFromJson(Map<String, dynamic> json) =>
    Geolocation(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$GeolocationToJson(Geolocation instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

SignalStrength _$SignalStrengthFromJson(Map<String, dynamic> json) =>
    SignalStrength(rssi: (json['rssi'] as num?)?.toInt() ?? 0)
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$SignalStrengthToJson(SignalStrength instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
      'rssi': instance.rssi,
    };

StepCount _$StepCountFromJson(Map<String, dynamic> json) =>
    StepCount(steps: (json['steps'] as num?)?.toInt() ?? 0)
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$StepCountToJson(StepCount instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'steps': instance.steps,
};

HeartRate _$HeartRateFromJson(Map<String, dynamic> json) =>
    HeartRate(bpm: (json['bpm'] as num?)?.toInt() ?? 0)
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$HeartRateToJson(HeartRate instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'bpm': instance.bpm,
};

ECG _$ECGFromJson(Map<String, dynamic> json) =>
    ECG(
        samplingFrequencyHz:
            (json['samplingFrequencyHz'] as num?)?.toInt() ?? 250,
        milliVolt:
            (json['milliVolt'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [],
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$ECGToJson(ECG instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'samplingFrequencyHz': instance.samplingFrequencyHz,
  'milliVolt': instance.milliVolt,
};

EDA _$EDAFromJson(Map<String, dynamic> json) =>
    EDA(microSiemens: (json['microSiemens'] as num?)?.toDouble() ?? 0)
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$EDAToJson(EDA instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'microSiemens': instance.microSiemens,
};

CompletedTask _$CompletedTaskFromJson(Map<String, dynamic> json) =>
    CompletedTask(
      taskName: json['taskName'] as String,
      taskData: json['taskData'] == null
          ? null
          : Data.fromJson(json['taskData'] as Map<String, dynamic>),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$CompletedTaskToJson(CompletedTask instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'taskName': instance.taskName,
      'taskData': ?instance.taskData?.toJson(),
    };

TriggeredTask _$TriggeredTaskFromJson(Map<String, dynamic> json) =>
    TriggeredTask(
      triggerId: (json['triggerId'] as num).toInt(),
      taskName: json['taskName'] as String,
      destinationDeviceRoleName: json['destinationDeviceRoleName'] as String,
      control: $enumDecode(_$ControlEnumMap, json['control']),
      triggerData: json['triggerData'] == null
          ? null
          : Data.fromJson(json['triggerData'] as Map<String, dynamic>),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$TriggeredTaskToJson(TriggeredTask instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'triggerId': instance.triggerId,
      'taskName': instance.taskName,
      'destinationDeviceRoleName': instance.destinationDeviceRoleName,
      'control': _$ControlEnumMap[instance.control]!,
      'triggerData': ?instance.triggerData?.toJson(),
    };

Error _$ErrorFromJson(Map<String, dynamic> json) =>
    Error(message: json['message'] as String)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$ErrorToJson(Error instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'message': instance.message,
};

CustomInput _$CustomInputFromJson(Map<String, dynamic> json) =>
    CustomInput(value: json['value'])..$type = json['__type'] as String?;

Map<String, dynamic> _$CustomInputToJson(CustomInput instance) =>
    <String, dynamic>{'__type': ?instance.$type, 'value': ?instance.value};

SexInput _$SexInputFromJson(Map<String, dynamic> json) =>
    SexInput(value: $enumDecode(_$SexEnumMap, json['value']))
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$SexInputToJson(SexInput instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'value': _$SexEnumMap[instance.value]!,
};

const _$SexEnumMap = {
  Sex.Male: 'Male',
  Sex.Female: 'Female',
  Sex.Intersex: 'Intersex',
};

PhoneNumberInput _$PhoneNumberInputFromJson(Map<String, dynamic> json) =>
    PhoneNumberInput(
        countryCode: json['countryCode'] as String,
        number: json['number'] as String,
      )
      ..$type = json['__type'] as String?
      ..isoCode = json['isoCode'] as String?;

Map<String, dynamic> _$PhoneNumberInputToJson(PhoneNumberInput instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'countryCode': instance.countryCode,
      'isoCode': ?instance.isoCode,
      'number': instance.number,
    };

SocialSecurityNumberInput _$SocialSecurityNumberInputFromJson(
  Map<String, dynamic> json,
) => SocialSecurityNumberInput(
  socialSecurityNumber: json['socialSecurityNumber'] as String,
  country: json['country'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$SocialSecurityNumberInputToJson(
  SocialSecurityNumberInput instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'socialSecurityNumber': instance.socialSecurityNumber,
  'country': instance.country,
};

FullNameInput _$FullNameInputFromJson(Map<String, dynamic> json) =>
    FullNameInput(
      firstName: json['firstName'] as String?,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$FullNameInputToJson(FullNameInput instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'firstName': ?instance.firstName,
      'middleName': ?instance.middleName,
      'lastName': ?instance.lastName,
    };

InformedConsentInput _$InformedConsentInputFromJson(
  Map<String, dynamic> json,
) => InformedConsentInput(
  signedTimestamp: json['signedTimestamp'] == null
      ? null
      : DateTime.parse(json['signedTimestamp'] as String),
  signedLocation: json['signedLocation'] as String?,
  userId: json['userId'] as String,
  name: json['name'] as String,
  consent: json['consent'] as String,
  signatureImage: json['signatureImage'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$InformedConsentInputToJson(
  InformedConsentInput instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'signedTimestamp': instance.signedTimestamp.toIso8601String(),
  'signedLocation': ?instance.signedLocation,
  'userId': instance.userId,
  'name': instance.name,
  'consent': instance.consent,
  'signatureImage': instance.signatureImage,
};

AddressInput _$AddressInputFromJson(Map<String, dynamic> json) => AddressInput(
  address1: json['address1'] as String?,
  address2: json['address2'] as String?,
  street: json['street'] as String?,
  city: json['city'] as String?,
  postalCode: json['postalCode'] as String?,
  country: json['country'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AddressInputToJson(AddressInput instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'address1': ?instance.address1,
      'address2': ?instance.address2,
      'street': ?instance.street,
      'city': ?instance.city,
      'postalCode': ?instance.postalCode,
      'country': ?instance.country,
    };

DiagnosisInput _$DiagnosisInputFromJson(Map<String, dynamic> json) =>
    DiagnosisInput(
      effectiveDate: json['effectiveDate'] == null
          ? null
          : DateTime.parse(json['effectiveDate'] as String),
      diagnosis: json['diagnosis'] as String?,
      icd11Code: json['icd11Code'] as String,
      conclusion: json['conclusion'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$DiagnosisInputToJson(DiagnosisInput instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'effectiveDate': ?instance.effectiveDate?.toIso8601String(),
      'diagnosis': ?instance.diagnosis,
      'icd11Code': instance.icd11Code,
      'conclusion': ?instance.conclusion,
    };

NoteInput _$NoteInputFromJson(Map<String, dynamic> json) =>
    NoteInput(note: json['note'] as String)..$type = json['__type'] as String?;

Map<String, dynamic> _$NoteInputToJson(NoteInput instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'note': instance.note,
};

EducationalDegreeInput _$EducationalDegreeInputFromJson(
  Map<String, dynamic> json,
) => EducationalDegreeInput(
  level: $enumDecode(_$IscedLevelEnumMap, json['level']),
  details: json['details'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$EducationalDegreeInputToJson(
  EducationalDegreeInput instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'level': _$IscedLevelEnumMap[instance.level]!,
  'details': ?instance.details,
};

const _$IscedLevelEnumMap = {
  IscedLevel.ISCED_0: 'ISCED_0',
  IscedLevel.ISCED_1: 'ISCED_1',
  IscedLevel.ISCED_2: 'ISCED_2',
  IscedLevel.ISCED_3: 'ISCED_3',
  IscedLevel.ISCED_4: 'ISCED_4',
  IscedLevel.ISCED_5: 'ISCED_5',
  IscedLevel.ISCED_6: 'ISCED_6',
  IscedLevel.ISCED_7: 'ISCED_7',
  IscedLevel.ISCED_8: 'ISCED_8',
};

OnboardingResearcherInput _$OnboardingResearcherInputFromJson(
  Map<String, dynamic> json,
) => OnboardingResearcherInput(
  researcherId: json['researcherId'] as String,
  researcherName: json['researcherName'] as String,
  institutionName: json['institutionName'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$OnboardingResearcherInputToJson(
  OnboardingResearcherInput instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'researcherId': instance.researcherId,
  'researcherName': instance.researcherName,
  'institutionName': ?instance.institutionName,
};

PreferredLanguageInput _$PreferredLanguageInputFromJson(
  Map<String, dynamic> json,
) => PreferredLanguageInput(
  languageCode: json['languageCode'] as String,
  region: json['region'] as String?,
  displayName: json['displayName'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$PreferredLanguageInputToJson(
  PreferredLanguageInput instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'languageCode': instance.languageCode,
  'region': ?instance.region,
  'displayName': ?instance.displayName,
};

OccupationInput _$OccupationInputFromJson(Map<String, dynamic> json) =>
    OccupationInput(
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      other: json['other'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$OccupationInputToJson(OccupationInput instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roles': instance.roles,
      'other': ?instance.other,
    };
