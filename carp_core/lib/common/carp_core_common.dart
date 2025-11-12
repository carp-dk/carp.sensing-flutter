/// Contains common CARP domain classes which are used across the libraries.
library;

import 'dart:io';

import 'package:iso_duration_parser/iso_duration_parser.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';

part 'application/account.dart';
part 'infrastructure/service_request.dart';
part 'application/users.dart';
part 'application/measure.dart';
part 'application/tasks.dart';
part 'application/task_control.dart';
part 'application/devices/device_configuration.dart';
part 'application/devices/device_registration.dart';
part 'application/devices/smartphone.dart';
part 'application/devices/personal_computer.dart';
part 'application/devices/web_browser.dart';
part 'application/devices/alt_beacon.dart';
part 'application/devices/heart_rate_device.dart';
part 'application/triggers.dart';
part 'application/sampling/configurations.dart';
part 'application/sampling/schemes.dart';
part 'application/data_type.dart';
part 'application/data_types.dart';
part 'application/data.dart';
part 'application/input_data.dart';

part 'carp_core_common.g.dart';

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
