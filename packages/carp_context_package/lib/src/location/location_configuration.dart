part of '../../carp_context_package.dart';

/// A sampling configuration for the [ContextSamplingPackage.LOCATION] measure.
///
/// Set [once] to collect a single location instead of a continuous stream.
/// Combine it with a periodic trigger to sample location at fixed intervals.
/// Read by [ConfigurableLocationProbe].
///
/// ```dart
/// Measure(type: ContextSamplingPackage.LOCATION)
///   ..overrideSamplingConfiguration = LocationSamplingConfiguration(once: true),
/// ```
///
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LocationSamplingConfiguration extends SamplingConfiguration {
  /// Should the location be sampled only once? Default is false (continuous).
  bool once = false;

  LocationSamplingConfiguration({this.once = false}) : super();

  @override
  Map<String, dynamic> toJson() => _$LocationSamplingConfigurationToJson(this);
  @override
  Function get fromJsonFunction => _$LocationSamplingConfigurationFromJson;
  factory LocationSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<LocationSamplingConfiguration>(json);
}
