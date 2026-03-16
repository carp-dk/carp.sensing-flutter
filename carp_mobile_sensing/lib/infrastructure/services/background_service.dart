/*
 * Copyright 2026 (c) the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// A service for managing background execution on Android.
///
/// On Android, this service can be used to run data collection in the background
/// while the app is not in the foreground. On iOS, background execution is not
/// supported, and this service will do nothing.
///
/// Works as a singleton service, and should be initialized and enabled
/// when the app starts, and disabled when the app is closed.
///
/// Note that the background service must be enabled in the app's manifest file.
/// You must specify the appropriate foregroundServiceType for your use case.
/// See the [Android docs](https://developer.android.com/about/versions/14/changes/fgs-types-required)
/// and the [list of available service types](https://developer.android.com/develop/background-work/services/fgs/service-types)
/// for more information on foreground service types.
///
/// Uses the [flutter_background](https://pub.dev/packages/flutter_background) package.
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._();
  BackgroundService._();
  bool _initialized = false;
  bool _enabled = false;

  /// Get the singleton [BackgroundService].
  factory BackgroundService() => _instance;

  /// Has the background service been enabled?
  bool get isEnabled => _enabled;

  /// Initialize the background service.
  ///
  /// On Android, this will initialize the background service with the provided
  /// notification title and text. If not provided, default English titles and
  /// text will be used. If you want to use localized titles and text, you can
  /// provide them here.
  ///
  /// On iOS, this will do nothing as background services are not supported.
  ///
  /// Returns `true` if the background service was successfully initialized,
  /// `false` otherwise.
  Future<bool> initialize({
    String? notificationTitle,
    String? notificationText,
  }) async {
    if (Platform.isIOS) {
      warning('$runtimeType - Background services are not supported on iOS.');
      return false;
    }
    if (_initialized) {
      warning('$runtimeType - Background service is already initialized');
      return true;
    }
    info('Initializing background service...');

    final config = FlutterBackgroundAndroidConfig(
      notificationTitle: notificationTitle ?? "CARP Mobile Sensing",
      notificationText:
          notificationText ?? "Data sampling will be running in the background",
      notificationImportance: AndroidNotificationImportance.normal,
    );

    // Initialize the background service with the provided configuration.
    // This has to be done twice due to a quirk in the flutter_background package.
    // See issue #56 in the flutter_background package for more information.

    // First attempt will open the "Stop Battery Optimization" dialog on Android,
    // which is required to allow the app to run in the background.
    _initialized = await FlutterBackground.initialize(androidConfig: config);
    bool backgroundPermissions = await FlutterBackground.hasPermissions;

    // Second attempt will actually initialize the background service if permissions were granted.
    if (!_initialized && backgroundPermissions) {
      _initialized = await FlutterBackground.initialize(androidConfig: config);
    }

    if (!_initialized) {
      warning('$runtimeType - Failed to initialize background service');
    }
    debug('$runtimeType - Background service initialized: $_initialized');
    return _initialized;
  }

  /// Enable the background service.
  Future<bool> enable() async {
    if (!_initialized) {
      warning('$runtimeType - Background service is not initialized.');
      return false;
    }

    bool enabled = FlutterBackground.isBackgroundExecutionEnabled;
    if (enabled) {
      warning('$runtimeType - Background service is already enabled.');
      return true;
    }

    bool hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      warning('$runtimeType - Background service does not have permissions.');
      return false;
    }

    info('Enabling background service...');
    _enabled = await FlutterBackground.enableBackgroundExecution();
    if (!_enabled) {
      warning('$runtimeType - Failed to enable background service.');
    }
    debug('$runtimeType - Background service enabled: $_enabled');
    return _enabled;
  }

  /// Disable the background service.
  Future<bool> disable() async {
    if (!_initialized) {
      warning('$runtimeType - Background service is not initialized.');
      return false;
    }

    info('Disabling background service...');
    _enabled = await FlutterBackground.disableBackgroundExecution();
    if (_enabled) {
      warning('$runtimeType - Failed to disable background service.');
    }
    debug('$runtimeType - Background service disabled: $_enabled');
    return !_enabled;
  }
}
