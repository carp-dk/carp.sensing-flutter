/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'transportation.dart';

/// A transportation mode, as predicted for a [TransportationSample] (point-wise)
/// or a [Stage] (stage-wise).
///
/// The set of modes supported by a deployment is configured in
/// [TransportationModelConfiguration.modeLabels]. Since the server-side
/// classifier may evolve and return labels not yet known to this client,
/// deserialization of an unknown label falls back to [other] instead of failing.
enum TransportationMode {
  walk,
  bike,
  car,
  bus,
  train,

  /// The user is not moving - the mode of a [StopStage].
  stationary,

  /// Mode could not be determined.
  unknown,

  /// A mode not (yet) known to this client - see enum-level doc.
  other,
}

/// The semantic category of a [MobilityActivity].
enum MobilityActivityType {
  home,
  work,
  education,
  shopping,
  food,
  leisure,
  exercise,
  transfer,
  other,
  unknown,
}

/// Configuration of the transportation recognition model, collected once when
/// the recognition component is initialized.
///
/// These attributes normally remain unchanged during a sensing session, and
/// are therefore not repeated on every [TransportationSample].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TransportationModelConfiguration extends Data {
  /// Name of the model used to generate [TransportationSample.embedding].
  String? embeddingModel;

  /// Mapping from mode index to transportation mode label,
  /// e.g. `{0: 'walk', 1: 'bike', 2: 'car', 3: 'bus', 4: 'train'}`.
  Map<int, String> modeLabels;

  /// Total number of possible transportation modes.
  @JsonKey(includeFromJson: false, includeToJson: true)
  int get numModes => modeLabels.length;

  /// Main classification method or model used for mode recognition,
  /// e.g. `Transformer`.
  String? mainMethod;

  /// Method used to decode point-wise predictions, e.g. `argmax`, `HMM`, or
  /// `temporal smoothing`.
  String? decodeMethod;

  /// Operating system of the device, e.g. `Android` or `iOS`.
  String? operatingSystem;

  /// Smartphone model used for data collection.
  String? phoneModel;

  TransportationModelConfiguration({
    this.embeddingModel,
    this.modeLabels = const {},
    this.mainMethod,
    this.decodeMethod,
    this.operatingSystem,
    this.phoneModel,
  }) : super();

  @override
  Function get fromJsonFunction => _$TransportationModelConfigurationFromJson;
  factory TransportationModelConfiguration.fromJson(
    Map<String, dynamic> json,
  ) => FromJsonFactory().fromJson<TransportationModelConfiguration>(json);
  @override
  Map<String, dynamic> toJson() =>
      _$TransportationModelConfigurationToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.MODEL_CONFIGURATION;

  @override
  String toString() => '${super.toString()}, modes: ${modeLabels.values}';
}

