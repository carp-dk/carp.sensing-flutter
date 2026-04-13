/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Provides (static) information about the local device.
///
/// This service works as a singleton that one time access the information from the
/// local device to be used in the sensing framework.
///
/// It takes different hardware information from Android and iOS:
///
///  * [Android](https://developer.android.com/reference/android/os/Build)
///  * [iOS](https://developer.apple.com/documentation/uikit/uidevice)
class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static final DeviceInfoService _instance = DeviceInfoService._();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._();

  /// Android or iOS
  String? platform;

  /// The name of the hardware.
  ///  * Android- the name of the hardware (from the kernel command line or /proc).
  ///  * iOS - hardware type (e.g. 'iPhone7,1' for iPhone 6 Plus).
  String? hardware;

  /// Unique device ID
  /// * Android - Either a changelist number, or a label like "M4-rc20".
  /// * iOS - [Unique UUID](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor) value identifying the current device.
  String? deviceID;

  /// Device name.
  /// * Android - The name of the industrial design.
  /// * iOS < 16 user-assigned device name.
  /// * iOS >= 16 a generic device name if project has no entitlement to get user-assigned device name.
  ///
  /// On iOS, se more about [device name](https://developer.apple.com/documentation/uikit/uidevice/1620015-name).
  String? deviceName;

  /// The manufacturer of the device.
  /// * Android - The manufacturer of the product/hardware.
  /// * iOS - always "Apple"
  String? deviceManufacturer;

  /// Device Model
  /// * Android - The end-user-visible name for the end product.
  /// * iOS - Device model according to OS
  String? deviceModel;

  /// The name of the current operating system.
  String? operatingSystemName;

  /// The current operating system version.
  String? operatingSystemVersion;

  /// SDK level.
  String? sdk;

  /// Release level.
  String? release;

  /// The full device info for this device.
  /// See [BaseDeviceInfo.data].
  Map<String, dynamic> deviceData = {};

  /// Has the device info been initialized?
  bool get initialized => deviceData.isNotEmpty;

  /// Initialize the device info service using the [DeviceInfoPlugin].
  Future<void> init() async {
    // early out if already initialized
    if (initialized) return;

    try {
      if (Platform.isAndroid) {
        deviceData = _parseAndroidDeviceInfo(
          await _deviceInfoPlugin.androidInfo,
        );
      } else if (Platform.isIOS) {
        deviceData = _parseIosDeviceInfo(await _deviceInfoPlugin.iosInfo);
      }
    } on Exception {
      deviceData = {};
    }
  }

  @override
  String toString() => ((Platform.isAndroid)
      ? '$platform (${deviceManufacturer?.toUpperCase()}) - $deviceModel [SDK: $sdk]'
      : '$platform - $hardware [SDK: $sdk]');

  Map<String, dynamic> _parseAndroidDeviceInfo(AndroidDeviceInfo info) {
    platform = 'Android';
    hardware = info.hardware;
    deviceID = info.id;
    deviceName = info.device;
    deviceManufacturer = info.manufacturer;
    deviceModel = info.model;
    operatingSystemName = info.version.codename;
    operatingSystemVersion = info.version.baseOS;
    sdk = info.version.sdkInt.toString();
    release = info.version.release;

    return info.data;
  }

  Map<String, dynamic> _parseIosDeviceInfo(IosDeviceInfo info) {
    platform = 'iOS';
    hardware = info.utsname.machine;
    deviceID = info.identifierForVendor;
    deviceName = info.name;
    deviceManufacturer = 'Apple';
    deviceModel = info.model;
    operatingSystemName = info.systemName;
    operatingSystemVersion = info.systemVersion;
    sdk = info.utsname.release;
    release = info.utsname.version;

    return info.data;
  }
}
