/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// An online service which works as a "software device" in a protocol.
///
/// This is typically a connected device which the phone app connects to
/// via the internet, e.g., a weather service.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OnlineService<TRegistration extends DeviceRegistration>
    extends DeviceConfiguration<TRegistration> {
  OnlineService({required super.roleName, super.isOptional = true});
  @override
  Function get fromJsonFunction => _$OnlineServiceFromJson;

  factory OnlineService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OnlineService<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$OnlineServiceToJson(this);
}

/// Configuration of a smartphone that runs the Mobile Sensing app.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MobileSensingSmartphone extends Smartphone {
  /// The type of a smartphone device.
  static const String DEVICE_TYPE =
      '${DeviceConfiguration.DEVICE_NAMESPACE}.MobileSensingSmartphone';

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes =>
      DataTypeSamplingSchemeMap()
        ..addSamplingSchema(MonitoringSamplingPackage().samplingSchemes)
        ..addSamplingSchema(DeviceSamplingPackage().samplingSchemes)
        ..addSamplingSchema(SensorSamplingPackage().samplingSchemes);

  /// Create a new MobileSensingSmartphone device descriptor.
  /// If [roleName] is not specified, then the [Smartphone.DEFAULT_ROLE_NAME] is used.
  MobileSensingSmartphone({super.roleName = Smartphone.DEFAULT_ROLE_NAME});

  @override
  Function get fromJsonFunction => _$MobileSensingSmartphoneFromJson;
  factory MobileSensingSmartphone.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MobileSensingSmartphone>(json);
  @override
  Map<String, dynamic> toJson() => _$MobileSensingSmartphoneToJson(this);
}
