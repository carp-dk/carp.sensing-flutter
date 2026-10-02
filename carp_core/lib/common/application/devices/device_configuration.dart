/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// Describes a device that takes part in a study, as part of a protocol.
///
/// A device can be any electronic device, such as a sensor, video camera,
/// desktop computer, or smartphone, that collects data which is incorporated
/// into the platform after being processed by a primary device (potentially
/// itself). Optionally, a device can present output and receive user input.
///
/// Key points:
///  * [roleName] identifies the device within a protocol and must be unique.
///  * Devices are either primary devices ([PrimaryDeviceConfiguration], e.g. a
///    [Smartphone]) or connected devices (e.g., a [BLEHeartRateDevice]) added
///    with [StudyProtocol.addConnectedDevice].
///  * [dataTypeSamplingSchemes] lists the data types the device can collect.
///  * At deployment, each device gets a [DeviceRegistration] of type
///    [TRegistration] that identifies the physical device.
///
/// CARP Mobile Sensing and its sampling packages add more device types,
/// each handled at runtime by a `DeviceManager`.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DeviceConfiguration<TRegistration extends DeviceRegistration>
    extends Serializable {
  /// The JSON namespace of the CARP Core device types.
  static const DEVICE_NAMESPACE = 'dk.cachet.carp.common.application.devices';

  /// The device type identifier, i.e. its [jsonType].
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get type => jsonType;

  /// A name which describes how the device participates within the study protocol;
  /// its 'role'. For example, 'Parent's phone' or 'Child phone'.
  /// Must be unique within a protocol.
  String roleName;

  /// Determines whether device registration for this device is optional prior to
  /// starting a study, i.e., whether the study can run without this device or not.
  bool? isOptional;

  /// Sampling configurations which override the default configurations for
  /// data types available on this device, mapped by data type.
  Map<String, SamplingConfiguration>? defaultSamplingConfiguration = {};

  /// Sampling schemes for all the sensors available on this device.
  ///
  /// Implementations of [DeviceConfiguration] should return a map of all
  /// supported sampling schemes here. Null in this base class.
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes => null;

  /// The set of data types which can be collected on this device.
  Set<String>? get supportedDataTypes => dataTypeSamplingSchemes?.types;

  DeviceConfiguration({required this.roleName, this.isOptional}) : super();

  /// Create a [DeviceRegistration] which can be used to configure this device
  /// for deployment.
  ///
  /// Override this method to configure device-specific registration options, if any.
  @Deprecated(
    'Use createRegistration on a DeviceManager instead, '
    'which allows for hardware-specific runtime registration options.',
  )
  TRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
  }) =>
      DefaultDeviceRegistration(
            deviceId: deviceId,
            deviceDisplayName: deviceDisplayName,
          )
          as TRegistration;

  @override
  String toString() =>
      '$runtimeType - roleName: $roleName, isOptional: $isOptional';

  @override
  Function get fromJsonFunction => _$DeviceConfigurationFromJson;
  factory DeviceConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DeviceConfiguration<TRegistration>>(json);

  @override
  Map<String, dynamic> toJson() => _$DeviceConfigurationToJson(this);

  @override
  String get jsonType => '$DEVICE_NAMESPACE.$runtimeType';
}

/// A [DeviceConfiguration] with no extra properties, for generic devices.
///
/// Also used as a placeholder when deserializing device-dependent objects.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DefaultDeviceConfiguration
    extends DeviceConfiguration<DefaultDeviceRegistration> {
  DefaultDeviceConfiguration({required super.roleName, super.isOptional});

  @override
  DefaultDeviceRegistration createRegistration({
    String? deviceId,
    String? deviceDisplayName,
  }) => DefaultDeviceRegistration(
    deviceId: deviceId,
    deviceDisplayName: deviceDisplayName,
  );

  @override
  Function get fromJsonFunction => _$DefaultDeviceConfigurationFromJson;
  factory DefaultDeviceConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DefaultDeviceConfiguration>(json);
  @override
  Map<String, dynamic> toJson() => _$DefaultDeviceConfigurationToJson(this);
}

/// A device which aggregates, synchronizes, and optionally uploads incoming
/// data received from one or more connected devices (potentially just itself).
///
/// Every protocol has at least one, added with
/// [StudyProtocol.addPrimaryDevice]. In CARP Mobile Sensing this is the phone
/// ([Smartphone]). Each primary device receives its own
/// [PrimaryDeviceDeployment]. Primary devices are never optional.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PrimaryDeviceConfiguration<TRegistration extends DeviceRegistration>
    extends DeviceConfiguration<TRegistration> {
  PrimaryDeviceConfiguration({required super.roleName})
    : super(isOptional: false);

  /// Always true. Only here for (de)serialization: for unknown device types,
  /// the JSON tells whether to treat them as primary devices.
  bool isPrimaryDevice = true;

  /// A new trigger which fires immediately at the start of a study deployment
  /// on this device.
  TriggerConfiguration get atStartOfStudy => ElapsedTimeTrigger(
    sourceDeviceRoleName: roleName,
    elapsedTime: const Duration(),
  );

  @override
  Function get fromJsonFunction => _$PrimaryDeviceConfigurationFromJson;
  factory PrimaryDeviceConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PrimaryDeviceConfiguration<TRegistration>>(
        json,
      );
  @override
  Map<String, dynamic> toJson() => _$PrimaryDeviceConfigurationToJson(this);
}

/// A general-purpose primary device for custom protocols.
/// Only used when downloading custom protocols from the CARP web service.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CustomProtocolDevice
    extends PrimaryDeviceConfiguration<DefaultDeviceRegistration> {
  /// The default role name for a custom protocol device.
  static const String DEFAULT_ROLE_NAME = 'Custom device';

  /// Create a new [CustomProtocolDevice] device descriptor.
  /// If [roleName] is not specified, then the  [DEFAULT_ROLE_NAME] is used.
  CustomProtocolDevice({
    super.roleName = CustomProtocolDevice.DEFAULT_ROLE_NAME,
  });

  @override
  Function get fromJsonFunction => _$CustomProtocolDeviceFromJson;
  factory CustomProtocolDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CustomProtocolDevice>(json);
  @override
  Map<String, dynamic> toJson() => _$CustomProtocolDeviceToJson(this);
}
