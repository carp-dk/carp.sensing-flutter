/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Root class for all CAMS device registrations.
abstract class CamsDeviceRegistration extends DeviceRegistration {
  /// Indicates whether this device was connected when registered.
  ///
  /// Note that a device may be registered when it is not yet connected, e.g.,
  /// when the device is configured as part of a study deployment, but not yet
  /// connected. In this case, the device registration information can be used
  /// for connecting the device later on, e.g., when the device is re-connected
  /// or when the app is restarted.
  bool isConnected = false;

  CamsDeviceRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    this.isConnected = false,
  });

  /// Convert this [CamsDeviceRegistration] to a [DefaultDeviceRegistration]
  /// with the same base properties.
  ///
  /// This is needed for registering the device in the [DeploymentService]
  /// due to issue #561 - right now CAWS only can process a [DefaultDeviceRegistration].
  DefaultDeviceRegistration toDefaultDeviceRegistration() =>
      DefaultDeviceRegistration(
        deviceId: deviceId,
        deviceDisplayName: deviceDisplayName,
        registrationCreatedOn: registrationCreatedOn,
      );

  @override
  String get jsonType => '${CamsDevice.CAMS_DEVICE_NAMESPACE}.$runtimeType';
}

/// The charging state of the device battery of a [HardwareDeviceRegistration].
enum BatteryChargingState { unknown, full, normal, low, critical }

/// A [DeviceRegistration] for a hardware device.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HardwareDeviceRegistration extends CamsDeviceRegistration {
  /// The battery charging state of the device upon registration.
  BatteryChargingState batteryChargingState = BatteryChargingState.unknown;

  /// Get the [BatteryChargingState] based on a battery level percentage (0-100).
  static BatteryChargingState parseBatteryLevel(int batteryLevel) =>
      switch (batteryLevel) {
        <= 10 => BatteryChargingState.critical,
        > 10 && <= 20 => BatteryChargingState.low,
        > 20 && <= 90 => BatteryChargingState.normal,
        > 90 && <= 100 => BatteryChargingState.full,
        _ => BatteryChargingState.unknown,
      };

  /// The hardware name of this device, if available.
  String? hardwareName;

  /// Create a new [HardwareDeviceRegistration] based on hardware information,
  /// incl [hardwareName] and [batteryChargingState].
  HardwareDeviceRegistration({
    super.deviceId,
    String? deviceDisplayName,
    super.registrationCreatedOn,
    super.isConnected,
    this.batteryChargingState = BatteryChargingState.unknown,
    this.hardwareName,
  }) : super(
         deviceDisplayName:
             deviceDisplayName ??
             '$hardwareName [${batteryChargingState.name.toUpperCase()}]',
       );

  @override
  Function get fromJsonFunction => _$HardwareDeviceRegistrationFromJson;
  factory HardwareDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HardwareDeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$HardwareDeviceRegistrationToJson(this);
}

/// A [DeviceRegistration] for a [Smartphone] specifying details of the phone.
///
/// Takes inspiration from the device information available via the
/// [device_info_plus](https://pub.dev/packages/device_info_plus) via the
/// [AndroidDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/AndroidDeviceInfo-class.html)
/// and [IosDeviceInfo](https://pub.dev/documentation/device_info_plus/latest/device_info_plus/IosDeviceInfo-class.html) classes.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SmartphoneRegistration extends HardwareDeviceRegistration {
  ///The platform type of the device - Android or iOS.
  String? platform;

  /// The hardware type of this device (e.g. 'iPhone7,1' for iPhone 6 Plus).
  String? hardware;

  /// Device name as specified by the OS.
  String? deviceName;

  /// Device manufacturer as specified by the OS.
  String? deviceManufacturer;

  /// Device model as specified by the OS.
  String? deviceModel;

  /// Device OS as specified by the OS.
  String? operatingSystem;

  /// The SDK version.
  String? sdk;

  /// The OS release.
  String? release;

  SmartphoneRegistration({
    super.deviceId,
    String? deviceDisplayName,
    super.registrationCreatedOn,
    super.isConnected = true, // A smartphone is always connected.
    super.batteryChargingState,
    super.hardwareName,
    this.platform,
    this.deviceName,
    this.deviceManufacturer,
    this.deviceModel,
    this.operatingSystem,
    this.sdk,
    this.release,
  }) : super(
         deviceDisplayName:
             deviceDisplayName ??
             ((Platform.isAndroid)
                 ? '$platform (${deviceManufacturer?.toUpperCase()}) - $deviceModel [SDK: $sdk]'
                 : '$platform - $hardwareName [SDK: $sdk]'),
       );

  @override
  Function get fromJsonFunction => _$SmartphoneRegistrationFromJson;
  factory SmartphoneRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SmartphoneRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneRegistrationToJson(this);
}

/// A [DeviceRegistration] for Bluetooth Low Energy (BLE) devices which can
/// connect to the smartphone via BLE, e.g., a heart rate monitor or a BLE beacon.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BLEDeviceRegistration extends HardwareDeviceRegistration {
  /// The BLE address of this device.
  ///
  /// The format of the BLE address is platform-specific.
  /// On Android, it is typically a MAC address of the form `00:04:79:00:0F:4D`.
  /// On iOS, it may be a UUID string on the form `E2C56DB5-DFFB-48D2-B060-D0F5A71096E0`.
  String bleAddress;

  /// The BLE name of this device, if known. Not all devices will have a BLE name,
  /// and it may not be available at the time of registration.
  String? bleName;

  /// Create a new [BLEDeviceRegistration] with a unique BLE [bleAddress].
  BLEDeviceRegistration({
    String? deviceDisplayName,
    super.registrationCreatedOn,
    super.isConnected,
    super.batteryChargingState,
    String? hardwareName,
    required this.bleAddress,
    this.bleName,
  }) : super(
         deviceId: bleAddress,
         deviceDisplayName: deviceDisplayName ?? bleName,
         hardwareName: hardwareName ?? bleName,
       );

  @override
  Function get fromJsonFunction => _$BLEDeviceRegistrationFromJson;
  factory BLEDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BLEDeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$BLEDeviceRegistrationToJson(this);
}

/// A [DeviceRegistration] for a [ServiceConfiguration].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ServiceRegistration extends CamsDeviceRegistration {
  ServiceRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    super.isConnected,
  });

  @override
  Function get fromJsonFunction => _$ServiceRegistrationFromJson;
  factory ServiceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ServiceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$ServiceRegistrationToJson(this);
}