/// A point-wise mobility sample - a location observation enriched with its
/// learned representation and the transportation mode predicted for it.
///
/// Created by the recognition component once inference on a window of raw
/// sensor samples (location, acceleration, rotation - collected by other
/// sampling packages) has completed.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TransportationSample extends Data {
  /// Unique identifier of this sample, starting from 0 and incrementing
  /// sequentially each day.
  int sampleId;

  /// Timestamp when the sample was collected.
  DateTime timestamp;

  /// Latitude of the sample location in degrees (WGS 84).
  double latitude;

  /// Longitude of the sample location in degrees (WGS 84).
  double longitude;

  /// Altitude of the sample location in meters.
  double altitude;

  /// Estimated GPS positioning accuracy in meters.
  double gpsAccuracy;

  /// Estimated instantaneous speed of the sample in m/s.
  double speed;

  /// Movement direction in degrees, clockwise from north (90 is east).
  double heading;

  /// Learned embedding representation of this sample, if available.
  List<double>? embedding;

  /// Dimension of the [embedding] vector.
  @JsonKey(includeFromJson: false, includeToJson: true)
  int? get embeddingDim => embedding?.length;

  /// Final predicted transportation mode.
  @JsonKey(unknownEnumValue: TransportationMode.other)
  TransportationMode mode;

  /// Raw classifier scores per candidate mode, e.g. `{'walk': 1.2, 'car': 2.8}`.
  Map<String, double>? logits;

  /// Probability distribution over the candidate modes (summing to 1),
  /// e.g. `{'walk': 0.12, 'car': 0.68}`.
  Map<String, double>? probabilities;

  /// Confidence of the prediction, in the range [0-1].
  ///
  /// Derived from [probabilities] using [confidenceFromProbabilities] when not
  /// given explicitly (0 when neither is available).
  double confidence;

  /// Confidence derived from the entropy of a predicted probability
  /// distribution - lower entropy means higher confidence:
  ///
  ///   `confidence = 1 - (-sum(p * log p)) / log K`
  ///
  /// where `K` is the number of candidate modes. Returns 1 when there is only
  /// one candidate mode (zero entropy).
  static double confidenceFromProbabilities(Map<String, double> probabilities) {
    if (probabilities.length < 2) return 1;
    final entropy = probabilities.values
        .where((p) => p > 0)
        .fold<double>(0, (sum, p) => sum - p * log(p));
    return 1 - entropy / log(probabilities.length);
  }

  TransportationSample({
    required this.sampleId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.gpsAccuracy = 0,
    this.speed = 0,
    this.heading = 0,
    this.embedding,
    this.mode = TransportationMode.unknown,
    this.logits,
    Map<String, double>? probabilities,
    double? confidence,
  }) : probabilities = probabilities,
       confidence =
           confidence ??
           (probabilities != null
               ? confidenceFromProbabilities(probabilities)
               : 0),
       super();

  @override
  Function get fromJsonFunction => _$TransportationSampleFromJson;
  factory TransportationSample.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<TransportationSample>(json);
  @override
  Map<String, dynamic> toJson() => _$TransportationSampleToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.TRANSPORTATION_SAMPLE;

  @override
  String toString() =>
      '${super.toString()}, sampleId: $sampleId, mode: $mode, '
      'confidence: $confidence';
}

/// Configuration of the segmentation component generating [Stage]s, collected
/// once when the component is initialized.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StageConfiguration extends Data {
  /// Identifier of the associated user.
  String userId;

  /// Method used to generate the [Stage]s.
  String? segmentMethod;

  StageConfiguration({required this.userId, this.segmentMethod}) : super();

  @override
  Function get fromJsonFunction => _$StageConfigurationFromJson;
  factory StageConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<StageConfiguration>(json);
  @override
  Map<String, dynamic> toJson() => _$StageConfigurationToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.STAGE_CONFIGURATION;

  @override
  String toString() => '${super.toString()}, userId: $userId';
}

/// A continuous temporal interval in a user's mobility timeline, obtained by
/// grouping consecutive [TransportationSample]s.
///
/// Base class of the two stage types: [MoveStage] and [StopStage].
abstract class Stage extends Data {
  /// Unique identifier of this stage, assigned sequentially in temporal order.
  int stageId;

  /// Identifier of the first [TransportationSample] in this stage.
  int startSampleId;

  /// Identifier of the last [TransportationSample] in this stage.
  int endSampleId;

  /// Start time of this stage - the timestamp of its first sample.
  DateTime startTime;

  /// End time of this stage - the timestamp of its last sample.
  DateTime endTime;

  /// Final predicted transportation mode of this stage.
  @JsonKey(unknownEnumValue: TransportationMode.other)
  TransportationMode mode;

  /// Confidence of the stage detection / classification, in the range [0-1].
  double? confidence;

  /// Quality score associated with the data collection accuracy.
  double? quality;

  /// Number of samples included in this stage.
  @JsonKey(includeFromJson: false, includeToJson: true)
  int get numSamples => endSampleId - startSampleId + 1;

