/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movesense_package.dart';

/// The states a Movesense device can report in a [MovesenseStateChange].
///
/// See https://www.movesense.com/docs/esw/api_reference/#systemstates for an
/// overview.
enum MovesenseDeviceState {
  /// Unknown state.
  unknown,

  /// Device is moving.
  moving,

  /// Device is not moving.
  notMoving,

  /// Device connected to gear (e.g., strap).
  connected,

  /// Device disconnected from gear.
  disconnected,

  /// Device tapped once.
  tap,

  /// Device double tapped.
  doubleTap,

  /// Device is under acceleration.
  acceleration,

  /// Device is in free fall (no gravity).
  freeFall,
}

/// Information about a Movesense device and the firmware running on it.
///
/// Holds the hardware version, serial number, software version and similar.
/// Collected by [MovesenseDeviceProbe] for the
/// [MovesenseSamplingPackage.DEVICE_INFO] measure.
///
/// See https://www.movesense.com/docs/esw/api_reference/#info
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseDeviceInformation extends SensorData {
  String? manufacturerName;
  String? brandName;
  String? productName;
  String? variant;
  String? design;
  String? hardwareCompatibilityId;
  String? serial;
  String? pcbaSerial;
  String? softwareVersion;

  /// The hardware type ("hw"), like "A1" for the MD. See [MovesenseDeviceType].
  String? hardwareType;
  String? additionalVersionInfo;
  String? apiLevel;

  /// The BLE address of the device.
  String? address;

  MovesenseDeviceInformation([
    this.manufacturerName,
    this.brandName,
    this.productName,
    this.variant,
    this.design,
    this.hardwareCompatibilityId,
    this.serial,
    this.pcbaSerial,
    this.softwareVersion,
    this.hardwareType,
    this.additionalVersionInfo,
    this.apiLevel,
    this.address,
  ]) : super();

  /// Creates device information from the decoded JSON response of the
  /// device's `/Info` resource.
  factory MovesenseDeviceInformation.fromMovesenseData(dynamic data) {
    var deviceInfo = data["Content"] as Map<String, dynamic>;

    String? manufacturerName = deviceInfo["manufacturerName"] as String?;
    String? brandName = deviceInfo["brandName"] as String?;
    String? productName = deviceInfo["productName"] as String?;
    String? variant = deviceInfo["variant"] as String?;
    String? design = deviceInfo["design"] as String?;
    String? hardwareCompatibilityId =
        deviceInfo["hwCompatibilityId"] as String?;
    String? serial = deviceInfo["serial"] as String?;
    String? pcbaSerial = deviceInfo["pcbaSerial"] as String?;
    String? softwareVersion = deviceInfo["sw"] as String?;
    String? hardwareType = deviceInfo["hw"] as String?;
    String? additionalVersionInfo =
        deviceInfo["additionalVersionInfo"] as String?;
    String? apiLevel = deviceInfo["apiLevel"] as String?;
    String? address = deviceInfo["addressInfo"][0]["address"] as String?;

    return MovesenseDeviceInformation(
      manufacturerName,
      brandName,
      productName,
      variant,
      design,
      hardwareCompatibilityId,
      serial,
      pcbaSerial,
      softwareVersion,
      hardwareType,
      additionalVersionInfo,
      apiLevel,
      address,
    );
  }

  @override
  Function get fromJsonFunction => _$MovesenseDeviceInformationFromJson;
  factory MovesenseDeviceInformation.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MovesenseDeviceInformation>(json);
  @override
  Map<String, dynamic> toJson() => _$MovesenseDeviceInformationToJson(this);

  @override
  String get jsonType => MovesenseSamplingPackage.DEVICE_INFO;
}

