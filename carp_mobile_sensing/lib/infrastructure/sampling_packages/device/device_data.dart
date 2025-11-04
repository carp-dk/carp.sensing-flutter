/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../device.dart';

/// Holds basic information about the mobile device from where the data is collected.
///
/// More information on the data from Android and iOS are available at:
///   * [AndroidDeviceInfo](https://pub.dev/documentation/device_info/latest/device_info/AndroidDeviceInfo-class.html)
///   * [IosDeviceInfo](https://pub.dev/documentation/device_info/latest/device_info/IosDeviceInfo-class.html)
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DeviceInformation extends Data {
  static const dataType = DeviceSamplingPackage.DEVICE_INFORMATION;

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

/// Holds battery level and charging status collected from the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BatteryState extends Data {
  static const dataType = DeviceSamplingPackage.BATTERY_STATE;

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
  Function get fromJsonFunction => _$BatteryStateFromJson;
  factory BatteryState.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BatteryState>(json);
  @override
  Map<String, dynamic> toJson() => _$BatteryStateToJson(this);
}

/// Holds information about free memory on the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FreeMemory extends Data {
  static const dataType = DeviceSamplingPackage.FREE_MEMORY;

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
  static const dataType = DeviceSamplingPackage.SCREEN_EVENT;

  /// A screen event:
  /// - SCREEN_OFF
  /// - SCREEN_ON
  /// - SCREEN_UNLOCKED
  String? screenEvent;

  ScreenEvent([this.screenEvent]) : super();

  factory ScreenEvent.fromScreenStateEvent(ScreenStateEvent event) {
    ScreenEvent sd = ScreenEvent();

    switch (event) {
      case ScreenStateEvent.SCREEN_ON:
        sd.screenEvent = 'SCREEN_ON';
        break;
      case ScreenStateEvent.SCREEN_OFF:
        sd.screenEvent = 'SCREEN_OFF';
        break;
      case ScreenStateEvent.SCREEN_UNLOCKED:
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
  static const dataType = DeviceSamplingPackage.TIMEZONE;

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
  static const dataType = DeviceSamplingPackage.APP_LIFECYCLE_EVENT;

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
