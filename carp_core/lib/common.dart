/// Contains common CARP domain classes which are used across the libraries.
library;

import 'dart:io';

import 'package:iso_duration_parser/iso_duration_parser.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';

part 'common/application/account.dart';
part 'common/infrastructure/service_request.dart';
part 'common/application/users.dart';
part 'common/application/measure.dart';
part 'common/application/tasks.dart';
part 'common/application/task_control.dart';
part 'common/application/devices/device_configuration.dart';
part 'common/application/devices/device_registration.dart';
part 'common/application/devices/smartphone.dart';
part 'common/application/devices/personal_computer.dart';
part 'common/application/devices/web_browser.dart';
part 'common/application/devices/alt_beacon.dart';
part 'common/application/devices/heart_rate_device.dart';
part 'common/application/triggers.dart';
part 'common/application/sampling/configurations.dart';
part 'common/application/sampling/schemes.dart';
part 'common/application/data_type.dart';
part 'common/application/data_types.dart';
part 'common/application/data.dart';
part 'common/application/input_data.dart';

part 'common.g.dart';

/// Exception thrown when the application is in an illegal state.
class IllegalStateException implements Exception {
  final String message;
  IllegalStateException(this.message);
  @override
  String toString() => "IllegalStateException: $message";
}

/// Exception thrown when the argument provided to a method is invalid.
class IllegalArgumentException implements Exception {
  final String message;
  IllegalArgumentException(this.message);
  @override
  String toString() => "IllegalArgumentException: $message";
}

/// Exception thrown when a required component has not been configured properly.
class NotConfiguredException implements Exception {
  final String message;
  NotConfiguredException(this.message);
  @override
  String toString() => "NotConfiguredException: $message";
}

/// An immutable snapshot of a CARP Core domain object.
/// Used as the base class for serializable CARP domain objects.
abstract class Snapshot {
  /// Unique id for this object.
  late String id;

  /// The date when the object represented by this snapshot was created.
  late DateTime createdOn;

  /// The number of edits made to the object represented by this snapshot,
  /// indicating its version number.
  late int version;

  Snapshot([String? id]) {
    version = 0;
    this.id = id ?? const Uuid().v1;
    createdOn = DateTime.now().toUtc();
  }
}

/// Deserialization of [isoString] according to the ISO 8061 standard to [Duration]
Duration? _$IsoDurationFromJson(String? isoString) => (isoString != null)
    ? Duration(seconds: IsoDuration.tryParse(isoString)!.toSeconds().round())
    : null;

/// Serialization of [Duration] to a ISO 8061 string.
String? _$IsoDurationToJson(Duration? duration) => (duration != null)
    ? IsoDuration(seconds: duration.inSeconds.roundToDouble()).toIso()
    : null;
