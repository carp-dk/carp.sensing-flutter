/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../common.dart';

/// Describes requested measures to be collected by a device.
///
/// A [TaskConfiguration] holds information about each task to be triggered by
/// a [TriggerConfiguration] as part of a [TaskControl].
/// Each task holds a list of [Measure]s to be done as part of this task.
/// A [TaskConfiguration] is hence an aggregation of [Measure]s.
///
/// Note that the [name] of the task identifies the task and has to be unique
/// within a study deployment.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TaskConfiguration extends Serializable {
  static int _counter = 0;

  /// A name which uniquely identifies the task.
  late String name;

  /// The data which needs to be collected/measured passively as part of this task.
  List<Measure>? measures = [];

  /// A description of this task, emphasizing the reason why the data is collected.
  String? description;

  /// Get data types of all data which may be collected, either passively as part
  /// of task measures, or as the result of user interactions, for this task.
  Set<String> getAllExpectedDataTypes() =>
      (measures?.map((measure) => measure.type).toSet() ?? {})
        ..add(CarpDataTypes.COMPLETED_TASK);

  /// Add [measure] to this task.
  void addMeasure(Measure measure) => measures!.add(measure);

  /// Add a [list] of measures to this task.
  void addMeasures(Iterable<Measure> list) => measures!.addAll(list);

  /// Remove [measure] from this task.
  void removeMeasure(Measure measure) => measures!.remove(measure);

  /// Create a task. The [name] uniquely identifies the task.
  /// If [name] is not specified, a name is generated.
  TaskConfiguration({String? name, this.description, List<Measure>? measures})
    : super() {
    this.name = name ?? 'Task #${_counter++}';
    // Remove duplicates by converting to a set and back to a list.
    this.measures = measures?.toSet().toList() ?? [];
  }

  @override
  Function get fromJsonFunction => _$TaskConfigurationFromJson;
  factory TaskConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<TaskConfiguration>(json);
  @override
  Map<String, dynamic> toJson() => _$TaskConfigurationToJson(this);
  @override
  String get jsonType => 'dk.cachet.carp.common.application.tasks.$runtimeType';

  @override
  String toString() =>
      '$runtimeType - name: $name, measures size: ${measures?.length}';
}

/// A task which is used for monitoring the execution of the data sampling
/// collecting data on [CompletedTask], [TriggeredTask], and [Error].
/// This task is not supposed to be executed as such, but allows the addition
/// of such monitoring measure to be added to a protocol.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MonitoringTask extends TaskConfiguration {
  /// Create a new monitoring task.
  MonitoringTask({super.name, super.description, super.measures});

  @override
  Function get fromJsonFunction => _$MonitoringTaskFromJson;
  factory MonitoringTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MonitoringTask>(json);
  @override
  Map<String, dynamic> toJson() => _$MonitoringTaskToJson(this);
}

/// A task which specifies that all containing measures and/or
/// outputs should immediately start running in the background once triggered.
/// The task runs for the specified [duration], or until stopped, or until
/// all measures and/or outputs have completed.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BackgroundTask extends TaskConfiguration {
  /// The optional duration over the course of which the [measures] need to
  /// be sampled.
  /// Null implies infinite by default.
  @JsonKey(toJson: _$IsoDurationToJson, fromJson: _$IsoDurationFromJson)
  Duration? duration;

  /// Create a new task which can run in the background.
  BackgroundTask({
    super.name,
    super.description,
    super.measures,
    this.duration,
  });

  @override
  Function get fromJsonFunction => _$BackgroundTaskFromJson;
  factory BackgroundTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BackgroundTask>(json);
  @override
  Map<String, dynamic> toJson() => _$BackgroundTaskToJson(this);
}

/// A task which contains a definition of a custom protocol which differs from
/// the CARP domain model.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CustomProtocolTask extends TaskConfiguration {
  /// A definition on how to run a study on a primary device, serialized as a string.
  String studyProtocol;

  /// Create a task which is used in a custom protocol, specified as a
  /// string in [studyProtocol].
  CustomProtocolTask({
    super.name,
    super.description,
    required this.studyProtocol,
    // The measures list is empty, since measures are defined in [studyProtocol]
    // in a different format.
  }) : super(measures: []);

  @override
  Function get fromJsonFunction => _$CustomProtocolTaskFromJson;
  factory CustomProtocolTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CustomProtocolTask>(json);
  @override
  Map<String, dynamic> toJson() => _$CustomProtocolTaskToJson(this);

  @override
  String toString() => '${super.toString()}, studyProtocol: $studyProtocol';
}

/// Redirects to a web page which contains the task which needs to be performed.
/// The passive [measures] are started when the website is opened and stopped
/// when it is closed.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class WebTask extends TaskConfiguration {
  /// The URL of the web page which contains the task to be performed.
  ///
  /// The URL may contain the following patterns, which will be replaced with
  /// the corresponding values by the client runtime:
  ///
  ///  * `$PARTICIPANT_ID` - Uniquely identifies the participant in the study.
  ///  * `$DEPLOYMENT_ID` - Uniquely identifies the deployment (group of participants
  ///     and devices) of the study.
  ///  * `$TRIGGER_ID` - Identifies the condition, defined by the study protocol,
  ///     which caused the [WebTask] to be triggered.
  ///
  String url;

  /// Create a task which redirects to a web page [url].
  WebTask({super.name, super.description, super.measures, required this.url});

  /// Replace the variables in [url] with the specified runtime values,
  /// if the variables are present.
  String getUrl(
    String participantId,
    String studyDeploymentId,
    int triggerId,
  ) => url
      .replaceFirst('\$PARTICIPANT_ID', participantId)
      .replaceFirst('\$DEPLOYMENT_ID', studyDeploymentId)
      .replaceFirst('\$TRIGGER_ID', triggerId.toString());

  @override
  Function get fromJsonFunction => _$WebTaskFromJson;
  factory WebTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<WebTask>(json);
  @override
  Map<String, dynamic> toJson() => _$WebTaskToJson(this);

  @override
  String toString() => '${super.toString()}, url: $url';
}
