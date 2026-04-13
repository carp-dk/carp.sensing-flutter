/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// A [DeviceRegistration] configures a [DeviceConfiguration] as part of the
/// deployment of a [StudyProtocol].
///
/// Note that this is an abstract class and should not be used. If a simple
/// device registration is needed, use a [DefaultDeviceRegistration].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DeviceRegistration extends Serializable {
  /// An ID for the device, used to disambiguate between devices of the same type,
  /// as provided by the device itself.
  /// It is up to specific types of devices to guarantee uniqueness across all
  /// devices of the same type.
  late String deviceId;

  /// An optional concise textual representation for display purposes describing
  /// the key specifications of the device.
  /// E.g., device manufacturer, name, and operating system version.
  String? deviceDisplayName;

  /// The registration time in zulu time.
  late DateTime registrationCreatedOn;

  DeviceRegistration({
    String? deviceId,
    this.deviceDisplayName,
    DateTime? registrationCreatedOn,
  }) : super() {
    this.registrationCreatedOn =
        registrationCreatedOn ?? DateTime.now().toUtc();
    this.deviceId = deviceId ?? const Uuid().v1;
  }

  @override
  Function get fromJsonFunction => _$DeviceRegistrationFromJson;
  factory DeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$DeviceRegistrationToJson(this);
  @override
  String get jsonType =>
      'dk.cachet.carp.common.application.devices.$runtimeType';

  @override
  String toString() =>
      '$runtimeType - deviceId: $deviceId, deviceDisplayName: $deviceDisplayName, registrationCreatedOn: $registrationCreatedOn';
}

/// A concrete [DeviceRegistration] which solely implements the base properties
/// and nothing else.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DefaultDeviceRegistration extends DeviceRegistration {
  /// Create a new [DefaultDeviceRegistration]
  ///  * [deviceId] - a unique id for this device.
  ///    If not specified, a unique id will be generated.
  ///  * [deviceDisplayName] - An optional concise textual representation for display
  ///    purposes describing the key specifications of the device.
  ///  * [registrationCreatedOn] - the timestamp in zulu when this registration was created.
  ///    If not specified, the time of creation will be used.
  DefaultDeviceRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
  });

  @override
  Function get fromJsonFunction => _$DefaultDeviceRegistrationFromJson;
  factory DefaultDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DefaultDeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$DefaultDeviceRegistrationToJson(this);
}

/// A [DeviceRegistration] for devices which have a MAC address.
///
/// Represents an IEEE 802 48-bit media access control address (MAC address);
/// a unique identifier assigned to a network interface controller (NIC) for
/// use as a network address in communications within a network segment.
///
/// This is equivalent to the EUI-48 identifier.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MACAddressDeviceRegistration extends DeviceRegistration {
  /// The MAC address, represented according to the recommended IEEE 802 standard notation.
  /// Six groups of two upper case hexadecimal digits, separate by hyphens (-).
  String macAddress;

  /// Create a new [MACAddressDeviceRegistration] with a unique MAC [macAddress].
  MACAddressDeviceRegistration({
    String? deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    required this.macAddress,
  }) : super(deviceId: deviceId ?? macAddress);

  @override
  Function get fromJsonFunction => _$MACAddressDeviceRegistrationFromJson;
  factory MACAddressDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MACAddressDeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$MACAddressDeviceRegistrationToJson(this);
}
