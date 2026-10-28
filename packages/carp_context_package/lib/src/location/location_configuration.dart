part of '../../carp_context_package.dart';

/// A sampling configuration for the [ContextSamplingPackage.LOCATION] measure.
///
/// Set [once] to collect a single location instead of a continuous stream.
/// Set [period] to emit a location every period, repeating the last fix if the
/// OS reported none.
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

  /// If set, a location is emitted every [period] (the latest fix, repeated if the
  /// OS has not reported a new one), instead of whenever the OS reports a location.
  Duration? period;

  LocationSamplingConfiguration({this.once = false, this.period}) : super();

  @override
  Map<String, dynamic> toJson() => _$LocationSamplingConfigurationToJson(this);
  @override
  Function get fromJsonFunction => _$LocationSamplingConfigurationFromJson;
  factory LocationSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<LocationSamplingConfiguration>(json);
}
