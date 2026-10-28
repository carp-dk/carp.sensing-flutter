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
/// This probe can be configured to collect location data continuously (default),
/// only once, or at a fixed period using a [LocationSamplingConfiguration].
/// If the configuration is set to collect location data only once, the probe
/// will automatically stop after collecting one location.
class ConfigurableLocationProbe extends Probe {
  LocationSamplingConfiguration? _configuration;
  StreamSubscription<Object>? _subscription;
  Timer? _timer;

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
      } else if (_configuration?.period != null) {
        // Time based: keep the OS stream running so the last fix stays fresh, but emit
        // that fix every period, also when the OS reported nothing new (a duplicate).
        _subscription = deviceManager.manager.onLocationChanged.listen(
          null,
          onError: (Object error) => addError(error),
        );
        _timer = Timer.periodic(_configuration!.period!, (_) {
          final location = deviceManager.manager.lastKnownLocation;
          if (location != null) addMeasurement(Measurement.fromData(location));
        });
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
    _timer?.cancel();
    await _subscription?.cancel();
    return true;
  }
}
