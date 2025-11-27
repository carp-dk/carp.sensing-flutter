// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudioMedia _$AudioMediaFromJson(Map<String, dynamic> json) =>
    AudioMedia(
        filename: json['filename'] as String,
        startRecordingTime: json['startRecordingTime'] == null
            ? null
            : DateTime.parse(json['startRecordingTime'] as String),
        endRecordingTime: json['endRecordingTime'] == null
            ? null
            : DateTime.parse(json['endRecordingTime'] as String),
      )
      ..$type = json['__type'] as String?
      ..path = json['path'] as String?
      ..upload = json['upload'] as bool
      ..metadata = (json['metadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      )
      ..id = json['id'] as String
      ..mediaType = $enumDecode(_$MediaTypeEnumMap, json['mediaType']);

Map<String, dynamic> _$AudioMediaToJson(AudioMedia instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'path': ?instance.path,
      'filename': instance.filename,
      'upload': instance.upload,
      'metadata': ?instance.metadata,
      'id': instance.id,
      'mediaType': _$MediaTypeEnumMap[instance.mediaType]!,
      'startRecordingTime': ?instance.startRecordingTime?.toIso8601String(),
      'endRecordingTime': ?instance.endRecordingTime?.toIso8601String(),
    };

const _$MediaTypeEnumMap = {
  MediaType.audio: 'audio',
  MediaType.video: 'video',
  MediaType.image: 'image',
};

ImageMedia _$ImageMediaFromJson(Map<String, dynamic> json) =>
    ImageMedia(
        filename: json['filename'] as String,
        startRecordingTime: json['startRecordingTime'] == null
            ? null
            : DateTime.parse(json['startRecordingTime'] as String),
        endRecordingTime: json['endRecordingTime'] == null
            ? null
            : DateTime.parse(json['endRecordingTime'] as String),
      )
      ..$type = json['__type'] as String?
      ..path = json['path'] as String?
      ..upload = json['upload'] as bool
      ..metadata = (json['metadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      )
      ..id = json['id'] as String
      ..mediaType = $enumDecode(_$MediaTypeEnumMap, json['mediaType']);

Map<String, dynamic> _$ImageMediaToJson(ImageMedia instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'path': ?instance.path,
      'filename': instance.filename,
      'upload': instance.upload,
      'metadata': ?instance.metadata,
      'id': instance.id,
      'mediaType': _$MediaTypeEnumMap[instance.mediaType]!,
      'startRecordingTime': ?instance.startRecordingTime?.toIso8601String(),
      'endRecordingTime': ?instance.endRecordingTime?.toIso8601String(),
    };

VideoMedia _$VideoMediaFromJson(Map<String, dynamic> json) =>
    VideoMedia(
        filename: json['filename'] as String,
        startRecordingTime: json['startRecordingTime'] == null
            ? null
            : DateTime.parse(json['startRecordingTime'] as String),
        endRecordingTime: json['endRecordingTime'] == null
            ? null
            : DateTime.parse(json['endRecordingTime'] as String),
      )
      ..$type = json['__type'] as String?
      ..path = json['path'] as String?
      ..upload = json['upload'] as bool
      ..metadata = (json['metadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      )
      ..id = json['id'] as String
      ..mediaType = $enumDecode(_$MediaTypeEnumMap, json['mediaType']);

Map<String, dynamic> _$VideoMediaToJson(VideoMedia instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'path': ?instance.path,
      'filename': instance.filename,
      'upload': instance.upload,
      'metadata': ?instance.metadata,
      'id': instance.id,
      'mediaType': _$MediaTypeEnumMap[instance.mediaType]!,
      'startRecordingTime': ?instance.startRecordingTime?.toIso8601String(),
      'endRecordingTime': ?instance.endRecordingTime?.toIso8601String(),
    };

Noise _$NoiseFromJson(Map<String, dynamic> json) => Noise(
  meanDecibel: (json['meanDecibel'] as num).toDouble(),
  stdDecibel: (json['stdDecibel'] as num).toDouble(),
  minDecibel: (json['minDecibel'] as num).toDouble(),
  maxDecibel: (json['maxDecibel'] as num).toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$NoiseToJson(Noise instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'meanDecibel': instance.meanDecibel,
  'stdDecibel': instance.stdDecibel,
  'minDecibel': instance.minDecibel,
  'maxDecibel': instance.maxDecibel,
};
