/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// Defines one type of data to collect passively as part of a task.
///
/// A measure names a data [type] (e.g., `dk.cachet.carp.geolocation`) and
/// is added to a [TaskConfiguration]. When the task is triggered, the client
/// collects this data type, typically through a probe.
///
/// Key points:
///  * Two measures are equal if they have the same [type]; a task keeps only
///    one measure per type.
///  * [overrideSamplingConfiguration] overrides how the data is sampled; see
///    [DataTypeSamplingScheme] for the order of priority.
///
/// ```dart
/// var task = BackgroundTask(measures: [
///   Measure(type: CarpDataTypes.STEP_COUNT),
///   Measure(type: CarpDataTypes.GEOLOCATION),
/// ]);
/// ```
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Measure extends Serializable {
  /// The type of measure to do.
  ///
  /// The fully qualified data type to collect, e.g.,
  /// "dk.cachet.carp.geolocation". See [CarpDataTypes] for the core types.
  String type;

  /// The type of measure as a [DataType].
  @JsonKey(includeFromJson: false, includeToJson: false)
  DataType get dataType => DataType.fromString(type);

  /// Optionally, override the default configuration on how to sample the data
  /// stream of the matching [type] on the device.
  /// In case `null` is specified, the default configuration is derived from the
  /// [DeviceConfiguration].
  SamplingConfiguration? overrideSamplingConfiguration;

  /// Create a measure by specifying its [type] and optionally a
  /// [samplingConfiguration] to override the default sampling configuration.
  Measure({required this.type, SamplingConfiguration? samplingConfiguration})
    : super() {
    overrideSamplingConfiguration = samplingConfiguration;
  }

  @override
  Function get fromJsonFunction => _$MeasureFromJson;
  factory Measure.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Measure>(json);
  @override
  Map<String, dynamic> toJson() => _$MeasureToJson(this);
  @override
  String get jsonType =>
      'dk.cachet.carp.common.application.tasks.Measure.DataStream';

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(Object other) => other is Measure && other.type == type;

  @override
  String toString() => '$runtimeType - type: $type';
}
