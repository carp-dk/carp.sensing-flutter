/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movesense_package.dart';

/// Different states of the Movensense device.
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

  /// Device disconnected to gear.
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

/// Information about used device and the platform which is running on it.
/// Contains knowledge about the hardware version, serial number, app name or
/// modules state.
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
  String? hardwareType;
  String? additionalVersionInfo;
  String? apiLevel;
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

/// States API is a uniform, simplistic interface for accessing states of internal
/// device components.
///
/// Currently available states are listed in [MovesenseDeviceState].
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

  /// The timestamp of this state event in milliseconds.
  late int timestamp;

  MovesenseStateChange(this.state, [int? timestamp])
    : timestamp = timestamp ?? DateTime.now().millisecond;

  // Example event:
  //
  //   Body: {Timestamp: 614897, StateId: 0, NewState: 1}
  //
  // NOTE - the json listed on the official Movesense API is wrong!
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

/// Movesense sensor is equipped with analog front-end capable of capturing ECG
/// signals and calculating user's heart rate from this.
///
/// See https://www.movesense.com/docs/esw/api_reference/#meashr
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseHR extends SensorData {
  /// The average heart rate (Hz).
  final double hr;

  /// The latest R-R measurement (ms).
  final int? rr;

  MovesenseHR(this.hr, [this.rr]);

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

/// Movesense sensor is equipped with analog front-end capable of capturing ECG
/// signals.
///
/// See https://www.movesense.com/docs/esw/api_reference/#measecg
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseECG extends SensorData {
  /// The device's internal timestamp of this sample in milliseconds.
  final int timestamp;

  /// The ECG samples.
  final List<int> samples;

  MovesenseECG(this.timestamp, this.samples);

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

/// The Movesense MD sensor is equipped with temperature sensor, which can be
/// used to measure device's internal temperature. Returned values are in units
/// of Kelvins (K).
///
/// See https://www.movesense.com/docs/esw/api_reference/#meastemperature
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseTemperature extends SensorData {
  /// The device's internal timestamp of this sample in milliseconds.
  final int timestamp;

  /// The device's internal temperature in units of Kelvins (K).
  final int measurement;

  MovesenseTemperature(this.timestamp, this.measurement);

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

/// Provides a synchronized access to combined accelerometer, gyroscope and
/// magnetometer data samples for easier processing e.g. for AHRS algorithms.
/// It is more efficient to subscribe to the IMU resource than to subscribe the
/// individual sensors separately.
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

/// Movesense accelerometer sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseAccelerometerSample {
  /// X,Y,Z value in milli-G (including gravity)
  final num x, y, z;

  MovesenseAccelerometerSample(this.x, this.y, this.z);

  factory MovesenseAccelerometerSample.fromJson(Map<String, dynamic> json) =>
      _$MovesenseAccelerometerSampleFromJson(json);
  Map<String, dynamic> toJson() => _$MovesenseAccelerometerSampleToJson(this);
}

/// Movesense gyroscope sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseGyroscopeSample {
  /// X, Y, Z axis value in deg/sec
  final num x, y, z;

  MovesenseGyroscopeSample(this.x, this.y, this.z);

  factory MovesenseGyroscopeSample.fromJson(Map<String, dynamic> json) =>
      _$MovesenseGyroscopeSampleFromJson(json);
  Map<String, dynamic> toJson() => _$MovesenseGyroscopeSampleToJson(this);
}

/// Movesense magnetometer sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class MovesenseMagnetometerSample {
  /// X, Y, Z axis value in Gauss
  final num x, y, z;

  MovesenseMagnetometerSample(this.x, this.y, this.z);

  factory MovesenseMagnetometerSample.fromJson(Map<String, dynamic> json) =>
      _$MovesenseMagnetometerSampleFromJson(json);
  Map<String, dynamic> toJson() => _$MovesenseMagnetometerSampleToJson(this);
}
