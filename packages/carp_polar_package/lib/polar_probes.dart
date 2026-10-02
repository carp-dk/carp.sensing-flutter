/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_polar_package.dart';

/// Base class for probes that stream data from a Polar device.
///
/// The [stream] is null (and the probe does not start) if the device is not
/// connected or does not support the needed [PolarDataType].
abstract class _PolarProbe extends StreamProbe {
  @override
  PolarDeviceManager get deviceManager =>
      super.deviceManager as PolarDeviceManager;

  /// Checks if the Polar device is connected and supports the specified data type.
  bool _checkDeviceAndDataAvailable(PolarDataType dataType) {
    if (!deviceManager.isConnected || deviceManager.polarIdentifier == null) {
      warning('$runtimeType - Polar device is not connected');
      return false;
    }
    if (!(deviceManager.dataTypes?.contains(dataType) ?? false)) {
      warning(
        "$runtimeType - Polar device does not support data type '$dataType'",
      );
      return false;
    }

    return true;
  }
}

/// Collects [PolarAccelerometer] data for the
/// [PolarSamplingPackage.ACCELEROMETER] measure.
class PolarAccelerometerProbe extends _PolarProbe {
  @override
  Stream<Measurement>? get stream =>
      _checkDeviceAndDataAvailable(PolarDataType.acc)
      ? deviceManager.polar
            .startAccStreaming(deviceManager.polarIdentifier!)
            .map(
              (event) =>
                  Measurement.fromData(PolarAccelerometer.fromPolarData(event)),
            )
            .asBroadcastStream()
      : null;
}

/// Collects [PolarGyroscope] data for the [PolarSamplingPackage.GYROSCOPE]
/// measure.
class PolarGyroscopeProbe extends _PolarProbe {
  @override
  Stream<Measurement>? get stream =>
      _checkDeviceAndDataAvailable(PolarDataType.gyro)
      ? deviceManager.polar
            .startGyroStreaming(deviceManager.polarIdentifier!)
            .map(
              (event) =>
                  Measurement.fromData(PolarGyroscope.fromPolarData(event)),
            )
            .asBroadcastStream()
      : null;
}

/// Collects [PolarMagnetometer] data for the
/// [PolarSamplingPackage.MAGNETOMETER] measure.
class PolarMagnetometerProbe extends _PolarProbe {
  @override
  Stream<Measurement>? get stream =>
      _checkDeviceAndDataAvailable(PolarDataType.magnetometer)
      ? deviceManager.polar
            .startMagnetometerStreaming(deviceManager.polarIdentifier!)
            .map(
              (event) =>
                  Measurement.fromData(PolarMagnetometer.fromPolarData(event)),
            )
            .asBroadcastStream()
      : null;
}

/// Collects [PolarPPG] data for the [PolarSamplingPackage.PPG] measure.
class PolarPPGProbe extends _PolarProbe {
  @override
  Stream<Measurement>? get stream =>
      _checkDeviceAndDataAvailable(PolarDataType.ppg)
      ? deviceManager.polar
            .startPpgStreaming(deviceManager.polarIdentifier!)
            .map((event) => Measurement.fromData(PolarPPG.fromPolarData(event)))
            .asBroadcastStream()
      : null;
}

/// Collects [PolarPPI] data for the [PolarSamplingPackage.PPI] measure.
class PolarPPIProbe extends _PolarProbe {
  @override
  Stream<Measurement>? get stream =>
      _checkDeviceAndDataAvailable(PolarDataType.ppi)
      ? deviceManager.polar
            .startPpiStreaming(deviceManager.polarIdentifier!)
            .map((event) => Measurement.fromData(PolarPPI.fromPolarData(event)))
            .asBroadcastStream()
      : null;
}

/// Collects [PolarECG] data for the [PolarSamplingPackage.ECG] measure.
class PolarECGProbe extends _PolarProbe {
  @override
  Stream<Measurement>? get stream =>
      _checkDeviceAndDataAvailable(PolarDataType.ecg)
      ? deviceManager.polar
            .startEcgStreaming(deviceManager.polarIdentifier!)
            .map((event) => Measurement.fromData(PolarECG.fromPolarData(event)))
            .asBroadcastStream()
      : null;
}

/// Collects [PolarHR] data for the [PolarSamplingPackage.HR] measure.
class PolarHRProbe extends _PolarProbe {
  @override
  Stream<Measurement>? get stream =>
      _checkDeviceAndDataAvailable(PolarDataType.hr)
      ? deviceManager.polar
            .startHrStreaming(deviceManager.polarIdentifier!)
            .map((event) => Measurement.fromData(PolarHR.fromPolarData(event)))
            .asBroadcastStream()
      : null;
}
