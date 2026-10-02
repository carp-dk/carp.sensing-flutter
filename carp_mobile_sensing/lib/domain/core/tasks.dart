/*
 * Copyright 2020-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Signature of a Dart function with no arguments and no return value.
typedef VoidFunction = void Function();

/// A task that can run a custom Dart function.
///
/// The [function] runs each time the task is resumed, see [FunctionTaskExecutor].
/// The function cannot be serialized to/from JSON, so it is lost when the
/// protocol is stored or retrieved from a [DeploymentService]. Use this task
/// only in a [StudyProtocol] built in Dart code in the app.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FunctionTask extends TaskConfiguration {
  /// The function to execute when this task is resumed.
  @JsonKey(includeFromJson: false, includeToJson: false)
  VoidFunction? function;

  /// Creates a function task that executes [function] when resumed.
  FunctionTask({super.name, super.description, this.function});

  @override
  Function get fromJsonFunction => _$FunctionTaskFromJson;

  factory FunctionTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<FunctionTask>(json);

  @override
  Map<String, dynamic> toJson() => _$FunctionTaskToJson(this);
}
