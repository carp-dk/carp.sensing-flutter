/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movisens_package.dart';

/// Base class for all data collected from a Movisens device.
///
/// One Movisens measure can produce several kinds of data. For example, the
/// [MovisensSamplingPackage.ACTIVITY] measure produces [MovisensStepCount],
/// [MovisensBodyPosition] and others. The constants below are the data types
/// of these sub-kinds.
///
/// Each subclass has a `fromMovisensEvent` factory that converts an event from
/// the `movisens_flutter` plugin.
abstract class MovisensData extends Data {
  /// Data type of [MovisensStepCount].
  static const String STEPS = "${MovisensSamplingPackage.ACTIVITY}.steps";

  /// Data type of [MovisensBodyPosition].
  static const String BODY_POSITION = "${MovisensSamplingPackage.ACTIVITY}.body_position";

  /// Data type of [MovisensInclination].
  static const String INCLINATION = "${MovisensSamplingPackage.ACTIVITY}.inclination";

  /// Data type of [MovisensMovementAcceleration].
  static const String MOVEMENT_ACCELERATION = "${MovisensSamplingPackage.ACTIVITY}.movement_acceleration";

  /// Data type of [MovisensMET].
  static const String MET = "${MovisensSamplingPackage.ACTIVITY}.met";

  /// Data type of [MovisensMETLevel].
  static const String MET_LEVEL = "${MovisensSamplingPackage.ACTIVITY}.met_level";

  /// Data type of [MovisensHR].
  ///
  /// Note that [MovisensHRV] and [MovisensIsHrvValid] currently also use this
  /// type as their [jsonType].
  static const String HR_MEAN = "${MovisensSamplingPackage.HR}.hr_mean";

  /// Data type of heart rate variability. Not used by [MovisensHRV] at the
  /// moment, which uses [HR_MEAN].
  static const String HRV = "${MovisensSamplingPackage.HR}.hrv";

  /// Data type of HRV validity. Not used by [MovisensIsHrvValid] at the
  /// moment, which uses [HR_MEAN].
  static const String IS_HRV_VALID = "${MovisensSamplingPackage.HR}.is_hrv_valid";

  /// The timestamp of the Movisens event.
  ///
  /// Note that on Movisens devices, the stream of data sent through Bluetooth
  /// is not transmitted instantaneously after it has been measured on the device.
  /// See the documentation on [Timestamps](https://pub.dev/packages/movisens_flutter#timestamps) for more information.
  late DateTime timestamp;

  /// The ID of the device which emitted this event.
  /// Uses a MAC address format on Android. Uses a UUID format on iOS.
  String deviceId;

  /// The name of the BLE characteristic which emitted this event.
  String type;

  /// Creates Movisens data. [timestamp] defaults to now.
  MovisensData({required this.deviceId, required this.type, DateTime? timestamp}) : super() {
    this.timestamp = timestamp ?? DateTime.now();
  }

  /// Converts a Movisens timestamp of the form `yyyy-MM-dd HH:mm:ss` to an
  /// ISO 8601 UTC string, like `yyyy-MM-ddTHH:mm:ss.000Z`.
  static String movisensTimestampToUTC(String timestamp) {
    var split = timestamp.split(" ");
    return "${split[0]}T${split[1]}.000Z";
  }
}

/// The step count measured by the Movisens device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensStepCount extends MovisensData {
  /// Number of steps taken by the user in the last interval.
  int steps;

  MovisensStepCount({required super.deviceId, required super.type, super.timestamp, required this.steps});

  @override
  factory MovisensStepCount.fromMovisensEvent(movisens.StepsEvent event) =>
      MovisensStepCount(deviceId: event.deviceId, type: event.type.name, timestamp: event.time, steps: event.steps);

  @override
  Function get fromJsonFunction => _$MovisensStepCountFromJson;
  factory MovisensStepCount.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensStepCount;
  @override
  Map<String, dynamic> toJson() => _$MovisensStepCountToJson(this);
  @override
  String get jsonType => MovisensData.STEPS;
}

