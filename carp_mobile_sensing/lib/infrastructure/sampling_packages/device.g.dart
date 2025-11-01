// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceInformation _$DeviceInformationFromJson(Map<String, dynamic> json) =>
    DeviceInformation(
        deviceData: json['deviceData'] as Map<String, dynamic>? ?? const {},
        platform: json['platform'] as String?,
        deviceId: json['deviceId'] as String?,
        deviceName: json['deviceName'] as String?,
        deviceModel: json['deviceModel'] as String?,
        deviceManufacturer: json['deviceManufacturer'] as String?,
        operatingSystem: json['operatingSystem'] as String?,
        hardware: json['hardware'] as String?,
      )
      ..$type = json['__type'] as String?
      ..sdk = json['sdk'] as String?
      ..release = json['release'] as String?;

Map<String, dynamic> _$DeviceInformationToJson(DeviceInformation instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'platform': ?instance.platform,
      'deviceId': ?instance.deviceId,
      'hardware': ?instance.hardware,
      'deviceName': ?instance.deviceName,
      'deviceManufacturer': ?instance.deviceManufacturer,
      'deviceModel': ?instance.deviceModel,
      'operatingSystem': ?instance.operatingSystem,
      'sdk': ?instance.sdk,
      'release': ?instance.release,
      'deviceData': instance.deviceData,
    };

BatteryState _$BatteryStateFromJson(Map<String, dynamic> json) => BatteryState(
  (json['batteryLevel'] as num?)?.toInt(),
  json['batteryStatus'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$BatteryStateToJson(BatteryState instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'batteryLevel': ?instance.batteryLevel,
      'batteryStatus': ?instance.batteryStatus,
    };

FreeMemory _$FreeMemoryFromJson(Map<String, dynamic> json) => FreeMemory(
  (json['freePhysicalMemory'] as num?)?.toInt(),
  (json['freeVirtualMemory'] as num?)?.toInt(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$FreeMemoryToJson(FreeMemory instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'freePhysicalMemory': ?instance.freePhysicalMemory,
      'freeVirtualMemory': ?instance.freeVirtualMemory,
    };

ScreenEvent _$ScreenEventFromJson(Map<String, dynamic> json) =>
    ScreenEvent(json['screenEvent'] as String?)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$ScreenEventToJson(ScreenEvent instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'screenEvent': ?instance.screenEvent,
    };

Timezone _$TimezoneFromJson(Map<String, dynamic> json) =>
    Timezone(json['timezone'] as String)..$type = json['__type'] as String?;

Map<String, dynamic> _$TimezoneToJson(Timezone instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'timezone': instance.timezone,
};
