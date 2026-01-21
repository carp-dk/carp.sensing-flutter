part of 'media.dart';

/// Type of media.
enum MediaType { audio, video, image }

/// An abstract media data that holds the path to media file on the local device,
/// as well as the timestamps of when the recording was started and stopped
abstract class MediaData extends FileData {
  /// A unique id of this media file.
  late String id;

  /// The type of media.
  MediaType mediaType;

  /// The timestamp for start of recording, if available.
  DateTime? startRecordingTime;

  /// The timestamp for end of recording, if available.
  DateTime? endRecordingTime;

  MediaData({
    required super.filename,
    required this.mediaType,
    this.startRecordingTime,
    this.endRecordingTime,
  }) {
    id = const Uuid().v1;
  }
}

/// An audio data.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AudioMedia extends MediaData {
  AudioMedia({
    required super.filename,
    super.startRecordingTime,
    super.endRecordingTime,
  }) : super(mediaType: MediaType.audio);

  @override
  String get jsonType => MediaSamplingPackage.AUDIO;

  @override
  Function get fromJsonFunction => _$AudioMediaFromJson;
  factory AudioMedia.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AudioMedia>(json);

  @override
  Map<String, dynamic> toJson() => _$AudioMediaToJson(this);
}

/// An image data.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ImageMedia extends MediaData {
  ImageMedia({
    required super.filename,
    super.startRecordingTime,
    super.endRecordingTime,
  }) : super(mediaType: MediaType.image);

  @override
  String get jsonType => MediaSamplingPackage.IMAGE;

  @override
  Function get fromJsonFunction => _$ImageMediaFromJson;
  factory ImageMedia.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ImageMedia>(json);

  @override
  Map<String, dynamic> toJson() => _$ImageMediaToJson(this);
}

/// An video data.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VideoMedia extends MediaData {
  VideoMedia({
    required super.filename,
    super.startRecordingTime,
    super.endRecordingTime,
  }) : super(mediaType: MediaType.video);

  @override
  String get jsonType => MediaSamplingPackage.VIDEO;

  @override
  Function get fromJsonFunction => _$VideoMediaFromJson;
  factory VideoMedia.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<VideoMedia>(json);

  @override
  Map<String, dynamic> toJson() => _$VideoMediaToJson(this);
}

/// Holds the noise level in decibel of a noise sampling.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Noise extends Data {
  // The sound intensity [dB] measurement statistics for a given sampling window.

  /// Mean decibel of sampling window.
  double meanDecibel;

  /// Standard deviation (in decibel) of sampling window.
  double stdDecibel;

  /// Minimum decibel of sampling window.
  double minDecibel;

  /// Maximum decibel of sampling window.
  double maxDecibel;

  Noise({
    required this.meanDecibel,
    required this.stdDecibel,
    required this.minDecibel,
    required this.maxDecibel,
  }) : super();

  @override
  Function get fromJsonFunction => _$NoiseFromJson;
  factory Noise.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Noise>(json);
  @override
  Map<String, dynamic> toJson() => _$NoiseToJson(this);

  @override
  String toString() =>
      '${super.toString()}, mean: $meanDecibel, std: $stdDecibel, min: $minDecibel, max: $maxDecibel';
}