/// The body position of the person wearing the device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensBodyPosition extends MovisensData {
  /// The name of the body position, as defined by the `movisens_flutter`
  /// plugin (like "standing" or "lyingSupine").
  String bodyPosition;

  MovisensBodyPosition({required super.deviceId, required super.type, super.timestamp, required this.bodyPosition});

  @override
  factory MovisensBodyPosition.fromMovisensEvent(movisens.BodyPositionEvent event) => MovisensBodyPosition(
    deviceId: event.deviceId,
    type: event.type.name,
    timestamp: event.time,
    bodyPosition: event.bodyPosition.name,
  );

  @override
  Function get fromJsonFunction => _$MovisensBodyPositionFromJson;
  factory MovisensBodyPosition.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensBodyPosition;
  @override
  Map<String, dynamic> toJson() => _$MovisensBodyPositionToJson(this);
  @override
  String get jsonType => MovisensData.BODY_POSITION;
}

/// The inclination of the body axes at the sensor location against the x, y
/// and z axes.
///
/// Calculates the mean inclinations of the three body axes from the
/// acceleration signal and displays the value for each inclination in degrees.
/// The values range from 0° to 180°.
///
/// Read more in the [Movisens Documentation](https://docs.movisens.com/Algorithms/physical_activity/#inclination-inclinsationdown-inclinationforward-inclinationright).
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensInclination extends MovisensData {
  /// Inclination of the sensor in degrees (0-180) on the x, y and z axis.
  int x, y, z;

  MovisensInclination({
    required super.deviceId,
    required super.type,
    super.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  factory MovisensInclination.fromMovisensEvent(movisens.InclinationEvent event) => MovisensInclination(
    deviceId: event.deviceId,
    type: event.type.name,
    timestamp: event.time,
    x: event.x,
    y: event.y,
    z: event.z,
  );

  @override
  Function get fromJsonFunction => _$MovisensInclinationFromJson;
  factory MovisensInclination.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensInclination;
  @override
  Map<String, dynamic> toJson() => _$MovisensInclinationToJson(this);
  @override
  String get jsonType => MovisensData.INCLINATION;
}

/// The movement acceleration measured by the Movisens device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensMovementAcceleration extends MovisensData {
  /// A measurement of physical activity metric that outputs values that have a
  /// very good correlation to the intensity of bodily movements.
  /// Measured in g (multiples of earth gravity, 1 g = 9.81 m/s²).
  double movementAcceleration;

  MovisensMovementAcceleration({
    required super.deviceId,
    required super.type,
    super.timestamp,
    required this.movementAcceleration,
  });

  @override
  factory MovisensMovementAcceleration.fromMovisensEvent(movisens.MovementAccelerationEvent event) =>
      MovisensMovementAcceleration(
        deviceId: event.deviceId,
        type: event.type.name,
        timestamp: event.time,
        movementAcceleration: event.movementAcceleration,
      );

  @override
  Function get fromJsonFunction => _$MovisensMovementAccelerationFromJson;
  factory MovisensMovementAcceleration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensMovementAcceleration;
  @override
  Map<String, dynamic> toJson() => _$MovisensMovementAccelerationToJson(this);
  @override
  String get jsonType => MovisensData.MOVEMENT_ACCELERATION;
}

/// The Metabolic Equivalent of Task (MET) measured by the Movisens device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensMET extends MovisensData {
  /// Measure of Metabolic Equivalent of Task (MET), indicates the energy expenditure.
  /// It is defined as the ratio of metabolic rate during a specific physical
  /// task to a reference metabolic rate.
  int met;

  MovisensMET({required super.deviceId, required super.type, super.timestamp, required this.met});

  @override
  factory MovisensMET.fromMovisensEvent(movisens.MetEvent event) =>
      MovisensMET(deviceId: event.deviceId, type: event.type.name, timestamp: event.time, met: event.met);

  @override
  Function get fromJsonFunction => _$MovisensMETFromJson;
  factory MovisensMET.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as MovisensMET;
  @override
  Map<String, dynamic> toJson() => _$MovisensMETToJson(this);
  @override
  String get jsonType => MovisensData.MET;
}

