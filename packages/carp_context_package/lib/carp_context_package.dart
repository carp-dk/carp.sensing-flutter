/// A sampling package for CARP Mobile Sensing that collects context data:
/// activity, location, geofences, mobility features, weather and air quality.
///
/// Register [ContextSamplingPackage] with the `SamplingPackageRegistry` before
/// you deploy a protocol that uses these measures. Works on Android and iOS.
///
/// Measure types provided (see [ContextSamplingPackage] for details):
///  * `dk.cachet.carp.activity`: activity recognition events. Runs on the
///    [Smartphone]; no connected device needed.
///  * `dk.cachet.carp.location`: one-time or continuous [Location] data.
///    Needs a [LocationService] connected device.
///  * `dk.cachet.carp.geofence`: [Geofence] enter/exit/dwell events. Needs a
///    [LocationService].
///  * `dk.cachet.carp.mobility`: daily [Mobility] features. Needs a
///    [LocationService].
///  * `dk.cachet.carp.weather`: current [Weather] from OpenWeather. Needs a
///    [WeatherService] with an API key.
///  * `dk.cachet.carp.airquality`: current [AirQuality] from WAQI. Needs an
///    [AirQualityService] with an API key.
///
/// Location permissions are best requested by the app itself, before sensing
/// starts. See the package README for the platform setup.
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:weather/weather.dart' as weather;
import 'package:openmhealth_schemas/openmhealth_schemas.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:air_quality/air_quality.dart' as waqi;
import 'package:mobility_features/mobility_features.dart';
import 'package:location/location.dart' as location;
// import 'package:geolocator/geolocator.dart' as geolocator;
// import 'package:geolocator_apple/geolocator_apple.dart';
// import 'package:geolocator_android/geolocator_android.dart';
// import 'package:carp_background_location/carp_background_location.dart' as cbl;
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart'
    as ar;

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone, BLEHeartRateDevice;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'src/location_manager.dart';
part 'src/activity/activity_data.dart';
part 'src/activity/activity_probe.dart';
part 'src/location/location_data.dart';
part 'src/location/location_probes.dart';
part 'src/location/location_configuration.dart';
part 'src/weather/weather_data.dart';
part 'src/weather/weather_probe.dart';
part 'src/weather/weather_services.dart';
part 'src/context_transformers.dart';
part 'src/context_package.dart';
part 'src/geofence/geofence_configuration.dart';
part 'src/geofence/geofence_data.dart';
part 'src/geofence/geofence_probe.dart';
part 'src/air_quality/air_quality_data.dart';
part 'src/air_quality/air_quality_probe.dart';
part 'src/air_quality/air_quality_services.dart';
part 'package:carp_context_package/src/mobility/mobility_data.dart';
part 'package:carp_context_package/src/mobility/mobility_probe.dart';
part 'package:carp_context_package/src/mobility/mobility_configuration.dart';
part 'src/location/location_services.dart';
part 'carp_context_package.g.dart';
