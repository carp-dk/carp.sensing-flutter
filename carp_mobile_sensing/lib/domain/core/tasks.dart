/*
 * Copyright 2020-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Signature of Dart function that have no arguments and returns no data.
typedef VoidFunction = void Function();

/// A task that can run a custom Dart function.
///
/// Note that the [function] to be executed is specified as a Dart function,
/// which cannot be serialized to/from JSON.
/// Thus, even though this trigger can be de/serialized from/to JSON, its
/// [function] cannot.
/// This implies that this function cannot be retrieved as part of a [StudyProtocol]
/// from a [DeploymentService] since it relies on specifying a Dart-specific function.
/// Hence, this trigger is mostly useful when creating a [StudyProtocol] directly
/// in the app using Dart code.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class FunctionTask extends TaskConfiguration {
  /// The function to execute when this task is resumed.
  @JsonKey(includeFromJson: false, includeToJson: false)
  VoidFunction? function;

  /// Create a function task that executed [function] when resumed.
  FunctionTask({super.name, super.description, this.function});

  @override
  Function get fromJsonFunction => _$FunctionTaskFromJson;

  factory FunctionTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<FunctionTask>(json);

  @override
  Map<String, dynamic> toJson() => _$FunctionTaskToJson(this);
}
