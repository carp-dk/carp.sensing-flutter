/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

// This file holds all the CARP Core defined data type.
// In CARP Core Kotlin, this is the "dk.cachet.carp.common.application.data" domain.

/// Base class of all collected data, such as a location or a heart rate.
///
/// A probe or user task produces a [Data] object, which is wrapped in a
/// [Measurement] with a timestamp and uploaded. This base class holds no
/// values itself; subclasses add the fields.
///
/// Key points:
///  * The data type ([dataType]) is derived from [jsonType]. By default this
///    is `dk.cachet.carp.<classname in lowercase>`, e.g.
///    `dk.cachet.carp.geolocation` for [Geolocation].
///  * Each subclass must be registered in [FromJsonFactory] to be
///    deserialized.
///  * Override [equivalentTo] to let triggers react to specific data values.
///
/// See also [SensorData], [InputData] and the data type names in
/// [CarpDataTypes].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Data extends Serializable {
  /// The type of this data as a [DataType].
  @JsonKey(includeFromJson: false, includeToJson: false)
  DataType get dataType => DataType.fromString(jsonType);

  Data() : super();

  /// Stable identifier of the source record, if available; null by default.
  ///
  /// Subclasses whose data comes from a store with record ids (e.g., health
  /// data) can return it, e.g. to avoid duplicates. Not serialized.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get recordId => null;

  /// Is this data equivalent to [other]?
  ///
  /// This is a custom 'soft' equal (==) operator used to compare two data objects.
  /// Used in triggering when some data is collected.
  /// Returns false in this base class; override in subclasses to provide
  /// custom equivalence checking.
  bool equivalentTo(Data other) => false;

  @override
  Function get fromJsonFunction => _$DataFromJson;
  factory Data.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Data>(json);
  @override
  Map<String, dynamic> toJson() => _$DataToJson(this);

  @override
  String get jsonType => '${NameSpace.CARP}.$runtimeType'.toLowerCase();
}

/// Holds data for a [DataType] collected by a sensor which may include additional
/// [sensorSpecificData].
///
/// Base class of the sensor data types, such as [Acceleration] and [HeartRate].
abstract class SensorData extends Data {
  /// Additional sensor-specific data pertaining to this data point.
  /// This can be used to append highly-specific sensor data to an otherwise
  /// common data type.
  Data? sensorSpecificData;
}

/// Change in velocity, including gravity, along perpendicular
/// [x], [y], and [z] axes in meters per second squared (m/s^2).
/// Typically captured by an accelerometer.
///
/// Data type [CarpDataTypes.ACCELERATION].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Acceleration extends SensorData {
  double x, y, z;
  Acceleration({this.x = 0, this.y = 0, this.z = 0}) : super();

  @override
  Function get fromJsonFunction => _$AccelerationFromJson;
  factory Acceleration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Acceleration>(json);
  @override
  Map<String, dynamic> toJson() => _$AccelerationToJson(this);
}

/// Rate of rotation of the device around the [x], [y] and [z] axes.
/// Typically captured by a gyroscope.
///
/// Data type [CarpDataTypes.ROTATION].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Rotation extends SensorData {
  double x, y, z;
  Rotation({this.x = 0, this.y = 0, this.z = 0}) : super();

  @override
  Function get fromJsonFunction => _$RotationFromJson;
  factory Rotation.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Rotation>(json);
  @override
  Map<String, dynamic> toJson() => _$RotationToJson(this);
}

/// Magnetic field of the device in 3D space, measured in microteslas μT
/// for each three-dimensional axis.
/// Typically captured by a magnetometer sensor.
///
/// Data type [CarpDataTypes.MAGNETIC_FIELD].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MagneticField extends SensorData {
  double x, y, z;
  MagneticField({this.x = 0, this.y = 0, this.z = 0}) : super();

  @override
  Function get fromJsonFunction => _$MagneticFieldFromJson;
  factory MagneticField.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MagneticField>(json);
  @override
  Map<String, dynamic> toJson() => _$MagneticFieldToJson(this);
}

/// Geolocation data as latitude and longitude in decimal degrees within
/// the World Geodetic System 1984.
///
/// Data type [CarpDataTypes.GEOLOCATION].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Geolocation extends SensorData {
  /// Latitude in GPS coordinates.
  double latitude;

  /// Longitude in GPS coordinates.
  double longitude;

  Geolocation({this.latitude = 0, this.longitude = 0}) : super();

  @override
  Function get fromJsonFunction => _$GeolocationFromJson;
  factory Geolocation.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Geolocation>(json);
  @override
  Map<String, dynamic> toJson() => _$GeolocationToJson(this);
}

