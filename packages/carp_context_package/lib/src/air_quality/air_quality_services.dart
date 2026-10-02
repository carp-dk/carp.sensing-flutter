/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../carp_context_package.dart';

/// A connected device for the WAQI air quality web service.
///
/// Add it to a protocol with `addConnectedDevice` to enable the
/// [ContextSamplingPackage.AIR_QUALITY] measure. Managed at runtime by
/// [AirQualityServiceManager].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AirQualityService extends ServiceConfiguration<ServiceRegistration> {
  /// The type of an air quality service.
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.AirQualityService';

  /// The default role name for an air quality service.
  static const String DEFAULT_ROLE_NAME = 'Air Quality Service';

  /// API key for the WAQI API. Get one at https://aqicn.org/data-platform/token/.
  String apiKey;

  AirQualityService({String? roleName, required this.apiKey})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$AirQualityServiceFromJson;
  factory AirQualityService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AirQualityService>(json);
  @override
  Map<String, dynamic> toJson() => _$AirQualityServiceToJson(this);
}

/// A [DeviceManager] for the [AirQualityService].
///
/// Connects when the configuration has an API key.
class AirQualityServiceManager
    extends ContextServiceManager<AirQualityService> {
  waqi.AirQuality? _service;

  /// A handle to the WAQI plugin, created on first use.
  ///
  /// Null if the service has no configuration (and hence no API key).
  waqi.AirQuality? get service => (_service != null)
      ? _service
      : (configuration?.apiKey != null)
      ? _service = waqi.AirQuality(configuration!.apiKey)
      : null;

  @override
  String? get displayName => 'Air Quality Service (WAQI)';

  AirQualityServiceManager([AirQualityService? configuration])
    : super(AirQualityService.DEVICE_TYPE, configuration: configuration);

  @override
  bool get canConnect => configuration?.apiKey != null;

  @override
  Future<DeviceStatus> onConnect() async =>
      (service != null) ? DeviceStatus.connected : DeviceStatus.disconnected;
}
