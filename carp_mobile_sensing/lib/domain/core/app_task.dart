/*
 * Copyright 2020 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A task that the user does in the app, like filling in a survey.
///
/// When its trigger fires, an [AppTaskExecutor] wraps the task in a [UserTask]
/// and puts it on the queue of the [AppTaskController]. The app shows the
/// queue as a task list, and the user starts, completes, or cancels the task.
///
/// Key points:
///  * [type] says what kind of task it is, e.g. [SURVEY_TYPE]. Sampling
///    packages provide subclasses, e.g. `RPAppTask` in carp_survey_package.
///  * [measures] are collected in the background while the task is running.
///  * A `dk.cachet.carp.completedapptask.<type>` measure is always added, so a
///    [CompletedAppTask] is collected when the task is done.
///  * [expire] removes the task from the queue; [notification] sends a
///    notification via the [NotificationManager].
///
/// ```dart
/// protocol.addTaskControl(
///   RecurrentScheduledTrigger(type: RecurrentType.daily, time: TimeOfDay(hour: 8)),
///   AppTask(type: AppTask.SURVEY_TYPE, title: 'Daily survey', notification: true),
///   phone,
/// );
/// ```
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppTask extends TaskConfiguration {
  /// A background sensing user task which can be started and stopped by the user.
  static const String SENSING_TYPE = 'sensing';

  /// A survey app task. Used in the carp_survey_package for `RPAppTask`s.
  static const String SURVEY_TYPE = 'survey';

  /// A cognitive assessment app task. Used in the carp_survey_package for `RPAppTask`s.
  static const String COGNITIVE_ASSESSMENT_TYPE = 'cognition';

  /// An audio app task. Used in the carp_audio_package.
  static const String AUDIO_TYPE = 'audio';

  /// A video app task. Used in the carp_audio_package.
  static const String VIDEO_TYPE = 'video';

  /// An image app task. Used in the carp_audio_package.
  static const String IMAGE_TYPE = 'image';

  /// An informed consent app task.
  static const String INFORMED_CONSENT_TYPE = 'informed_consent';

  /// An app task collecting health data. Used in the carp_health_package.
  static const String HEALTH_ASSESSMENT_TYPE = 'health';

  /// The type of task, e.g. [SURVEY_TYPE]. Any string is allowed.
  String type;

  /// A title for this task. Can be used in the app.
  String title;

  /// A short description (one line) of this task. Can be used in the app.
  @override
  String get description => super.description ?? '';

  /// A longer instruction text explaining how a user should perform this task.
  String instructions;

  /// How many minutes will it take for the user to perform this task?
  /// Typically shown to the user before engaging into this task.
  /// If `null` the task has no completion time.
  int? minutesToComplete;

  /// How long this task stays on the [AppTaskController]'s queue before it
  /// expires and is removed. If `null`, the task never expires.
  Duration? expire;

  /// Whether to send a notification to the user when the task is triggered.
  /// Default is `false`.
  bool notification;

  /// The list of background [measures] as a [BackgroundTask].
  BackgroundTask get backgroundTask => BackgroundTask(name: name, measures: measures);

  /// Creates an app task that notifies the app when it is triggered.
  ///
  /// [name] is a unique name of the task.
  /// [measures] is the list of measures to be collected in the background when
  /// this app task is started.
  /// [type] provide a unique type for this kind of app task.
  AppTask({
    super.name,
    List<Measure>? measures,
    required this.type,
    this.title = '',
    super.description = '',
    this.instructions = '',
    this.minutesToComplete,
    this.expire,
    this.notification = false,
  }) : super() {
    measures ??= <Measure>[];

    // Ensure that the completed app task data type is included in the measures.
    if (!measures.contains(Measure(type: '${CamsDataTypes.COMPLETED_APP_TASK}.$type'))) {
      measures.add(Measure(type: '${CamsDataTypes.COMPLETED_APP_TASK}.$type'));
    }

    super.measures = measures.toSet().toList();
  }

  @override
  Function get fromJsonFunction => _$AppTaskFromJson;

  factory AppTask.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<AppTask>(json);

  @override
  Map<String, dynamic> toJson() => _$AppTaskToJson(this);
}
