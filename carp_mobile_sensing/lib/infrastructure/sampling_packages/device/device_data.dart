/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// Holds basic information about the mobile device from where the data is collected.
///
/// More information on the data from Android and iOS are available at:
///   * [AndroidDeviceInfo](https://pub.dev/documentation/device_info/latest/device_info/AndroidDeviceInfo-class.html)
///   * [IosDeviceInfo](https://pub.dev/documentation/device_info/latest/device_info/IosDeviceInfo-class.html)
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DeviceInformation extends Data {
  ///The platform type of the device.
  /// * `Android`
  /// * `IOS`
  String? platform;

  /// An identifier that is unique to the particular device.
  /// Note that this ID will change if the user performs a factory reset on their device.
  String? deviceId;

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

  /// The full device info for this device.
  Map<String, dynamic> deviceData = {};

  DeviceInformation({
    this.deviceData = const {},
    this.platform,
    this.deviceId,
    this.deviceName,
    this.deviceModel,
    this.deviceManufacturer,
    this.operatingSystem,
    this.hardware,
  }) : super();

  /// Returns `true` if the [deviceId] is equal.
  @override
  bool equivalentTo(Data other) =>
      (other is DeviceInformation) ? deviceId == other.deviceId : false;

  @override
  Function get fromJsonFunction => _$DeviceInformationFromJson;
  factory DeviceInformation.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DeviceInformation>(json);
  @override
  Map<String, dynamic> toJson() => _$DeviceInformationToJson(this);
}

/// Holds basic information about the app from where the data is collected.
///
/// Uses the same data structure as the [package_info_plus](https://pub.dev/packages/package_info_plus) package.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ApplicationInformation extends Data {
  /// The app name.
  ///
  /// - `CFBundleDisplayName` on iOS - falls back to `CFBundleName`.
  ///   Defined in the `info.plist` and/or product target in xcode.
  /// - `application/label` on Android.
  ///   Defined in `AndroidManifest.xml` or String resources.
  final String appName;

  /// The package name.
  ///
  /// - `bundleIdentifier` on iOS and macOS. Defined in the product target in xcode.
  /// - `packageName` on Android. Defined in `build.gradle` as `applicationId`.
  final String packageName;

  /// The package version.
  /// Generated from the version in `pubspec.yaml`.
  ///
  /// - `CFBundleShortVersionString` on iOS.
  /// - `versionName` on Android.
  final String version;

  /// The build number.
  /// Generated from the version in `pubspec.yaml`.
  ///
  /// - `CFBundleVersion` on iOS.
  /// - `versionCode` on Android.
  ///
  /// Note, on iOS if an app has no buildNumber specified this property will return version
  /// Docs about CFBundleVersion: https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleversion
  final String buildNumber;

  /// The build signature.
  /// SHA-256 signing key signature (hex) on Android.
  /// Empty string on iOS.
  final String buildSignature;

  /// The installer store. Indicates through which store this application was installed.
  final String? installerStore;

  /// The time when the application was installed.
  ///
  /// - On Android, returns `PackageManager.firstInstallTime`
  /// - On iOS, return the creation date of the app default `NSDocumentDirectory`
  final DateTime? installTime;

  /// The time when the application was last updated.
  ///
  /// - On Android, returns `PackageManager.lastUpdateTime`
  /// - On iOS return the last modified date of the app main bundle
  final DateTime? updateTime;

  ApplicationInformation({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    this.buildSignature = '',
    this.installerStore,
    this.installTime,
    this.updateTime,
  }) : super();

  ApplicationInformation.fromPackageInfo(PackageInfo info)
    : appName = info.appName,
      packageName = info.packageName,
      version = info.version,
      buildNumber = info.buildNumber,
      buildSignature = info.buildSignature,
      installerStore = info.installerStore,
      installTime = info.installTime,
      updateTime = info.updateTime,
      super();

  /// Returns `true` if the [appName] is equal.
  @override
  bool equivalentTo(Data other) =>
      (other is ApplicationInformation) ? appName == other.appName : false;

  @override
  Function get fromJsonFunction => _$ApplicationInformationFromJson;
  factory ApplicationInformation.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ApplicationInformation>(json);
  @override
  Map<String, dynamic> toJson() => _$ApplicationInformationToJson(this);
}

