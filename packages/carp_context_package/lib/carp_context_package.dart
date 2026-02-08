/// A library for collecting context information on:
///  * location (both as one-time and continuous location data)
///  * geofence
///  * activity
///  * weather
///  * air quality
///  * mobility features
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
// import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart'
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
