/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// Configuration of an internet-connected smartphone with built-in sensors.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Smartphone extends PrimaryDeviceConfiguration<DefaultDeviceRegistration> {
  /// The type of a smartphone device.
  static const String DEVICE_TYPE =
      '${DeviceConfiguration.DEVICE_NAMESPACE}.Smartphone';

  /// The default role name for a smartphone.
  static const String DEFAULT_ROLE_NAME = 'Primary Phone';

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.GEOLOCATION]!,
          GranularitySamplingConfiguration(Granularity.Balanced),
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.STEP_COUNT]!,
          NoOptionsSamplingConfiguration(),
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.NON_GRAVITATIONAL_ACCELERATION]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.ACCELERATION]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.ANGULAR_VELOCITY]!,
        ),
      ]);

  /// Create a new Smartphone device descriptor.
  /// If [roleName] is not specified, then the [DEFAULT_ROLE_NAME] is used.
  Smartphone({super.roleName = Smartphone.DEFAULT_ROLE_NAME});

  @override
  DefaultDeviceRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
    String? platform,
    String? deviceManufacturer,
    String? hardware,
    String? deviceModel,
    String? sdk,
  }) => DefaultDeviceRegistration(
    deviceId: deviceId,
    deviceDisplayName:
        deviceDisplayName ??
        ((Platform.isAndroid)
            ? '$platform (${deviceManufacturer?.toUpperCase()}) - $deviceModel [SDK: $sdk]'
            : '$platform - $hardware [SDK: $sdk]'),
  );

  @override
  Function get fromJsonFunction => _$SmartphoneFromJson;
  factory Smartphone.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Smartphone>(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneToJson(this);
}

/// A [DeviceRegistration] for a [Smartphone] specifying details of the phone.
///
/// Takes inspiration from the device information available via the
/// [device_info_plus](https://pub.dev/packages/device_info_plus) via the
/// [AndroidDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/AndroidDeviceInfo-class.html)
/// and [IosDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/IosDeviceInfo-class.html) classes.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: true)
class SmartphoneDeviceRegistration extends DeviceRegistration {
  String? platform;
  String? hardware;
  String? deviceName;
  String? deviceManufacturer;
  String? deviceModel;
  String? operatingSystem;
  String? sdk;
  String? release;

  SmartphoneDeviceRegistration({
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
  Function get fromJsonFunction => _$SmartphoneDeviceRegistrationFromJson;
  factory SmartphoneDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SmartphoneDeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneDeviceRegistrationToJson(this);
}