  /// Duration of this stage in minutes.
  @JsonKey(includeFromJson: false, includeToJson: true)
  double get durationInMinutes =>
      endTime.difference(startTime).inMilliseconds / Duration.millisecondsPerMinute;

  Stage({
    required this.stageId,
    required this.startSampleId,
    required this.endSampleId,
    required this.startTime,
    required this.endTime,
    required this.mode,
    this.confidence,
    this.quality,
  }) : super();

  @override
  String toString() =>
      '${super.toString()}, stageId: $stageId, mode: $mode, '
      'duration: $durationInMinutes min';
}

/// A [Stage] during which the user is moving between locations.
///
/// The movement-specific attributes are derived from the point-wise samples
/// contained in the stage - see [MoveStage.fromSamples].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MoveStage extends Stage {
  /// Total traveled distance in meters, summed over consecutive samples.
  double distance;

  /// Latitude at the beginning of the movement.
  double startLatitude;

  /// Longitude at the beginning of the movement.
  double startLongitude;

  /// Latitude at the end of the movement.
  double endLatitude;

  /// Longitude at the end of the movement.
  double endLongitude;

  /// Mean speed during this stage in m/s.
  double? speedMean;

  /// Standard deviation of the speed during this stage in m/s.
  double? speedStd;

  /// Minimum observed speed during this stage in m/s.
  double? speedMin;

  /// Maximum observed speed during this stage in m/s.
  double? speedMax;

  /// Is this stage associated with public transport?
  bool isPublicTransport;

  /// Identifier of the public-transport stop or station where the movement
  /// begins.
  String? originStop;

  /// Identifier of the public-transport stop or station where the movement ends.
  String? destinationStop;

  /// Identifier or name of the most likely public-transport line used,
  /// e.g. `6A`, `150S`, or `M1`.
  String? transitLine;

  /// Top candidate public-transport lines and their probabilities,
  /// e.g. `{'150S': 0.72, '6A': 0.18}`.
  Map<String, double>? transitLineCandidates;

  MoveStage({
    required super.stageId,
    required super.startSampleId,
    required super.endSampleId,
    required super.startTime,
    required super.endTime,
    super.mode = TransportationMode.unknown,
    super.confidence,
    super.quality,
    this.distance = 0,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    this.speedMean,
    this.speedStd,
    this.speedMin,
    this.speedMax,
    this.isPublicTransport = false,
    this.originStop,
    this.destinationStop,
    this.transitLine,
    this.transitLineCandidates,
  });

  /// Create a [MoveStage] from the consecutive [samples] it spans, deriving the
  /// boundaries, the traveled [distance], and the speed statistics.
  ///
  /// The [samples] must be in temporal order.
  factory MoveStage.fromSamples(
    List<TransportationSample> samples, {
    required int stageId,
    TransportationMode mode = TransportationMode.unknown,
    double? confidence,
    bool isPublicTransport = false,
  }) {
    if (samples.isEmpty) {
      throw ArgumentError('A MoveStage must span at least one sample.');
    }
    final speeds = samples.map((sample) => sample.speed).toList();
    final mean = speeds.reduce((a, b) => a + b) / speeds.length;

    return MoveStage(
      stageId: stageId,
      startSampleId: samples.first.sampleId,
      endSampleId: samples.last.sampleId,
      startTime: samples.first.timestamp,
      endTime: samples.last.timestamp,
      mode: mode,
      confidence: confidence,
      distance: _traveledDistance(samples),
      startLatitude: samples.first.latitude,
      startLongitude: samples.first.longitude,
      endLatitude: samples.last.latitude,
      endLongitude: samples.last.longitude,
      speedMean: mean,
      speedStd: sqrt(
        speeds.fold<double>(0, (sum, s) => sum + pow(s - mean, 2)) /
            speeds.length,
      ),
      speedMin: speeds.reduce(min),
      speedMax: speeds.reduce(max),
      isPublicTransport: isPublicTransport,
    );
  }

  @override
  Function get fromJsonFunction => _$MoveStageFromJson;
  factory MoveStage.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MoveStage>(json);
  @override
  Map<String, dynamic> toJson() => _$MoveStageToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.MOVE;

  @override
  String toString() => '${super.toString()}, distance: $distance m';
}

