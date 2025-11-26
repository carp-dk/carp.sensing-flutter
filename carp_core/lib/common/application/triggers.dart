/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

/// Any condition on a device ([DeviceConfiguration]) which starts or stops
/// [TaskConfiguration]s at certain points in time when the condition applies.
/// The condition can either be time-bound, based on data streams,
/// initiated by a user of the platform, or a combination of these.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TriggerConfiguration extends Serializable {
  final String _triggerNamespace = 'dk.cachet.carp.common.application.triggers';

  /// The device role name from which the trigger originates.
  String? sourceDeviceRoleName;

  /// Determines whether the trigger needs to be evaluated on a primary
  /// device ([PrimaryDeviceConfiguration]).
  /// For example, this is the case when the trigger is time bound and needs
  /// to be evaluated by a task scheduler running on a primary device.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool? requiresPrimaryDevice;

  /// Create a trigger.
  TriggerConfiguration({this.sourceDeviceRoleName, this.requiresPrimaryDevice})
    : super();

  @override
  Function get fromJsonFunction => _$TriggerConfigurationFromJson;
  factory TriggerConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<TriggerConfiguration>(json);
  @override
  Map<String, dynamic> toJson() => _$TriggerConfigurationToJson(this);
  @override
  String get jsonType => '$_triggerNamespace.$runtimeType';

  @override
  String toString() =>
      '$runtimeType - sourceDeviceRoleName: $sourceDeviceRoleName';
}

/// An interface marking that a [TriggerConfiguration] can be scheduled.
///
/// Used when scheduling user tasks persistently on a phone.
abstract class Schedulable {}

/// A trigger which starts a task after [elapsedTime] has elapsed since the start
/// of a study deployment, i.e. when a protocol is deployed on the phone for
/// the first time.
///
/// Never stops sampling once started.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ElapsedTimeTrigger extends TriggerConfiguration implements Schedulable {
  /// Elapsed time since start of the study deployment.
  /// If null, sampling starts immediately.
  @JsonKey(toJson: _$IsoDurationToJson, fromJson: _$IsoDurationFromJson)
  Duration? elapsedTime;

  /// Create a trigger that starts after [elapsedTime] has elapsed since the start
  /// of the study deployment.
  ElapsedTimeTrigger({
    super.sourceDeviceRoleName,
    super.requiresPrimaryDevice = true,
    this.elapsedTime,
  });

  @override
  Function get fromJsonFunction => _$ElapsedTimeTriggerFromJson;
  factory ElapsedTimeTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ElapsedTimeTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$ElapsedTimeTriggerToJson(this);
}

/// A trigger initiated by a user, i.e., the user decides when to start a task.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ManualTrigger extends TriggerConfiguration {
  /// A short label to describe the action performed once the user chooses
  /// to initiate this trigger.
  String? label;

  /// An optional description elaborating on what happens when initiating
  /// this trigger.
  String? description;

  ManualTrigger({
    super.sourceDeviceRoleName,
    super.requiresPrimaryDevice = false,
    this.label,
    this.description,
  });

  @override
  Function get fromJsonFunction => _$ManualTriggerFromJson;
  factory ManualTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ManualTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$ManualTriggerToJson(this);
}

/// A trigger which starts a task according to a recurring schedule starting on
/// the date that the study starts.
///
/// The iCalendar RFC 5545 standard is used to specify the recurrence
/// rule: https://tools.ietf.org/html/rfc5545#section-3.3.10
///
/// This trigger needs to be evaluated on a primary device since it is time bound
/// and therefore requires a task scheduler.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ScheduledTrigger extends TriggerConfiguration implements Schedulable {
  /// The time of the day to trigger.
  TimeOfDay time;

  /// Recurrence rule according to the
  /// [iCalendar RFC 5545 standard](https://tools.ietf.org/html/rfc5545#section-3.3.10).
  RecurrenceRule recurrenceRule;

  /// Create a trigger that is scheduled at [time] and repeats according to the
  /// [recurrenceRule].
  ScheduledTrigger({
    super.sourceDeviceRoleName,
    super.requiresPrimaryDevice = false,
    required this.time,
    required this.recurrenceRule,
  });

  @override
  String toString() => '$runtimeType - time: $time, rrule: $recurrenceRule';

  @override
  Function get fromJsonFunction => _$ScheduledTriggerFromJson;
  factory ScheduledTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ScheduledTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$ScheduledTriggerToJson(this);
}

