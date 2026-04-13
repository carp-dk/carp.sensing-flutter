/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'esense.dart';

/// Abstract eSense datum class.
abstract class ESenseData extends Data {
  /// Timestamp of this event.
  late DateTime timestamp;

  /// The name of eSense device that generated this event.
  String deviceName;

  ESenseData(this.deviceName, [DateTime? timestamp]) : super() {
    this.timestamp = timestamp ?? DateTime.now();
  }

  @override
  String toString() => '${super.toString()}, device name: $deviceName';
}

/// Holds information about an eSense button pressed event.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ESenseButton extends ESenseData {
  /// true if the button is pressed, false if it is released
  bool pressed;

  ESenseButton({required String deviceName, required this.pressed})
    : super(deviceName);

  factory ESenseButton.fromButtonEventChanged(
    String deviceName,
    ButtonEventChanged event,
  ) => ESenseButton(deviceName: '', pressed: event.pressed);

  @override
  Function get fromJsonFunction => _$ESenseButtonFromJson;
  factory ESenseButton.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as ESenseButton;
  @override
  Map<String, dynamic> toJson() => _$ESenseButtonToJson(this);

  @override
  String get jsonType => ESenseSamplingPackage.ESENSE_BUTTON;

  @override
  String toString() => '${super.toString()}, button pressed: $pressed';
}

/// Holds information about an eSense button pressed event.
///
/// This data is a 1:1 mapping of the
/// eSense [SensorEvent](https://pub.dev/documentation/esense/latest/esense/SensorEvent-class.html)
/// event.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ESenseSensor extends ESenseData {
  /// Sequential number of sensor packets.
  /// The eSense device don't have a clock, so this index reflect the order of reading.
  int? packetIndex;

  /// 3-elements array with X, Y and Z axis for accelerometer
  List<int>? accel;

  /// 3-elements array with X, Y and Z axis for gyroscope
  List<int>? gyro;

  ESenseSensor({
    required String deviceName,
    DateTime? timestamp,
    this.packetIndex,
    this.accel,
    this.gyro,
  }) : super(deviceName, timestamp);

  factory ESenseSensor.fromSensorEvent({
    required String deviceName,
    required SensorEvent event,
  }) => ESenseSensor(
    deviceName: deviceName,
    timestamp: event.timestamp,
    packetIndex: event.packetIndex,
    gyro: event.gyro,
    accel: event.accel,
  );

  @override
  Function get fromJsonFunction => _$ESenseSensorFromJson;
  factory ESenseSensor.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as ESenseSensor;
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
