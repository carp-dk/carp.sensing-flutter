/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// Describes any type of electronic device, such as a sensor, video camera,
/// desktop computer, or smartphone that collects data which can be incorporated
/// into the platform after it has been processed by a primary device (potentially itself).
/// Optionally, a device can present output and receive user input.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DeviceConfiguration<TRegistration extends DeviceRegistration>
    extends Serializable {
  static const DEVICE_NAMESPACE = 'dk.cachet.carp.common.application.devices';

  /// The device type identifier
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get type => jsonType;

  /// A name which describes how the device participates within the study protocol;
  /// it's 'role'. For example, 'Parent's phone' or 'Child phone'.
  String roleName;

  /// Determines whether device registration for this device is optional prior to
  /// starting a study, i.e., whether the study can run without this device or not.
  bool? isOptional;

  /// Sampling configurations which override the default configurations for
  /// data types available on this device.
  Map<String, SamplingConfiguration>? defaultSamplingConfiguration = {};

  /// Sampling schemes for all the sensors available on this device.
  ///
  /// Implementations of [DeviceConfiguration] should simply return a map
  /// of all supported sampling schemes here.
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

/// A default device configuration just implementing the basics.
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
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PrimaryDeviceConfiguration<TRegistration extends DeviceRegistration>
    extends DeviceConfiguration<TRegistration> {
  PrimaryDeviceConfiguration({required super.roleName})
    : super(isOptional: false);

  // This property is only here for (de)serialization purposes.
  // For unknown types we need to know whether to treat them as primary
  // devices or not (in the case of 'DeviceConfiguration' collections).
  bool isPrimaryDevice = true;

  /// A trigger which fires immediately at the start of a study deployment.
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
