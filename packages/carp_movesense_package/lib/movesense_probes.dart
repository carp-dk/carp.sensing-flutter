/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movesense_package.dart';

/// Base class for probes that subscribe to a Movesense [resource] and turn each
/// notification into a [Measurement] using [parse].
///
/// Listening subscribes to the resource on the device, and pausing the probe
/// unsubscribes. The first [warmUp] notifications are skipped to let the
/// sensor stabilize.
abstract class _MovesenseStreamProbe extends StreamProbe {
  _MovesenseStreamProbe(this.resource, this.parse);

  /// The MDS resource to subscribe to, e.g. `/Meas/HR`.
  final String resource;

  /// Converts a decoded notification into [Data].
  final Data Function(dynamic json) parse;

  /// Number of notifications to skip after subscribing.
  int get warmUp => 10;

  @override
  MovesenseDeviceManager get deviceManager => super.deviceManager as MovesenseDeviceManager;

  @override
  Stream<Measurement>? get stream {
    if (deviceManager.device == null || !deviceManager.isConnected) return null;
    // Subscribes anew on every listen, since CAMS re-listens to this stream after a reconnect.
    return Stream<String>.multi(
      (controller) => controller.addStream(deviceManager.device!.subscribe(resource)).whenComplete(controller.close),
    ).map((body) => Measurement.fromData(parse(jsonDecode(body)))).skip(warmUp);
  }
}

/// A probe collecting [MovesenseHR] data from the `/Meas/HR` resource.
///
/// Used for the [MovesenseSamplingPackage.HR] measure.
class MovesenseHRProbe extends _MovesenseStreamProbe {
  MovesenseHRProbe() : super('/Meas/HR', MovesenseHR.fromMovesenseData);
}

/// A probe collecting [MovesenseECG] data at 125 Hz.
///
/// Used for the [MovesenseSamplingPackage.ECG] measure.
class MovesenseECGProbe extends _MovesenseStreamProbe {
  MovesenseECGProbe() : super('/Meas/ECG/125', MovesenseECG.fromMovesenseData);
}

/// A probe collecting [MovesenseTemperature] data.
///
/// Used for the [MovesenseSamplingPackage.TEMPERATURE] measure. Only the
/// Movesense MD supports temperature, so [MovesenseSamplingPackage.create]
/// only creates this probe for that device.
class MovesenseTemperatureProbe extends _MovesenseStreamProbe {
  MovesenseTemperatureProbe() : super('/Meas/Temp', MovesenseTemperature.fromMovesenseData);
}

/// A probe collecting [MovesenseIMU] data at 13 Hz (the lowest rate).
///
/// Used for the [MovesenseSamplingPackage.IMU] measure.
class MovesenseIMUProbe extends _MovesenseStreamProbe {
  MovesenseIMUProbe() : super('/Meas/IMU9/13', MovesenseIMU.fromMovesenseData);
}

/// A probe collecting single tap [MovesenseStateChange] events.
///
/// Used for the [MovesenseSamplingPackage.STATE] measure.
///
/// Movesense firmware only allows one state subscription at a time, and only
/// the connectors and tap states have been confirmed on the MD and HR2.
/// See https://github.com/petri-lipponen-movesense/mdsflutter/issues/15
class MovesenseStateChangeProbe extends _MovesenseStreamProbe {
  MovesenseStateChangeProbe() : super('/System/States/4', MovesenseStateChange.fromMovesenseData);

  @override
  int get warmUp => 0; // every tap is an event, none are noise
}

/// A probe collecting [MovesenseDeviceInformation] from the connected
/// Movesense device.
///
/// Used for the [MovesenseSamplingPackage.DEVICE_INFO] measure. Returns null if
/// the device is not connected.
class MovesenseDeviceProbe extends MeasurementProbe {
  @override
  MovesenseDeviceManager get deviceManager => super.deviceManager as MovesenseDeviceManager;

  @override
  Future<Measurement?> getMeasurement() async {
    final device = deviceManager.device;
    if (device == null || device.serial == null) return null;

    final response = await device.request(ms.MdsRequestMethod.get, '/Info');
    return Measurement.fromData(MovesenseDeviceInformation.fromMovesenseData(jsonDecode(response.body)));
  }
}
