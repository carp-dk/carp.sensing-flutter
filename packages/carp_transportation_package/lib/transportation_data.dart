/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'transportation.dart';

/// A single GPS fix as part of a [Route].
///
/// Mirrors the field names of the core [Geolocation] data type, but is kept
/// as a plain nested object (like [BeaconRegion] in the connectivity
/// package) since it is never sent standalone - only as part of a [Route] or
/// as a location cluster in [UserFeedback].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RoutePoint {
  /// Latitude in GPS coordinates (WGS 84).
  double latitude;

  /// Longitude in GPS coordinates (WGS 84).
  double longitude;

  /// The time when this point was collected.
  DateTime timestamp;

  /// Estimated horizontal accuracy of this location, radial, in meters.
  double? accuracy;

  /// Movement speed, in meters/second, if available.
  double? speed;

  /// Altitude in meters above the WGS 84 reference ellipsoid, if available.
  double? altitude;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.altitude,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) =>
      _$RoutePointFromJson(json);
  Map<String, dynamic> toJson() => _$RoutePointToJson(this);

  @override
  String toString() =>
      '$runtimeType - lat: $latitude, lon: $longitude, timestamp: $timestamp';
}

/// A [Data] type holding the GPS trace of a route as collected on the phone.
///
/// This is what the client sends to the server for classification.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Route extends Data {
  /// A unique identifier of this route.
  ///
  /// Used to correlate the [Mode] classification and any [UserFeedback]
  /// returned/sent for this route.
  String id;

  /// Timestamp of the first point in this route.
  DateTime startTime;

  /// Timestamp of the last point in this route, if the route is complete.
  DateTime? endTime;

  /// The GPS points collected for this route, in chronological order.
  List<RoutePoint> points;

  Route({
    String? id,
    required this.startTime,
    this.endTime,
    this.points = const [],
  }) : id = id ?? const Uuid().v4(),
       super();

  @override
  Function get fromJsonFunction => _$RouteFromJson;
  factory Route.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Route>(json);
  @override
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.ROUTE;

  @override
  String toString() =>
      '${super.toString()}, id: $id, points: ${points.length}';
}

/// The detected transportation mode of a [RouteSegment].
///
/// Note the [other] value: since the server-side classifier may evolve and
/// return mode values not yet known to this client, deserialization of an
/// unrecognized mode string falls back to [other] instead of failing - see
/// the `unknownEnumValue` on [RouteSegment.mode].
enum TransportationModeType {
  walking,
  running,
  cycling,
  car,
  bus,
  train,
  tram,
  subway,
  ferry,
  plane,

  /// The user was not moving (e.g. at home, at work).
  stationary,

  /// Mode could not be determined.
  unknown,

  /// A mode not (yet) known to this client - see enum-level doc.
  other,
}

/// One segment of a classified [Route], as returned by the server, holding
/// the time span, the start/end location, and the detected [mode].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RouteSegment {
  /// Start time of this segment.
  DateTime startTime;

  /// End time of this segment.
  DateTime endTime;

  /// The location where this segment starts, if available.
  RoutePoint? startLocation;

  /// The location where this segment ends, if available.
  RoutePoint? endLocation;

  /// The transportation mode detected for this segment.
  @JsonKey(unknownEnumValue: TransportationModeType.other)
  TransportationModeType mode;

  /// The server's confidence in this classification, in the range [0-1],
  /// if available.
  double? confidence;

  /// Any additional, server-specific information about this segment.
  ///
  /// Kept as a free-form map since the exact shape of server-side
  /// classification metadata is not yet fixed.
  Map<String, dynamic>? metadata;

  RouteSegment({
    required this.startTime,
    required this.endTime,
    this.startLocation,
    this.endLocation,
    this.mode = TransportationModeType.unknown,
    this.confidence,
    this.metadata,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) =>
      _$RouteSegmentFromJson(json);
  Map<String, dynamic> toJson() => _$RouteSegmentToJson(this);

  @override
  String toString() =>
      '$runtimeType - mode: $mode, start: $startTime, end: $endTime';
}

