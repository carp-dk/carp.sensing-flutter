/*
 * Copyright 2019-2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Air quality at the phone's location, from the
/// [World's Air Quality Index (WAQI)](https://waqi.info) API.
///
/// Produced by [AirQualityProbe] for the [ContextSamplingPackage.AIR_QUALITY]
/// measure. Values come from the WAQI station nearest to the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AirQuality extends Data {
  /// The air quality index (AQI) reported by WAQI. Higher is worse.
  int airQualityIndex;

  /// The data source ([source]) and the name of the measuring station
  /// ([place]), as reported by WAQI.
  String? source, place;

  /// Position of the measuring station, in degrees.
  double latitude, longitude;

  /// The [airQualityIndex] as a health category.
  AirQualityLevel? airQualityLevel;

  AirQuality({
    required this.airQualityIndex,
    this.source,
    this.place,
    required this.latitude,
    required this.longitude,
    this.airQualityLevel,
  }) : super();

  /// Creates an [AirQuality] from the WAQI plugin's `AirQualityData`.
  AirQuality.fromAirQualityData(waqi.AirQualityData airQualityData)
    : latitude = airQualityData.latitude,
      longitude = airQualityData.longitude,
      airQualityIndex = airQualityData.airQualityIndex,
      source = airQualityData.source,
      place = airQualityData.place,
      airQualityLevel = AirQualityLevel.values[airQualityData.airQualityLevel.index],
      super();

  @override
  Function get fromJsonFunction => _$AirQualityFromJson;
  factory AirQuality.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<AirQuality>(json);
  @override
  Map<String, dynamic> toJson() => _$AirQualityToJson(this);

  @override
  String get jsonType => ContextSamplingPackage.AIR_QUALITY;
}

/// Health category of an air quality index, following the WAQI scale.
enum AirQualityLevel { UNKNOWN, GOOD, MODERATE, UNHEALTHY_FOR_SENSITIVE_GROUPS, UNHEALTHY, VERY_UNHEALTHY, HAZARDOUS }