/// A time on a day in 24-hour format. Used in a [ScheduledTrigger].
///
/// Follows the conventions in the [DateTime] class, but only uses the Time
/// part in a 24 hour time format.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TimeOfDay {
  /// The hour in 24 hour format.
  final int hour;

  /// The minute 0-59.
  final int minute;

  /// The second 0-59.
  final int second;

  /// Constructs an instance of [TimeOfDay].
  const TimeOfDay({this.hour = 0, this.minute = 0, this.second = 0})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60),
      assert(second >= 0 && second < 60),
      super();

  /// Creates a [TimeOfDay] based on the given [time].
  TimeOfDay.fromDateTime(DateTime time)
    : hour = time.hour,
      minute = time.minute,
      second = time.second;

  /// Constructs a [TimeOfDay] instance with current time in the
  /// local time zone.
  factory TimeOfDay.now() => TimeOfDay.fromDateTime(DateTime.now());

  /// Returns true if [this] occurs before [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in
  /// the local time zone.
  bool isBefore(TimeOfDay other) => DateTime(
    2021,
    1,
    1,
    hour,
    minute,
    second,
  ).isBefore(DateTime(2021, 1, 1, other.hour, other.minute, other.second));

  /// Returns true if [this] occurs after [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in
  /// the local time zone.
  bool isAfter(TimeOfDay other) => DateTime(
    2021,
    1,
    1,
    hour,
    minute,
    second,
  ).isAfter(DateTime(2021, 1, 1, other.hour, other.minute, other.second));

  /// Returns a [Duration] with the difference when subtracting [other] from
  /// [this].
  ///
  ///  The returned [Duration] will be negative if [other] occurs after [this].
  Duration difference(TimeOfDay other) => DateTime(
    2021,
    1,
    1,
    hour,
    minute,
    second,
  ).difference(DateTime(2021, 1, 1, other.hour, other.minute, other.second));

  static String _twoDigits(int n) => (n >= 10) ? '$n' : '0$n';

  factory TimeOfDay.fromJson(Map<String, dynamic> json) =>
      _$TimeOfDayFromJson(json);
  Map<String, dynamic> toJson() => _$TimeOfDayToJson(this);

  /// Output as ISO 8601 extended time format with seconds accuracy, omitting
  /// the 24th hour and 60th leap second. E.g., "09:30:00".
  @override
  String toString() =>
      '${_twoDigits(hour)}:${_twoDigits(minute)}:${_twoDigits(second)}';
}

/// Represents the iCalendar RFC 5545 standard recurrence rule to specify
/// repeating events: https://tools.ietf.org/html/rfc5545#section-3.3.10
///
/// However, since date times are relative to the start time of a study,
/// they are replaced with time spans representing elapsed time since the
/// start of the study.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RecurrenceRule {
  /// Specifies the type of interval at which to repeat events, or multiples thereof.
  final Frequency frequency;

  /// The interval at which [frequency] repeats.
  /// The default is 1. For example, with [Frequency.DAILY], a value
  /// of "8" means every eight days.
  int interval = 1;

  /// Specifies when, if ever, to stop repeating events.
  /// Default recurrence is forever.
  End end = End.never();

  RecurrenceRule(this.frequency, {this.interval = 1, End? end}) : super() {
    this.end = end ?? End.never();
  }

  /// Initialize a [RecurrenceRule] based on a [rrule] string.
  factory RecurrenceRule.fromString(String rrule) {
    var str = rrule.substring(rrule.indexOf('RRULE:') + 6);
    var parameters = <String, String>{};
    str.split(';').forEach((element) {
      var par = element.split('=');
      parameters[par[0]] = par[1];
    });

    var frequency = Frequency.DAILY;
    for (var element in Frequency.values) {
      if (element.name == parameters['FREQ']) frequency = element;
    }

    var end = End.never();
    int interval = 1;
    parameters.forEach((key, value) {
      switch (key) {
        case 'INTERVAL':
          interval = int.tryParse(value) ?? 1;
          break;
        case 'UNTIL':
          end = End.until(Duration(milliseconds: int.tryParse(value) ?? 1));
          break;
        case 'COUNT':
          end = End.count(int.tryParse(value) ?? 1);
          break;
        default:
      }
    });

    return RecurrenceRule(frequency, interval: interval, end: end);
  }

  /// A valid RFC 5545 string representation of this recurrence rule, except
  /// when [end] is specified as [End.Until].
  /// When [End.Until] is specified, 'UNTIL' holds the total number of microseconds
  /// which need to be added to a desired start date.
  /// 'UNTIL' should be reassigned to a calculated end date time, formatted using
  /// the RFC 5545 specifications: https://tools.ietf.org/html/rfc5545#section-3.3.5
  @override
  String toString() {
    String rule = 'RRULE:FREQ=${frequency.name}';
    rule += (interval != 1) ? ';INTERVAL=$interval' : '';
    rule += (end.type != EndType.NEVER) ? ';$end' : '';

    return rule;
  }

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) =>
      _$RecurrenceRuleFromJson(json);
  Map<String, dynamic> toJson() => _$RecurrenceRuleToJson(this);
}

/// Specify repeating events in a [RecurrenceRule] based on an interval of a
/// chosen type or multiples thereof.
enum Frequency { SECONDLY, MINUTELY, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY }

/// Specify how a [RecurrenceRule] may end as specified in [End].
enum EndType { UNTIL, COUNT, NEVER }

/// Specify how a [RecurrenceRule] ends.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class End {
  final EndType type;
  final Duration? elapsedTime;
  final int? count;

  End(this.type, {this.elapsedTime, this.count}) : super();

  /// Bounds the recurrence rule in an inclusive manner to the associated
  /// start date of this rule plus [elapsedTime].
  factory End.until(Duration elapsedTime) =>
      End(EndType.UNTIL, elapsedTime: elapsedTime);

  /// Specify a number of occurrences at which to range-bound the recurrence.
  /// The start date time always counts as the first occurrence.
  factory End.count(int count) => End(EndType.COUNT, count: count);

  /// The recurrence repeats forever.
  factory End.never() => End(EndType.NEVER);

  @override
  String toString() {
    switch (type) {
      case EndType.UNTIL:
        return 'UNTIL=${elapsedTime!.inMilliseconds}';
      case EndType.COUNT:
        return 'COUNT=$count';
      case EndType.NEVER:
        return '';
    }
  }

  factory End.fromJson(Map<String, dynamic> json) => _$EndFromJson(json);
  Map<String, dynamic> toJson() => _$EndToJson(this);
}
