part of 'survey.dart';

/// A [UserTask] that contains a survey.
///
/// A [SurveyUserTask] is enqueued on the [AppTaskController]'s [userTaskQueue]
/// and can be accessed from here. When a user starts this user task, the
/// [onStart] method should be called.
///
/// The survey page to show in the app is available as the [widget].
class SurveyUserTask extends UserTask {
  // A set if predefined commonly used task types.
  static const String SURVEY_TYPE = 'survey';
  static const String COGNITIVE_ASSESSMENT_TYPE = 'cognition';
  static const String AUDIO_TYPE = 'audio';
  static const String VIDEO_TYPE = 'video';
  static const String IMAGE_TYPE = 'image';
  static const String INFORMED_CONSENT_TYPE = 'informed_consent';

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

class SurveyUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [
    SurveyUserTask.INFORMED_CONSENT_TYPE,
    SurveyUserTask.SURVEY_TYPE,
    SurveyUserTask.COGNITIVE_ASSESSMENT_TYPE,
  ];

  // always create a [SurveyUserTask]
  @override
  UserTask create(AppTaskExecutor executor) => SurveyUserTask(executor);
}
