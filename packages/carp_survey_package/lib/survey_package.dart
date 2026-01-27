part of 'survey.dart';

/// A [SamplingPackage] that knows how to collect data from user surveys based
/// on the [research_package](https://pub.dev/packages/research_package)
/// package.
///
/// In contrast to other sampling packages, this package does not support any
/// [dataTypes]. Collection of [RPTask] data from a user is supported by the
/// [SurveyUserTask] user task.
class SurveySamplingPackage extends SmartphoneSamplingPackage {
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

/// A simple no-op probe that does nothing.
/// We don't need a probe since the [SurveyUserTask] handles data collection.
class SurveyProbe extends Probe {}