/// A state change of a Movesense device, like a tap or a connection to a strap.
///
/// Collected by [MovesenseStateChangeProbe] for the
/// [MovesenseSamplingPackage.STATE] measure, using the Movesense States API.
/// The possible states are listed in [MovesenseDeviceState].
///
/// See https://www.movesense.com/docs/esw/api_reference/#systemstates
///
/// **NOTE**, however, that currently there is a limitation to the Movesense API and the
/// [MovesenseStateChangeProbe] is only able to collect single tap events.
/// See issue [#15](https://github.com/petri-lipponen-movesense/mdsflutter/issues/15).
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseStateChange extends SensorData {
  /// The state event.
  final MovesenseDeviceState state;

  /// The device's internal timestamp of this state event in milliseconds.
  ///
  /// If not given to the constructor, it is set to the millisecond part
  /// (0-999) of the current phone time.
  late int timestamp;

  MovesenseStateChange(this.state, [int? timestamp])
    : timestamp = timestamp ?? DateTime.now().millisecond;

  // Example event:
  //
  //   Body: {Timestamp: 614897, StateId: 0, NewState: 1}
  //
  // NOTE - the json listed on the official Movesense API is wrong!
  /// Creates a state change from a decoded Movesense `System/States`
  /// notification.
  ///
  /// Unknown state ids, and double-tap or tap events with a new state other
  /// than 1, give [MovesenseDeviceState.unknown].
  factory MovesenseStateChange.fromMovesenseData(dynamic data) {
    MovesenseDeviceState state = MovesenseDeviceState.unknown;

    num timestamp = data["Body"]["Timestamp"] as num;
    num stateId = data["Body"]["StateId"] as num;
    num newState = data["Body"]["NewState"] as num;

    switch (stateId) {
      case 0: // movement
        state = (newState == 0)
            ? MovesenseDeviceState.notMoving
            : MovesenseDeviceState.moving;
        break;
      case 2: // connectors
        state = (newState == 0)
            ? MovesenseDeviceState.disconnected
            : MovesenseDeviceState.connected;
        break;
      case 3: // double-tap
        if (newState == 1) {
          state = MovesenseDeviceState.doubleTap;
        }
        break;
      case 4: // tap
        if (newState == 1) {
          state = MovesenseDeviceState.tap;
        }
        break;
      case 5: // free-fall
        state = (newState == 0)
            ? MovesenseDeviceState.acceleration
            : MovesenseDeviceState.freeFall;
        break;

      default:
    }

    return MovesenseStateChange(state, timestamp.toInt());
  }

  /// Two state changes are equivalent if they have the same [state].
  @override
  bool equivalentTo(Data other) =>
      other is MovesenseStateChange && state == other.state;

  @override
  Function get fromJsonFunction => _$MovesenseStateChangeFromJson;
  factory MovesenseStateChange.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MovesenseStateChange>(json);
  @override
  Map<String, dynamic> toJson() => _$MovesenseStateChangeToJson(this);

  @override
  String get jsonType => MovesenseSamplingPackage.STATE;
}

/// A heart rate reading from a Movesense device.
///
/// The Movesense sensor calculates heart rate from its ECG signal.
/// Collected by [MovesenseHRProbe] for the [MovesenseSamplingPackage.HR]
/// measure.
///
/// See https://www.movesense.com/docs/esw/api_reference/#meashr
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseHR extends SensorData {
  /// The average heart rate in beats per minute (BPM).
  final double hr;

  /// The latest R-R interval in milliseconds. Null if not available.
  final int? rr;

  MovesenseHR(this.hr, [this.rr]);

  /// Creates a heart rate reading from a decoded Movesense `Meas/HR`
  /// notification.
  factory MovesenseHR.fromMovesenseData(dynamic data) {
    num average = data["Body"]["average"] as num;
    // returns a list of R-R measures with only one entry (the latest)
    int rr = (data["Body"]["rrData"] as List<dynamic>)
        .map((e) => e as int)
        .toList()[0];

    return MovesenseHR(average.toDouble(), rr);
  }

  @override
  Function get fromJsonFunction => _$MovesenseHRFromJson;
  factory MovesenseHR.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MovesenseHR>(json);
  @override
  Map<String, dynamic> toJson() => _$MovesenseHRToJson(this);

  @override
  String get jsonType => MovesenseSamplingPackage.HR;
}

