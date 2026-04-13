/*
 * Copyright 2020 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A task that notifies the app when it is triggered.
///
/// See [AppTaskExecutor] on how this work on runtime.
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

  /// Type of task. For example a `survey`.
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

  /// The duration of this app task, i.e. when it expire and is removed
  /// from the [AppTaskController]'s queue.
  /// If `null` the task never expire.
  Duration? expire;

  /// Should a notification be send to the user on the phone?
  bool notification;

  /// The list of background [measures] as a [BackgroundTask].
  BackgroundTask get backgroundTask =>
      BackgroundTask(name: name, measures: measures);

  /// Create an app task that notifies the app when it is triggered.
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
    if (!measures.contains(
      Measure(type: '${CamsDataTypes.COMPLETED_APP_TASK}.$type'),
    )) {
      measures.add(Measure(type: '${CamsDataTypes.COMPLETED_APP_TASK}.$type'));
    }

    super.measures = measures.toSet().toList();
  }

  @override
  Function get fromJsonFunction => _$AppTaskFromJson;

  factory AppTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppTask>(json);

  @override
  Map<String, dynamic> toJson() => _$AppTaskToJson(this);
}