/// A [Stage] during which the user stays within a relatively small
/// geographical area.
///
/// The spatial attributes are derived from the point-wise samples contained in
/// the stage - see [StopStage.fromSamples].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StopStage extends Stage {
  /// Latitude of the spatial centroid of this stop.
  double centroidLatitude;

  /// Longitude of the spatial centroid of this stop.
  double centroidLongitude;

  /// Maximum spatial displacement from the centroid observed within this stop,
  /// in meters.
  double? maxDisplacement;

  /// Most likely point of interest (POI) associated with this stop.
  String? nearestPoi;

  /// Top candidate POIs and their distance to the centroid in meters,
  /// e.g. `{'University': 18.4, 'Cafe A': 32.7}`.
  Map<String, double>? nearestPoiCandidates;

  StopStage({
    required super.stageId,
    required super.startSampleId,
    required super.endSampleId,
    required super.startTime,
    required super.endTime,
    super.mode = TransportationMode.stationary,
    super.confidence,
    super.quality,
    required this.centroidLatitude,
    required this.centroidLongitude,
    this.maxDisplacement,
    this.nearestPoi,
    this.nearestPoiCandidates,
  });

  /// Create a [StopStage] from the consecutive [samples] it spans, deriving the
  /// boundaries, the spatial centroid, and the maximum displacement.
  ///
  /// The [samples] must be in temporal order.
  factory StopStage.fromSamples(
    List<TransportationSample> samples, {
    required int stageId,
    double? confidence,
  }) {
    if (samples.isEmpty) {
      throw ArgumentError('A StopStage must span at least one sample.');
    }
    final centroidLatitude =
        samples.map((s) => s.latitude).reduce((a, b) => a + b) / samples.length;
    final centroidLongitude =
        samples.map((s) => s.longitude).reduce((a, b) => a + b) / samples.length;

    return StopStage(
      stageId: stageId,
      startSampleId: samples.first.sampleId,
      endSampleId: samples.last.sampleId,
      startTime: samples.first.timestamp,
      endTime: samples.last.timestamp,
      confidence: confidence,
      centroidLatitude: centroidLatitude,
      centroidLongitude: centroidLongitude,
      maxDisplacement: samples
          .map(
            (s) => _distanceBetween(
              centroidLatitude,
              centroidLongitude,
              s.latitude,
              s.longitude,
            ),
          )
          .reduce(max),
    );
  }

  @override
  Function get fromJsonFunction => _$StopStageFromJson;
  factory StopStage.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<StopStage>(json);
  @override
  Map<String, dynamic> toJson() => _$StopStageToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.STOP;

  @override
  String toString() =>
      '${super.toString()}, centroid: ($centroidLatitude, $centroidLongitude)';
}

