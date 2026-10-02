/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../carp_context_package.dart';

/// The sampling package for context measures: activity, location, geofence,
/// mobility, weather and air quality.
///
/// Register it once at app start, before a protocol using these measures is
/// deployed. It defines the measure type names ([ACTIVITY], [LOCATION], ...)
/// that you use in a `Measure` in your protocol.
///
/// Key points:
///  * Only [ACTIVITY] is collected by this package itself (on the phone).
///    On registration it also registers three sub-packages:
///    [LocationSamplingPackage], [WeatherSamplingPackage] and
///    [AirQualitySamplingPackage]. They handle the other measures.
///  * Location-based measures need a [LocationService] connected device in
///    the protocol. [WEATHER] needs a [WeatherService] and [AIR_QUALITY] an
///    [AirQualityService], each with an API key.
///  * Registers all its configurations, services and data types with the
///    [FromJsonFactory], so protocols and measurements can be deserialized.
///  * Adds OMH transformers for [LOCATION] ([OMHGeopositionDataPoint]) and
///    [ACTIVITY] ([OMHPhysicalActivityDataPoint]). Assumes an OMH schema is
///    already registered in the [DataTransformerSchemaRegistry].
///
/// ```dart
/// SamplingPackageRegistry().register(ContextSamplingPackage());
///
/// final locationService = LocationService();
/// protocol.addConnectedDevice(locationService, phone);
/// protocol.addTaskControl(ImmediateTrigger(),
///     BackgroundTask(measures: [Measure(type: ContextSamplingPackage.LOCATION)]),
///     locationService);
/// ```
class ContextSamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for continuous collection of activity events as recognized
  /// by the phone's activity recognition sub-system.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * No sampling configuration needed.
  static const String ACTIVITY = "${NameSpace.CARP}.activity";

  /// Measure type for collection of [Location] data.
  ///  * Event-based measure; continuous by default.
  ///  * Uses the [LocationService] connected device for data collection.
  ///  * Optional [LocationSamplingConfiguration] to sample only once, e.g.
  ///    together with a periodic trigger.
  static const String LOCATION = "${NameSpace.CARP}.location";

  /// Measure type for collection of [Geofence] events (enter/exit/dwell).
  ///  * Event-based measure.
  ///  * Uses the [LocationService] connected device for data collection.
  ///  * Use [GeofenceSamplingConfiguration] for configuration.
  static const String GEOFENCE = "${NameSpace.CARP}.geofence";

  /// Measure type for continuous collection of [Mobility] features like number
  /// of places visited, home stay percentage, and location entropy.
  ///
  ///  * Event-based measure.
  ///  * Uses the [LocationService] connected device for data collection.
  ///  * Use [MobilitySamplingConfiguration] for configuration.
  static const String MOBILITY = "${NameSpace.CARP}.mobility";

  /// Measure type for collection of [AirQuality] data from the
  /// [World's Air Quality Index (WAQI)](https://waqi.info) API.
  ///  * One-time measure.
  ///  * Uses the [AirQualityService] connected device for data collection.
  ///  * No sampling configuration needed.
  static const String AIR_QUALITY = "${NameSpace.CARP}.airquality";

  /// Measure type for collection of [Weather] data from the
  /// [Open Weather](https://openweathermap.org/) API.
  ///  * One-time measure.
  ///  * Uses the [WeatherService] connected device for data collection.
  ///  * No sampling configuration needed.
  static const String WEATHER = "${NameSpace.CARP}.weather";

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ACTIVITY,
            displayName: "Activity",
            timeType: DataTimeType.POINT,
            permissions: [Permission.activityRecognition],
          ),
        ),
      ]);

  @override
  Probe? create(String type) => type == ACTIVITY ? ActivityProbe() : null;

  @override
  void onRegister() {
    // first register all configurations and services used in a protocol
    FromJsonFactory().registerAll([
      LocationSamplingConfiguration(),
      MobilitySamplingConfiguration(),
      GeofenceSamplingConfiguration(
        name: '',
        center: GeoPosition(1.1, 1.1),
        dwell: const Duration(),
        radius: 1.0,
      ),
      LocationService(),
      WeatherService(apiKey: ''),
      AirQualityService(apiKey: ''),
      GeoPosition(1.1, 1.1),
    ]);

    // Backwards compatibility with CAMS 1.x (protocol API level < 2.0) where
    // these services used the carp_core device namespace.
    FromJsonFactory().register(
      LocationService(),
      type: '${DeviceConfiguration.DEVICE_NAMESPACE}.LocationService',
    );
    FromJsonFactory().register(
      WeatherService(apiKey: ''),
      type: '${DeviceConfiguration.DEVICE_NAMESPACE}.WeatherService',
    );
    FromJsonFactory().register(
      AirQualityService(apiKey: ''),
      type: '${DeviceConfiguration.DEVICE_NAMESPACE}.AirQualityService',
    );

    // register all data types
    FromJsonFactory().registerAll([
      Activity(type: ActivityType.UNKNOWN, confidence: 0),
      AirQuality(airQualityIndex: 0, latitude: 0, longitude: 0),
      Geofence(type: GeofenceType.DWELL, name: ''),
      Location(),
      Mobility(),
      Weather(),
    ]);

    // registering the transformers from CARP to OMH for geolocation and physical activity
    // we assume that there is an OMH schema registered already...
    DataTransformerSchemaRegistry().lookup(NameSpace.OMH)!
      ..add(LOCATION, OMHGeopositionDataPoint.transformer)
      ..add(ACTIVITY, OMHPhysicalActivityDataPoint.transformer);

    // register the sub-packages
    SamplingPackageRegistry()
      ..register(LocationSamplingPackage())
      ..register(AirQualitySamplingPackage())
      ..register(WeatherSamplingPackage());
  }
}

