part of 'apps.dart';

/// Collects the list of apps installed on this device as [Apps] data.
///
/// Used for the [AppsSamplingPackage.APPS] measure. Only runs on Android.
class AppsProbe extends MeasurementProbe {
  @override
  Future<Measurement> getMeasurement() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps();

    return Measurement.fromData(Apps(apps.map((app) => App.fromAppInfo(app)).toList()));
  }
}

/// Collects usage information on the apps installed on this device as
/// [AppUsage] data.
///
/// Used for the [AppsSamplingPackage.APP_USAGE] measure. The period starts at
/// the last time this probe collected data or, the first time, at
/// [HistoricSamplingConfiguration.past] before now. The period ends now.
///
/// Only runs on Android, and needs the `PACKAGE_USAGE_STATS` permission.
class AppUsageProbe extends MeasurementProbe {
  AppUsageProbe() : super();

  @override
  HistoricSamplingConfiguration get samplingConfiguration =>
      super.samplingConfiguration as HistoricSamplingConfiguration;

  @override
  Future<Measurement> getMeasurement() async {
    // get the last mark - if null, go back as specified in history
    DateTime start = samplingConfiguration.lastTime ?? DateTime.now().subtract(samplingConfiguration.past);
    DateTime end = DateTime.now();

    debug('Collecting app usage - start: ${start.toUtc()}, end: ${end.toUtc()}');
    List<app_usage.AppUsageInfo> infos = await app_usage.AppUsage().getAppUsage(start, end);

    Map<String, AppUsageInfo> usage = {};
    for (var info in infos) {
      usage[info.packageName] = AppUsageInfo.fromAppUsageInfo(info);
    }

    return Measurement(
      sensorStartTime: start.microsecondsSinceEpoch,
      sensorEndTime: end.microsecondsSinceEpoch,
      data: AppUsage(start.toUtc(), end.toUtc(), usage),
    );
  }
}
