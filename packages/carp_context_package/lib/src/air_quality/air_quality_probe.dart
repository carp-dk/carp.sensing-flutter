part of '../../carp_context_package.dart';

/// Collects local air quality for [ContextSamplingPackage.AIR_QUALITY].
///
/// A [MeasurementProbe] that gets the phone's location from [LocationManager]
/// and asks the WAQI API (through [AirQualityServiceManager]) for an
/// [AirQuality] measurement. Returns an `Error` measurement if no
/// [AirQualityService] is in the protocol or the lookup fails.
class AirQualityProbe extends MeasurementProbe {
  @override
  AirQualityServiceManager get deviceManager =>
      super.deviceManager as AirQualityServiceManager;

  @override
  bool onInitialize() {
    LocationManager().enable().then((_) => super.onInitialize());
    return true;
  }

  /// Returns the [AirQuality] based on the location of the phone, wrapped as
  /// a [Measurement].
  // ignore: annotate_overrides
  Future<Measurement> getMeasurement() async {
    if (deviceManager.service != null) {
      try {
        final loc = await LocationManager().getLocation();
        waqi.AirQualityData airQuality = await deviceManager.service!
            .feedFromGeoLocation(loc.latitude, loc.longitude);

        return Measurement.fromData(AirQuality.fromAirQualityData(airQuality));
      } catch (err) {
        warning('$runtimeType - Error getting air quality - $err');
        return Measurement.fromData(
          Error(message: '$runtimeType Exception: $err'),
        );
      }
    }
    warning(
      '$runtimeType - no service available. Has the AirQualityService been added to the study protocol?',
    );

    return Measurement.fromData(
      Error(message: ('$runtimeType - no service available.')),
    );
  }
}