/// The sampling package for the location-based measures:
/// [ContextSamplingPackage.LOCATION], [ContextSamplingPackage.GEOFENCE] and
/// [ContextSamplingPackage.MOBILITY].
///
/// Registered automatically by [ContextSamplingPackage]. Its probes run on a
/// [LocationService] connected device, managed by a [LocationServiceManager].
class LocationSamplingPackage extends SmartphoneSamplingPackage {
  final _deviceManager = LocationServiceManager();

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ContextSamplingPackage.LOCATION,
            displayName: "Location",
            timeType: DataTimeType.POINT,
            permissions: [Permission.locationAlways],
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ContextSamplingPackage.GEOFENCE,
            displayName: "Geofence",
            timeType: DataTimeType.POINT,
            permissions: [Permission.locationAlways],
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ContextSamplingPackage.MOBILITY,
            displayName: "Mobility",
            timeType: DataTimeType.POINT,
            permissions: [Permission.locationAlways],
          ),
          MobilitySamplingConfiguration(
            placeRadius: 50,
            stopRadius: 5,
            usePriorContexts: true,
            stopDuration: const Duration(seconds: 30),
          ),
        ),
      ]);

  @override
  Probe? create(String type) => switch (type) {
    ContextSamplingPackage.LOCATION => ConfigurableLocationProbe(),
    ContextSamplingPackage.GEOFENCE => GeofenceProbe(),
    ContextSamplingPackage.MOBILITY => MobilityProbe(),
    _ => null,
  };

  @override
  String get deviceType => LocationService.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;
}

/// The sampling package for [ContextSamplingPackage.AIR_QUALITY].
///
/// Registered automatically by [ContextSamplingPackage]. Its [AirQualityProbe]
/// runs on an [AirQualityService] connected device.
class AirQualitySamplingPackage extends SmartphoneSamplingPackage {
  final DeviceManager _deviceManager = AirQualityServiceManager();

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ContextSamplingPackage.AIR_QUALITY,
            displayName: "Air Quality",
            timeType: DataTimeType.POINT,
            permissions: [Permission.locationWhenInUse],
          ),
        ),
      ]);

  @override
  Probe? create(String type) =>
      type == ContextSamplingPackage.AIR_QUALITY ? AirQualityProbe() : null;

  @override
  String get deviceType => AirQualityService.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;
}

/// The sampling package for [ContextSamplingPackage.WEATHER].
///
/// Registered automatically by [ContextSamplingPackage]. Its [WeatherProbe]
/// runs on a [WeatherService] connected device.
class WeatherSamplingPackage extends SmartphoneSamplingPackage {
  final DeviceManager _deviceManager = WeatherServiceManager();

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ContextSamplingPackage.WEATHER,
            displayName: "Weather",
            timeType: DataTimeType.POINT,
            permissions: [Permission.locationWhenInUse],
          ),
        ),
      ]);

  @override
  Probe? create(String type) =>
      type == ContextSamplingPackage.WEATHER ? WeatherProbe() : null;

  @override
  String get deviceType => WeatherService.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;
}

/// Base [ServiceManager] for the online services in this package
/// ([LocationService], [WeatherService] and [AirQualityService]).
///
/// Services always try to connect, need no extra configuration, and use
/// location permissions via [LocationManager]. Subclasses override
/// [canConnect] when a precondition (like an API key) applies.
abstract class ContextServiceManager<
  TDeviceConfiguration extends ServiceConfiguration<ServiceRegistration>
>
    extends ServiceManager<TDeviceConfiguration, ServiceRegistration> {
  ContextServiceManager(super.type, {super.configuration});

  @override
  void onConfigure() {} // most services do not need further configuration

  @override
  ServiceRegistration createRegistration() => ServiceRegistration(
    deviceDisplayName: displayName,
    isConnected: isConnected,
  );

  @override
  Future<bool> onHasPermissions() async =>
      await LocationManager().hasPermission();

  @override
  Future<void> onRequestPermissions() async =>
      await LocationManager().requestPermission();

  @override
  bool get canConnect => true; // most online services can always connect - override if not...

  @override
  bool get shouldConnect => true; // online services should always connect

  @override
  Future<bool> onDisconnect() async => true;
}
