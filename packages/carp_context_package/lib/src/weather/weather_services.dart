/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// An [OnlineService] for the [Open Weather](https://openweathermap.org/) service.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WeatherService extends ServiceConfiguration<ServiceRegistration> {
  /// The type of a air quality service.
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.WeatherService';

  /// The default role name for a weather service.
  static const String DEFAULT_ROLE_NAME = 'Weather Service';

  /// API key for the Open Weather API.
  String apiKey;

  WeatherService({String? roleName, required this.apiKey})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$WeatherServiceFromJson;
  factory WeatherService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<WeatherService>(json);
  @override
  Map<String, dynamic> toJson() => _$WeatherServiceToJson(this);
}

/// A [DeviceManager] for the [WeatherService].
class WeatherServiceManager extends ContextServiceManager<WeatherService> {
  weather.WeatherFactory? _service;

  /// A handle to the [WeatherFactory] plugin.
  /// Returns null if the service is not configured.
  weather.WeatherFactory? get service => (_service != null)
      ? _service
      : (configuration?.apiKey != null)
      ? _service = weather.WeatherFactory(configuration!.apiKey)
      : null;

  @override
  String? get displayName => 'Weather Service (OW)';

  WeatherServiceManager([WeatherService? configuration])
    : super(WeatherService.DEVICE_TYPE, configuration: configuration);

  @override
  bool get canConnect => configuration?.apiKey != null;

  @override
  Future<DeviceStatus> onConnect() async =>
      (service != null) ? DeviceStatus.connected : DeviceStatus.disconnected;
}
