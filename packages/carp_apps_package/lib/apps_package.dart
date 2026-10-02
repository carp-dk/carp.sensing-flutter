part of 'apps.dart';

/// The sampling package for collecting installed apps and app usage.
///
/// Register it before you deploy a protocol that uses [APPS] or [APP_USAGE]:
///
/// ```dart
/// SamplingPackageRegistry().register(AppsSamplingPackage());
/// ```
///
/// Key points:
///  * Both measures only work on Android. On other platforms [create] returns
///    `null`, so no probe runs.
///  * Registers [Apps] and [AppUsage] for JSON deserialization.
///
/// See also [AppsProbe] and [AppUsageProbe], which do the collection.
class AppsSamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for one-time collection of the apps installed on this phone.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * No sampling configuration needed.
  ///  * Collected as [Apps] data.
  static const String APPS = "${NameSpace.CARP}.apps";

  /// Measure type for one-time collection of app usage information on apps
  /// that are installed on the phone.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * Use a [HistoricSamplingConfiguration] for configuration. Default is
  ///    one day back in time.
  ///  * Collected as [AppUsage] data.
  static const String APP_USAGE = "${NameSpace.CARP}.appusage";

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: APPS,
            displayName: "Installed Apps",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: APP_USAGE,
            displayName: "App Usage",
            timeType: DataTimeType.TIME_SPAN,
            dataEventType: DataEventType.ONE_TIME,
          ),
          HistoricSamplingConfiguration(
            future: Duration.zero,
            past: Duration(days: 1),
          ),
        ),
      ]);

  @override
  Probe? create(String type) => switch (type) {
    APPS => (Platform.isAndroid) ? AppsProbe() : null,
    APP_USAGE => (Platform.isAndroid) ? AppUsageProbe() : null,
    _ => null,
  };

  @override
  void onRegister() => FromJsonFactory().registerAll([
    Apps([]),
    AppUsage(DateTime.now(), DateTime.now()),
  ]);
}
