/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../device.dart';

class DeviceSamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for collection of basic device information like device name,
  /// model, manufacturer, operating system, and hardware profile.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * No sampling configuration needed.
  static const String DEVICE_INFORMATION =
      '${CarpDataTypes.CARP_NAMESPACE}.deviceinformation';

  /// Measure type for collection of free physical and virtual memory.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * Use [IntervalSamplingConfiguration] for configuration.
  static const String FREE_MEMORY =
      '${CarpDataTypes.CARP_NAMESPACE}.freememory';

  /// Measure type for collection of battery level and charging status.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * No sampling configuration needed.
  static const String BATTERY_STATE =
      '${CarpDataTypes.CARP_NAMESPACE}.batterystate';

  /// Measure type for collection of screen events (on/off/unlocked).
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * No sampling configuration needed.
  static const String SCREEN_EVENT =
      '${CarpDataTypes.CARP_NAMESPACE}.screenevent';

  /// Measure type for app lifecycle state events (inactive, hidden, paused,
  /// resumed, detached).
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * No sampling configuration needed.
  static const String APP_LIFECYCLE_EVENT =
      '${CarpDataTypes.CARP_NAMESPACE}.applifecycleevent';

  /// Measure type for collection of the time zone of the device.
  /// See [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  /// for an overview of timezones.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * No sampling configuration needed.
  static const String TIMEZONE = '${CarpDataTypes.CARP_NAMESPACE}.timezone';

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: DEVICE_INFORMATION,
            displayName: "Device Information",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: FREE_MEMORY,
            displayName: "Free Memory",
            timeType: DataTimeType.POINT,
          ),
          IntervalSamplingConfiguration(interval: const Duration(minutes: 1)),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: BATTERY_STATE,
            displayName: "Battery State",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: SCREEN_EVENT,
            displayName: "Screen Events",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: APP_LIFECYCLE_EVENT,
            displayName: "App Lifecycle Events",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: TIMEZONE,
            displayName: "Device Timezone",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
      ]);

  @override
  Probe? create(String type) => switch (type) {
    DEVICE_INFORMATION => DeviceProbe(),
    FREE_MEMORY => MemoryProbe(),
    BATTERY_STATE => BatteryProbe(),
    TIMEZONE => TimezoneProbe(),
    APP_LIFECYCLE_EVENT => AppLifecycleProbe(),
    SCREEN_EVENT => (Platform.isAndroid) ? ScreenProbe() : null,
    _ => null,
  };

  @override
  void onRegister() {
    FromJsonFactory().registerAll([
      DeviceInformation(),
      BatteryState(),
      FreeMemory(),
      ScreenEvent(),
      Timezone(''),
    ]);
  }
}
