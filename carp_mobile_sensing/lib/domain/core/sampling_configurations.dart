/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A [SamplingConfiguration] that remembers when its measure was last collected.
///
/// The probe updates [lastTime] and the value is saved with the deployment,
/// so sampling can resume from that point after an app restart. Extend it for
/// probes that collect data since the last sample, like health data.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PersistentSamplingConfiguration extends SamplingConfiguration {
  /// When this measure was last collected, or `null` if never.
  ///
  /// Set by the [Probe]; saved at most once per second.
  DateTime? lastTime;

  PersistentSamplingConfiguration() : super();

  @override
  Map<String, dynamic> toJson() =>
      _$PersistentSamplingConfigurationToJson(this);
  @override
  Function get fromJsonFunction => _$PersistentSamplingConfigurationFromJson;
  factory PersistentSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PersistentSamplingConfiguration>(json);
}

/// A [PersistentSamplingConfiguration] that collects data from a time window
/// [past] and [future] relative to now.
///
/// Used by probes that read stored data, e.g. app usage or calls and texts.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HistoricSamplingConfiguration extends PersistentSamplingConfiguration {
  /// The default length of [past] and [future], in days.
  static const int DEFAULT_NUMBER_OF_DAYS = 1;

  /// How far back in time to collect data. Default is one day.
  late Duration past;

  /// How far ahead in time to collect data. Default is one day.
  late Duration future;

  HistoricSamplingConfiguration({Duration? past, Duration? future}) : super() {
    this.past = past ?? const Duration(days: DEFAULT_NUMBER_OF_DAYS);
    this.future = future ?? const Duration(days: DEFAULT_NUMBER_OF_DAYS);
  }

  @override
  Function get fromJsonFunction => _$HistoricSamplingConfigurationFromJson;
  @override
  Map<String, dynamic> toJson() => _$HistoricSamplingConfigurationToJson(this);
  factory HistoricSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HistoricSamplingConfiguration>(json);
}

/// A [SamplingConfiguration] that sets the time [interval] between measurements.
///
/// Used by probes that sample on a timer, see [IntervalProbe].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class IntervalSamplingConfiguration extends SamplingConfiguration {
  /// Sampling interval (i.e., delay between sampling).
  Duration interval;

  IntervalSamplingConfiguration({required this.interval}) : super();

  @override
  Function get fromJsonFunction => _$IntervalSamplingConfigurationFromJson;
  @override
  Map<String, dynamic> toJson() => _$IntervalSamplingConfigurationToJson(this);
  factory IntervalSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<IntervalSamplingConfiguration>(json);
}

/// A sampling configuration specifying how to collect data on a regular basis
/// for a specific period.
///
/// Every [interval], data is collected for the length of [duration]. Useful
/// for listening in on a sensor (e.g. the accelerometer) in regular, short
/// time windows. See [BufferingPeriodicProbe].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PeriodicSamplingConfiguration extends IntervalSamplingConfiguration {
  /// How long each sampling window lasts.
  late Duration duration;

  PeriodicSamplingConfiguration({
    required super.interval,
    required this.duration,
  });

  @override
  Map<String, dynamic> toJson() => _$PeriodicSamplingConfigurationToJson(this);
  @override
  Function get fromJsonFunction => _$PeriodicSamplingConfigurationFromJson;
  factory PeriodicSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PeriodicSamplingConfiguration>(json);
}
