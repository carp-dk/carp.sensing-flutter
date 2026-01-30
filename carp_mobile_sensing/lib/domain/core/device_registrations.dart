/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Root class for all CAMS device registrations.
abstract class CamsDeviceRegistration extends DeviceRegistration {
  CamsDeviceRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
  });

  @override
  String get jsonType => '${CamsDevice.CAMS_DEVICE_NAMESPACE}.$runtimeType';
}

/// A [DeviceRegistration] for a [Smartphone] specifying details of the phone.
///
/// Takes inspiration from the device information available via the
/// [device_info_plus](https://pub.dev/packages/device_info_plus) via the
/// [AndroidDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/AndroidDeviceInfo-class.html)
/// and [IosDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/IosDeviceInfo-class.html) classes.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: true)
class SmartphoneRegistration extends CamsDeviceRegistration {
  String? platform;
  String? hardware;
  String? deviceName;
  String? deviceManufacturer;
  String? deviceModel;
  String? operatingSystem;
  String? sdk;
  String? release;

  SmartphoneRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    this.platform,
    this.hardware,
    this.deviceName,
    this.deviceManufacturer,
    this.deviceModel,
    this.operatingSystem,
    this.sdk,
    this.release,
  });

  @override
  Function get fromJsonFunction => _$SmartphoneRegistrationFromJson;
  factory SmartphoneRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SmartphoneRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneRegistrationToJson(this);
}
