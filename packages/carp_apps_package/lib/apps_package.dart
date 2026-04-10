part of 'apps.dart';

class AppsSamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for one-time collection of apps installed on this phone.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * No sampling configuration needed.
  static const String APPS = "${NameSpace.CARP}.apps";

  /// Measure type for one-time collection app usage information on apps that
  /// are installed on the phone.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * Use the [HistoricSamplingConfiguration] for configuration.
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
