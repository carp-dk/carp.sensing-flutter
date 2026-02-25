// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sampling_packages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AmbientLight _$AmbientLightFromJson(Map<String, dynamic> json) =>
    AmbientLight(
        json['meanLux'] as num,
        json['stdLux'] as num,
        json['minLux'] as num,
        json['maxLux'] as num,
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$AmbientLightToJson(AmbientLight instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
      'meanLux': instance.meanLux,
      'stdLux': instance.stdLux,
      'minLux': instance.minLux,
      'maxLux': instance.maxLux,
    };

AccelerationFeatures _$AccelerationFeaturesFromJson(
  Map<String, dynamic> json,
) => AccelerationFeatures()
  ..$type = json['__type'] as String?
  ..sensorSpecificData = json['sensorSpecificData'] == null
      ? null
      : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>)
  ..count = (json['count'] as num).toInt()
  ..xMean = json['xMean'] as num?
  ..yMean = json['yMean'] as num?
  ..zMean = json['zMean'] as num?
  ..xStd = json['xStd'] as num?
  ..yStd = json['yStd'] as num?
  ..zStd = json['zStd'] as num?
  ..xAad = json['xAad'] as num?
  ..yAad = json['yAad'] as num?
  ..zAad = json['zAad'] as num?
  ..xMin = json['xMin'] as num?
  ..yMin = json['yMin'] as num?
  ..zMin = json['zMin'] as num?
  ..xMax = json['xMax'] as num?
  ..yMax = json['yMax'] as num?
  ..zMax = json['zMax'] as num?
  ..xMaxMinDiff = json['xMaxMinDiff'] as num?
  ..yMaxMinDiff = json['yMaxMinDiff'] as num?
  ..zMaxMinDiff = json['zMaxMinDiff'] as num?
  ..xMedian = json['xMedian'] as num?
  ..yMedian = json['yMedian'] as num?
  ..zMedian = json['zMedian'] as num?
  ..xMad = json['xMad'] as num?
  ..yMad = json['yMad'] as num?
  ..zMad = json['zMad'] as num?
  ..xIqr = json['xIqr'] as num?
  ..yIqr = json['yIqr'] as num?
  ..zIqr = json['zIqr'] as num?
  ..xNegCount = json['xNegCount'] as num?
  ..yNegCount = json['yNegCount'] as num?
  ..zNegCount = json['zNegCount'] as num?
  ..xPosCount = json['xPosCount'] as num?
  ..yPosCount = json['yPosCount'] as num?
  ..zPosCount = json['zPosCount'] as num?
  ..xAboveMean = json['xAboveMean'] as num?
  ..yAboveMean = json['yAboveMean'] as num?
  ..zAboveMean = json['zAboveMean'] as num?
  ..xEnergy = json['xEnergy'] as num?
  ..yEnergy = json['yEnergy'] as num?
  ..zEnergy = json['zEnergy'] as num?
  ..avgResultAcceleration = json['avgResultAcceleration'] as num?
  ..signalMagnitudeArea = json['signalMagnitudeArea'] as num?;

Map<String, dynamic> _$AccelerationFeaturesToJson(
  AccelerationFeatures instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'count': instance.count,
  'xMean': ?instance.xMean,
  'yMean': ?instance.yMean,
  'zMean': ?instance.zMean,
  'xStd': ?instance.xStd,
  'yStd': ?instance.yStd,
  'zStd': ?instance.zStd,
  'xAad': ?instance.xAad,
  'yAad': ?instance.yAad,
  'zAad': ?instance.zAad,
  'xMin': ?instance.xMin,
  'yMin': ?instance.yMin,
  'zMin': ?instance.zMin,
  'xMax': ?instance.xMax,
  'yMax': ?instance.yMax,
  'zMax': ?instance.zMax,
  'xMaxMinDiff': ?instance.xMaxMinDiff,
  'yMaxMinDiff': ?instance.yMaxMinDiff,
  'zMaxMinDiff': ?instance.zMaxMinDiff,
  'xMedian': ?instance.xMedian,
  'yMedian': ?instance.yMedian,
  'zMedian': ?instance.zMedian,
  'xMad': ?instance.xMad,
  'yMad': ?instance.yMad,
  'zMad': ?instance.zMad,
  'xIqr': ?instance.xIqr,
  'yIqr': ?instance.yIqr,
  'zIqr': ?instance.zIqr,
  'xNegCount': ?instance.xNegCount,
  'yNegCount': ?instance.yNegCount,
  'zNegCount': ?instance.zNegCount,
  'xPosCount': ?instance.xPosCount,
  'yPosCount': ?instance.yPosCount,
  'zPosCount': ?instance.zPosCount,
  'xAboveMean': ?instance.xAboveMean,
  'yAboveMean': ?instance.yAboveMean,
  'zAboveMean': ?instance.zAboveMean,
  'xEnergy': ?instance.xEnergy,
  'yEnergy': ?instance.yEnergy,
  'zEnergy': ?instance.zEnergy,
  'avgResultAcceleration': ?instance.avgResultAcceleration,
  'signalMagnitudeArea': ?instance.signalMagnitudeArea,
};

StepEvent _$StepEventFromJson(Map<String, dynamic> json) =>
    StepEvent(steps: (json['steps'] as num?)?.toInt() ?? 0)
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$StepEventToJson(StepEvent instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'steps': instance.steps,
};

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

ApplicationInformation _$ApplicationInformationFromJson(
  Map<String, dynamic> json,
) => ApplicationInformation(
  appName: json['appName'] as String,
  packageName: json['packageName'] as String,
  version: json['version'] as String,
  buildNumber: json['buildNumber'] as String,
  buildSignature: json['buildSignature'] as String? ?? '',
  installerStore: json['installerStore'] as String?,
  installTime: json['installTime'] == null
      ? null
      : DateTime.parse(json['installTime'] as String),
  updateTime: json['updateTime'] == null
      ? null
      : DateTime.parse(json['updateTime'] as String),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$ApplicationInformationToJson(
  ApplicationInformation instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'appName': instance.appName,
  'packageName': instance.packageName,
  'version': instance.version,
  'buildNumber': instance.buildNumber,
  'buildSignature': instance.buildSignature,
  'installerStore': ?instance.installerStore,
  'installTime': ?instance.installTime?.toIso8601String(),
  'updateTime': ?instance.updateTime?.toIso8601String(),
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

AppLifecycleEvent _$AppLifecycleEventFromJson(Map<String, dynamic> json) =>
    AppLifecycleEvent(json['state'] as String)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$AppLifecycleEventToJson(AppLifecycleEvent instance) =>
    <String, dynamic>{'__type': ?instance.$type, 'state': instance.state};

Heartbeat _$HeartbeatFromJson(Map<String, dynamic> json) => Heartbeat(
  deviceType: json['deviceType'] as String,
  deviceRoleName: json['deviceRoleName'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$HeartbeatToJson(Heartbeat instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceType': instance.deviceType,
  'deviceRoleName': instance.deviceRoleName,
};
