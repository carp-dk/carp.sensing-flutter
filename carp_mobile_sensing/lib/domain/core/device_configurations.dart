/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

// This file contains device configurations used in CAMS protocols.

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

/// Configuration of a smartphone that can be part of CAMS mobile
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

  /// Create a new [Smartphone] device.
  /// If [roleName] is not specified, then the [Smartphone.DEFAULT_ROLE_NAME] is used.
  Smartphone({super.roleName = Smartphone.DEFAULT_ROLE_NAME});

  @override
  SmartphoneRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
  }) {
    if (!DeviceInfoService().initialized) {
      warning(
        '$runtimeType - Initialize DeviceInfo before creating a Smartphone registration '
        'in order to get correct device specific information.',
      );
    }

    final id = deviceId ?? DeviceInfoService().deviceID;
    final platform = DeviceInfoService().platform;
    final hardware = DeviceInfoService().hardware;
    final deviceManufacturer = DeviceInfoService().deviceManufacturer;
    final deviceModel = DeviceInfoService().deviceModel;
    final sdk = DeviceInfoService().sdk;
    final displayName =
        deviceDisplayName ??
        ((Platform.isAndroid)
            ? '$platform (${deviceManufacturer?.toUpperCase()}) - $deviceModel [SDK: $sdk]'
            : '$platform - $hardware [SDK: $sdk]');

    return SmartphoneRegistration(
      deviceId: id,
      deviceDisplayName: displayName,
      platform: platform,
      hardwareName: hardware,
      deviceManufacturer: deviceManufacturer,
      deviceModel: deviceModel,
      operatingSystem: DeviceInfoService().operatingSystemName,
      sdk: sdk,
      release: DeviceInfoService().release,
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

/// A Bluetooth Low Energy (BLE) device configuration.
///
/// Holds high-level scan configuration for BLE devices.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BLEDevice<TRegistration extends BLEDeviceRegistration>
    extends CamsDevice<TRegistration> {
  /// Advertised service UUIDs to filter for.
  /// String representation of UUIDs, for example: "0000180D-0000-1000-8000-00805f9b34fb"
  List<String> serviceUuids = [];

  /// Optional device name filter (substring match, case-insensitive).
  /// Applied AFTER discovery, not at the BLE controller level.
  String? namePrefix;

  /// Minimum RSSI (dBm) to accept, for example: -80.
  int? minRssi;

  /// Whether to receive repeated scan results for the same device.
  /// Useful for RSSI updates.
  bool allowDuplicates = true;

  /// Scan timeout.
  Duration? timeout;

  BLEDevice({
    required super.roleName,
    super.isOptional = true,
    List<String>? serviceUuids,
    this.namePrefix,
    this.minRssi,
    this.allowDuplicates = true,
    this.timeout,
  }) {
    serviceUuids = serviceUuids ?? [];
  }

  @override
  Function get fromJsonFunction => _$BLEDeviceFromJson;
  factory BLEDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BLEDevice<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$BLEDeviceToJson(this);
}

/// A Bluetooth Low Energy (BLE) device which implements a GATT Heart
/// Rate service (https://www.bluetooth.com/specifications/gatt/services/).
///
/// If no service UUIDs are specified, then the standard Heart Rate service UUID
/// is used.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BLEHeartRateDevice extends BLEDevice<BLEDeviceRegistration> {
  BLEHeartRateDevice({
    required super.roleName,
    super.isOptional = true,
    List<String>? serviceUuids,
    super.namePrefix,
    super.minRssi,
    super.allowDuplicates = true,
    super.timeout,
  }) {
    this.serviceUuids =
        serviceUuids ?? ["0000180D-0000-1000-8000-00805F9B34FB"];
  }

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.HEART_RATE]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.INTERBEAT_INTERVAL]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.SENSOR_SKIN_CONTACT]!,
        ),
      ]);

  @override
  Function get fromJsonFunction => _$BLEHeartRateDeviceFromJson;
  factory BLEHeartRateDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BLEHeartRateDevice>(json);
  @override
  Map<String, dynamic> toJson() => _$BLEHeartRateDeviceToJson(this);
}

/// An 'connected device' which is a service.
///
/// Examples include online services, like a weather service, which the phone
/// app connects to via the internet, or a local service running on the phone,
/// where data can be collected from the service directly, like a health service.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ServiceConfiguration<TRegistration extends ServiceRegistration>
    extends CamsDevice<TRegistration> {
  ServiceConfiguration({required super.roleName, super.isOptional = true});
  @override
  Function get fromJsonFunction => _$ServiceConfigurationFromJson;
  factory ServiceConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ServiceConfiguration<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$ServiceConfigurationToJson(this);
}