/// A batch of single-channel ECG samples from a Movesense device.
///
/// Collected by [MovesenseECGProbe] at 125 Hz for the
/// [MovesenseSamplingPackage.ECG] measure.
///
/// See https://www.movesense.com/docs/esw/api_reference/#measecg
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseECG extends SensorData {
  /// The device's internal timestamp of this sample in milliseconds.
  final int timestamp;

  /// The raw (unscaled) integer ECG samples.
  final List<int> samples;

  MovesenseECG(this.timestamp, this.samples);

  /// Creates ECG data from a decoded Movesense `Meas/ECG` notification.
  factory MovesenseECG.fromMovesenseData(dynamic data) {
    List<int> samples = (data["Body"]["Samples"] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    num timestamp = data["Body"]["Timestamp"] as num;
    return MovesenseECG(timestamp.toInt(), samples);
  }

  @override
  Function get fromJsonFunction => _$MovesenseECGFromJson;
  factory MovesenseECG.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MovesenseECG>(json);
  @override
  Map<String, dynamic> toJson() => _$MovesenseECGToJson(this);

  @override
  String get jsonType => MovesenseSamplingPackage.ECG;
}

/// The internal temperature of a Movesense MD device, in Kelvin (K).
///
/// Only the Movesense MD has a temperature sensor. Collected by
/// [MovesenseTemperatureProbe] for the [MovesenseSamplingPackage.TEMPERATURE]
/// measure.
///
/// See https://www.movesense.com/docs/esw/api_reference/#meastemperature
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseTemperature extends SensorData {
  /// The device's internal timestamp of this sample in milliseconds.
  final int timestamp;

  /// The device's internal temperature in units of Kelvins (K).
  final int measurement;

  MovesenseTemperature(this.timestamp, this.measurement);

  /// Creates a temperature reading from a decoded Movesense `Meas/Temp`
  /// notification.
  factory MovesenseTemperature.fromMovesenseData(dynamic data) {
    num timestamp = data["Body"]["Timestamp"] as num;
    num measurement = data["Body"]["Measurement"] as num;

    return MovesenseTemperature(timestamp.toInt(), measurement.toInt());
  }

  @override
  Function get fromJsonFunction => _$MovesenseTemperatureFromJson;
  factory MovesenseTemperature.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MovesenseTemperature>(json);
  @override
  Map<String, dynamic> toJson() => _$MovesenseTemperatureToJson(this);

  @override
  String get jsonType => MovesenseSamplingPackage.TEMPERATURE;
}

/// A batch of 9-axis IMU samples (accelerometer, gyroscope and magnetometer)
/// from a Movesense device.
///
/// Collected by [MovesenseIMUProbe] at 13 Hz for the
/// [MovesenseSamplingPackage.IMU] measure. The three sensors are sampled
/// together, which suits for example AHRS algorithms.
///
/// Note that [MovesenseIMU.fromMovesenseData] currently fills [gyroscope] and
/// [magnetometer] from the accelerometer array (`ArrayAcc`) of the
/// notification, so all three lists hold accelerometer values.
///
/// See https://www.movesense.com/docs/esw/api_reference/#measimu
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseIMU extends SensorData {
  /// The device's internal timestamp of this sample in milliseconds.
  final int timestamp;

  final List<MovesenseAccelerometerSample> accelerometer;

  final List<MovesenseGyroscopeSample> gyroscope;

  final List<MovesenseMagnetometerSample> magnetometer;

  MovesenseIMU(
    this.timestamp,
    this.accelerometer,
    this.gyroscope,
    this.magnetometer,
  );

  /// Creates IMU data from a decoded Movesense `Meas/IMU9` notification.
  factory MovesenseIMU.fromMovesenseData(dynamic data) {
    num timestamp = data["Body"]["Timestamp"] as num;

    List<MovesenseAccelerometerSample> acc =
        (data["Body"]["ArrayAcc"] as List<dynamic>)
            .map(
              (sample) => MovesenseAccelerometerSample(
                sample['x'] as num,
                sample['y'] as num,
                sample['z'] as num,
              ),
            )
            .toList();

    List<MovesenseGyroscopeSample> gyro =
        (data["Body"]["ArrayAcc"] as List<dynamic>)
            .map(
              (sample) => MovesenseGyroscopeSample(
                sample['x'] as num,
                sample['y'] as num,
                sample['z'] as num,
              ),
            )
            .toList();

    List<MovesenseMagnetometerSample> mag =
        (data["Body"]["ArrayAcc"] as List<dynamic>)
            .map(
              (sample) => MovesenseMagnetometerSample(
                sample['x'] as num,
                sample['y'] as num,
                sample['z'] as num,
              ),
            )
            .toList();

    return MovesenseIMU(timestamp.toInt(), acc, gyro, mag);
  }

  @override
  Function get fromJsonFunction => _$MovesenseIMUFromJson;
  factory MovesenseIMU.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MovesenseIMU>(json);
  @override
  Map<String, dynamic> toJson() => _$MovesenseIMUToJson(this);

  @override
  String get jsonType => MovesenseSamplingPackage.IMU;
}

/// One accelerometer sample in a [MovesenseIMU].
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseAccelerometerSample {
  /// X, Y and Z axis values in m/s² (including gravity).
  final num x, y, z;

  MovesenseAccelerometerSample(this.x, this.y, this.z);

  factory MovesenseAccelerometerSample.fromJson(Map<String, dynamic> json) =>
      _$MovesenseAccelerometerSampleFromJson(json);
  Map<String, dynamic> toJson() => _$MovesenseAccelerometerSampleToJson(this);
}

/// One gyroscope sample in a [MovesenseIMU].
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseGyroscopeSample {
  /// X, Y and Z axis values in degrees per second.
  final num x, y, z;

  MovesenseGyroscopeSample(this.x, this.y, this.z);

  factory MovesenseGyroscopeSample.fromJson(Map<String, dynamic> json) =>
      _$MovesenseGyroscopeSampleFromJson(json);
  Map<String, dynamic> toJson() => _$MovesenseGyroscopeSampleToJson(this);
}

/// One magnetometer sample in a [MovesenseIMU].
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseMagnetometerSample {
  /// X, Y and Z axis values in microtesla (µT).
  final num x, y, z;

  MovesenseMagnetometerSample(this.x, this.y, this.z);

  factory MovesenseMagnetometerSample.fromJson(Map<String, dynamic> json) =>
      _$MovesenseMagnetometerSampleFromJson(json);
  Map<String, dynamic> toJson() => _$MovesenseMagnetometerSampleToJson(this);
}
