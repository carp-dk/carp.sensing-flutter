part of 'survey.dart';

/// An [AppTask] that asks the user to complete a Research Package task.
///
/// The [rpTask] can be a survey, a cognitive test, or any other [RPTask] from
/// Research Package. Add it to a protocol with a trigger, like any other task.
/// When triggered, it shows up as a [SurveyUserTask] in the
/// [AppTaskController.userTaskQueue].
///
/// Key points:
///  * The [type] decides how the app treats it, e.g. [AppTask.SURVEY_TYPE] or
///    [AppTask.COGNITIVE_ASSESSMENT_TYPE].
///  * The [SurveySamplingPackage.SURVEY] measure and a completed app task
///    measure are always added to [measures], so the result is collected.
///  * Other [measures] are sampled in the background while the user does the task.
///
/// For example, a [PeriodicTrigger] triggers the survey on a regular basis, and
/// a [RecurrentScheduledTrigger] schedules a recurrent survey, e.g. every
/// Monday at 8pm:
///
/// ```dart
/// protocol.addTaskControl(
///   RecurrentScheduledTrigger(type: RecurrentType.daily, time: TimeOfDay(hour: 13)),
///   RPAppTask(type: AppTask.SURVEY_TYPE, name: 'WHO-5 Survey', rpTask: who5Task),
///   phone,
/// );
/// ```
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RPAppTask extends AppTask {
  /// The survey, cognitive test or other Research Package task to show to the user.
  RPTask rpTask;

  RPAppTask({
    super.name,
    required super.type,
    super.title,
    super.description,
    super.instructions,
    super.minutesToComplete,
    super.expire,
    super.notification,
    List<Measure>? measures,
    required this.rpTask,
  }) {
    measures ??= <Measure>[];

    // Add the survey as a measure type to be collected and later uploaded,
    // if not already added - issue #342.
    if (!measures.contains(Measure(type: SurveySamplingPackage.SURVEY))) {
      measures.add(Measure(type: SurveySamplingPackage.SURVEY));
    }
    // Ensure that the completed app task data type is included in the measures.
    if (!measures.contains(
      Measure(type: '${CamsDataTypes.COMPLETED_APP_TASK}.$type'),
    )) {
      measures.add(Measure(type: '${CamsDataTypes.COMPLETED_APP_TASK}.$type'));
    }

    super.measures = measures.toSet().toList();
  }

  @override
  Function get fromJsonFunction => _$RPAppTaskFromJson;
  factory RPAppTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<RPAppTask>(json);

  @override
  Map<String, dynamic> toJson() => _$RPAppTaskToJson(this);
}

/// The status of a finished survey, as stored in [RPTaskResultData.status].
enum SurveyStatus { unknown, submitted, canceled }

/// The result of a survey or cognitive test from an [RPAppTask].
///
/// Created by [SurveyUserTask] when the user submits or cancels the task, and
/// collected for the [SurveySamplingPackage.SURVEY] measure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RPTaskResultData extends Data {
  /// The status of [result] (was the survey submitted or canceled?).
  /// When a survey is canceled, [result] holds the data entered by the user
  /// until it was canceled.
  SurveyStatus status;

  /// The survey result. May be `null` if the survey was canceled before any
  /// result was created.
  RPTaskResult? result;

  RPTaskResultData([this.status = SurveyStatus.unknown, this.result]);

  @override
  Function get fromJsonFunction => _$RPTaskResultDataFromJson;
  factory RPTaskResultData.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<RPTaskResultData>(json);

  @override
  Map<String, dynamic> toJson() => _$RPTaskResultDataToJson(this);

  @override
  String get jsonType => SurveySamplingPackage.SURVEY;
}
