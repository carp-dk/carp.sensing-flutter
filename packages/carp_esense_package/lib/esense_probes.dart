/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'esense.dart';

abstract class _ESenseProbe extends StreamProbe {
  @override
  ESenseDeviceManager get deviceManager => super.deviceManager as ESenseDeviceManager;
}

/// Collects eSense button events for the [ESenseSamplingPackage.ESENSE_BUTTON]
/// measure.
///
/// Emits an [ESenseButton] every time the button is pressed or released.
/// Has no stream until the [ESenseDeviceManager] is connected.
class ESenseButtonProbe extends _ESenseProbe {
  @override
  Stream<Measurement>? get stream => (deviceManager.isConnected)
      ? deviceManager.manager!.eSenseEvents
            .where((event) => event.runtimeType == ButtonEventChanged)
            .map(
              (event) => Measurement.fromData(
                ESenseButton(
                  deviceName: deviceManager.manager!.deviceName,
                  pressed: (event as ButtonEventChanged).pressed,
                ),
              ),
            )
            .asBroadcastStream()
      : null;
}

/// Collects eSense sensor events for the [ESenseSamplingPackage.ESENSE_SENSOR]
/// measure.
///
/// Emits an [ESenseSensor] for each sensor event, at the
/// [ESenseDevice.samplingRate]. Has no stream until the [ESenseDeviceManager]
/// is connected.
class ESenseSensorProbe extends _ESenseProbe {
  Stream<Measurement>? _stream;

  @override
  Stream<Measurement>? get stream => _stream ??= (deviceManager.isConnected)
      ? deviceManager.manager!.sensorEvents
            .map(
              (event) => Measurement.fromData(
                ESenseSensor.fromSensorEvent(deviceName: deviceManager.manager!.deviceName, event: event),
                event.timestamp.microsecondsSinceEpoch,
              ),
            )
            .asBroadcastStream()
      : null;
}
