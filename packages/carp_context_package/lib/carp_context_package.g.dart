// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carp_context_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
  type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
  confidence: (json['confidence'] as num).toInt(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'confidence': instance.confidence,
  'type': _$ActivityTypeEnumMap[instance.type]!,
};

const _$ActivityTypeEnumMap = {
  ActivityType.IN_VEHICLE: 'IN_VEHICLE',
  ActivityType.ON_BICYCLE: 'ON_BICYCLE',
  ActivityType.RUNNING: 'RUNNING',
  ActivityType.STILL: 'STILL',
  ActivityType.WALKING: 'WALKING',
  ActivityType.UNKNOWN: 'UNKNOWN',
};

Location _$LocationFromJson(Map<String, dynamic> json) =>
    Location(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        altitude: (json['altitude'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        verticalAccuracy: (json['verticalAccuracy'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        headingAccuracy: (json['headingAccuracy'] as num?)?.toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        speedAccuracy: (json['speedAccuracy'] as num?)?.toDouble(),
        time: json['time'] == null
            ? null
            : DateTime.parse(json['time'] as String),
        isMock: json['isMock'] as bool?,
        elapsedRealtimeNanos: (json['elapsedRealtimeNanos'] as num?)
            ?.toDouble(),
        elapsedRealtimeUncertaintyNanos:
            (json['elapsedRealtimeUncertaintyNanos'] as num?)?.toDouble(),
        satellites: (json['satellites'] as num?)?.toInt(),
        provider: json['provider'] as String?,
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData?.toJson(),
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'altitude': ?instance.altitude,
  'accuracy': ?instance.accuracy,
  'verticalAccuracy': ?instance.verticalAccuracy,
  'speed': ?instance.speed,
  'speedAccuracy': ?instance.speedAccuracy,
  'heading': ?instance.heading,
  'headingAccuracy': ?instance.headingAccuracy,
  'time': ?instance.time?.toIso8601String(),
  'isMock': ?instance.isMock,
  'elapsedRealtimeNanos': ?instance.elapsedRealtimeNanos,
  'elapsedRealtimeUncertaintyNanos': ?instance.elapsedRealtimeUncertaintyNanos,
  'satellites': ?instance.satellites,
  'provider': ?instance.provider,
};

LocationSamplingConfiguration _$LocationSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) =>
    LocationSamplingConfiguration(once: json['once'] as bool? ?? false)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$LocationSamplingConfigurationToJson(
  LocationSamplingConfiguration instance,
) => <String, dynamic>{'__type': ?instance.$type, 'once': instance.once};

Weather _$WeatherFromJson(Map<String, dynamic> json) => Weather()
  ..$type = json['__type'] as String?
  ..country = json['country'] as String?
  ..areaName = json['areaName'] as String?
  ..weatherMain = json['weatherMain'] as String?
  ..weatherDescription = json['weatherDescription'] as String?
  ..date = json['date'] == null ? null : DateTime.parse(json['date'] as String)
  ..sunrise = json['sunrise'] == null
      ? null
      : DateTime.parse(json['sunrise'] as String)
  ..sunset = json['sunset'] == null
      ? null
      : DateTime.parse(json['sunset'] as String)
  ..latitude = (json['latitude'] as num?)?.toDouble()
  ..longitude = (json['longitude'] as num?)?.toDouble()
  ..pressure = (json['pressure'] as num?)?.toDouble()
  ..windSpeed = (json['windSpeed'] as num?)?.toDouble()
  ..windDegree = (json['windDegree'] as num?)?.toDouble()
  ..humidity = (json['humidity'] as num?)?.toDouble()
  ..cloudiness = (json['cloudiness'] as num?)?.toDouble()
  ..rainLastHour = (json['rainLastHour'] as num?)?.toDouble()
  ..rainLast3Hours = (json['rainLast3Hours'] as num?)?.toDouble()
  ..snowLastHour = (json['snowLastHour'] as num?)?.toDouble()
  ..snowLast3Hours = (json['snowLast3Hours'] as num?)?.toDouble()
  ..temperature = (json['temperature'] as num?)?.toDouble()
  ..tempMin = (json['tempMin'] as num?)?.toDouble()
  ..tempMax = (json['tempMax'] as num?)?.toDouble();

Map<String, dynamic> _$WeatherToJson(Weather instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'country': ?instance.country,
  'areaName': ?instance.areaName,
  'weatherMain': ?instance.weatherMain,
  'weatherDescription': ?instance.weatherDescription,
  'date': ?instance.date?.toIso8601String(),
  'sunrise': ?instance.sunrise?.toIso8601String(),
  'sunset': ?instance.sunset?.toIso8601String(),
  'latitude': ?instance.latitude,
  'longitude': ?instance.longitude,
  'pressure': ?instance.pressure,
  'windSpeed': ?instance.windSpeed,
  'windDegree': ?instance.windDegree,
  'humidity': ?instance.humidity,
  'cloudiness': ?instance.cloudiness,
  'rainLastHour': ?instance.rainLastHour,
  'rainLast3Hours': ?instance.rainLast3Hours,
  'snowLastHour': ?instance.snowLastHour,
  'snowLast3Hours': ?instance.snowLast3Hours,
  'temperature': ?instance.temperature,
  'tempMin': ?instance.tempMin,
  'tempMax': ?instance.tempMax,
};

WeatherService _$WeatherServiceFromJson(Map<String, dynamic> json) =>
    WeatherService(
        roleName: json['roleName'] as String?,
        apiKey: json['apiKey'] as String,
      )
      ..$type = json['__type'] as String?
      ..isOptional = json['isOptional'] as bool?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$WeatherServiceToJson(WeatherService instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
      'apiKey': instance.apiKey,
    };

OMHContextDataPoint _$OMHContextDataPointFromJson(Map<String, dynamic> json) =>
    OMHContextDataPoint(
      DataPoint.fromJson(json['datapoint'] as Map<String, dynamic>),
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$OMHContextDataPointToJson(
  OMHContextDataPoint instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'datapoint': instance.datapoint.toJson(),
};

GeoPosition _$GeoPositionFromJson(Map<String, dynamic> json) => GeoPosition(
  (json['latitude'] as num).toDouble(),
  (json['longitude'] as num).toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$GeoPositionToJson(GeoPosition instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

GeofenceSamplingConfiguration _$GeofenceSamplingConfigurationFromJson(
  Map<String, dynamic> json,
) =>
    GeofenceSamplingConfiguration(
        center: GeoPosition.fromJson(json['center'] as Map<String, dynamic>),
        radius: (json['radius'] as num).toDouble(),
        dwell: Duration(microseconds: (json['dwell'] as num).toInt()),
        name: json['name'] as String,
      )
      ..$type = json['__type'] as String?
      ..lastTime = json['lastTime'] == null
          ? null
          : DateTime.parse(json['lastTime'] as String);

Map<String, dynamic> _$GeofenceSamplingConfigurationToJson(
  GeofenceSamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'lastTime': ?instance.lastTime?.toIso8601String(),
  'center': instance.center.toJson(),
  'radius': instance.radius,
  'dwell': instance.dwell.inMicroseconds,
  'name': instance.name,
};

Geofence _$GeofenceFromJson(Map<String, dynamic> json) => Geofence(
  type: $enumDecode(_$GeofenceTypeEnumMap, json['type']),
  name: json['name'] as String,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$GeofenceToJson(Geofence instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'name': instance.name,
  'type': _$GeofenceTypeEnumMap[instance.type]!,
};

const _$GeofenceTypeEnumMap = {
  GeofenceType.ENTER: 'ENTER',
  GeofenceType.EXIT: 'EXIT',
  GeofenceType.DWELL: 'DWELL',
};

AirQuality _$AirQualityFromJson(Map<String, dynamic> json) => AirQuality(
  airQualityIndex: (json['airQualityIndex'] as num).toInt(),
  source: json['source'] as String?,
  place: json['place'] as String?,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  airQualityLevel: $enumDecodeNullable(
    _$AirQualityLevelEnumMap,
    json['airQualityLevel'],
  ),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AirQualityToJson(AirQuality instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'airQualityIndex': instance.airQualityIndex,
      'source': ?instance.source,
      'place': ?instance.place,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'airQualityLevel': ?_$AirQualityLevelEnumMap[instance.airQualityLevel],
    };

const _$AirQualityLevelEnumMap = {
  AirQualityLevel.UNKNOWN: 'UNKNOWN',
  AirQualityLevel.GOOD: 'GOOD',
  AirQualityLevel.MODERATE: 'MODERATE',
  AirQualityLevel.UNHEALTHY_FOR_SENSITIVE_GROUPS:
      'UNHEALTHY_FOR_SENSITIVE_GROUPS',
  AirQualityLevel.UNHEALTHY: 'UNHEALTHY',
  AirQualityLevel.VERY_UNHEALTHY: 'VERY_UNHEALTHY',
  AirQualityLevel.HAZARDOUS: 'HAZARDOUS',
};

AirQualityService _$AirQualityServiceFromJson(Map<String, dynamic> json) =>
    AirQualityService(
        roleName: json['roleName'] as String?,
        apiKey: json['apiKey'] as String,
      )
      ..$type = json['__type'] as String?
      ..isOptional = json['isOptional'] as bool?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$AirQualityServiceToJson(AirQualityService instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
      'apiKey': instance.apiKey,
    };

Mobility _$MobilityFromJson(Map<String, dynamic> json) => Mobility(
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  numberOfStops: (json['numberOfStops'] as num?)?.toInt(),
  numberOfMoves: (json['numberOfMoves'] as num?)?.toInt(),
  numberOfPlaces: (json['numberOfPlaces'] as num?)?.toInt(),
  locationVariance: (json['locationVariance'] as num?)?.toDouble(),
  entropy: (json['entropy'] as num?)?.toDouble(),
  normalizedEntropy: (json['normalizedEntropy'] as num?)?.toDouble(),
  homeStay: (json['homeStay'] as num?)?.toDouble(),
  distanceTraveled: (json['distanceTraveled'] as num?)?.toDouble(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$MobilityToJson(Mobility instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'timestamp': ?instance.timestamp?.toIso8601String(),
  'date': ?instance.date?.toIso8601String(),
  'numberOfStops': ?instance.numberOfStops,
  'numberOfMoves': ?instance.numberOfMoves,
  'numberOfPlaces': ?instance.numberOfPlaces,
  'locationVariance': ?instance.locationVariance,
  'entropy': ?instance.entropy,
  'normalizedEntropy': ?instance.normalizedEntropy,
  'homeStay': ?instance.homeStay,
  'distanceTraveled': ?instance.distanceTraveled,
};

MobilitySamplingConfiguration _$MobilitySamplingConfigurationFromJson(
  Map<String, dynamic> json,
) =>
    MobilitySamplingConfiguration(
        usePriorContexts: json['usePriorContexts'] as bool? ?? true,
        stopRadius: (json['stopRadius'] as num?)?.toDouble() ?? 25,
        placeRadius: (json['placeRadius'] as num?)?.toDouble() ?? 50,
        stopDuration: json['stopDuration'] == null
            ? null
            : Duration(microseconds: (json['stopDuration'] as num).toInt()),
      )
      ..$type = json['__type'] as String?
      ..lastTime = json['lastTime'] == null
          ? null
          : DateTime.parse(json['lastTime'] as String);

Map<String, dynamic> _$MobilitySamplingConfigurationToJson(
  MobilitySamplingConfiguration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'lastTime': ?instance.lastTime?.toIso8601String(),
  'usePriorContexts': instance.usePriorContexts,
  'stopRadius': instance.stopRadius,
  'placeRadius': instance.placeRadius,
  'stopDuration': instance.stopDuration.inMicroseconds,
};

LocationService _$LocationServiceFromJson(Map<String, dynamic> json) =>
    LocationService(
        roleName: json['roleName'] as String?,
        accuracy:
            $enumDecodeNullable(
              _$GeolocationAccuracyEnumMap,
              json['accuracy'],
            ) ??
            GeolocationAccuracy.balanced,
        distance: (json['distance'] as num?)?.toDouble() ?? 10,
        interval: json['interval'] == null
            ? const Duration(minutes: 1)
            : Duration(microseconds: (json['interval'] as num).toInt()),
        notificationTitle: json['notificationTitle'] as String?,
        notificationMessage: json['notificationMessage'] as String?,
        notificationDescription: json['notificationDescription'] as String?,
        notificationIconName: json['notificationIconName'] as String?,
        notificationOnTapBringToFront:
            json['notificationOnTapBringToFront'] as bool? ?? false,
      )
      ..$type = json['__type'] as String?
      ..isOptional = json['isOptional'] as bool?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$LocationServiceToJson(LocationService instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration
          ?.map((k, e) => MapEntry(k, e.toJson())),
      'accuracy': _$GeolocationAccuracyEnumMap[instance.accuracy]!,
      'distance': instance.distance,
      'interval': instance.interval.inMicroseconds,
      'notificationTitle': ?instance.notificationTitle,
      'notificationMessage': ?instance.notificationMessage,
      'notificationDescription': ?instance.notificationDescription,
      'notificationIconName': ?instance.notificationIconName,
      'notificationOnTapBringToFront': instance.notificationOnTapBringToFront,
    };

const _$GeolocationAccuracyEnumMap = {
  GeolocationAccuracy.powerSave: 'powerSave',
  GeolocationAccuracy.low: 'low',
  GeolocationAccuracy.balanced: 'balanced',
  GeolocationAccuracy.high: 'high',
  GeolocationAccuracy.navigation: 'navigation',
  GeolocationAccuracy.reduced: 'reduced',
};
