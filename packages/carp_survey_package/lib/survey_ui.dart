part of 'survey.dart';

/// A full-screen widget that shows a survey (i.e., a [RPTask]).
class SurveyPage extends StatelessWidget {
  /// The task to present
  final RPTask task;

  /// The callback function which has to return an [RPTaskResult] object.
  final void Function(RPTaskResult) resultCallback;

  /// The callback function if a survey is canceled by user.
  /// The [RPTaskResult] is optional and can be `null` if no results were created.
  final void Function([RPTaskResult?])? onSurveyCancel;

  const SurveyPage({
    super.key,
    required this.task,
    required this.resultCallback,
    this.onSurveyCancel,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return RPUITask(
      task: task as RPOrderedTask,
      onSubmit: resultCallback,
      onCancel: onSurveyCancel,
    );
  }
}
