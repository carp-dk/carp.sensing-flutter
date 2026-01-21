/*
 * Copyright 2025 Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// Reflects a heart beat data send every [period] minute.
/// Useful for calculating sampling coverage over time.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Heartbeat extends Data {
  /// The period of heartbeats per minute.
  int period;

  /// The type of device.
  String deviceType;

  /// The role name of the device in the protocol.
  String deviceRoleName;

  Heartbeat({
    required this.period,
    required this.deviceType,
    required this.deviceRoleName,
  }) : super();

  @override
  Function get fromJsonFunction => _$HeartbeatFromJson;
  factory Heartbeat.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Heartbeat>(json);
  @override
  Map<String, dynamic> toJson() => _$HeartbeatToJson(this);
}
