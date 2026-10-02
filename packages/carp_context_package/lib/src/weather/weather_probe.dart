part of '../../carp_context_package.dart';

/// Collects local weather for [ContextSamplingPackage.WEATHER].
///
/// A [MeasurementProbe] that gets the phone's location from [LocationManager]
/// and asks the OpenWeather API (through [WeatherServiceManager]) for a
/// [Weather] measurement. Returns an `Error` measurement if no
/// [WeatherService] is in the protocol or the lookup fails.
class WeatherProbe extends MeasurementProbe {
  @override
  WeatherServiceManager get deviceManager =>
      super.deviceManager as WeatherServiceManager;

  @override
  bool onInitialize() {
    LocationManager().enable().then((_) => super.onInitialize());
    return true;
  }

  /// Returns the [Weather] for this location wrapped as a [Measurement].
  @override
  Future<Measurement> getMeasurement() async {
    if (deviceManager.service != null) {
      try {
        final loc = await LocationManager().getLocation();
        final w = await deviceManager.service!.currentWeatherByLocation(
          loc.latitude,
          loc.longitude,
        );

        return Measurement.fromData(Weather.fromWeatherData(w));
      } catch (error) {
        warning('$runtimeType - Error getting weather - $error');
        return Measurement.fromData(
          Error(message: '$runtimeType Exception: $error'),
        );
      }
    }
    warning(
      '$runtimeType - no service available. Check if the WeatherService has been added to the study protocol?',
    );
    return Measurement.fromData(
      Error(message: '$runtimeType - no service available.'),
    );
  }
}
