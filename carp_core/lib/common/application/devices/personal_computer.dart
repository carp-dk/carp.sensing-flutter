/*
 * Copyright 2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// Configuration of an internet-connected personal computer with no built-in [sensors].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PersonalComputer
    extends PrimaryDeviceConfiguration<PersonalComputerRegistration> {
  /// The type of a personal computer device.
  static const String DEVICE_TYPE =
      '${DeviceConfiguration.DEVICE_NAMESPACE}.PersonalComputer';

  /// The default role name for a personal computer.
  static const String DEFAULT_ROLE_NAME = 'Primary PC';

  /// Create a new personal computer device descriptor.
  /// If [roleName] is not specified, then the [DEFAULT_ROLE_NAME] is used.
  PersonalComputer({super.roleName = PersonalComputer.DEFAULT_ROLE_NAME});

  @override
  PersonalComputerRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
    String? platform,
    String? computerName,
    int? memorySize,
    String? deviceModel,
    String? operatingSystem,
    String? version,
  }) => PersonalComputerRegistration(
    deviceId: deviceId,
    deviceDisplayName: deviceDisplayName,
    platform: platform,
    computerName: computerName,
    memorySize: memorySize,
    deviceModel: deviceModel,
    operatingSystem: operatingSystem,
    version: version,
  );

  @override
  Function get fromJsonFunction => _$PersonalComputerFromJson;
  factory PersonalComputer.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PersonalComputer>(json);
  @override
  Map<String, dynamic> toJson() => _$PersonalComputerToJson(this);
}

/// A [DeviceRegistration] for a [PersonalComputer] specifying details of the PC.
///
/// Takes inspiration from the device information available via the
/// [device_info_plus](https://pub.dev/packages/device_info_plus) via the
/// [MacOsDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/MacOsDeviceInfo-class.html)
/// and [WindowsDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/WindowsDeviceInfo-class.html) classes.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PersonalComputerRegistration extends DeviceRegistration {
  String? platform;
  String? computerName;
  int? memorySize;
  String? deviceModel;
  String? operatingSystem;
  String? version;

  PersonalComputerRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    this.platform,
    this.computerName,
    this.memorySize,
    this.deviceModel,
    this.operatingSystem,
    this.version,
  });

  @override
  Function get fromJsonFunction => _$PersonalComputerRegistrationFromJson;
  factory PersonalComputerRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PersonalComputerRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$PersonalComputerRegistrationToJson(this);
}
