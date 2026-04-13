/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'apps.dart';

/// Holds a list of names of apps installed on the device.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Apps extends Data {
  /// List of of installed apps.
  List<App> installedApps = [];

  Apps(this.installedApps) : super();

  @override
  Function get fromJsonFunction => _$AppsFromJson;
  factory Apps.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Apps>(json);
  @override
  Map<String, dynamic> toJson() => _$AppsToJson(this);

  @override
  String toString() => '${super.toString()}, installedApps: $installedApps';
}

/// An application installed on the device.
/// Depending on the Android version, some attributes may not be available.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class App {
  /// Displayable name of the application.
  String? name;

  /// The name of the application package.
  String? packageName;

  /// Public name of the application (e.g., 1.0.0).
  /// The version name of this package, as specified by the `manifest` tag's
  /// `versionName` attribute.
  String? versionName;

  /// Unique version id for the application.
  int? versionCode;

  /// The time at which the app was first installed in milliseconds.
  int? installTimeMillis;

  /// What framework the app was built with.
  ///  * flutter,
  ///  * react_native,
  ///  * xamarin,
  ///  * ionic,
  ///  * native_or_others,
  String? framework;

  App({
    this.name,
    this.packageName,
    this.versionName,
    this.versionCode,
    this.installTimeMillis,
  }) : super();

  /// Create an [App] object from an [AppInfo] object.
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

/// Holds a map of names of apps and their usage, as defined in [AppUsageInfo].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppUsage extends Data {
  DateTime start, end;

  /// A map from the full package name of an app and its usage.
  Map<String, AppUsageInfo> usage = {};

  AppUsage(this.start, this.end, [this.usage = const {}]) : super();

  @override
  Function get fromJsonFunction => _$AppUsageFromJson;
  factory AppUsage.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppUsage>(json);
  @override
  Map<String, dynamic> toJson() => _$AppUsageToJson(this);

  @override
  String toString() =>
      '${super.toString()}, start: $start, end: $end, usage: $usage';
}

/// Holds information about usage for a specific app.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppUsageInfo {
  /// The name of the application
  String name;

  /// The full name of the application package
  String packageName;

  /// The amount of time the application has been used
  /// in the specified interval
  Duration usage;

  /// The start of the interval
  DateTime startDate;

  /// The end of the interval
  DateTime endDate;

  /// Last time app was in foreground
  DateTime lastForeground;

  AppUsageInfo(
    this.name,
    this.packageName,
    this.usage,
    this.startDate,
    this.endDate,
    this.lastForeground,
  );

  AppUsageInfo.fromAppUsageInfo(app_usage.AppUsageInfo info)
    : this(
        info.appName,
        info.packageName,
        info.usage,
        info.startDate,
        info.endDate,
        info.lastForeground,
      );

  factory AppUsageInfo.fromJson(Map<String, dynamic> json) =>
      _$AppUsageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AppUsageInfoToJson(this);

  @override
  String toString() =>
      'App Usage: $packageName - $name, duration: $usage [$startDate, $endDate]';
}
