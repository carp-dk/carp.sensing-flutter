/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'health_package.dart';

/// An [OnlineService] for the [health](https://pub.dev/packages/health) service.
///
/// On Android, this health package always uses Google [Health Connect](https://developer.android.com/health-and-fitness/guides/health-connect).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthService extends ServiceConfiguration<ServiceRegistration> {
  /// The type of the health service.
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.HealthService';

  /// The default role name for a health service.
  static const String DEFAULT_ROLE_NAME = 'Health Service';

  /// Create a new [HealthService] with a default role name, if not specified.
  HealthService({super.roleName = HealthService.DEFAULT_ROLE_NAME});

  @override
  Function get fromJsonFunction => _$HealthServiceFromJson;
  factory HealthService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HealthService>(json);
  @override
  Map<String, dynamic> toJson() => _$HealthServiceToJson(this);
}

/// A [DeviceManager] for the [HealthService].
class HealthServiceManager
    extends ServiceManager<HealthService, ServiceRegistration> {
  Health? _service;

  /// A handle to the [Health] plugin.
  /// Returns null if the service is not yet configured.
  Health? get service => configuration == null ? null : _service ??= Health();

  @override
  String get displayName => (configuration != null)
      ? (Platform.isIOS)
            ? "Apple Health"
            : "Google Health Connect"
      : 'N/A';

  final List<HealthDataType> _types = [];

  /// Which health data types should this service access.
  List<HealthDataType> get types => _types.toSet().toList();

  /// Add a set of health [types] this service should access.
  void addTypes(List<HealthDataType> types) {
    _types.addAll(types);
    _hasPermissions = false;
  }

  HealthServiceManager([HealthService? configuration])
    : super(HealthService.DEVICE_TYPE, configuration: configuration) {
    // Health().configure();
  }

  @override
  void onConfigure() {
    Health().configure();

    if (Platform.isAndroid) {
      var sdkLevel = int.parse(DeviceInfoService().sdk ?? '-1');
      if (sdkLevel < 34) {
        warning(
          '$runtimeType - Trying to use Google Health Connect on a phone with SDK level < 34 (SDK is $sdkLevel). '
          'In order to use Health Connect on this phone, you need to install Health Connect as a separate app. '
          'Please read more about Health Connect at https://developer.android.com/health-and-fitness/guides/health-connect/develop/get-started',
        );
      }
    }
  }

  @override
  ServiceRegistration createRegistration() => ServiceRegistration(
    deviceId: service?.deviceId,
    deviceDisplayName: displayName,
    isConnected: isConnected,
  );

  // There is an issue with Apple Health.
  // When asking for "hasPermissions" on the service, it always return "null".
  //  - https://github.com/cph-cachet/flutter-plugins/issues/892

  /// Check if the service has permissions to access the list of health [types].
  ///
  /// This method is called by the [HealthProbe] when it needs to access health
  /// data and is a more specific method than [hasPermissions].
  ///
  /// Note that this method always return false on iOS, as there is no way to
  /// know if permissions are granted.
  Future<bool> hasHealthPermissions(List<HealthDataType> types) async {
    if (types.isEmpty) return true;

    info(
      '$runtimeType - Checking permissions for health types: $types on ${Platform.operatingSystem}',
    );

    try {
      return await service?.hasPermissions(types) ?? false;
    } catch (error) {
      warning('$runtimeType - Error getting permission status - $error');
    }
    return false;
  }

  /// Request permissions for the list of health [types].
  ///
  /// This method is called by the [HealthProbe] when it needs to access health data
  /// and is a more specific method than [requestPermissions].
  Future<bool> requestHealthPermissions(List<HealthDataType> types) async {
    if (types.isEmpty) return true;

    info(
      '$runtimeType - Requesting permissions for health types: $types on ${Platform.operatingSystem}',
    );

    try {
      return await service?.requestAuthorization(types) ?? false;
    } catch (error) {
      warning('$runtimeType - Error requesting permissions - $error');
    }
    return false;
  }

  bool _hasPermissions = false;

  @override
  Future<bool> onHasPermissions() async {
    if (_hasPermissions) return true;
    _hasPermissions = await hasHealthPermissions(types);
    // if permissions are granted, we can consider the service as connected, otherwise disconnected.
    status = _hasPermissions
        ? DeviceStatus.connected
        : DeviceStatus.disconnected;
    return _hasPermissions;
  }

  @override
  Future<void> onRequestPermissions() async {
    _hasPermissions = await requestHealthPermissions(types);
    // if permissions are granted, we can consider the service as connected, otherwise disconnected.
    status = _hasPermissions
        ? DeviceStatus.connected
        : DeviceStatus.disconnected;
  }

  @override
  bool get canConnect => true;

  @override
  Future<DeviceStatus> onConnect() async => DeviceStatus.connected;

  @override
  Future<bool> onDisconnect() async {
    _hasPermissions = false;
    return true;
  }
}
