/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Collects streaming location information from the OS's location API.
///
/// A [StreamProbe] that emits a [Location] every time the location changes.
/// Not used by [LocationSamplingPackage], which uses
/// [ConfigurableLocationProbe] instead.
class LocationProbe extends StreamProbe {
  @override
  LocationServiceManager get deviceManager => super.deviceManager as LocationServiceManager;

  @override
  Stream<Measurement> get stream =>
      deviceManager.manager.onLocationChanged.map((location) => Measurement.fromData(location));
}

/// Collects [Location] data for the [ContextSamplingPackage.LOCATION] measure.
///
/// Collects location continuously (default), only once, or every `period`
/// (repeating the last fix if the OS reported none), set by a
/// [LocationSamplingConfiguration]. In one-time mode it pauses itself 5
/// seconds after collecting one location; the next resume (e.g. from a
/// periodic trigger) collects a new one. Uses the [LocationManager] of its
/// [LocationServiceManager]. Asks for location permission on resume and
/// collects nothing if it is not granted.
class ConfigurableLocationProbe extends Probe {
  LocationSamplingConfiguration? _configuration;
  StreamSubscription<Object>? _subscription;
  Timer? _timer;

  /// True if the [LocationSamplingConfiguration] asks for one location only.
  bool get oneTimeSampling => _configuration?.once ?? false;

  @override
  LocationServiceManager get deviceManager => super.deviceManager as LocationServiceManager;

  @override
  bool onInitialize() {
    if (samplingConfiguration is LocationSamplingConfiguration) {
      _configuration = samplingConfiguration as LocationSamplingConfiguration;
    }
    return super.onInitialize();
  }

  @override
  Future<bool> onResume() async {
    if (!await requestPermissions()) {
      warning('$runtimeType - No location permission, not sampling.');
    } else {
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
        final period = _configuration!.period!;
        info('$runtimeType - Time based sampling, one location every ${period.inSeconds} s.');
        _subscription = deviceManager.manager.onLocationChanged.listen(
          (location) => debug('$runtimeType - OS fix: ${location.time} (${location.latitude}, ${location.longitude}).'),
          onError: (Object error) => addError(error),
        );
        _timer = Timer.periodic(period, (_) {
          final location = deviceManager.manager.lastKnownLocation;
          if (location == null) {
            warning('$runtimeType - No OS fix yet, nothing to emit.');
            return;
          }
          debug('$runtimeType - Emitting fix from ${location.time}.');
          addMeasurement(Measurement.fromData(location));
        });
      } else {
        var stream = deviceManager.manager.onLocationChanged.map((location) => Measurement.fromData(location));

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
