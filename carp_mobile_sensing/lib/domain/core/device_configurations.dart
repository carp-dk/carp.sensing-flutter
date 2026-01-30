/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Root class for all CAMS device configurations.
///
/// Note that we define a new CAMS-specific device namespace which is
/// different from the CARP Core device namespace.
abstract class CamsDevice<TRegistration extends DeviceRegistration>
    extends DeviceConfiguration<TRegistration> {
  static const CAMS_DEVICE_NAMESPACE = 'dk.carp.cams.devices';

  CamsDevice({required super.roleName, super.isOptional});

  @override
  String get jsonType => '$CAMS_DEVICE_NAMESPACE.$runtimeType';
}

/// Root class for all CAMS primary device configurations.
///
/// This can be used to defined different types of primary devices, which
/// are supported by different CAMS applications. See #546 for details.
abstract class PrimaryDevice<TRegistration extends DeviceRegistration>
    extends PrimaryDeviceConfiguration<TRegistration> {
  PrimaryDevice({required super.roleName});

  @override
  String get jsonType => '${CamsDevice.CAMS_DEVICE_NAMESPACE}.$runtimeType';
}

/// Configuration of a CAMS-specific smartphone that can be part of mobile
/// sensing study protocols.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Smartphone extends PrimaryDevice<SmartphoneRegistration> {
  /// The type of a smartphone device.
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.Smartphone';

  /// The default role name for a smartphone.
  static const String DEFAULT_ROLE_NAME = 'Smartphone';

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes =>
      DataTypeSamplingSchemeMap()
        ..addSamplingSchema(MonitoringSamplingPackage().samplingSchemes)
        ..addSamplingSchema(DeviceSamplingPackage().samplingSchemes)
        ..addSamplingSchema(SensorSamplingPackage().samplingSchemes);

  /// Create a new Smartphone device.
  /// If [roleName] is not specified, then the [Smartphone.DEFAULT_ROLE_NAME] is used.
  Smartphone({super.roleName = Smartphone.DEFAULT_ROLE_NAME});

  @override
  SmartphoneRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
  }) {
    if (!DeviceInfo().initialized) {
      warning(
        '$runtimeType - Initialize DeviceInfo before creating a Smartphone registration '
        'in order to get correct device specific information.',
      );
    }

    final id = deviceId ?? DeviceInfo().deviceID;
    final platform = DeviceInfo().platform;
    final hardware = DeviceInfo().hardware;
    final deviceManufacturer = DeviceInfo().deviceManufacturer;
    final deviceModel = DeviceInfo().deviceModel;
    final sdk = DeviceInfo().sdk;
    final displayName =
        deviceDisplayName ??
        ((Platform.isAndroid)
            ? '$platform (${deviceManufacturer?.toUpperCase()}) - $deviceModel [SDK: $sdk]'
            : '$platform - $hardware [SDK: $sdk]');

    return SmartphoneRegistration(
      deviceId: id,
      deviceDisplayName: displayName,
      platform: platform,
      hardware: hardware,
      deviceManufacturer: deviceManufacturer,
      deviceModel: deviceModel,
      operatingSystem: DeviceInfo().operatingSystemName,
      sdk: sdk,
      release: DeviceInfo().release,
    );
  }

  @override
  String get jsonType => DEVICE_TYPE;

  @override
  Function get fromJsonFunction => _$SmartphoneFromJson;
  factory Smartphone.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Smartphone>(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneToJson(this);
}

/// An online service which works as a "software device" in a protocol.
///
/// This is typically a connected device which the phone app connects to
/// via the internet, e.g., a weather service.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OnlineService<TRegistration extends DeviceRegistration>
    extends CamsDevice<TRegistration> {
  OnlineService({required super.roleName, super.isOptional = true});
  @override
  Function get fromJsonFunction => _$OnlineServiceFromJson;

  factory OnlineService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OnlineService<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$OnlineServiceToJson(this);
}
