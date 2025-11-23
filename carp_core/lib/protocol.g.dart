// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudyProtocol _$StudyProtocolFromJson(Map<String, dynamic> json) =>
    StudyProtocol(
        ownerId: json['ownerId'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
      )
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
              .toSet()
      ..applicationData = json['applicationData'] as Map<String, dynamic>?;

Map<String, dynamic> _$StudyProtocolToJson(StudyProtocol instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdOn': instance.createdOn.toIso8601String(),
      'version': instance.version,
      'ownerId': instance.ownerId,
      'name': instance.name,
      'description': ?instance.description,
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
      'applicationData': ?instance.applicationData,
    };

DeviceConnection _$DeviceConnectionFromJson(Map<String, dynamic> json) =>
    DeviceConnection(
      json['roleName'] as String?,
      json['connectedToRoleName'] as String?,
    );

Map<String, dynamic> _$DeviceConnectionToJson(DeviceConnection instance) =>
    <String, dynamic>{
      'roleName': ?instance.roleName,
      'connectedToRoleName': ?instance.connectedToRoleName,
    };

ProtocolVersion _$ProtocolVersionFromJson(Map<String, dynamic> json) =>
    ProtocolVersion(json['tag'] as String)
      ..date = DateTime.parse(json['date'] as String);

Map<String, dynamic> _$ProtocolVersionToJson(ProtocolVersion instance) =>
    <String, dynamic>{
      'tag': instance.tag,
      'date': instance.date.toIso8601String(),
    };

Add _$AddFromJson(Map<String, dynamic> json) =>
    Add(
        StudyProtocol.fromJson(json['protocol'] as Map<String, dynamic>),
        json['versionTag'] as String?,
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$AddToJson(Add instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'apiVersion': instance.apiVersion,
  'protocol': instance.protocol.toJson(),
  'versionTag': ?instance.versionTag,
};

AddVersion _$AddVersionFromJson(Map<String, dynamic> json) =>
    AddVersion(
        StudyProtocol.fromJson(json['protocol'] as Map<String, dynamic>),
        json['versionTag'] as String?,
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$AddVersionToJson(AddVersion instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'apiVersion': instance.apiVersion,
      'protocol': instance.protocol.toJson(),
      'versionTag': ?instance.versionTag,
    };

UpdateParticipantDataConfiguration _$UpdateParticipantDataConfigurationFromJson(
  Map<String, dynamic> json,
) =>
    UpdateParticipantDataConfiguration(
        json['protocolId'] as String,
        json['versionTag'] as String?,
        (json['expectedParticipantData'] as List<dynamic>?)
            ?.map(
              (e) =>
                  ExpectedParticipantData.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$UpdateParticipantDataConfigurationToJson(
  UpdateParticipantDataConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'apiVersion': instance.apiVersion,
  'protocolId': instance.protocolId,
  'versionTag': ?instance.versionTag,
  'expectedParticipantData': ?instance.expectedParticipantData
      ?.map((e) => e.toJson())
      .toList(),
};

GetBy _$GetByFromJson(Map<String, dynamic> json) =>
    GetBy(json['protocolId'] as String, json['versionTag'] as String?)
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$GetByToJson(GetBy instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'apiVersion': instance.apiVersion,
  'protocolId': instance.protocolId,
  'versionTag': ?instance.versionTag,
};

GetAllForOwner _$GetAllForOwnerFromJson(Map<String, dynamic> json) =>
    GetAllForOwner(json['ownerId'] as String)
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$GetAllForOwnerToJson(GetAllForOwner instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'apiVersion': instance.apiVersion,
      'ownerId': instance.ownerId,
    };

GetVersionHistoryFor _$GetVersionHistoryForFromJson(
  Map<String, dynamic> json,
) => GetVersionHistoryFor(json['protocolId'] as String)
  ..$type = json['__type'] as String?
  ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$GetVersionHistoryForToJson(
  GetVersionHistoryFor instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'apiVersion': instance.apiVersion,
  'protocolId': instance.protocolId,
};

CreateCustomProtocol _$CreateCustomProtocolFromJson(
  Map<String, dynamic> json,
) =>
    CreateCustomProtocol(
        json['ownerId'] as String,
        json['name'] as String,
        json['description'] as String,
        json['customProtocol'] as String,
      )
      ..$type = json['__type'] as String?
      ..apiVersion = json['apiVersion'] as String;

Map<String, dynamic> _$CreateCustomProtocolToJson(
  CreateCustomProtocol instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'apiVersion': instance.apiVersion,
  'ownerId': instance.ownerId,
  'name': instance.name,
  'description': instance.description,
  'customProtocol': instance.customProtocol,
};
