/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// A probe that collects the device info about this device.
class DeviceProbe extends MeasurementProbe {
  @override
  Future<Measurement?> getMeasurement() async {
    await DeviceInfoService().init();

    return Measurement.fromData(
      DeviceInformation(
        deviceData: DeviceInfoService().deviceData,
        platform: DeviceInfoService().platform,
        deviceId: DeviceInfoService().deviceID,
        deviceName: DeviceInfoService().deviceName,
        deviceModel: DeviceInfoService().deviceModel,
        deviceManufacturer: DeviceInfoService().deviceManufacturer,
        operatingSystem: DeviceInfoService().operatingSystemName,
        hardware: DeviceInfoService().hardware,
      ),
    );
  }
}

/// A probe that collects heartbeat info about the master device on a regular basis
/// as specified in [PeriodicMeasure.frequency].
class HeartbeatProbe extends IntervalProbe {
  @override
  Future<Measurement?> getMeasurement() async => Measurement.fromData(
    Heartbeat(
      deviceType: SmartPhoneClientManager()
          .deviceController
          .smartphoneDeviceManager
          .deviceType,
      deviceRoleName: deployment?.deviceRoleName ?? 'unknown',
    ),
  );
}

/// A probe that collects the device info about this device.
class ApplicationProbe extends MeasurementProbe {
  @override
  Future<Measurement?> getMeasurement() async {
    if (!Settings().initialized) return null;

    return Measurement.fromData(
      ApplicationInformation.fromPackageInfo(Settings().packageInfo!),
    );
  }
}

/// Collects battery information (charging state and battery level) on a regular
/// basis as specified by the [IntervalSamplingConfiguration.interval].
class BatteryProbe extends IntervalProbe {
  BatteryState _priorState = BatteryState(0, 'unknown');

  @override
  Future<Measurement?> getMeasurement() async {
    final level = await battery.Battery().batteryLevel;
    final state = await battery.Battery().batteryState;
    final batteryState = BatteryState.fromBatteryState(level, state);
    if (batteryState != _priorState) {
      _priorState = batteryState;
      return Measurement.fromData(batteryState);
    }
    return null;
  }
}

/// A probe collecting screen events:
///  - SCREEN ON
///  - SCREEN OFF
///  - SCREEN UNLOCK
/// which are stored as a [ScreenEvent].
///
/// This probe is only available on Android.
class ScreenProbe extends StreamProbe {
  Screen screen = Screen();

  @override
  Stream<Measurement> get stream => screen.screenStateStream.map(
    (event) => Measurement.fromData(ScreenEvent.fromScreenStateEvent(event)),
  );
}

/// A probe that collects free virtual memory on a regular basis
/// as specified by the [IntervalSamplingConfiguration.interval].
///
/// Only available on Android (it seems).
class MemoryProbe extends IntervalProbe {
  @override
  bool onInitialize() {
    // check if SysInfo is available (seems not to be available on iOS)
    SysInfo.getFreePhysicalMemory();
    return true;
  }

  @override
  Future<Measurement?> getMeasurement() async => Measurement.fromData(
    FreeMemory(SysInfo.getFreePhysicalMemory(), SysInfo.getFreeVirtualMemory()),
  );
}

/// A probe that collects the device's current timezone.
class TimezoneProbe extends MeasurementProbe {
  @override
  Future<Measurement?> getMeasurement() async => Measurement.fromData(
    Timezone((await FlutterTimezone.getLocalTimezone()).identifier),
  );
}

/// A probe that collects app lifecycle events.
class AppLifecycleProbe extends StreamProbe with WidgetsBindingObserver {
  final StreamController<Measurement> _controller =
      StreamController.broadcast();

  @override
  Stream<Measurement> get stream => _controller.stream;

  @override
  Future<bool> onResume() async {
    WidgetsBinding.instance.addObserver(this);
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    WidgetsBinding.instance.removeObserver(this);
    return await super.onPause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _controller.add(Measurement.fromData(AppLifecycleEvent(state.name)));
}
