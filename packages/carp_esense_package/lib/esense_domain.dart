/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'esense.dart';

/// The base class of the [Data] collected from an [ESenseDevice].
///
/// Extended by [ESenseButton] and [ESenseSensor].
abstract class ESenseData extends Data {
  /// Timestamp of this event. Defaults to the time this object is created.
  late DateTime timestamp;

  /// The name of eSense device that generated this event.
  String deviceName;

  ESenseData(this.deviceName, [DateTime? timestamp]) : super() {
    this.timestamp = timestamp ?? DateTime.now();
  }

  @override
  String toString() => '${super.toString()}, device name: $deviceName';
}

/// An eSense button event: the button was pressed or released.
///
/// Collected by the [ESenseButtonProbe] for the
/// [ESenseSamplingPackage.ESENSE_BUTTON] measure.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ESenseButton extends ESenseData {
  /// True if the button is pressed, false if it is released.
  bool pressed;

  ESenseButton({required String deviceName, required this.pressed}) : super(deviceName);

  /// Creates an [ESenseButton] from an `esense_flutter` [ButtonEventChanged].
  ///
  /// Note that [deviceName] is ignored and the device name is set to an
  /// empty string.
  factory ESenseButton.fromButtonEventChanged(String deviceName, ButtonEventChanged event) =>
      ESenseButton(deviceName: '', pressed: event.pressed);

  @override
  Function get fromJsonFunction => _$ESenseButtonFromJson;
  factory ESenseButton.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as ESenseButton;
  @override
  Map<String, dynamic> toJson() => _$ESenseButtonToJson(this);

  @override
  String get jsonType => ESenseSamplingPackage.ESENSE_BUTTON;

  @override
  String toString() => '${super.toString()}, button pressed: $pressed';
}

/// An eSense motion sensor event with accelerometer and gyroscope readings.
///
/// Collected by the [ESenseSensorProbe] for the
/// [ESenseSamplingPackage.ESENSE_SENSOR] measure. This data is a 1:1 mapping
/// of the `esense_flutter` [SensorEvent].
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ESenseSensor extends ESenseData {
  /// Sequential number of sensor packets.
  /// The eSense device does not have a clock, so this index reflects the order of reading.
  int? packetIndex;

  /// 3-element array with the X, Y and Z axis of the accelerometer, as raw
  /// sensor values.
  List<int>? accel;

  /// 3-element array with the X, Y and Z axis of the gyroscope, as raw
  /// sensor values.
  List<int>? gyro;

  ESenseSensor({required String deviceName, DateTime? timestamp, this.packetIndex, this.accel, this.gyro})
    : super(deviceName, timestamp);

  /// Creates an [ESenseSensor] from an `esense_flutter` [SensorEvent].
  factory ESenseSensor.fromSensorEvent({required String deviceName, required SensorEvent event}) => ESenseSensor(
    deviceName: deviceName,
    timestamp: event.timestamp,
    packetIndex: event.packetIndex,
    gyro: event.gyro,
    accel: event.accel,
  );

  @override
  Function get fromJsonFunction => _$ESenseSensorFromJson;
  factory ESenseSensor.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson(json) as ESenseSensor;
  @override
  Map<String, dynamic> toJson() => _$ESenseSensorToJson(this);

  @override
  String get jsonType => ESenseSamplingPackage.ESENSE_SENSOR;

  @override
  String toString() =>
      '${super.toString()}'
      ', packetIndex: $packetIndex'
      ', accel: [${accel![0]},${accel![1]},${accel![2]}]'
      ', gyro: [${gyro![0]},${gyro![1]},${gyro![2]}]';
}