/// A [Data] type holding the transportation mode classification of a
/// [Route], as returned by the server.
///
/// This is what the client receives from the server: the [routeId] refers
/// back to the [Route] that was sent, split into a list of [segments], each
/// labelled with a detected [TransportationModeType].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Mode extends Data {
  /// The id of the [Route] that this classification applies to.
  String routeId;

  /// The route split into segments, each with a detected transportation mode.
  List<RouteSegment> segments;

  /// Any additional, server-specific information about this classification.
  Map<String, dynamic>? metadata;

  Mode({required this.routeId, this.segments = const [], this.metadata})
    : super();

  @override
  Function get fromJsonFunction => _$ModeFromJson;
  factory Mode.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Mode>(json);
  @override
  Map<String, dynamic> toJson() => _$ModeToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.MODE;

  @override
  String toString() =>
      '${super.toString()}, routeId: $routeId, segments: ${segments.length}';
}

/// The kind of feedback a user gave on a [Mode] classification.
enum FeedbackType {
  /// The user confirmed a segment's detected mode is correct.
  approved,

  /// The user rejected a segment's detected mode (without providing a
  /// correction).
  rejected,

  /// The user corrected a segment's mode - see [UserFeedback.correctedMode].
  corrected,

  /// The user labeled a cluster of locations - see [UserFeedback.placeLabel]
  /// and [UserFeedback.locationCluster].
  labeled,
}

/// Common, well-known [UserFeedback.placeLabel] values.
///
/// This is a set of suggested labels, not an exhaustive/closed list - the
/// user may enter any free-form label, hence [UserFeedback.placeLabel] is a
/// [String] and not an enum.
class PlaceLabel {
  static const String home = 'home';
  static const String work = 'work';
  static const String restaurant = 'restaurant';
  static const String gym = 'gym';
  static const String school = 'school';
}

/// A [Data] type holding user feedback on a [Mode] classification.
///
/// This is what the client sends back to the server after the user
/// interacts with a classified route, e.g.:
///
///  * approving or rejecting the detected mode of a route segment
///    ([FeedbackType.approved]/[FeedbackType.rejected]),
///  * correcting the mode of a route segment ([FeedbackType.corrected]),
///  * labeling a cluster of locations, e.g. as home, work, or restaurant
///    ([FeedbackType.labeled]).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UserFeedback extends Data {
  /// The id of the [Route] that this feedback applies to.
  String routeId;

  /// Start time of the [RouteSegment] this feedback applies to.
  ///
  /// Null when the feedback is a location cluster [FeedbackType.labeled]
  /// event, which is not tied to a specific segment.
  DateTime? segmentStartTime;

  /// End time of the [RouteSegment] this feedback applies to.
  DateTime? segmentEndTime;

  /// The type of feedback given.
  FeedbackType feedbackType;

  /// The transportation mode the user corrected a segment to.
  /// Set when [feedbackType] is [FeedbackType.corrected].
  @JsonKey(unknownEnumValue: TransportationModeType.other)
  TransportationModeType? correctedMode;

  /// A free-form label of a cluster of locations (e.g. 'home', 'work',
  /// 'restaurant' - see [PlaceLabel] for common suggestions).
  /// Set when [feedbackType] is [FeedbackType.labeled].
  String? placeLabel;

  /// The cluster of locations that [placeLabel] applies to.
  /// Set when [feedbackType] is [FeedbackType.labeled].
  List<RoutePoint>? locationCluster;

  /// An optional free-text comment from the user.
  String? comment;

  /// Any additional information about this feedback.
  Map<String, dynamic>? metadata;

  UserFeedback({
    required this.routeId,
    this.segmentStartTime,
    this.segmentEndTime,
    required this.feedbackType,
    this.correctedMode,
    this.placeLabel,
    this.locationCluster,
    this.comment,
    this.metadata,
  }) : super();

  @override
  Function get fromJsonFunction => _$UserFeedbackFromJson;
  factory UserFeedback.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<UserFeedback>(json);
  @override
  Map<String, dynamic> toJson() => _$UserFeedbackToJson(this);

  @override
  String get jsonType => TransportationSamplingPackage.USER_FEEDBACK;

  @override
  String toString() =>
      '${super.toString()}, routeId: $routeId, feedbackType: $feedbackType';
}
