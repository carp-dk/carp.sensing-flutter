part of '../../carp_context_package.dart';

/// A sampling configuration for location sampling.
/// This configuration allows for specifying if the location should be sampled only once,
/// or at a fixed [period] instead of whenever the OS reports a new location.
///
/// Usage:
///
/// ```dart
/// Measure(type: ContextSamplingPackage.LOCATION)
///   ..overrideSamplingConfiguration = LocationSamplingConfiguration(once: true),
/// ```
///
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LocationSamplingConfiguration extends SamplingConfiguration {
  /// Should the location be sampled only once?
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
