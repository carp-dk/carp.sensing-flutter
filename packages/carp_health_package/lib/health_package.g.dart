// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthSamplingConfiguration _$HealthSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) =>
    HealthSamplingConfiguration(
        past: json['past'] == null
            ? null
            : Duration(microseconds: (json['past'] as num).toInt()),
        healthDataTypes: (json['healthDataTypes'] as List<dynamic>)
            .map((e) => $enumDecode(_$HealthDataTypeEnumMap, e))
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..lastTime = json['lastTime'] == null
          ? null
          : DateTime.parse(json['lastTime'] as String)
      ..future = Duration(microseconds: (json['future'] as num).toInt());

Map<String, dynamic> _$HealthSamplingConfigurationToJson(
  HealthSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'lastTime': ?instance.lastTime?.toIso8601String(),
  'past': instance.past.inMicroseconds,
  'future': instance.future.inMicroseconds,
  'healthDataTypes': instance.healthDataTypes
      .map((e) => _$HealthDataTypeEnumMap[e]!)
      .toList(),
};

const _$HealthDataTypeEnumMap = {
  HealthDataType.ACTIVE_ENERGY_BURNED: 'ACTIVE_ENERGY_BURNED',
  HealthDataType.ATRIAL_FIBRILLATION_BURDEN: 'ATRIAL_FIBRILLATION_BURDEN',
  HealthDataType.APPLE_STAND_HOUR: 'APPLE_STAND_HOUR',
  HealthDataType.APPLE_MOVE_TIME: 'APPLE_MOVE_TIME',
  HealthDataType.APPLE_STAND_TIME: 'APPLE_STAND_TIME',
  HealthDataType.AUDIOGRAM: 'AUDIOGRAM',
  HealthDataType.BASAL_ENERGY_BURNED: 'BASAL_ENERGY_BURNED',
  HealthDataType.BLOOD_GLUCOSE: 'BLOOD_GLUCOSE',
  HealthDataType.BLOOD_OXYGEN: 'BLOOD_OXYGEN',
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC: 'BLOOD_PRESSURE_DIASTOLIC',
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC: 'BLOOD_PRESSURE_SYSTOLIC',
  HealthDataType.BODY_FAT_PERCENTAGE: 'BODY_FAT_PERCENTAGE',
  HealthDataType.LEAN_BODY_MASS: 'LEAN_BODY_MASS',
  HealthDataType.BODY_MASS_INDEX: 'BODY_MASS_INDEX',
  HealthDataType.BODY_TEMPERATURE: 'BODY_TEMPERATURE',
  HealthDataType.BODY_WATER_MASS: 'BODY_WATER_MASS',
  HealthDataType.DIETARY_CARBS_CONSUMED: 'DIETARY_CARBS_CONSUMED',
  HealthDataType.DIETARY_CAFFEINE: 'DIETARY_CAFFEINE',
  HealthDataType.DIETARY_ENERGY_CONSUMED: 'DIETARY_ENERGY_CONSUMED',
  HealthDataType.DIETARY_FATS_CONSUMED: 'DIETARY_FATS_CONSUMED',
  HealthDataType.DIETARY_PROTEIN_CONSUMED: 'DIETARY_PROTEIN_CONSUMED',
  HealthDataType.DIETARY_FIBER: 'DIETARY_FIBER',
  HealthDataType.DIETARY_SUGAR: 'DIETARY_SUGAR',
  HealthDataType.DIETARY_FAT_MONOUNSATURATED: 'DIETARY_FAT_MONOUNSATURATED',
  HealthDataType.DIETARY_FAT_POLYUNSATURATED: 'DIETARY_FAT_POLYUNSATURATED',
  HealthDataType.DIETARY_FAT_SATURATED: 'DIETARY_FAT_SATURATED',
  HealthDataType.DIETARY_CHOLESTEROL: 'DIETARY_CHOLESTEROL',
  HealthDataType.DIETARY_VITAMIN_A: 'DIETARY_VITAMIN_A',
  HealthDataType.DIETARY_THIAMIN: 'DIETARY_THIAMIN',
  HealthDataType.DIETARY_RIBOFLAVIN: 'DIETARY_RIBOFLAVIN',
  HealthDataType.DIETARY_NIACIN: 'DIETARY_NIACIN',
  HealthDataType.DIETARY_PANTOTHENIC_ACID: 'DIETARY_PANTOTHENIC_ACID',
  HealthDataType.DIETARY_VITAMIN_B6: 'DIETARY_VITAMIN_B6',
  HealthDataType.DIETARY_BIOTIN: 'DIETARY_BIOTIN',
  HealthDataType.DIETARY_VITAMIN_B12: 'DIETARY_VITAMIN_B12',
  HealthDataType.DIETARY_VITAMIN_C: 'DIETARY_VITAMIN_C',
  HealthDataType.DIETARY_VITAMIN_D: 'DIETARY_VITAMIN_D',
  HealthDataType.DIETARY_VITAMIN_E: 'DIETARY_VITAMIN_E',
  HealthDataType.DIETARY_VITAMIN_K: 'DIETARY_VITAMIN_K',
  HealthDataType.DIETARY_FOLATE: 'DIETARY_FOLATE',
  HealthDataType.DIETARY_CALCIUM: 'DIETARY_CALCIUM',
  HealthDataType.DIETARY_CHLORIDE: 'DIETARY_CHLORIDE',
  HealthDataType.DIETARY_IRON: 'DIETARY_IRON',
  HealthDataType.DIETARY_MAGNESIUM: 'DIETARY_MAGNESIUM',
  HealthDataType.DIETARY_PHOSPHORUS: 'DIETARY_PHOSPHORUS',
  HealthDataType.DIETARY_POTASSIUM: 'DIETARY_POTASSIUM',
  HealthDataType.DIETARY_SODIUM: 'DIETARY_SODIUM',
  HealthDataType.DIETARY_ZINC: 'DIETARY_ZINC',
  HealthDataType.DIETARY_CHROMIUM: 'DIETARY_CHROMIUM',
  HealthDataType.DIETARY_COPPER: 'DIETARY_COPPER',
  HealthDataType.DIETARY_IODINE: 'DIETARY_IODINE',
  HealthDataType.DIETARY_MANGANESE: 'DIETARY_MANGANESE',
  HealthDataType.DIETARY_MOLYBDENUM: 'DIETARY_MOLYBDENUM',
  HealthDataType.DIETARY_SELENIUM: 'DIETARY_SELENIUM',
  HealthDataType.FORCED_EXPIRATORY_VOLUME: 'FORCED_EXPIRATORY_VOLUME',
  HealthDataType.HEART_RATE: 'HEART_RATE',
  HealthDataType.HEART_RATE_VARIABILITY_SDNN: 'HEART_RATE_VARIABILITY_SDNN',
  HealthDataType.HEART_RATE_VARIABILITY_RMSSD: 'HEART_RATE_VARIABILITY_RMSSD',
  HealthDataType.HEIGHT: 'HEIGHT',
  HealthDataType.INSULIN_DELIVERY: 'INSULIN_DELIVERY',
  HealthDataType.RESTING_HEART_RATE: 'RESTING_HEART_RATE',
  HealthDataType.RESPIRATORY_RATE: 'RESPIRATORY_RATE',
  HealthDataType.PERIPHERAL_PERFUSION_INDEX: 'PERIPHERAL_PERFUSION_INDEX',
  HealthDataType.STEPS: 'STEPS',
  HealthDataType.WAIST_CIRCUMFERENCE: 'WAIST_CIRCUMFERENCE',
  HealthDataType.WALKING_HEART_RATE: 'WALKING_HEART_RATE',
  HealthDataType.WEIGHT: 'WEIGHT',
  HealthDataType.DISTANCE_WALKING_RUNNING: 'DISTANCE_WALKING_RUNNING',
  HealthDataType.DISTANCE_SWIMMING: 'DISTANCE_SWIMMING',
  HealthDataType.DISTANCE_CYCLING: 'DISTANCE_CYCLING',
  HealthDataType.FLIGHTS_CLIMBED: 'FLIGHTS_CLIMBED',
  HealthDataType.DISTANCE_DELTA: 'DISTANCE_DELTA',
  HealthDataType.WALKING_SPEED: 'WALKING_SPEED',
  HealthDataType.SPEED: 'SPEED',
  HealthDataType.MINDFULNESS: 'MINDFULNESS',
  HealthDataType.WATER: 'WATER',
  HealthDataType.SLEEP_ASLEEP: 'SLEEP_ASLEEP',
  HealthDataType.SLEEP_AWAKE_IN_BED: 'SLEEP_AWAKE_IN_BED',
  HealthDataType.SLEEP_AWAKE: 'SLEEP_AWAKE',
  HealthDataType.SLEEP_DEEP: 'SLEEP_DEEP',
  HealthDataType.SLEEP_IN_BED: 'SLEEP_IN_BED',
  HealthDataType.SLEEP_LIGHT: 'SLEEP_LIGHT',
  HealthDataType.SLEEP_OUT_OF_BED: 'SLEEP_OUT_OF_BED',
  HealthDataType.SLEEP_REM: 'SLEEP_REM',
  HealthDataType.SLEEP_SESSION: 'SLEEP_SESSION',
  HealthDataType.SLEEP_UNKNOWN: 'SLEEP_UNKNOWN',
  HealthDataType.EXERCISE_TIME: 'EXERCISE_TIME',
  HealthDataType.WORKOUT: 'WORKOUT',
  HealthDataType.WORKOUT_ROUTE: 'WORKOUT_ROUTE',
  HealthDataType.HEADACHE_NOT_PRESENT: 'HEADACHE_NOT_PRESENT',
  HealthDataType.HEADACHE_MILD: 'HEADACHE_MILD',
  HealthDataType.HEADACHE_MODERATE: 'HEADACHE_MODERATE',
  HealthDataType.HEADACHE_SEVERE: 'HEADACHE_SEVERE',
  HealthDataType.HEADACHE_UNSPECIFIED: 'HEADACHE_UNSPECIFIED',
  HealthDataType.NUTRITION: 'NUTRITION',
  HealthDataType.UV_INDEX: 'UV_INDEX',
  HealthDataType.GENDER: 'GENDER',
  HealthDataType.BIRTH_DATE: 'BIRTH_DATE',
  HealthDataType.BLOOD_TYPE: 'BLOOD_TYPE',
  HealthDataType.MENSTRUATION_FLOW: 'MENSTRUATION_FLOW',
  HealthDataType.WATER_TEMPERATURE: 'WATER_TEMPERATURE',
  HealthDataType.UNDERWATER_DEPTH: 'UNDERWATER_DEPTH',
  HealthDataType.SLEEP_WRIST_TEMPERATURE: 'SLEEP_WRIST_TEMPERATURE',
  HealthDataType.HIGH_HEART_RATE_EVENT: 'HIGH_HEART_RATE_EVENT',
  HealthDataType.LOW_HEART_RATE_EVENT: 'LOW_HEART_RATE_EVENT',
  HealthDataType.IRREGULAR_HEART_RATE_EVENT: 'IRREGULAR_HEART_RATE_EVENT',
  HealthDataType.ELECTRODERMAL_ACTIVITY: 'ELECTRODERMAL_ACTIVITY',
  HealthDataType.ELECTROCARDIOGRAM: 'ELECTROCARDIOGRAM',
  HealthDataType.TOTAL_CALORIES_BURNED: 'TOTAL_CALORIES_BURNED',
  HealthDataType.ACTIVITY_INTENSITY: 'ACTIVITY_INTENSITY',
  HealthDataType.SKIN_TEMPERATURE: 'SKIN_TEMPERATURE',
};

HealthData _$HealthDataFromJson(Map<String, dynamic> json) => HealthData(
  uuid: json['uuid'] as String,
  value: HealthValue.fromJson(json['value'] as Map<String, dynamic>),
  unit: json['unit'] as String,
  healthDataType: json['healthDataType'] as String,
  dateFrom: DateTime.parse(json['dateFrom'] as String),
  dateTo: DateTime.parse(json['dateTo'] as String),
  platform: $enumDecode(_$HealthPlatformEnumMap, json['platform']),
  deviceId: json['deviceId'] as String?,
  sourceId: json['sourceId'] as String?,
  sourceName: json['sourceName'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$HealthDataToJson(HealthData instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'uuid': instance.uuid,
      'value': instance.value.toJson(),
      'unit': instance.unit,
      'healthDataType': instance.healthDataType,
      'dateFrom': instance.dateFrom.toIso8601String(),
      'dateTo': instance.dateTo.toIso8601String(),
      'platform': _$HealthPlatformEnumMap[instance.platform]!,
      'deviceId': ?instance.deviceId,
      'sourceId': ?instance.sourceId,
      'sourceName': ?instance.sourceName,
    };

const _$HealthPlatformEnumMap = {
  HealthPlatform.APPLE_HEALTH: 'APPLE_HEALTH',
  HealthPlatform.GOOGLE_HEALTH_CONNECT: 'GOOGLE_HEALTH_CONNECT',
};

DummyHealthData _$DummyHealthDataFromJson(Map<String, dynamic> json) =>
    DummyHealthData(uuid: json['uuid'] as String)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$DummyHealthDataToJson(DummyHealthData instance) =>
    <String, dynamic>{'__type': ?instance.$type, 'uuid': instance.uuid};

HealthAppTask _$HealthAppTaskFromJson(Map<String, dynamic> json) =>
    HealthAppTask(
      type: json['type'] as String? ?? AppTask.HEALTH_ASSESSMENT_TYPE,
      name: json['name'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      minutesToComplete: (json['minutesToComplete'] as num?)?.toInt(),
      expire: json['expire'] == null
          ? null
          : Duration(microseconds: (json['expire'] as num).toInt()),
      notification: json['notification'] as bool? ?? false,
      measures: (json['measures'] as List<dynamic>?)
          ?.map((e) => Measure.fromJson(e as Map<String, dynamic>))
          .toList(),
      types:
          (json['types'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$HealthDataTypeEnumMap, e))
              .toList() ??
          const [],
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$HealthAppTaskToJson(HealthAppTask instance) =>
    <String, dynamic>{
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
      'types': instance.types.map((e) => _$HealthDataTypeEnumMap[e]!).toList(),
    };

HealthService _$HealthServiceFromJson(Map<String, dynamic> json) =>
    HealthService(
        roleName:
            json['roleName'] as String? ?? HealthService.DEFAULT_ROLE_NAME,
      )
      ..$type = json['__type'] as String?
      ..isOptional = json['isOptional'] as bool?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$HealthServiceToJson(HealthService instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
    };
