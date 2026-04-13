/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// A beacon meeting the open AltBeacon standard.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AltBeacon extends DeviceConfiguration<AltBeaconDeviceRegistration> {
  AltBeacon({super.roleName = 'Beacon'}) : super(isOptional: true);

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.SIGNAL_STRENGTH]!,
        ),
      ]);

  @override
  AltBeaconDeviceRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
    int? manufacturerId,
    String? organizationId,
    int? majorId,
    int? minorId,
    int? referenceRssi,
  }) => AltBeaconDeviceRegistration(
    deviceId: deviceId,
    deviceDisplayName: deviceDisplayName,
    manufacturerId: manufacturerId,
    organizationId: organizationId,
    majorId: majorId,
    minorId: minorId,
    referenceRssi: referenceRssi,
  );

  @override
  Function get fromJsonFunction => _$AltBeaconFromJson;
  factory AltBeacon.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AltBeacon>(json);
  @override
  Map<String, dynamic> toJson() => _$AltBeaconToJson(this);
}

/// A [DeviceRegistration] for [AltBeacon] specifying which beacon to listen to.
///
/// The beacon ID is 20 bytes, made up out of the recommended subdivision
/// [organizationId], [majorId], and [minorId].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AltBeaconDeviceRegistration extends DeviceRegistration {
  /// The beacon device manufacturer's company identifier code as maintained by
  /// the Bluetooth SIG assigned numbers database.
  int? manufacturerId;

  /// The first 16 bytes of the beacon identifier which should be unique to the
  /// advertiser's organizational unit.
  String? organizationId;

  /// The first 2 bytes of the beacon identifier after the [organizationId],
  /// commonly named major ID.
  int? majorId;

  /// The last 2 bytes of the beacon identifier, commonly named minor ID.
  int? minorId;

  /// The average received signal strength at 1 meter from the beacon in
  /// decibel-milliwatts (dBm).
  /// This value is constrained from -127 to 0.
  int? referenceRssi;

  AltBeaconDeviceRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    this.manufacturerId,
    this.organizationId,
    this.majorId,
    this.minorId,
    this.referenceRssi,
  });

  @override
  Function get fromJsonFunction => _$AltBeaconDeviceRegistrationFromJson;
  factory AltBeaconDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AltBeaconDeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$AltBeaconDeviceRegistrationToJson(this);
}
