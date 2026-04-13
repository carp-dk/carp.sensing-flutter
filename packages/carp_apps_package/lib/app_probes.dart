part of 'apps.dart';

/// A probe collecting a list of installed apps on this device.
///
/// Note that this probe only runs on Android.
class AppsProbe extends MeasurementProbe {
  @override
  Future<Measurement> getMeasurement() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps();

    return Measurement.fromData(
      Apps(apps.map((app) => App.fromAppInfo(app)).toList()),
    );
  }
}

/// A probe collecting app usage information on apps that are installed on
/// the device.
///
/// Note that this probe only runs on Android.
class AppUsageProbe extends MeasurementProbe {
  AppUsageProbe() : super();

  @override
  HistoricSamplingConfiguration get samplingConfiguration =>
      super.samplingConfiguration as HistoricSamplingConfiguration;

  @override
  Future<Measurement> getMeasurement() async {
    // get the last mark - if null, go back as specified in history
    DateTime start =
        samplingConfiguration.lastTime ??
        DateTime.now().subtract(samplingConfiguration.past);
    DateTime end = DateTime.now();

    debug(
      'Collecting app usage - start: ${start.toUtc()}, end: ${end.toUtc()}',
    );
    List<app_usage.AppUsageInfo> infos = await app_usage.AppUsage().getAppUsage(
      start,
      end,
    );

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
