/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../carp_context_package.dart';

/// The precision of the Location. A lower precision will provide a greater
/// battery life.
///
/// This is modelled following [LocationAccuracy](https://pub.dev/documentation/location_platform_interface/latest/location_platform_interface/LocationAccuracy.html)
/// in the location plugin. This is good compromise between the iOS and Android models:
///
///  * iOS [CLLocationAccuracy](https://developer.apple.com/documentation/corelocation/cllocationaccuracy?language=objc)
///  * Android [LocationRequest](https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest)
enum GeolocationAccuracy {
  /// Location is accurate within a distance of 3000m on iOS and 500m on Android.
  powerSave,

  /// Location is accurate within a distance of 1000m on iOS and 500m on Android.
  low,

  /// Location is accurate within a distance of 100m on iOS and between 100m and
  /// 500m on Android.
  balanced,

  /// Location is accurate within a distance of 10m on iOS and between 0m and
  /// 100m on Android.
  high,

  /// Location accuracy is optimized for navigation on iOS and between 0m and
  /// 100m on Android.
  navigation,

  /// Location accuracy is reduced for iOS 14+ devices, matches the
  /// [GeolocationAccuracy.powerSave] on iOS 13 and below and all other platforms.
  reduced,
}

/// A manger that knows how to get location information.
/// Provide access to location data while the app is in the background.
///
/// Use as a singleton:
///
///  `LocationManager()...`
///
/// Does not ask for location permission - CAMS asks for a study's permissions
/// before it connects anything. [configure] only checks, via [hasPermission].
///
/// This [LocationManager] based on the [location](https://pub.dev/packages/location)
/// plugin.
class LocationManager {
  static final LocationManager _instance = LocationManager._();
  LocationManager._();

  /// Get the singleton [LocationManager] instance
  factory LocationManager() => _instance;

  bool _enabled = false, _configured = false;
  final _provider = location.Location();
  Location? _lastKnownLocation;

  /// Is the location service enabled, which entails that
  ///  * location service is enabled
  ///  * permissions granted
  bool get enabled => _enabled;

  /// Is the location service configured via the [configure] method.
  bool get configured => _configured;

  /// Is the location service enabled in background mode?
  Future<bool> isBackgroundModeEnabled() async => await _provider.isBackgroundModeEnabled();

  /// Does this location manger have permission to access location?
  Future<bool> hasPermission() => Permission.locationWhenInUse.isGranted;

  /// Enable the [LocationManager] for accessing location also when the app is
  /// in the background.
  ///
  /// This method will try to enable 'background mode' to allow location
  /// when the app is in the background (i.e., not in use but still running).
  /// Therefore it will request the "location always" permission which will
  /// open the OS-specific settings on the phone (both iOS and Android)
  ///
  /// After the location manager is enabled, configuration can be done via the
  /// [configure] method.
  Future<void> enable() async {
    // fast out if already enabled
    if (enabled) return;

    info('Enabling $runtimeType...');
    _enabled = false;

    bool serviceEnabled = await _provider.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _provider.requestService();
      if (!serviceEnabled) {
        warning('$runtimeType - Location service could not be enabled.');
        return;
      }
    }
    _enabled = true;
    bool backgroundMode = false;

    try {
      backgroundMode = await _provider.enableBackgroundMode();
    } catch (error) {
      warning('$runtimeType - Could not enable background mode - $error');
    }

    info('$runtimeType - Location service enabled, background mode: $backgroundMode');
  }

  LocationService? _configuration;
  LocationService? get configuration => _configuration;

  /// Configures the [LocationManager], incl. sending a notification to the
  /// Android notification system.
  ///
  /// Configuration is done based on the [configuration]. If not provided,
  /// as set of default configurations are used.
  Future<void> configure(LocationService configuration) async {
    // fast out if already configured
    if (configured) return;
    _configuration = configuration;

    // ensured that this location manager is enable first
    await enable();

    info('Configuring $runtimeType - configuration: $configuration');
    _configured = false;

    // Only on Android, configure the notification shown when running in background.
    if (Platform.isAndroid) {
      // The location plugin throws a *native* Android exception when settings are
      // changed without location permission - it never reaches Flutter, so it
      // cannot be caught below. Bail out instead; connecting the location service
      // again once permission is granted will configure it.
      //
      // See https://github.com/Lyokone/flutterlocation/blob/c14f8173caf33f8c38d01b28c94e0804c63e0db9/packages/location/android/src/main/java/com/lyokone/location/FlutterLocation.java#L201
      if (!await hasPermission()) {
        warning('$runtimeType - Cannot configure without permission to access location.');
        return;
      }

      // Change notification options - only on Android.
      try {
        await _provider.changeNotificationOptions(
          title: configuration.notificationTitle ?? 'CARP Location Service',
          subtitle: configuration.notificationMessage ?? 'The location service is running in the background',
          description:
              configuration.notificationDescription ??
              'Background location is on to keep the CARP Mobile Sensing app up-to-date with your location. '
                  'This is required for main features to work properly when the app is not in use.',
          onTapBringToFront: configuration.notificationOnTapBringToFront,
          iconName: configuration.notificationIconName,
        );
      } catch (error) {
        warning(
          '$runtimeType - Configuration of Android notification failed - $error\n'
          'Ignoring this.',
        );
      }
    }

    // Change location settings - both Android and iOS.
    try {
      await _provider.changeSettings(
        accuracy: location.LocationAccuracy.values[configuration.accuracy.index],
        distanceFilter: configuration.distance,
        interval: configuration.interval.inMilliseconds,
      );

      info('$runtimeType - configured successfully.');
      _configured = true;
    } catch (error) {
      warning('$runtimeType - Configuration failed - $error');
    }
  }

  /// The last know location, if any.
  Location? get lastKnownLocation => _lastKnownLocation;

  /// Gets the current location of the phone. In case the location cannot be
  /// obtained within a few seconds, the last known location is returned.
  ///
  /// Throws an error if the app does not have permission to access location.
  Future<Location> getLocation() async {
    try {
      _lastKnownLocation = await onLocationChanged.first.timeout(const Duration(seconds: 6));
    } catch (_) {}

    if (_lastKnownLocation == null) {
      warning('$runtimeType - Could not get location.');
      throw StateError('Could not get location.');
    }
    return _lastKnownLocation!;
  }

  // The following implementation of getLocation() does not work, since the
  // _provider.getLocation() method sometimes never returns.
  //
  // See issue https://github.com/cph-cachet/carp.sensing-flutter/issues/389
  //
  // Future<Location> getLocation() async => _lastKnownLocation =
  //     Location.fromLocationData(await _provider.getLocation().timeout(
  //           const Duration(seconds: 6),
  //           // onTimeout: () => lastKnownLocation,
  //         ));

  /// Returns a stream of [Location] objects.
  ///
  /// The underlying native `location` plugin reports permission errors
  /// (e.g. PERMISSION_DENIED_NEVER_ASK) on its event channel. `handleError`
  /// absorbs them here so they don't propagate as unhandled future errors
  /// to downstream subscribers.
  Stream<Location> get onLocationChanged => _provider.onLocationChanged
      .handleError((Object error) {
        warning('$runtimeType - native location stream error absorbed: $error');
      })
      .map((location) => _lastKnownLocation = Location.fromLocationData(location));

  @override
  toString() => configuration != null
      ? '$runtimeType\n${configuration!.accuracy.name} | ${configuration!.distance.toInt()} m | ${configuration!.interval.inSeconds} secs'
      : '$runtimeType';
}
