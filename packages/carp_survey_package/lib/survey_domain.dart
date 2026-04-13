part of 'survey.dart';

/// A [RPAppTask] is a special case of an [AppTask] which can take an Research
/// Package (RP) Task.
/// This can be a survey, a cognitive test, or other tasks that implements the
/// [RPTask] from the Research Package.
///
/// A [RPAppTask] holding a survey can then be triggered in different
/// ways. For example:
///
///  * a [PeriodicTrigger] would trigger the survey on a regular basis.
///  * a [RecurrentScheduledTrigger] would schedule a recurrent survey, e.g every Monday at 8pm.
///
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RPAppTask extends AppTask {
  /// The survey to be issued to the user.
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

/// The status of a finished survey.
enum SurveyStatus { unknown, submitted, canceled }

/// Holds information about the result of a survey.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RPTaskResultData extends Data {
  /// The status of [result] (was the survey submitted or canceled?)
  /// When a survey is canceled, [result] holds the data inputted by the user
  /// until it was canceled.
  SurveyStatus status;

  // The survey result.
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
