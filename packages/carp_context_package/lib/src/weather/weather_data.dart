/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Current weather at the phone's location, from the OpenWeather API.
///
/// Produced by [WeatherProbe] for the [ContextSamplingPackage.WEATHER]
/// measure. Field values follow the OpenWeather "current weather" response:
/// temperatures in degrees Celsius, wind speed in m/s, wind direction in
/// degrees, humidity and cloudiness in percent, pressure in hPa, and
/// rain/snow in mm.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Weather extends Data {
  /// Location names and a short ([weatherMain]) and long
  /// ([weatherDescription]) text, e.g. "Rain" and "light rain".
  String? country, areaName, weatherMain, weatherDescription;

  /// Time of the weather report, and today's sunrise and sunset.
  DateTime? date, sunrise, sunset;

  /// Weather values; see the class description for units.
  double? latitude,
      longitude,
      pressure,
      windSpeed,
      windDegree,
      humidity,
      cloudiness,
      rainLastHour,
      rainLast3Hours,
      snowLastHour,
      snowLast3Hours,
      temperature,
      tempMin,
      tempMax;

  Weather() : super();

  /// Creates a [Weather] from the `weather` plugin's `Weather` object.
  ///
  /// Throws if the plugin data has no temperature values.
  Weather.fromWeatherData(weather.Weather weather)
    : country = weather.country,
      areaName = weather.areaName,
      weatherMain = weather.weatherMain,
      weatherDescription = weather.weatherDescription,
      date = weather.date,
      sunrise = weather.sunrise,
      sunset = weather.sunset,
      latitude = weather.latitude,
      longitude = weather.longitude,
      pressure = weather.pressure,
      windSpeed = weather.windSpeed,
      windDegree = weather.windDegree,
      humidity = weather.humidity,
      cloudiness = weather.cloudiness,
      rainLastHour = weather.rainLastHour,
      rainLast3Hours = weather.rainLast3Hours,
      snowLastHour = weather.snowLastHour,
      snowLast3Hours = weather.snowLast3Hours,
      temperature = weather.temperature!.celsius,
      tempMin = weather.tempMin!.celsius,
      tempMax = weather.tempMax!.celsius,
      super();

  @override
  Function get fromJsonFunction => _$WeatherFromJson;
  factory Weather.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Weather>(json);
  @override
  Map<String, dynamic> toJson() => _$WeatherToJson(this);
}
