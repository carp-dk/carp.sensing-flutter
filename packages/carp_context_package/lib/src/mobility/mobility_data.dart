part of '../../carp_context_package.dart';

/// Daily mobility features computed from the phone's location.
///
/// Produced by [MobilityProbe] for the [ContextSamplingPackage.MOBILITY]
/// measure, using the `mobility_features` plugin. Features are for one day
/// ([date]) and are updated during the day.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Mobility extends Data {
  /// The time this data was computed. Defaults to now.
  DateTime? timestamp;

  // TODO - make this a day instead of a date time.
  /// The day these mobility features are for.
  DateTime? date;

  /// Number of stops made on [date].
  int? numberOfStops;

  /// Number of moves made on [date].
  int? numberOfMoves;

  /// Number of significant places visited on [date].
  int? numberOfPlaces;

  /// Location variance on [date].
  double? locationVariance;

  /// Location entropy on [date].
  ///  * High entropy: Time is spent evenly among all places
  ///  * Low  entropy: Time is mainly spent at a few of the places
  double? entropy;

  /// Normalized entropy on [date]. A scalar between 0 and 1.
  double? normalizedEntropy;

  /// Home stay on [date]: the fraction of time spent at home, between 0 and 1.
  double? homeStay;

  /// Distance traveled on [date], in meters.
  double? distanceTraveled;

  Mobility({
    this.timestamp,
    this.date,
    this.numberOfStops,
    this.numberOfMoves,
    this.numberOfPlaces,
    this.locationVariance,
    this.entropy,
    this.normalizedEntropy,
    this.homeStay,
    this.distanceTraveled,
  }) : super() {
    timestamp ??= DateTime.now();
  }

  /// Creates a [Mobility] from a `MobilityContext` from the
  /// `mobility_features` plugin.
  factory Mobility.fromMobilityContext(MobilityContext context) => Mobility()
    ..timestamp = context.timestamp
    ..date = context.date
    ..numberOfStops = context.numberOfStops
    ..numberOfMoves = context.numberOfMoves
    ..numberOfPlaces = context.numberOfSignificantPlaces
    ..locationVariance = context.locationVariance
    ..entropy = context.entropy
    ..normalizedEntropy = context.normalizedEntropy
    ..homeStay = context.homeStay
    ..distanceTraveled = context.distanceTraveled;

  @override
  Function get fromJsonFunction => _$MobilityFromJson;
  factory Mobility.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Mobility>(json);
  @override
  Map<String, dynamic> toJson() => _$MobilityToJson(this);
}
