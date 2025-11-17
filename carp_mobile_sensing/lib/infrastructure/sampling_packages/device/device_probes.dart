/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// The [BatteryProbe] listens to the hardware battery and collect a [BatteryState]
/// every time the battery state changes. For example, battery level or charging mode.
class BatteryProbe extends StreamProbe {
  @override
  Stream<Measurement>? get stream {
    late StreamSubscription<battery.BatteryState> subscription;
    late StreamController<Measurement> controller;

    void onData(battery.BatteryState state) async {
      try {
        int level = await battery.Battery().batteryLevel;
        controller.add(
          Measurement.fromData(BatteryState.fromBatteryState(level, state)),
        );
      } catch (error) {
        controller.addError(error);
      }
    }

    controller = StreamController<Measurement>(
      onListen: () => subscription.resume(),
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () => subscription.cancel(),
    );

    subscription = battery.Battery().onBatteryStateChanged.listen(
      onData,
      onError: (Object error) => controller.addError(error),
      onDone: () => controller.close(),
    );

    return controller.stream.asBroadcastStream();
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
/// as specified in [PeriodicMeasure.frequency].
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

/// A probe that collects the device info about this device.
class DeviceProbe extends MeasurementProbe {
  @override
  Future<Measurement?> getMeasurement() async {
    await DeviceInfo().init();

    return Measurement.fromData(
      DeviceInformation(
        deviceData: DeviceInfo().deviceData,
        platform: DeviceInfo().platform,
        deviceId: DeviceInfo().deviceID,
        deviceName: DeviceInfo().deviceName,
        deviceModel: DeviceInfo().deviceModel,
        deviceManufacturer: DeviceInfo().deviceManufacturer,
        operatingSystem: DeviceInfo().operatingSystemName,
        hardware: DeviceInfo().hardware,
      ),
    );
  }
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
