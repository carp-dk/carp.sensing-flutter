// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transportation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutePoint _$RoutePointFromJson(Map<String, dynamic> json) => RoutePoint(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  accuracy: (json['accuracy'] as num?)?.toDouble(),
  speed: (json['speed'] as num?)?.toDouble(),
  altitude: (json['altitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RoutePointToJson(RoutePoint instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'accuracy': ?instance.accuracy,
      'speed': ?instance.speed,
      'altitude': ?instance.altitude,
    };

Route _$RouteFromJson(Map<String, dynamic> json) => Route(
  id: json['id'] as String?,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  points:
      (json['points'] as List<dynamic>?)
          ?.map((e) => RoutePoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
)..$type = json['__type'] as String?;

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'id': instance.id,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': ?instance.endTime?.toIso8601String(),
  'points': instance.points.map((e) => e.toJson()).toList(),
};

RouteSegment _$RouteSegmentFromJson(Map<String, dynamic> json) => RouteSegment(
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  startLocation: json['startLocation'] == null
      ? null
      : RoutePoint.fromJson(json['startLocation'] as Map<String, dynamic>),
  endLocation: json['endLocation'] == null
      ? null
      : RoutePoint.fromJson(json['endLocation'] as Map<String, dynamic>),
  mode:
      $enumDecodeNullable(
        _$TransportationModeTypeEnumMap,
        json['mode'],
        unknownValue: TransportationModeType.other,
      ) ??
      TransportationModeType.unknown,
  confidence: (json['confidence'] as num?)?.toDouble(),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RouteSegmentToJson(RouteSegment instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'startLocation': ?instance.startLocation?.toJson(),
      'endLocation': ?instance.endLocation?.toJson(),
      'mode': _$TransportationModeTypeEnumMap[instance.mode]!,
      'confidence': ?instance.confidence,
      'metadata': ?instance.metadata,
    };

const _$TransportationModeTypeEnumMap = {
  TransportationModeType.walking: 'walking',
  TransportationModeType.running: 'running',
  TransportationModeType.cycling: 'cycling',
  TransportationModeType.car: 'car',
  TransportationModeType.bus: 'bus',
  TransportationModeType.train: 'train',
  TransportationModeType.tram: 'tram',
  TransportationModeType.subway: 'subway',
  TransportationModeType.ferry: 'ferry',
  TransportationModeType.plane: 'plane',
  TransportationModeType.stationary: 'stationary',
  TransportationModeType.unknown: 'unknown',
  TransportationModeType.other: 'other',
};

Mode _$ModeFromJson(Map<String, dynamic> json) => Mode(
  routeId: json['routeId'] as String,
  segments:
      (json['segments'] as List<dynamic>?)
          ?.map((e) => RouteSegment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  metadata: json['metadata'] as Map<String, dynamic>?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$ModeToJson(Mode instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'routeId': instance.routeId,
  'segments': instance.segments.map((e) => e.toJson()).toList(),
  'metadata': ?instance.metadata,
};

UserFeedback _$UserFeedbackFromJson(Map<String, dynamic> json) => UserFeedback(
  routeId: json['routeId'] as String,
  segmentStartTime: json['segmentStartTime'] == null
      ? null
      : DateTime.parse(json['segmentStartTime'] as String),
  segmentEndTime: json['segmentEndTime'] == null
      ? null
      : DateTime.parse(json['segmentEndTime'] as String),
  feedbackType: $enumDecode(_$FeedbackTypeEnumMap, json['feedbackType']),
  correctedMode: $enumDecodeNullable(
    _$TransportationModeTypeEnumMap,
    json['correctedMode'],
    unknownValue: TransportationModeType.other,
  ),
  placeLabel: json['placeLabel'] as String?,
  locationCluster: (json['locationCluster'] as List<dynamic>?)
      ?.map((e) => RoutePoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  comment: json['comment'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$UserFeedbackToJson(
  UserFeedback instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'routeId': instance.routeId,
  'segmentStartTime': ?instance.segmentStartTime?.toIso8601String(),
  'segmentEndTime': ?instance.segmentEndTime?.toIso8601String(),
  'feedbackType': _$FeedbackTypeEnumMap[instance.feedbackType]!,
  'correctedMode': ?_$TransportationModeTypeEnumMap[instance.correctedMode],
  'placeLabel': ?instance.placeLabel,
  'locationCluster': ?instance.locationCluster?.map((e) => e.toJson()).toList(),
  'comment': ?instance.comment,
  'metadata': ?instance.metadata,
};

const _$FeedbackTypeEnumMap = {
  FeedbackType.approved: 'approved',
  FeedbackType.rejected: 'rejected',
  FeedbackType.corrected: 'corrected',
  FeedbackType.labeled: 'labeled',
};
