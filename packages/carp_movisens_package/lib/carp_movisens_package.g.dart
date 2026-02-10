// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carp_movisens_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovisensStepCount _$MovisensStepCountFromJson(Map<String, dynamic> json) =>
    MovisensStepCount(
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      steps: (json['steps'] as num).toInt(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensStepCountToJson(MovisensStepCount instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'steps': instance.steps,
    };

MovisensBodyPosition _$MovisensBodyPositionFromJson(
  Map<String, dynamic> json,
) => MovisensBodyPosition(
  deviceId: json['deviceId'] as String,
  type: json['type'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  bodyPosition: json['bodyPosition'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensBodyPositionToJson(
  MovisensBodyPosition instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'timestamp': instance.timestamp.toIso8601String(),
  'deviceId': instance.deviceId,
  'type': instance.type,
  'bodyPosition': instance.bodyPosition,
};

MovisensInclination _$MovisensInclinationFromJson(Map<String, dynamic> json) =>
    MovisensInclination(
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      z: (json['z'] as num).toInt(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensInclinationToJson(
  MovisensInclination instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'timestamp': instance.timestamp.toIso8601String(),
  'deviceId': instance.deviceId,
  'type': instance.type,
  'x': instance.x,
  'y': instance.y,
  'z': instance.z,
};

MovisensMovementAcceleration _$MovisensMovementAccelerationFromJson(
  Map<String, dynamic> json,
) => MovisensMovementAcceleration(
  deviceId: json['deviceId'] as String,
  type: json['type'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  movementAcceleration: (json['movementAcceleration'] as num).toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensMovementAccelerationToJson(
  MovisensMovementAcceleration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'timestamp': instance.timestamp.toIso8601String(),
  'deviceId': instance.deviceId,
  'type': instance.type,
  'movementAcceleration': instance.movementAcceleration,
};

MovisensMET _$MovisensMETFromJson(Map<String, dynamic> json) => MovisensMET(
  deviceId: json['deviceId'] as String,
  type: json['type'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  met: (json['met'] as num).toInt(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensMETToJson(MovisensMET instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'met': instance.met,
    };

MovisensMETLevel _$MovisensMETLevelFromJson(Map<String, dynamic> json) =>
    MovisensMETLevel(
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      sedentary: (json['sedentary'] as num).toInt(),
      light: (json['light'] as num).toInt(),
      moderate: (json['moderate'] as num).toInt(),
      vigorous: (json['vigorous'] as num).toInt(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensMETLevelToJson(MovisensMETLevel instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'sedentary': instance.sedentary,
      'light': instance.light,
      'moderate': instance.moderate,
      'vigorous': instance.vigorous,
    };

MovisensHR _$MovisensHRFromJson(Map<String, dynamic> json) => MovisensHR(
  deviceId: json['deviceId'] as String,
  type: json['type'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  hr: (json['hr'] as num).toInt(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensHRToJson(MovisensHR instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'hr': instance.hr,
    };

MovisensHRV _$MovisensHRVFromJson(Map<String, dynamic> json) => MovisensHRV(
  deviceId: json['deviceId'] as String,
  type: json['type'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  hrv: (json['hrv'] as num).toInt(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensHRVToJson(MovisensHRV instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'hrv': instance.hrv,
    };

MovisensIsHrvValid _$MovisensIsHrvValidFromJson(Map<String, dynamic> json) =>
    MovisensIsHrvValid(
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      isHrvValid: json['isHrvValid'] as bool,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensIsHrvValidToJson(MovisensIsHrvValid instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'isHrvValid': instance.isHrvValid,
    };

MovisensEDA _$MovisensEDAFromJson(Map<String, dynamic> json) => MovisensEDA(
  deviceId: json['deviceId'] as String,
  type: json['type'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  edaSclMean: (json['edaSclMean'] as num).toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensEDAToJson(MovisensEDA instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'edaSclMean': instance.edaSclMean,
    };

MovisensSkinTemperature _$MovisensSkinTemperatureFromJson(
  Map<String, dynamic> json,
) => MovisensSkinTemperature(
  deviceId: json['deviceId'] as String,
  type: json['type'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  skinTemperature: (json['skinTemperature'] as num).toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensSkinTemperatureToJson(
  MovisensSkinTemperature instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'timestamp': instance.timestamp.toIso8601String(),
  'deviceId': instance.deviceId,
  'type': instance.type,
  'skinTemperature': instance.skinTemperature,
};

MovisensRespiration _$MovisensRespirationFromJson(Map<String, dynamic> json) =>
    MovisensRespiration(
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toInt(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensRespirationToJson(
  MovisensRespiration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'timestamp': instance.timestamp.toIso8601String(),
  'deviceId': instance.deviceId,
  'type': instance.type,
  'value': instance.value,
};

MovisensTapMarker _$MovisensTapMarkerFromJson(Map<String, dynamic> json) =>
    MovisensTapMarker(
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      tapMarker: (json['tapMarker'] as num).toInt(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MovisensTapMarkerToJson(MovisensTapMarker instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'type': instance.type,
      'tapMarker': instance.tapMarker,
    };

MovisensDevice _$MovisensDeviceFromJson(Map<String, dynamic> json) =>
    MovisensDevice(
        roleName: json['roleName'] as String?,
        sensorLocation:
            $enumDecodeNullable(
              _$SensorLocationEnumMap,
              json['sensorLocation'],
            ) ??
            SensorLocation.Chest,
        sex: $enumDecodeNullable(_$SexEnumMap, json['sex']) ?? Sex.Male,
        height: (json['height'] as num?)?.toInt() ?? 178,
        weight: (json['weight'] as num?)?.toInt() ?? 78,
        age: (json['age'] as num?)?.toInt() ?? 25,
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
      ..serviceUuids = (json['serviceUuids'] as List<dynamic>)
          .map((e) => e as String)
          .toList()
      ..namePrefix = json['namePrefix'] as String?
      ..minRssi = (json['minRssi'] as num?)?.toInt()
      ..allowDuplicates = json['allowDuplicates'] as bool
      ..timeout = json['timeout'] == null
          ? null
          : Duration(microseconds: (json['timeout'] as num).toInt());

Map<String, dynamic> _$MovisensDeviceToJson(MovisensDevice instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration,
      'serviceUuids': instance.serviceUuids,
      'namePrefix': ?instance.namePrefix,
      'minRssi': ?instance.minRssi,
      'allowDuplicates': instance.allowDuplicates,
      'timeout': ?instance.timeout?.inMicroseconds,
      'sensorLocation': _$SensorLocationEnumMap[instance.sensorLocation]!,
      'weight': instance.weight,
      'height': instance.height,
      'age': instance.age,
      'sex': _$SexEnumMap[instance.sex]!,
    };

const _$SensorLocationEnumMap = {
  SensorLocation.RightSideHip: 'RightSideHip',
  SensorLocation.Chest: 'Chest',
  SensorLocation.RightWrist: 'RightWrist',
  SensorLocation.LeftWrist: 'LeftWrist',
  SensorLocation.LeftAnkle: 'LeftAnkle',
  SensorLocation.RightAnkle: 'RightAnkle',
  SensorLocation.RightThigh: 'RightThigh',
  SensorLocation.LeftThigh: 'LeftThigh',
  SensorLocation.RightUpperArm: 'RightUpperArm',
  SensorLocation.LeftUpperArm: 'LeftUpperArm',
  SensorLocation.LeftSideHip: 'LeftSideHip',
};

const _$SexEnumMap = {
  Sex.Male: 'Male',
  Sex.Female: 'Female',
  Sex.Intersex: 'Intersex',
};
