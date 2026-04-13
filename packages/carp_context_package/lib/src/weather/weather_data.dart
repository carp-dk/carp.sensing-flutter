/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// Holds weather information collected through OpenWeather API.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Weather extends Data {
  String? country, areaName, weatherMain, weatherDescription;
  DateTime? date, sunrise, sunset;
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