/// The semantic interpretation of a meaningful [StopStage] - what the user is doing
/// at that location, e.g. being at home, working, or shopping.
///
/// Named `MobilityActivity` (and not `Activity`, as in the design spec) to
/// avoid clashing with the `Activity` data type of `carp_context_package`,
/// which is typically used alongside this package.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MobilityActivity extends Data {
  /// Unique identifier of this activity.
  int activityId;

  /// Identifier of the [StopStage] this activity interprets.
  int? stopId;

  /// Predicted or annotated activity category.
  @JsonKey(unknownEnumValue: MobilityActivityType.unknown)
  MobilityActivityType activityType;

  /// Start time of this activity.
  DateTime startTime;

  /// End time of this activity.
  DateTime endTime;

  /// Duration of this activity in minutes.
  @JsonKey(includeFromJson: false, includeToJson: true)
  double get dwellTime =>
      endTime.difference(startTime).inMilliseconds / Duration.millisecondsPerMinute;

  /// Identifier of the associated place or POI.
  String? placeId;

  /// POI category associated with this activity.
  String? placeCategory;

  /// Confidence of the activity recognition, in the range [0-1].
  double? confidence;

  MobilityActivity({
    required this.activityId,
    this.stopId,
    this.activityType = MobilityActivityType.unknown,
    required this.startTime,
    required this.endTime,
    this.placeId,
    this.placeCategory,
    this.confidence,
  }) : super();

  @override
  Function get fromJsonFunction => _$MobilityActivityFromJson;
  factory MobilityActivity.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MobilityActivity>(json);
  @override
  Map<String, dynamic> toJson() => _$MobilityActivityToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.ACTIVITY;

  @override
  String toString() =>
      '${super.toString()}, activityId: $activityId, type: $activityType';
}

/// A user correction of the [TransportationMode] predicted for a [Stage],
/// leaving the stage boundaries unchanged.
///
/// The user may correct the same stage multiple times - the most recent
/// correction ([isLatest]) is the current mode label of the stage, while
/// earlier records are retained for error analysis and model improvement.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StageModeCorrection extends Data {
  /// Identifier of the user providing the correction.
  String userId;

  /// Calendar date of the corrected stage.
  DateTime date;

  /// Identifier of the stage whose mode is corrected.
  int stageId;

  /// Unique identifier of this correction record.
  String correctionId;

  /// The mode originally assigned to the stage before this correction.
  @JsonKey(unknownEnumValue: TransportationMode.other)
  TransportationMode originalMode;

  /// The mode selected by the user.
  @JsonKey(unknownEnumValue: TransportationMode.other)
  TransportationMode correctedMode;

  /// Confidence of the original mode prediction, in the range [0-1].
  double? originalConfidence;

  /// Timestamp when this correction was submitted by the user.
  DateTime feedbackTime;

  /// Is this the most recent correction for the stage?
  ///
  /// True when submitted; set to false once a later correction supersedes it.
  bool isLatest;

  /// Optional comment provided by the user regarding this correction.
  String? comment;

  StageModeCorrection({
    required this.userId,
    required this.date,
    required this.stageId,
    String? correctionId,
    required this.originalMode,
    required this.correctedMode,
    this.originalConfidence,
    required this.feedbackTime,
    this.isLatest = true,
    this.comment,
  }) : correctionId = correctionId ?? const Uuid().v4(),
       super();

  @override
  Function get fromJsonFunction => _$StageModeCorrectionFromJson;
  factory StageModeCorrection.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<StageModeCorrection>(json);
  @override
  Map<String, dynamic> toJson() => _$StageModeCorrectionToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.STAGE_MODE_CORRECTION;

  @override
  String toString() =>
      '${super.toString()}, stageId: $stageId, '
      '$originalMode -> $correctedMode';
}

/// Distance in meters between two WGS 84 coordinates.
// ponytail: haversine on a spherical earth - ~0.5% error, fine for stage-level
// statistics. Use a geodesic (Vincenty) formula if higher accuracy is needed.
double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  // clamped since rounding can push `a` just above 1 for near-antipodal
  // points, which would make `sqrt(1 - a)` NaN.
  final a = (pow(sin(dLat / 2), 2) +
          cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2))
      .clamp(0.0, 1.0);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _toRadians(double degrees) => degrees * pi / 180;

/// Distance in meters traveled along [samples], in temporal order.
double _traveledDistance(List<TransportationSample> samples) {
  var distance = 0.0;
  for (var i = 1; i < samples.length; i++) {
    distance += _distanceBetween(
      samples[i - 1].latitude,
      samples[i - 1].longitude,
      samples[i].latitude,
      samples[i].longitude,
    );
  }
  return distance;
}