/// The relative received signal strength of a wireless device.
/// The unit of the received signal strength indicator ([rssi]) is arbitrary
/// and determined by the chip manufacturer, but the greater the value,
/// the stronger the signal.
///
/// Data type [CarpDataTypes.SIGNAL_STRENGTH].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SignalStrength extends SensorData {
  int rssi;
  SignalStrength({this.rssi = 0}) : super();

  @override
  Function get fromJsonFunction => _$SignalStrengthFromJson;
  factory SignalStrength.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SignalStrength>(json);
  @override
  Map<String, dynamic> toJson() => _$SignalStrengthToJson(this);
}

/// Step count data as number of [steps] taken in a corresponding time interval.
///
/// Data type [CarpDataTypes.STEP_COUNT].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class StepCount extends SensorData {
  int steps;
  StepCount({this.steps = 0}) : super();

  @override
  Function get fromJsonFunction => _$StepCountFromJson;
  factory StepCount.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<StepCount>(json);
  @override
  Map<String, dynamic> toJson() => _$StepCountToJson(this);
}

/// Heart rate data in beats per minute ([bpm]).
///
/// Data type [CarpDataTypes.HEART_RATE].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HeartRate extends SensorData {
  int bpm;
  HeartRate({this.bpm = 0}) : super();

  @override
  Function get fromJsonFunction => _$HeartRateFromJson;
  factory HeartRate.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HeartRate>(json);
  @override
  Map<String, dynamic> toJson() => _$HeartRateToJson(this);
}

/// Electrocardiogram data of a single lead.
///
/// Data type [CarpDataTypes.ECG].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ECG extends SensorData {
  /// The sampling frequency in hertz (Hz).
  int samplingFrequencyHz = 250;

  /// The array of ECG voltage measurements in millivolt (mV).
  List<double> milliVolt;
  ECG({this.samplingFrequencyHz = 250, this.milliVolt = const []}) : super();

  @override
  Function get fromJsonFunction => _$ECGFromJson;
  factory ECG.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ECG>(json);
  @override
  Map<String, dynamic> toJson() => _$ECGToJson(this);
}

/// Single-channel electrodermal activity (EDA) data, represented as skin conductance.
/// Among others, also known as galvanic skin response (GSR) or skin conductance response/level.
///
/// Data type [CarpDataTypes.EDA].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class EDA extends SensorData {
  /// Skin conductance in microsiemens (μS).
  double microSiemens;
  EDA({this.microSiemens = 0}) : super();

  @override
  Function get fromJsonFunction => _$EDAFromJson;
  factory EDA.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<EDA>(json);
  @override
  Map<String, dynamic> toJson() => _$EDAToJson(this);
}

/// Data about an interactive user task with [taskName], which has been completed.
///
/// [taskData] holds the result of the task, or null if no result is collected.
/// Data type [CarpDataTypes.COMPLETED_TASK]. Two completed tasks are
/// [equivalentTo] each other if they have the same [taskName].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CompletedTask extends Data {
  /// The name of the task which was completed.
  /// This is the name of the task as specified in the study protocol.
  String taskName;

  /// The result of the completed task, if any.
  Data? taskData;

  CompletedTask({required this.taskName, this.taskData}) : super();

  @override
  bool equivalentTo(Data other) =>
      other is CompletedTask && taskName == other.taskName;

  @override
  Function get fromJsonFunction => _$CompletedTaskFromJson;
  factory CompletedTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CompletedTask>(json);
  @override
  Map<String, dynamic> toJson() => _$CompletedTaskToJson(this);
}

/// Indicates the task with [taskName] was started or stopped ([control]) by the
/// trigger with [triggerId] on the device with [destinationDeviceRoleName],
/// referring to identifiers in the study protocol.
/// [triggerData] may contain additional information related to the circumstances
/// which caused the trigger to fire.
///
/// Data type [CarpDataTypes.TRIGGERED_TASK].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TriggeredTask extends Data {
  int triggerId;
  String taskName;
  String destinationDeviceRoleName;
  Control control;
  Data? triggerData;

  TriggeredTask({
    required this.triggerId,
    required this.taskName,
    required this.destinationDeviceRoleName,
    required this.control,
    this.triggerData,
  }) : super();

  @override
  Function get fromJsonFunction => _$TriggeredTaskFromJson;
  factory TriggeredTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<TriggeredTask>(json);
  @override
  Map<String, dynamic> toJson() => _$TriggeredTaskToJson(this);
}

/// Indicates that some error occurred during data collection. [message]
/// holds any message about the error which might have been captured.
///
/// Data type [CarpDataTypes.ERROR]. Note that this class hides `dart:core`
/// [Error] when carp_core is imported without a prefix.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Error extends Data {
  /// The original error message returned from the probe, if available.
  String message;

  Error({required this.message}) : super();

  @override
  Function get fromJsonFunction => _$ErrorFromJson;
  factory Error.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Error>(json);
  @override
  Map<String, dynamic> toJson() => _$ErrorToJson(this);
}
