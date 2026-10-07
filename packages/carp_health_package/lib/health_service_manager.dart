/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'health_package.dart';

/// A connected device that represents the health database on the phone:
/// Apple Health on iOS and Google Health Connect on Android.
///
/// Add it to a protocol with [StudyProtocol.addConnectedDevice] and use it as
/// the target device of tasks with [HealthSamplingPackage.HEALTH] measures.
/// At runtime it is handled by a [HealthServiceManager], which uses the
/// [health](https://pub.dev/packages/health) plugin.
///
/// On Android, this health package always uses Google [Health Connect](https://developer.android.com/health-and-fitness/guides/health-connect).
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthService extends ServiceConfiguration<ServiceRegistration> {
  /// The type of the health service.
  static const String DEVICE_TYPE = '${CamsDevice.CAMS_DEVICE_NAMESPACE}.HealthService';

  /// The default role name for a health service.
  static const String DEFAULT_ROLE_NAME = 'Health Service';

  /// Create a new [HealthService] with a default role name, if not specified.
  HealthService({super.roleName = HealthService.DEFAULT_ROLE_NAME});

  @override
  Function get fromJsonFunction => _$HealthServiceFromJson;
  factory HealthService.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<HealthService>(json);
  @override
  Map<String, dynamic> toJson() => _$HealthServiceToJson(this);
}

/// The [DeviceManager] for the [HealthService].
///
/// Owns the [Health] plugin instance, keeps the set of health data [types] to
/// access, and checks and requests permissions for them.
///
/// Key points:
///  * Types come from each [HealthProbe] (on initialize) and from the default
///    sampling configuration of the [HealthService] (on configure).
///  * Connecting always succeeds once permissions are granted.
///  * On iOS, [hasPermissions] is true as soon as types are registered, because
///    Apple Health does not disclose whether read access is granted.
///  * On Android below SDK level 34, it logs a warning that Health Connect must
///    be installed as a separate app.
class HealthServiceManager extends ServiceManager<HealthService, ServiceRegistration> {
  Health? _service;

  /// The [Health] plugin, or null if this manager is not configured yet.
  Health? get service => configuration == null ? null : _service ??= Health();

  @override
  String get displayName => (configuration != null)
      ? (Platform.isIOS)
            ? "Apple Health"
            : "Google Health Connect"
      : 'N/A';

  final Set<HealthDataType> _types = {};

  /// The health data types this service accesses.
  List<HealthDataType> get types => _types.toList();

  /// Add a set of health [types] this service should access.
  ///
  /// Types not supported on the current platform are ignored and logged as a
  /// warning.
  void addTypes(List<HealthDataType> types) {
    bool isSupported(HealthDataType type) =>
        Platform.isIOS ? dataTypeKeysIOS.contains(type) : dataTypeKeysAndroid.contains(type);

    final unsupported = types.where((type) => !isSupported(type));
    if (unsupported.isNotEmpty) {
      warning(
        '$runtimeType - Ignoring health data types not supported on '
        '${Platform.isIOS ? 'iOS' : 'Android'}: ${unsupported.toList()}.',
      );
    }

    _types.addAll(types.where(isSupported));
  }

  HealthServiceManager([HealthService? configuration])
    : super(HealthService.DEVICE_TYPE, configuration: configuration) {
    // Health().configure();
  }

  /// Adds the health data types from the default sampling configuration of
  /// [service] for the [HealthSamplingPackage.HEALTH] measure, so that the
  /// right permissions can be requested.
  ///
  /// Called when this manager is configured.
  void gatherTypesFrom(HealthService? service) {
    final config = service?.defaultSamplingConfiguration?[HealthSamplingPackage.HEALTH];
    if (config is HealthSamplingConfiguration) {
      addTypes(config.healthDataTypes);
    }
  }

  @override
  void onConfigure() {
    Health().configure();
    gatherTypesFrom(configuration);

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
  ServiceRegistration createRegistration() =>
      ServiceRegistration(deviceId: service?.deviceId, deviceDisplayName: displayName, isConnected: isConnected);

  // There is an issue with Apple Health.
  // When asking for "hasPermissions" on the service, it always return "null".
  //  - https://github.com/cph-cachet/flutter-plugins/issues/892

  /// Checks if the service has permissions to access the list of health [types].
  ///
  /// This method is called by the [HealthProbe] when it needs to access health
  /// data and is a more specific method than [hasPermissions].
  /// Returns true if [types] is empty, and false if the check fails.
  ///
  /// Note that on iOS this is only false if access was never requested, as
  /// Apple Health does not disclose whether read access is granted.
  Future<bool> hasHealthPermissions(List<HealthDataType> types) async {
    if (types.isEmpty) return true;

    info('$runtimeType - Checking permissions for health types: $types on ${Platform.operatingSystem}');

    try {
      // On iOS, null means access was requested, but read access is never disclosed.
      return await service?.hasPermissions(types) ?? Platform.isIOS;
    } catch (error) {
      warning('$runtimeType - Error getting permission status - $error');
    }
    return false;
  }

  /// Requests permissions for the list of health [types].
  ///
  /// This method is called by the [HealthProbe] when it needs to access health data
  /// and is a more specific method than [requestPermissions]. It shows the OS
  /// permission dialog. Returns true if [types] is empty, and false if the
  /// request fails.
  Future<bool> requestHealthPermissions(List<HealthDataType> types) async {
    if (types.isEmpty) return true;

    info('$runtimeType - Requesting permissions for health types: $types on ${Platform.operatingSystem}');

    try {
      return await service?.requestAuthorization(types) ?? false;
    } catch (error) {
      warning('$runtimeType - Error requesting permissions - $error');
    }
    return false;
  }

  @override
  Future<bool> onHasPermissions() async {
    // No registered types yet must not count as "granted".
    if (types.isEmpty) return false;

    final granted = await hasHealthPermissions(types);
    if (!granted) {
      final missing = await missingHealthPermissions(types);
      warning(
        '$runtimeType - Missing health permissions for: $missing. '
        'Either the user has not granted them, or they are not declared in the app\'s AndroidManifest.xml.',
      );
    }
    return granted;
  }

  /// The health [types] this service cannot read, checked one type at a time.
  ///
  /// On iOS, only types never requested, since Apple Health does not disclose read access.
  Future<List<HealthDataType>> missingHealthPermissions(
    List<HealthDataType> types,
  ) async {
    final missing = <HealthDataType>[];
    for (final type in types) {
      if (!await hasHealthPermissions([type])) missing.add(type);
    }
    return missing;
  }

  @override
  Future<void> onRequestPermissions() async {
    await requestHealthPermissions(types);
  }

  @override
  bool get canConnect => true;

  // Note that [connect] only calls this once permissions have been granted.
  @override
  Future<DeviceStatus> onConnect() async => DeviceStatus.connected;

  @override
  Future<bool> onDisconnect() async => true;
}