/// The time spent in each Metabolic Equivalent of Task (MET) level.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensMETLevel extends MovisensData {
  /// Number of seconds the user was in the sedentary, light, moderate and
  /// vigorous MET level.
  int sedentary, light, moderate, vigorous;

  MovisensMETLevel({
    required super.deviceId,
    required super.type,
    super.timestamp,
    required this.sedentary,
    required this.light,
    required this.moderate,
    required this.vigorous,
  });

  @override
  factory MovisensMETLevel.fromMovisensEvent(movisens.MetLevelEvent event) => MovisensMETLevel(
    deviceId: event.deviceId,
    type: event.type.name,
    timestamp: event.time,
    sedentary: event.sedentary,
    light: event.light,
    moderate: event.moderate,
    vigorous: event.vigorous,
  );

  @override
  Function get fromJsonFunction => _$MovisensMETLevelFromJson;
  factory MovisensMETLevel.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as MovisensMETLevel;
  @override
  Map<String, dynamic> toJson() => _$MovisensMETLevelToJson(this);
  @override
  String get jsonType => MovisensData.MET_LEVEL;
}

/// Heart rate (HR) in beats per minute (BPM).
///
/// Can be transformed to OMH ([OMHHeartRateDataPoint]) and FHIR
/// ([FHIRHeartRateObservation]).
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensHR extends MovisensData {
  /// Mean heart rate (HR) of the previous 60 seconds in beats per minute (BPM).
  int hr;

  MovisensHR({required super.deviceId, required super.type, super.timestamp, required this.hr});

  @override
  factory MovisensHR.fromMovisensEvent(movisens.HrMeanEvent event) =>
      MovisensHR(deviceId: event.deviceId, type: event.type.name, timestamp: event.time, hr: event.hrMean);

  @override
  Function get fromJsonFunction => _$MovisensHRFromJson;
  factory MovisensHR.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as MovisensHR;
  @override
  Map<String, dynamic> toJson() => _$MovisensHRToJson(this);

  @override
  String get jsonType => MovisensData.HR_MEAN;
}

/// Heart rate variability (HRV).
///
/// Note that [jsonType] is currently [MovisensData.HR_MEAN], the same as for
/// [MovisensHR].
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensHRV extends MovisensData {
  /// The Root Mean Square of Successive Differences (RMSSD) of heart beat intervals.
  ///
  /// This parameter is the mean value of the HRV parameter RMSSD per output interval.
  /// RMSSD is the root mean square of successive differences of beat intervals.
  /// The unit is milliseconds.
  int hrv;

  MovisensHRV({required super.deviceId, required super.type, super.timestamp, required this.hrv});

  @override
  factory MovisensHRV.fromMovisensEvent(movisens.RmssdEvent event) =>
      MovisensHRV(deviceId: event.deviceId, type: event.type.name, timestamp: event.time, hrv: event.rmssd);

  @override
  Function get fromJsonFunction => _$MovisensHRVFromJson;
  factory MovisensHRV.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as MovisensHRV;
  @override
  Map<String, dynamic> toJson() => _$MovisensHRVToJson(this);
  @override
  String get jsonType => MovisensData.HR_MEAN;
}

/// Whether the current heart rate variability (HRV) values are valid.
///
/// Note that [jsonType] is currently [MovisensData.HR_MEAN], the same as for
/// [MovisensHR].
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensIsHrvValid extends MovisensData {
  /// Are the current HRV measurements valid?
  bool isHrvValid;

  MovisensIsHrvValid({required super.deviceId, required super.type, super.timestamp, required this.isHrvValid});

  @override
  factory MovisensIsHrvValid.fromMovisensEvent(movisens.HrvIsValidEvent event) => MovisensIsHrvValid(
    deviceId: event.deviceId,
    type: event.type.name,
    timestamp: event.time,
    isHrvValid: event.hrvIsValid,
  );

  @override
  Function get fromJsonFunction => _$MovisensIsHrvValidFromJson;
  factory MovisensIsHrvValid.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensIsHrvValid;
  @override
  Map<String, dynamic> toJson() => _$MovisensIsHrvValidToJson(this);
  @override
  String get jsonType => MovisensData.HR_MEAN;
}

