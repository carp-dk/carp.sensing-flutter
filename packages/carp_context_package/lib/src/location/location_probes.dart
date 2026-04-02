/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Collects streaming location information from the underlying OS's location API.
/// Is a [StreamProbe] that generates a [Location] data point every time
/// location is changed.
class LocationProbe extends StreamProbe {
  @override
  LocationServiceManager get deviceManager =>
      super.deviceManager as LocationServiceManager;

  @override
  Stream<Measurement> get stream => deviceManager.manager.onLocationChanged.map(
    (location) => Measurement.fromData(location),
  );
}

/// A probe that collects location data from the underlying OS's location API.
///
/// This probe can be configured to collect location data continuously (default)
/// or only once using a [LocationSamplingConfiguration].
/// If the configuration is set to collect location data only once, the probe
/// will automatically stop after collecting one location.
class ConfigurableLocationProbe extends Probe {
  LocationSamplingConfiguration? _configuration;
  StreamSubscription<Measurement>? _subscription;

  bool get oneTimeSampling => _configuration?.once ?? false;

  @override
  LocationServiceManager get deviceManager =>
      super.deviceManager as LocationServiceManager;

  @override
  bool onInitialize() {
    if (samplingConfiguration is LocationSamplingConfiguration) {
      _configuration = samplingConfiguration as LocationSamplingConfiguration;
    }
    return super.onInitialize();
  }

  @override
  Future<bool> onResume() async {
    if (await requestPermissions()) {
      // if this is a one-time sampling, just get the location once and return
      if (oneTimeSampling) {
        try {
          final location = await deviceManager.manager.getLocation();
          addMeasurement(Measurement.fromData(location));
        } catch (error) {
          warning('$runtimeType - Error getting location - $error');
          addError('$runtimeType - Error getting location: $error');
        }
        // automatically pause this probe after it is done collecting the measurement
        Future.delayed(const Duration(seconds: 5), () => pause());
      } else {
        var stream = deviceManager.manager.onLocationChanged.map(
          (location) => Measurement.fromData(location),
        );

        _subscription = stream.listen(
          (measurement) => addMeasurement(measurement),
          onError: (Object error) => addError(error),
        );
      }
    }
    return true;
  }

  @override
  Future<bool> onPause() async {
    await _subscription?.cancel();
    return true;
  }
}
