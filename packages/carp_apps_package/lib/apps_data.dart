/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'apps.dart';

/// The apps installed on the device.
///
/// Collected by [AppsProbe] for the [AppsSamplingPackage.APPS] measure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Apps extends Data {
  /// The list of installed apps.
  List<App> installedApps = [];

  Apps(this.installedApps) : super();

  @override
  Function get fromJsonFunction => _$AppsFromJson;
  factory Apps.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Apps>(json);
  @override
  Map<String, dynamic> toJson() => _$AppsToJson(this);

  @override
  String toString() => '${super.toString()}, installedApps: $installedApps';
}

/// An app installed on the device, as listed in [Apps].
///
/// Depending on the Android version, some attributes may not be available.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class App {
  /// Displayable name of the application.
  String? name;

  /// The name of the application package.
  String? packageName;

  /// Public version name of the application (e.g., 1.0.0), as specified by
  /// the `manifest` tag's `versionName` attribute.
  String? versionName;

  /// Unique version id for the application.
  int? versionCode;

  /// The time the app was first installed, in milliseconds since epoch.
  int? installTimeMillis;

  /// The framework the app was built with. One of:
  ///  * flutter
  ///  * react_native
  ///  * xamarin
  ///  * ionic
  ///  * native_or_others
  String? framework;

  App({this.name, this.packageName, this.versionName, this.versionCode, this.installTimeMillis}) : super();

  /// Creates an [App] from an [AppInfo] object from the `installed_apps` plugin.
  App.fromAppInfo(AppInfo app) : super() {
    name = app.name;
    packageName = app.packageName;
    versionName = app.versionName;
    versionCode = app.versionCode;
    installTimeMillis = app.installedTimestamp;
    framework = app.platformType.name;
  }

  factory App.fromJson(Map<String, dynamic> json) => _$AppFromJson(json);
  Map<String, dynamic> toJson() => _$AppToJson(this);

  @override
  String toString() {
    return 'App {'
        'name: $name, '
        'packageName: $packageName, '
        'versionName: $versionName, '
        'versionCode: $versionCode, '
        'installTimeMillis: $installTimeMillis, '
        'builtWith: $framework'
        '}';
  }
}

/// The usage of each app on the device over a period from [start] to [end].
///
/// Collected by [AppUsageProbe] for the [AppsSamplingPackage.APP_USAGE] measure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppUsage extends Data {
  /// The start and end (UTC) of the period this usage covers.
  DateTime start, end;

  /// The usage of each app, keyed by the app's full package name.
  Map<String, AppUsageInfo> usage = {};

  AppUsage(this.start, this.end, [this.usage = const {}]) : super();

  @override
  Function get fromJsonFunction => _$AppUsageFromJson;
  factory AppUsage.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<AppUsage>(json);
  @override
  Map<String, dynamic> toJson() => _$AppUsageToJson(this);

  @override
  String toString() => '${super.toString()}, start: $start, end: $end, usage: $usage';
}

/// The usage of a single app, as listed in [AppUsage].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppUsageInfo {
  /// The name of the application.
  String name;

  /// The full name of the application package.
  String packageName;

  /// The amount of time the application has been used in the interval from
  /// [startDate] to [endDate].
  Duration usage;

  /// The start of the interval.
  DateTime startDate;

  /// The end of the interval.
  DateTime endDate;

  /// The last time the app was in the foreground.
  DateTime lastForeground;

  AppUsageInfo(this.name, this.packageName, this.usage, this.startDate, this.endDate, this.lastForeground);

  /// Creates an [AppUsageInfo] from the `app_usage` plugin's usage info.
  AppUsageInfo.fromAppUsageInfo(app_usage.AppUsageInfo info)
    : this(info.appName, info.packageName, info.usage, info.startDate, info.endDate, info.lastForeground);

  factory AppUsageInfo.fromJson(Map<String, dynamic> json) => _$AppUsageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AppUsageInfoToJson(this);

  @override
  String toString() => 'App Usage: $packageName - $name, duration: $usage [$startDate, $endDate]';
}
