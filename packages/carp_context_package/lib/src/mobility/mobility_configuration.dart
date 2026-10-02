part of '../../carp_context_package.dart';

/// The sampling configuration for the [ContextSamplingPackage.MOBILITY] measure.
///
/// Read by [MobilityProbe], which passes the values to the `mobility_features`
/// plugin.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MobilitySamplingConfiguration extends PersistentSamplingConfiguration {
  /// Should prior computed context be used? Default is true.
  ///
  /// Not currently passed on by [MobilityProbe].
  bool usePriorContexts;

  /// The radius of a stop, in meters. Default is 25.
  double stopRadius;

  /// The radius for registering a place, in meters. Default is 50.
  double placeRadius;

  /// The minimum duration of a stop. Default is 30 seconds.
  late Duration stopDuration;

  MobilitySamplingConfiguration({
    this.usePriorContexts = true,
    this.stopRadius = 25,
    this.placeRadius = 50,
    Duration? stopDuration,
  }) : super() {
    this.stopDuration = stopDuration ?? const Duration(seconds: 30);
  }

  @override
  Function get fromJsonFunction => _$MobilitySamplingConfigurationFromJson;

  @override
  Map<String, dynamic> toJson() => _$MobilitySamplingConfigurationToJson(this);

  factory MobilitySamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MobilitySamplingConfiguration>(json);
}
