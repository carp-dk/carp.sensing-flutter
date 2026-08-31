// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transportation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransportationModelConfiguration _$TransportationModelConfigurationFromJson(
  Map<String, dynamic> json,
) => TransportationModelConfiguration(
  embeddingModel: json['embeddingModel'] as String?,
  modeLabels:
      (json['modeLabels'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as String),
      ) ??
      const {},
  mainMethod: json['mainMethod'] as String?,
  decodeMethod: json['decodeMethod'] as String?,
  operatingSystem: json['operatingSystem'] as String?,
  phoneModel: json['phoneModel'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$TransportationModelConfigurationToJson(
  TransportationModelConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'embeddingModel': ?instance.embeddingModel,
  'modeLabels': instance.modeLabels.map((k, e) => MapEntry(k.toString(), e)),
  'numModes': instance.numModes,
  'mainMethod': ?instance.mainMethod,
  'decodeMethod': ?instance.decodeMethod,
  'operatingSystem': ?instance.operatingSystem,
  'phoneModel': ?instance.phoneModel,
};

TransportationSample _$TransportationSampleFromJson(
  Map<String, dynamic> json,
) => TransportationSample(
  sampleId: (json['sampleId'] as num).toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
  gpsAccuracy: (json['gpsAccuracy'] as num?)?.toDouble() ?? 0,
  speed: (json['speed'] as num?)?.toDouble() ?? 0,
  heading: (json['heading'] as num?)?.toDouble() ?? 0,
  embedding: (json['embedding'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
  mode:
      $enumDecodeNullable(
        _$TransportationModeEnumMap,
        json['mode'],
        unknownValue: TransportationMode.other,
      ) ??
      TransportationMode.unknown,
  logits: (json['logits'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  probabilities: (json['probabilities'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  confidence: (json['confidence'] as num?)?.toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$TransportationSampleToJson(
  TransportationSample instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sampleId': instance.sampleId,
  'timestamp': instance.timestamp.toIso8601String(),
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'altitude': instance.altitude,
  'gpsAccuracy': instance.gpsAccuracy,
  'speed': instance.speed,
  'heading': instance.heading,
  'embedding': ?instance.embedding,
  'embeddingDim': ?instance.embeddingDim,
  'mode': _$TransportationModeEnumMap[instance.mode]!,
  'logits': ?instance.logits,
  'probabilities': ?instance.probabilities,
  'confidence': instance.confidence,
};

const _$TransportationModeEnumMap = {
  TransportationMode.walk: 'walk',
  TransportationMode.bike: 'bike',
  TransportationMode.car: 'car',
  TransportationMode.bus: 'bus',
  TransportationMode.train: 'train',
  TransportationMode.stationary: 'stationary',
  TransportationMode.unknown: 'unknown',
  TransportationMode.other: 'other',
};

StageConfiguration _$StageConfigurationFromJson(Map<String, dynamic> json) =>
    StageConfiguration(
      userId: json['userId'] as String,
      segmentMethod: json['segmentMethod'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$StageConfigurationToJson(StageConfiguration instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'userId': instance.userId,
      'segmentMethod': ?instance.segmentMethod,
    };

MoveStage _$MoveStageFromJson(Map<String, dynamic> json) => MoveStage(
  stageId: (json['stageId'] as num).toInt(),
  startSampleId: (json['startSampleId'] as num).toInt(),
  endSampleId: (json['endSampleId'] as num).toInt(),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  mode:
      $enumDecodeNullable(
        _$TransportationModeEnumMap,
        json['mode'],
        unknownValue: TransportationMode.other,
      ) ??
      TransportationMode.unknown,
  confidence: (json['confidence'] as num?)?.toDouble(),
  quality: (json['quality'] as num?)?.toDouble(),
  distance: (json['distance'] as num?)?.toDouble() ?? 0,
  startLatitude: (json['startLatitude'] as num).toDouble(),
  startLongitude: (json['startLongitude'] as num).toDouble(),
  endLatitude: (json['endLatitude'] as num).toDouble(),
  endLongitude: (json['endLongitude'] as num).toDouble(),
  speedMean: (json['speedMean'] as num?)?.toDouble(),
  speedStd: (json['speedStd'] as num?)?.toDouble(),
  speedMin: (json['speedMin'] as num?)?.toDouble(),
  speedMax: (json['speedMax'] as num?)?.toDouble(),
  isPublicTransport: json['isPublicTransport'] as bool? ?? false,
  originStop: json['originStop'] as String?,
  destinationStop: json['destinationStop'] as String?,
  transitLine: json['transitLine'] as String?,
  transitLineCandidates:
      (json['transitLineCandidates'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MoveStageToJson(MoveStage instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'stageId': instance.stageId,
  'startSampleId': instance.startSampleId,
  'endSampleId': instance.endSampleId,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'mode': _$TransportationModeEnumMap[instance.mode]!,
  'confidence': ?instance.confidence,
  'quality': ?instance.quality,
  'numSamples': instance.numSamples,
  'durationInMinutes': instance.durationInMinutes,
  'distance': instance.distance,
  'startLatitude': instance.startLatitude,
  'startLongitude': instance.startLongitude,
  'endLatitude': instance.endLatitude,
  'endLongitude': instance.endLongitude,
  'speedMean': ?instance.speedMean,
  'speedStd': ?instance.speedStd,
  'speedMin': ?instance.speedMin,
  'speedMax': ?instance.speedMax,
  'isPublicTransport': instance.isPublicTransport,
  'originStop': ?instance.originStop,
  'destinationStop': ?instance.destinationStop,
  'transitLine': ?instance.transitLine,
  'transitLineCandidates': ?instance.transitLineCandidates,
};

StopStage _$StopStageFromJson(Map<String, dynamic> json) => StopStage(
  stageId: (json['stageId'] as num).toInt(),
  startSampleId: (json['startSampleId'] as num).toInt(),
  endSampleId: (json['endSampleId'] as num).toInt(),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  mode:
      $enumDecodeNullable(
        _$TransportationModeEnumMap,
        json['mode'],
        unknownValue: TransportationMode.other,
      ) ??
      TransportationMode.stationary,
  confidence: (json['confidence'] as num?)?.toDouble(),
  quality: (json['quality'] as num?)?.toDouble(),
  centroidLatitude: (json['centroidLatitude'] as num).toDouble(),
  centroidLongitude: (json['centroidLongitude'] as num).toDouble(),
  maxDisplacement: (json['maxDisplacement'] as num?)?.toDouble(),
  nearestPoi: json['nearestPoi'] as String?,
  nearestPoiCandidates: (json['nearestPoiCandidates'] as Map<String, dynamic>?)
      ?.map((k, e) => MapEntry(k, (e as num).toDouble())),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$StopStageToJson(StopStage instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'stageId': instance.stageId,
  'startSampleId': instance.startSampleId,
  'endSampleId': instance.endSampleId,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'mode': _$TransportationModeEnumMap[instance.mode]!,
  'confidence': ?instance.confidence,
  'quality': ?instance.quality,
  'numSamples': instance.numSamples,
  'durationInMinutes': instance.durationInMinutes,
  'centroidLatitude': instance.centroidLatitude,
  'centroidLongitude': instance.centroidLongitude,
  'maxDisplacement': ?instance.maxDisplacement,
  'nearestPoi': ?instance.nearestPoi,
  'nearestPoiCandidates': ?instance.nearestPoiCandidates,
};

MobilityActivity _$MobilityActivityFromJson(Map<String, dynamic> json) =>
    MobilityActivity(
      activityId: (json['activityId'] as num).toInt(),
      stopId: (json['stopId'] as num?)?.toInt(),
      activityType:
          $enumDecodeNullable(
            _$MobilityActivityTypeEnumMap,
            json['activityType'],
            unknownValue: MobilityActivityType.unknown,
          ) ??
          MobilityActivityType.unknown,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      placeId: json['placeId'] as String?,
      placeCategory: json['placeCategory'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$MobilityActivityToJson(MobilityActivity instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'activityId': instance.activityId,
      'stopId': ?instance.stopId,
      'activityType': _$MobilityActivityTypeEnumMap[instance.activityType]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'dwellTime': instance.dwellTime,
      'placeId': ?instance.placeId,
      'placeCategory': ?instance.placeCategory,
      'confidence': ?instance.confidence,
    };

const _$MobilityActivityTypeEnumMap = {
  MobilityActivityType.home: 'home',
  MobilityActivityType.work: 'work',
  MobilityActivityType.education: 'education',
  MobilityActivityType.shopping: 'shopping',
  MobilityActivityType.food: 'food',
  MobilityActivityType.leisure: 'leisure',
  MobilityActivityType.exercise: 'exercise',
  MobilityActivityType.transfer: 'transfer',
  MobilityActivityType.other: 'other',
  MobilityActivityType.unknown: 'unknown',
};

StageModeCorrection _$StageModeCorrectionFromJson(Map<String, dynamic> json) =>
    StageModeCorrection(
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      stageId: (json['stageId'] as num).toInt(),
      correctionId: json['correctionId'] as String?,
      originalMode: $enumDecode(
        _$TransportationModeEnumMap,
        json['originalMode'],
        unknownValue: TransportationMode.other,
      ),
      correctedMode: $enumDecode(
        _$TransportationModeEnumMap,
        json['correctedMode'],
        unknownValue: TransportationMode.other,
      ),
      originalConfidence: (json['originalConfidence'] as num?)?.toDouble(),
      feedbackTime: DateTime.parse(json['feedbackTime'] as String),
      isLatest: json['isLatest'] as bool? ?? true,
      comment: json['comment'] as String?,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$StageModeCorrectionToJson(
  StageModeCorrection instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'userId': instance.userId,
  'date': instance.date.toIso8601String(),
  'stageId': instance.stageId,
  'correctionId': instance.correctionId,
  'originalMode': _$TransportationModeEnumMap[instance.originalMode]!,
  'correctedMode': _$TransportationModeEnumMap[instance.correctedMode]!,
  'originalConfidence': ?instance.originalConfidence,
  'feedbackTime': instance.feedbackTime.toIso8601String(),
  'isLatest': instance.isLatest,
  'comment': ?instance.comment,
};
