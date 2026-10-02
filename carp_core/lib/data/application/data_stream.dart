/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../data.dart';

/// Configures the set of [ExpectedDataStream]s for a study deployment.
///
/// Derived from the protocol by [StudyDeployment.requiredDataStreams] and
/// passed to [DataStreamService.openDataStreams].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DataStreamsConfiguration {
  /// The study deployment the data streams belong to.
  String studyDeploymentId;

  /// The data streams to accept data for.
  Set<ExpectedDataStream> expectedDataStreams;

  DataStreamsConfiguration({
    required this.studyDeploymentId,
    required this.expectedDataStreams,
  });
  factory DataStreamsConfiguration.fromJson(Map<String, dynamic> json) =>
      _$DataStreamsConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$DataStreamsConfigurationToJson(this);
}

/// The expected data type for a device with a specific role name.
///
/// Two expected data streams are equal if they have the same
/// [deviceRoleName] and [dataType].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ExpectedDataStream {
  String deviceRoleName;
  String dataType;

  ExpectedDataStream({required this.deviceRoleName, required this.dataType});
  factory ExpectedDataStream.fromJson(Map<String, dynamic> json) =>
      _$ExpectedDataStreamFromJson(json);
  Map<String, dynamic> toJson() => _$ExpectedDataStreamToJson(this);

  @override
  bool operator ==(other) =>
      other is ExpectedDataStream &&
      deviceRoleName == other.deviceRoleName &&
      dataType == other.dataType;

  @override
  int get hashCode => Object.hash(deviceRoleName.hashCode, dataType.hashCode);
}

/// Identifies a data stream of collected [dataType] data on the device with
/// [deviceRoleName] in a deployed study protocol with [studyDeploymentId].
///
/// Used in [DataStreamBatch] and [DataStreamService.getDataStream].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DataStreamId {
  String studyDeploymentId;
  String deviceRoleName;
  String dataType;

  DataStreamId({
    required this.studyDeploymentId,
    required this.deviceRoleName,
    required this.dataType,
  });
  factory DataStreamId.fromJson(Map<String, dynamic> json) =>
      _$DataStreamIdFromJson(json);
  Map<String, dynamic> toJson() => _$DataStreamIdToJson(this);
}

/// A collection of non-overlapping, ordered, data [measurements].
///
/// The unit of upload to a [DataStreamService] with
/// [DataStreamService.appendToDataStreams]. All measurements belong to the
/// same [dataStream].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DataStreamBatch {
  /// The data stream these measurements belong to.
  DataStreamId dataStream;

  /// The sequence id of the first measurement; the rest follow in order.
  int firstSequenceId;

  /// The measurements, ordered in time.
  List<Measurement> measurements;

  /// Ids of the triggers (see [StudyProtocol.triggers]) which caused the
  /// measurements to be collected.
  Set<int> triggerIds;

  DataStreamBatch({
    required this.dataStream,
    required this.firstSequenceId,
    required this.measurements,
    required this.triggerIds,
  });
  factory DataStreamBatch.fromJson(Map<String, dynamic> json) =>
      _$DataStreamBatchFromJson(json);
  Map<String, dynamic> toJson() => _$DataStreamBatchToJson(this);
}

/// A piece of collected [data] with the time it was measured.
///
/// A probe or task produces [Data]; the client wraps it in a [Measurement]
/// with a timestamp and passes it on for storage and upload, e.g. in a
/// [DataStreamBatch]. This is the unit of data collected in CARP.
/// When [sensorEndTime] is set, the [data] pertains to an interval in time;
/// otherwise, a point in time.
///
/// The unit of [sensorStartTime] and [sensorEndTime] is either determined by the
/// sensor that collected the data, or, in case the sensor does not provide this
/// information, by the phone.
/// For example, the timestamps could be a simple clock increment since the device
/// powered up.
/// Note that in CARP we prefer microseconds over milliseconds for higher precision.
///
/// ```dart
/// // Timestamp is now, in microseconds since epoch.
/// var measurement = Measurement.fromData(StepCount(steps: 12));
/// ```
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Measurement {
  /// Start time as set by the sensor.
  ///
  /// If this timestamp has been provided by the sensor, the unit is determined
  /// by the sensor.
  /// If this timestamp is provided by the phone (e.g., by using the [Measurement.fromData]
  /// method), this timestamp is in microseconds since epoch.
  int sensorStartTime;

  /// End time as set by the sensor, if available.
  int? sensorEndTime;

  /// The type of the [data].
  @JsonKey(includeFromJson: false, includeToJson: false)
  DataType get dataType => data.dataType;

  /// The [TaskControl] which triggered the collection of this measurement.
  /// Set at runtime only; not serialized.
  @JsonKey(includeFromJson: false, includeToJson: false)
  TaskControl? taskControl;

  /// The [Data] collected in this measurement.
  Data data;

  /// Create a new measurement based on [data].
  Measurement({
    required this.sensorStartTime,
    this.sensorEndTime,
    required this.data,
  });

  /// Create a measurement from [data] based on the [sensorStartTime] provided
  /// by the sensor. If [sensorStartTime] is not specified, the phones current
  /// time stamp as microseconds since epoch is used.
  factory Measurement.fromData(Data data, [int? sensorStartTime]) =>
      Measurement(
        sensorStartTime:
            sensorStartTime ?? DateTime.now().microsecondsSinceEpoch,
        data: data,
      );

  factory Measurement.fromJson(Map<String, dynamic> json) =>
      _$MeasurementFromJson(json);
  Map<String, dynamic> toJson() => _$MeasurementToJson(this);
}
