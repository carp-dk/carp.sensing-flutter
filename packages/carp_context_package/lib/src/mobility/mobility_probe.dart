part of '../../carp_context_package.dart';

/// Collects [Mobility] features for the [ContextSamplingPackage.MOBILITY]
/// measure.
///
/// Feeds the location stream from [LocationManager] into the
/// `mobility_features` plugin while resumed, and emits each computed
/// mobility context. Needs a [MobilitySamplingConfiguration].
class MobilityProbe extends StreamProbe {
  @override
  bool onInitialize() {
    MobilitySamplingConfiguration conf = samplingConfiguration as MobilitySamplingConfiguration;

    MobilityFeatures().stopRadius = conf.stopRadius;
    MobilityFeatures().placeRadius = conf.placeRadius;
    MobilityFeatures().stopDuration = conf.stopDuration;

    return true;
  }

  @override
  Future<bool> onResume() async {
    // get the location data stream from the LocationManager
    Stream<LocationSample> locationStream = LocationManager().onLocationChanged.map(
      (loc) => LocationSample(GeoLocation(loc.latitude, loc.longitude), DateTime.now()),
    );

    // Feed the location data stream to the MobilityFeatures singleton
    // which in turn produce [MobilityContext] readings.
    await MobilityFeatures().startListening(locationStream);

    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    await MobilityFeatures().stopListening();
    return await super.onPause();
  }

  /// The stream of mobility features as they are generated.
  @override
  Stream<Measurement> get stream =>
      MobilityFeatures().contextStream.map((context) => Measurement.fromData(Mobility.fromMobilityContext(context)));
}