/// Electrodermal activity (EDA), measured by an EdaMove4 device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensEDA extends MovisensData {
  /// The Mean Skin Conductance Level (SCL) value in micro Siemens.
  double edaSclMean;

  MovisensEDA({required super.deviceId, required super.type, super.timestamp, required this.edaSclMean});

  @override
  factory MovisensEDA.fromMovisensEvent(movisens.EdaSclMeanEvent event) =>
      MovisensEDA(deviceId: event.deviceId, type: event.type.name, timestamp: event.time, edaSclMean: event.edaSclMean);

  @override
  Function get fromJsonFunction => _$MovisensEDAFromJson;
  factory MovisensEDA.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as MovisensEDA;
  @override
  Map<String, dynamic> toJson() => _$MovisensEDAToJson(this);
  @override
  String get jsonType => MovisensSamplingPackage.EDA;
}

/// Skin temperature measured by the Movisens device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensSkinTemperature extends MovisensData {
  /// Temperature of the skin in degree Celsius.
  double skinTemperature;

  MovisensSkinTemperature({
    required super.deviceId,
    required super.type,
    super.timestamp,
    required this.skinTemperature,
  });

  @override
  factory MovisensSkinTemperature.fromMovisensEvent(movisens.SkinTemperatureEvent event) => MovisensSkinTemperature(
    deviceId: event.deviceId,
    type: event.type.name,
    timestamp: event.time,
    skinTemperature: event.skinTemperature,
  );

  @override
  Function get fromJsonFunction => _$MovisensSkinTemperatureFromJson;
  factory MovisensSkinTemperature.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensSkinTemperature;
  @override
  Map<String, dynamic> toJson() => _$MovisensSkinTemperatureToJson(this);
  @override
  String get jsonType => MovisensSamplingPackage.SKIN_TEMPERATURE;
}

/// Respiratory movement measured by the Movisens device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensRespiration extends MovisensData {
  /// Respiration value derived from [movisens.RespiratoryMovementEvent].
  /// Its unit and meaning are not documented by the `movisens_flutter` plugin.
  int value;

  MovisensRespiration({required super.deviceId, required super.type, super.timestamp, required this.value});

  @override
  factory MovisensRespiration.fromMovisensEvent(movisens.RespiratoryMovementEvent event) =>
      MovisensRespiration(deviceId: event.deviceId, type: event.type.name, timestamp: event.time, value: event.values);

  @override
  Function get fromJsonFunction => _$MovisensRespirationFromJson;
  factory MovisensRespiration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensRespiration;
  @override
  Map<String, dynamic> toJson() => _$MovisensRespirationToJson(this);
  @override
  String get jsonType => MovisensSamplingPackage.RESPIRATION;
}

/// A tap marker event from a user tap on the Movisens device.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovisensTapMarker extends MovisensData {
  /// The tap marker value.
  int tapMarker;

  MovisensTapMarker({required super.deviceId, required super.type, super.timestamp, required this.tapMarker});

  @override
  factory MovisensTapMarker.fromMovisensEvent(movisens.TapMarkerEvent event) => MovisensTapMarker(
    deviceId: event.deviceId,
    type: event.type.name,
    timestamp: event.time,
    tapMarker: event.tapMarkerValue,
  );

  @override
  Function get fromJsonFunction => _$MovisensTapMarkerFromJson;
  factory MovisensTapMarker.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as MovisensTapMarker;
  @override
  Map<String, dynamic> toJson() => _$MovisensTapMarkerToJson(this);
  @override
  String get jsonType => MovisensSamplingPackage.TAP_MARKER;
}