/// Holds battery level and charging status collected from the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BatteryState extends Data {
  static const String STATE_FULL = 'full';
  static const String STATE_CHARGING = 'charging';
  static const String STATE_DISCHARGING = 'discharging';
  static const String STATE_CONNECTED_NOT_CHARGING = 'connectedNotCharging';
  static const String STATE_UNKNOWN = 'unknown';

  /// The battery level in percent.
  int? batteryLevel;

  /// The charging status of the battery:
  ///  - full
  ///  - charging
  ///  - discharging
  ///  - connectedNotCharging
  ///  - unknown
  String? batteryStatus;

  BatteryState([this.batteryLevel, this.batteryStatus]) : super();

  BatteryState.fromBatteryState(int level, battery.BatteryState state)
    : batteryLevel = level,
      batteryStatus = _parseBatteryState(state),
      super();

  static String _parseBatteryState(battery.BatteryState state) =>
      switch (state) {
        battery.BatteryState.full => STATE_FULL,
        battery.BatteryState.charging => STATE_CHARGING,
        battery.BatteryState.discharging => STATE_DISCHARGING,
        battery.BatteryState.connectedNotCharging =>
          STATE_CONNECTED_NOT_CHARGING,
        _ => STATE_UNKNOWN,
      };

  /// Returns `true` if the [batteryLevel] is equal.
  @override
  bool equivalentTo(Data other) =>
      (other is BatteryState) ? batteryLevel == other.batteryLevel : false;

  @override
  int get hashCode => Object.hash(batteryLevel, batteryStatus);

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is BatteryState &&
          runtimeType == other.runtimeType &&
          batteryLevel == other.batteryLevel &&
          batteryStatus == other.batteryStatus;

  @override
  Function get fromJsonFunction => _$BatteryStateFromJson;
  factory BatteryState.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BatteryState>(json);
  @override
  Map<String, dynamic> toJson() => _$BatteryStateToJson(this);
}

/// Holds information about free memory on the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FreeMemory extends Data {
  /// Amount of free physical memory in bytes.
  int? freePhysicalMemory;

  /// Amount of free virtual memory in bytes.
  int? freeVirtualMemory;

  FreeMemory([this.freePhysicalMemory, this.freeVirtualMemory]) : super();

  @override
  Function get fromJsonFunction => _$FreeMemoryFromJson;
  factory FreeMemory.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<FreeMemory>(json);
  @override
  Map<String, dynamic> toJson() => _$FreeMemoryToJson(this);
}

/// Holds a screen event collected from the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ScreenEvent extends Data {
  /// A screen event:
  /// - SCREEN_OFF
  /// - SCREEN_ON
  /// - SCREEN_UNLOCKED
  String? screenEvent;

  ScreenEvent([this.screenEvent]) : super();

  factory ScreenEvent.fromScreenStateEvent(ScreenStateEvent event) {
    ScreenEvent sd = ScreenEvent();

    switch (event) {
      case ScreenStateEvent.screenOn:
        sd.screenEvent = 'SCREEN_ON';
        break;
      case ScreenStateEvent.screenOff:
        sd.screenEvent = 'SCREEN_OFF';
        break;
      case ScreenStateEvent.screenUnlocked:
        sd.screenEvent = 'SCREEN_UNLOCKED';
        break;
    }
    return sd;
  }

  /// Returns `true` if the [screenEvent] is equal.
  @override
  bool equivalentTo(Data other) =>
      (other is ScreenEvent) ? screenEvent == other.screenEvent : false;

  @override
  Function get fromJsonFunction => _$ScreenEventFromJson;
  factory ScreenEvent.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ScreenEvent>(json);
  @override
  Map<String, dynamic> toJson() => _$ScreenEventToJson(this);
}

/// Holds timezone information about the mobile device.
///
/// See [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
/// for an overview of timezones.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class Timezone extends Data {
  /// The timezone as a string.
  String timezone;

  Timezone(this.timezone) : super();

  /// Returns `true` if the timezone of [other] is the same as this [timezone].
  @override
  bool equivalentTo(Data other) =>
      (other is Timezone) ? timezone == other.timezone : false;

  @override
  Function get fromJsonFunction => _$TimezoneFromJson;
  factory Timezone.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Timezone>(json);
  @override
  Map<String, dynamic> toJson() => _$TimezoneToJson(this);
}

/// Holds information about [AppLifecycleState] events collected from the phone.
///
/// [state] can be one of the following state:
///  * inactive
///  * hidden
///  * paused
///  * resumed
///  * detached
///
/// See [AppLifecycleState] for details.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class AppLifecycleEvent extends Data {
  /// The app lifecycle state.
  String state;

  AppLifecycleEvent(this.state) : super();

  @override
  bool equivalentTo(Data other) =>
      (other is AppLifecycleEvent) ? state == other.state : false;

  @override
  Function get fromJsonFunction => _$AppLifecycleEventFromJson;
  factory AppLifecycleEvent.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppLifecycleEvent>(json);
  @override
  Map<String, dynamic> toJson() => _$AppLifecycleEventToJson(this);
}

/// Reflects a heart beat data send every [period] minute.
/// Useful for calculating sampling coverage over time.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Heartbeat extends Data {
  /// The type of device.
  String deviceType;

  /// The role name of the device in the protocol.
  String deviceRoleName;

  Heartbeat({required this.deviceType, required this.deviceRoleName}) : super();

  @override
  Function get fromJsonFunction => _$HeartbeatFromJson;
  factory Heartbeat.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Heartbeat>(json);
  @override
  Map<String, dynamic> toJson() => _$HeartbeatToJson(this);
}
