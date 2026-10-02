/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

// This file contains device configurations used in CAMS protocols.

/// Base class for CAMS connected-device configurations.
///
/// Extends the carp_core [DeviceConfiguration] and puts the JSON type in the
/// CAMS device namespace [CAMS_DEVICE_NAMESPACE], which is different from the
/// carp_core device namespace. Sampling packages extend it (or [BLEDevice] /
/// [ServiceConfiguration]) to define the devices they support.
abstract class CamsDevice<TRegistration extends DeviceRegistration> extends DeviceConfiguration<TRegistration> {
  /// The JSON type namespace of all CAMS devices and device registrations.
  static const CAMS_DEVICE_NAMESPACE = 'dk.carp.cams.devices';

  CamsDevice({required super.roleName, super.isOptional});

  @override
  String get jsonType => '$CAMS_DEVICE_NAMESPACE.$runtimeType';
}

/// Base class for CAMS primary device configurations.
///
/// A primary device runs the study and collects data from connected devices.
/// [Smartphone] is the built-in one; extend this class to define other types
/// of primary devices supported by different CAMS apps (see issue #546).
abstract class PrimaryDevice<TRegistration extends DeviceRegistration>
    extends PrimaryDeviceConfiguration<TRegistration> {
  PrimaryDevice({required super.roleName});

  @override
  String get jsonType => '${CamsDevice.CAMS_DEVICE_NAMESPACE}.$runtimeType';
}

/// The smartphone that runs a CAMS study: the primary device of a protocol.
///
/// Add it with [SmartphoneStudyProtocol.addPrimaryDevice]. It supports the
/// measures of the built-in [MonitoringSamplingPackage], [DeviceSamplingPackage],
/// and [SensorSamplingPackage].
///
/// Key points:
///  * The default [roleName] is [DEFAULT_ROLE_NAME].
///  * [createRegistration] reads the phone details from [DeviceInfoService];
///    initialize it first to get correct values.
///
/// See also [SmartphoneRegistration], the registration it creates.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Smartphone extends PrimaryDevice<SmartphoneRegistration> {
  /// The type of a smartphone device.
  static const String DEVICE_TYPE = '${CamsDevice.CAMS_DEVICE_NAMESPACE}.Smartphone';

  /// The default role name for a smartphone.
  static const String DEFAULT_ROLE_NAME = 'Smartphone';

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes => DataTypeSamplingSchemeMap()
    ..addSamplingSchema(MonitoringSamplingPackage().samplingSchemes)
    ..addSamplingSchema(DeviceSamplingPackage().samplingSchemes)
    ..addSamplingSchema(SensorSamplingPackage().samplingSchemes);

  /// Creates a new [Smartphone] device.
  ///
  /// If [roleName] is not specified, [Smartphone.DEFAULT_ROLE_NAME] is used.
  Smartphone({super.roleName = Smartphone.DEFAULT_ROLE_NAME});

  /// Creates a [SmartphoneRegistration] with details of this phone.
  ///
  /// [deviceId] defaults to [DeviceInfoService.deviceID] and
  /// [deviceDisplayName] to a name built from platform, model, and SDK.
  /// Logs a warning if [DeviceInfoService] is not initialized.
  @override
  SmartphoneRegistration createRegistration({String? deviceId, String? deviceDisplayName}) {
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
  factory Smartphone.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Smartphone>(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneToJson(this);
}

/// A connected device that talks to the phone over Bluetooth Low Energy (BLE).
///
/// Holds the scan settings used to find the device. Its registration is a
/// [BLEDeviceRegistration]. Extend it for a specific BLE device, like
/// [BLEHeartRateDevice].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BLEDevice<TRegistration extends BLEDeviceRegistration> extends CamsDevice<TRegistration> {
  /// Advertised service UUIDs to filter for. Empty means no filter.
  ///
  /// UUIDs as strings, for example: "0000180D-0000-1000-8000-00805f9b34fb".
  @JsonKey(defaultValue: [])
  List<String> serviceUuids = [];

  /// Optional device name filter (substring match, case-insensitive).
  /// Applied AFTER discovery, not at the BLE controller level.
  String? namePrefix;

  /// Minimum RSSI (dBm) to accept, for example: -80.
  int? minRssi;

  /// Whether to receive repeated scan results for the same device.
  /// Useful for RSSI updates. Default is `true`.
  @JsonKey(defaultValue: true)
  bool allowDuplicates = true;

  /// Scan timeout. If `null`, the scan has no timeout.
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
    this.serviceUuids = serviceUuids ?? [];
  }

  @override
  Function get fromJsonFunction => _$BLEDeviceFromJson;
  factory BLEDevice.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<BLEDevice<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$BLEDeviceToJson(this);
}

/// A [BLEDevice] that implements the standard GATT Heart Rate service
/// (https://www.bluetooth.com/specifications/gatt/services/).
///
/// Supports the heart rate, interbeat interval, and skin contact measures of
/// [CarpDataTypes]. If no service UUIDs are specified, the standard Heart Rate
/// service UUID (`0x180D`) is used.
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
    this.serviceUuids = serviceUuids ?? ["0000180D-0000-1000-8000-00805F9B34FB"];
  }

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes => DataTypeSamplingSchemeMap.from([
    DataTypeSamplingScheme(CarpDataTypes().types[CarpDataTypes.HEART_RATE]!),
    DataTypeSamplingScheme(CarpDataTypes().types[CarpDataTypes.INTERBEAT_INTERVAL]!),
    DataTypeSamplingScheme(CarpDataTypes().types[CarpDataTypes.SENSOR_SKIN_CONTACT]!),
  ]);

  @override
  Function get fromJsonFunction => _$BLEHeartRateDeviceFromJson;
  factory BLEHeartRateDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BLEHeartRateDevice>(json);
  @override
  Map<String, dynamic> toJson() => _$BLEHeartRateDeviceToJson(this);
}

/// A connected device that is a software service rather than hardware.
///
/// Examples are an online service, like a weather service, which the app
/// reaches over the internet, or a local service on the phone, like a health
/// service. Its registration is a [ServiceRegistration].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ServiceConfiguration<TRegistration extends ServiceRegistration> extends CamsDevice<TRegistration> {
  ServiceConfiguration({required super.roleName, super.isOptional = true});
  @override
  Function get fromJsonFunction => _$ServiceConfigurationFromJson;
  factory ServiceConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ServiceConfiguration<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$ServiceConfigurationToJson(this);
}
