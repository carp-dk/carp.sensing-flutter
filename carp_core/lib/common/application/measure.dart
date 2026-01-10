/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// Defines data that needs to be measured/collected passively as part of a
/// task defined by [TaskConfiguration].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Measure extends Serializable {
  /// The type of measure to do.
  ///
  /// Specifies the full name space of the data to be collected, e.g.,
  /// "dk.cachet.carp.measure.location".
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
