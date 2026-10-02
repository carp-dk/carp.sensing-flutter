part of 'survey.dart';

/// The sampling package for surveys and cognitive tests filled in by the user.
///
/// Surveys are built with the
/// [research_package](https://pub.dev/packages/research_package) and added to
/// a protocol as an [RPAppTask]. Register the package before you deploy such a
/// protocol:
///
/// ```dart
/// SamplingPackageRegistry().register(SurveySamplingPackage());
/// ```
///
/// Key points:
///  * The [SurveyUserTask] collects the data, not a probe. [SurveyProbe] is a
///    no-op placeholder for the [SURVEY] measure.
///  * On registration, initializes Research Package and Cognition Package and
///    registers [SurveyUserTaskFactory] with the [AppTaskController].
///  * Registers [RPAppTask] and [RPTaskResultData] for JSON deserialization.
class SurveySamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for the result of a survey ([RPTaskResultData]).
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device.
  ///  * Added automatically to the measures of every [RPAppTask].
  static const String SURVEY = "${NameSpace.CARP}.survey";

  @override
  void onRegister() {
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();

    FromJsonFactory().registerAll([
      RPAppTask(
        type: '',
        rpTask: RPTask(identifier: 'ignored'),
      ),
      RPTaskResultData(),
    ]);
    AppTaskController().registerUserTaskFactory(SurveyUserTaskFactory());
  }

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: SURVEY,
            displayName: "User Survey",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
      ]);

  @override
  Probe? create(String type) => switch (type) {
    SURVEY => SurveyProbe(),
    _ => null,
  };
}

/// A no-op probe for the [SurveySamplingPackage.SURVEY] measure.
///
/// No probe is needed since the [SurveyUserTask] handles data collection.
class SurveyProbe extends Probe {}
