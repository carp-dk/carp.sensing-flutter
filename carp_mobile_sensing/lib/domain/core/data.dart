/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A [Data] object holding a link to a file.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FileData extends Data {
  /// The local path to the attached file on the phone where it is sampled.
  /// This is used by e.g. a data manager to get and manage the file on
  /// the phone.
  // @JsonKey(includeFromJson: false, includeToJson: false)
  String? path;

  /// The name to the attached file.
  String filename;

  /// Should the file also be uploaded, or only this meta data?
  /// Default is true.
  bool upload = true;

  /// Metadata for this file as a map of string key-value pairs.
  Map<String, String>? metadata = <String, String>{};

  /// Create a new [FileData] based the file path and whether it is
  /// to be uploaded or not.
  FileData({required this.filename, this.upload = true}) : super();

  @override
  bool equivalentTo(Data other) =>
      other is FileData && filename == other.filename;

  @override
  Function get fromJsonFunction => _$FileDataFromJson;
  factory FileData.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<FileData>(json);
  @override
  Map<String, dynamic> toJson() => _$FileDataToJson(this);
}

/// Data about a completed [AppTask].
///
/// [taskName] is the name of the completed app task.
/// [taskType] indicates the type of app task completed.
/// [completedAt] is the time this task was completed (in UTC).
/// [taskData] holds the result of the task, or null if no result is collected.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CompletedAppTask extends CompletedTask {
  /// The type of [AppTask] which was completed, if specified.
  ///
  /// Known types are:
  ///  - informed_consent - a task collecting informed consent from the user
  ///  - survey - a survey task
  ///  - cognition - a cognitive assessment task
  ///  - audio - an audio task
  ///  - video - a video task
  ///  - image - an image task
  ///  - health - a task collecting health data
  ///  - sensing - a task collecting sensing data
  String taskType;

  /// The time when the task was completed in UTC.
  late DateTime completedAt;

  /// Create a completed app task with the given [taskName] and [taskType],
  /// and optional [taskData].
  CompletedAppTask({
    required super.taskName,
    required this.taskType,
    super.taskData,
  }) : super() {
    completedAt = DateTime.now().toUtc();
  }

  /// Create a completed app task based on the given [userTask].
  CompletedAppTask.fromUserTask(UserTask userTask)
    : this(
        taskName: userTask.name,
        taskType: userTask.type,
        taskData: userTask.result,
      );

  @override
  bool equivalentTo(Data other) =>
      other is CompletedAppTask &&
      taskName == other.taskName &&
      taskType == other.taskType;

  // note that the jsonType is overridden to include the task type
  // in the form of 'completedapptask.<taskType>'
  @override
  String get jsonType => '${CamsDataTypes.COMPLETED_APP_TASK}.$taskType';

  @override
  Function get fromJsonFunction => _$CompletedAppTaskFromJson;
  factory CompletedAppTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CompletedAppTask>(json);
  @override
  Map<String, dynamic> toJson() => _$CompletedAppTaskToJson(this);
}
