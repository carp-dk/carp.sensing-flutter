/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../carp_context_package.dart';

/// This is the base class for this context sampling package.
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry().register(ContextSamplingPackage());
/// ```
class ContextSamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for continuous collection of activity events as recognized
  /// by the phone's activity recognition sub-system.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] device for data collection.
  ///  * No sampling configuration needed.
  static const String ACTIVITY = "${NameSpace.CARP}.activity";

  /// Measure type for continuos collection of location data.
  ///  * Event-based measure.
  ///  * Uses the [LocationService] connected device for data collection.
  ///  * No sampling configuration needed.
  static const String LOCATION = "${NameSpace.CARP}.location";

  /// Measure type for collection of geofence events (enter/exit/dwell).
  ///  * Event-based measure.
  ///  * Uses the [LocationService] connected device for data collection.
  ///  * Use [GeofenceSamplingConfiguration] for configuration.
  static const String GEOFENCE = "${NameSpace.CARP}.geofence";

  /// Measure type for continuos collection of mobility features like number of
  /// places visited, home stay percentage, and location entropy.
  ///
  ///  * Event-based measure.
  ///  * Uses the [LocationService] connected device for data collection.
  ///  * Use [MobilitySamplingConfiguration] for configuration.
  static const String MOBILITY = "${NameSpace.CARP}.mobility";

  /// Measure type for collection of air quality data from the
  /// [World's Air Quality Index (WAQI)](https://waqi.info) API.
  ///  * One-time measure.
  ///  * Uses the [AirQualityService] connected device for data collection.
  ///  * No sampling configuration needed.
  static const String AIR_QUALITY = "${NameSpace.CARP}.airquality";

  /// Measure type for collection of weather data from the
  /// [Open Weather]( https://openweathermap.org/) API.
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

/// The location sampling package.
class LocationSamplingPackage extends SmartphoneSamplingPackage {
  final _deviceManager = LocationServiceManager();

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ContextSamplingPackage.LOCATION,
            displayName: "Location",
            timeType: DataTimeType.POINT,
            // permissions: [Permission.locationAlways],
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ContextSamplingPackage.GEOFENCE,
            displayName: "Geofence",
            timeType: DataTimeType.POINT,
            // permissions: [Permission.locationAlways],
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ContextSamplingPackage.MOBILITY,
            displayName: "Mobility",
            timeType: DataTimeType.POINT,
            // permissions: [Permission.locationAlways],
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

/// The air quality sampling package.
class AirQualitySamplingPackage extends SmartphoneSamplingPackage {
  final DeviceManager _deviceManager = AirQualityServiceManager();

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ContextSamplingPackage.AIR_QUALITY,
            displayName: "Air Quality",
            timeType: DataTimeType.POINT,
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

/// The weather sampling package.
class WeatherSamplingPackage extends SmartphoneSamplingPackage {
  final DeviceManager _deviceManager = WeatherServiceManager();

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ContextSamplingPackage.WEATHER,
            displayName: "Weather",
            timeType: DataTimeType.POINT,
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

  bool _hasPermissions = false;

  @override
  Future<bool> onHasPermissions() async {
    if (_hasPermissions) return true;
    _hasPermissions = await LocationManager().hasPermission();
    // if permissions are granted, we can consider the service as connected, otherwise disconnected.
    status = _hasPermissions
        ? DeviceStatus.connected
        : DeviceStatus.disconnected;
    return _hasPermissions;
  }

  @override
  Future<void> onRequestPermissions() async {
    await LocationManager().requestPermission();
    _hasPermissions = await LocationManager().hasPermission();
    // if permissions are granted, we can consider the service as connected, otherwise disconnected.
    status = _hasPermissions
        ? DeviceStatus.connected
        : DeviceStatus.disconnected;
  }

  @override
  bool get canConnect => true; // most online services can always connect - override if not...

  @override
  bool get shouldConnect => true; // online services should always connect

  @override
  Future<bool> onDisconnect() async => true;
}
