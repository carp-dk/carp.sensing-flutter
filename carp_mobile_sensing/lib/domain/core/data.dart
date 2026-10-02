/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A [Data] object holding a link to a file, e.g. an audio recording or image.
///
/// The file itself is stored on the phone at [path]. A data manager can
/// upload the file in addition to this metadata, if [upload] is `true`.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FileData extends Data {
  /// The local path to the attached file on the phone where it is sampled.
  /// This is used by e.g. a data manager to get and manage the file on
  /// the phone.
  // @JsonKey(includeFromJson: false, includeToJson: false)
  String? path;

  /// The name of the attached file.
  String filename;

  /// Whether to upload the file too, or only this metadata. Default is `true`.
  bool upload = true;

  /// Metadata for this file as a map of string key-value pairs.
  Map<String, String>? metadata = <String, String>{};

  /// Creates a new [FileData] for [filename] and whether it is to be uploaded.
  FileData({required this.filename, this.upload = true}) : super();

  @override
  bool equivalentTo(Data other) => other is FileData && filename == other.filename;

  @override
  Function get fromJsonFunction => _$FileDataFromJson;
  factory FileData.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<FileData>(json);
  @override
  Map<String, dynamic> toJson() => _$FileDataToJson(this);
}

/// The measurement collected when the user completes an [AppTask].
///
/// [taskData] holds the result of the task (e.g. survey answers), or `null` if
/// the task has no result. Its JSON type is
/// `dk.cachet.carp.completedapptask.<taskType>`, so you can trigger on a
/// specific type of task with a [SamplingEventTrigger].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CompletedAppTask extends CompletedTask {
  /// The type of [AppTask] which was completed, if specified.
  ///
  /// Known types are the `*_TYPE` constants of [AppTask]:
  ///  * informed_consent - a task collecting informed consent from the user
  ///  * survey - a survey task
  ///  * cognition - a cognitive assessment task
  ///  * audio - an audio task
  ///  * video - a video task
  ///  * image - an image task
  ///  * health - a task collecting health data
  ///  * sensing - a task collecting sensing data
  String taskType;

  /// The time when the task was completed, in UTC. Set on creation.
  late DateTime completedAt;

  /// Creates a completed app task with the given `taskName` and [taskType],
  /// and optional `taskData`.
  CompletedAppTask({required super.taskName, required this.taskType, super.taskData}) : super() {
    completedAt = DateTime.now().toUtc();
  }

  /// Creates a completed app task based on the given [userTask].
  CompletedAppTask.fromUserTask(UserTask userTask)
    : this(taskName: userTask.name, taskType: userTask.type, taskData: userTask.result);

  @override
  bool equivalentTo(Data other) =>
      other is CompletedAppTask && taskName == other.taskName && taskType == other.taskType;

  // note that the jsonType is overridden to include the task type
  // in the form of 'completedapptask.<taskType>'
  @override
  String get jsonType => '${CamsDataTypes.COMPLETED_APP_TASK}.$taskType';

  @override
  Function get fromJsonFunction => _$CompletedAppTaskFromJson;
  factory CompletedAppTask.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<CompletedAppTask>(json);
  @override
  Map<String, dynamic> toJson() => _$CompletedAppTaskToJson(this);
}
