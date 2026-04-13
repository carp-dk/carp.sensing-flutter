/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// A Bluetooth Low Energy (BLE) device which implements a GATT Heart
/// Rate service (https://www.bluetooth.com/specifications/gatt/services/).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BLEHeartRateDevice
    extends DeviceConfiguration<MACAddressDeviceRegistration> {
  BLEHeartRateDevice({required super.roleName, super.isOptional = true});

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.HEART_RATE]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.INTERBEAT_INTERVAL]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.SENSOR_SKIN_CONTACT]!,
        ),
      ]);

  @override
  MACAddressDeviceRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
    DateTime? registrationCreatedOn,
    String? address,
  }) => MACAddressDeviceRegistration(
    deviceId: deviceId,
    deviceDisplayName: deviceDisplayName,
    registrationCreatedOn: registrationCreatedOn,
    macAddress:
        address ??
        '00-1B-44-11-3A-B7', // Random MAC address for testing purposes.
  );

  @override
  Function get fromJsonFunction => _$BLEHeartRateDeviceFromJson;
  factory BLEHeartRateDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BLEHeartRateDevice>(json);
  @override
  Map<String, dynamic> toJson() => _$BLEHeartRateDeviceToJson(this);
}
