// ignore_for_file: depend_on_referenced_packages

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_context_package/carp_context_package.dart';

/// This is a very simple example of how this sampling package is used as part
/// of defining a study protocol in CARP Mobile Sensing (CAMS).
///
/// NOTE, however, that the code below will not run on it own. A study protocol
/// needs to be deployed and executed in the CAMS framework.
///
/// See the documentation on how to use CAMS:
/// https://docs.carp.dk/carp-mobile-sensing/
void main() async {
  // register this sampling package before using its measures
  SamplingPackageRegistry().register(ContextSamplingPackage());

  // Create a study protocol
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Context Sensing Example',
  );

  // Define the smartphone as the primary device.
  Smartphone phone = Smartphone();
  protocol.addPrimaryDevice(phone);

  // Add a background task that collects activity data from the phone
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(measures: [Measure(type: ContextSamplingPackage.ACTIVITY)]),
    phone,
  );

  // Define the online location service and add it as a 'connected device'
  final locationService = LocationService(
    accuracy: GeolocationAccuracy.high,
    distance: 10,
    interval: const Duration(minutes: 1),
  );
  protocol.addConnectedDevice(locationService, phone);

  // Add a background task that continuously collects location and mobility
  // patterns. Delays sampling by 5 minutes.
  protocol.addTaskControl(
    DelayedTrigger(delay: Duration(minutes: 5)),
    BackgroundTask(
      measures: [
        Measure(type: ContextSamplingPackage.LOCATION),
        Measure(type: ContextSamplingPackage.MOBILITY),
      ],
    ),
    locationService,
  );

  // Add a background task that collects location on a regular basis
  // using a periodic trigger and a location sampling configuration that only
  // collects location data once.
  // See issue https://github.com/cph-cachet/carp.sensing-flutter/issues/471
  protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 5)),
    BackgroundTask(
      measures: [
        Measure(type: ContextSamplingPackage.LOCATION)
          ..overrideSamplingConfiguration = LocationSamplingConfiguration(
            once: true,
          ),
      ],
    ),
    locationService,
  );

  // Add a background task that collects geofence events using DTU as the
  // center for the geofence.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask()..addMeasure(
      Measure(type: ContextSamplingPackage.GEOFENCE)
        ..overrideSamplingConfiguration = GeofenceSamplingConfiguration(
          name: 'DTU',
          center: GeoPosition(55.786025, 12.524159),
          dwell: const Duration(minutes: 15),
          radius: 10.0,
        ),
    ),
    locationService,
  );

  // Define the online weather service and add it as a 'device'
  final weatherService = WeatherService(apiKey: 'OW_API_key_goes_here');
  protocol.addConnectedDevice(weatherService, phone);

  // Add a background task that collects weather every 30 minutes.
  protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 30)),
    BackgroundTask(measures: [Measure(type: ContextSamplingPackage.WEATHER)]),
    weatherService,
  );

  // Define the online air quality service and add it as a 'device'
  final airQualityService = AirQualityService(apiKey: 'WAQI_API_key_goes_here');
  protocol.addConnectedDevice(airQualityService, phone);

  // Add a background task that air quality every 30 minutes.
  protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 30)),
    BackgroundTask(
      measures: [Measure(type: ContextSamplingPackage.AIR_QUALITY)],
    ),
    airQualityService,
  );
}
