part of 'survey.dart';

/// A [UserTask] that shows a survey or cognitive test from an [RPAppTask].
///
/// Created by [SurveyUserTaskFactory] and put on the
/// [AppTaskController.userTaskQueue] when the [RPAppTask] is triggered.
/// The app shows the [widget] (a [SurveyPage]) to the user.
///
/// Key points:
///  * Call [onStart] when the user starts the task. This resumes background
///    sampling of the task's measures.
///  * On submit, adds an [RPTaskResultData] measurement with status
///    [SurveyStatus.submitted], pauses background sampling and marks the task done.
///  * On cancel, also adds the partial result (status [SurveyStatus.canceled]),
///    pauses background sampling and marks the task canceled.
class SurveyUserTask extends UserTask {
  /// The [RPAppTask] from which this user task originates from.
  RPAppTask get rpAppTask => task as RPAppTask;

  @override
  bool get hasWidget => true;

  SurveyUserTask(super.executor);

  @override
  Widget? get widget => SurveyPage(
    task: rpAppTask.rpTask,
    resultCallback: _onSurveySubmit,
    onSurveyCancel: _onSurveyCancel,
  );

  @override
  void onStart() {
    super.onStart();

    // resume collecting sensor data in the background
    backgroundTaskExecutor.resume();
  }

  void _onSurveySubmit(RPTaskResult result) {
    // when we have the survey result, add it to the measurement stream
    var data = RPTaskResultData(SurveyStatus.submitted, result);
    backgroundTaskExecutor.addMeasurement(Measurement.fromData(data));
    // and then pause the background executor
    backgroundTaskExecutor.pause();
    super.onDone(result: data);
  }

  void _onSurveyCancel([RPTaskResult? result]) {
    // also save result even though it was canceled by the user
    backgroundTaskExecutor.addMeasurement(
      Measurement.fromData(RPTaskResultData(SurveyStatus.canceled, result)),
    );
    backgroundTaskExecutor.pause();
    super.onCancel();
  }
}

/// Creates a [SurveyUserTask] for app tasks of type informed consent, survey
/// and cognitive assessment.
///
/// Registered with the [AppTaskController] by [SurveySamplingPackage].
class SurveyUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [
    AppTask.INFORMED_CONSENT_TYPE,
    AppTask.SURVEY_TYPE,
    AppTask.COGNITIVE_ASSESSMENT_TYPE,
  ];

  // always create a [SurveyUserTask]
  @override
  UserTask create(AppTaskExecutor executor) => SurveyUserTask(executor);
}
