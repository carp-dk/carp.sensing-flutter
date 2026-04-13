/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// A trigger that does nothing.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class NoOpTrigger extends TriggerConfiguration {
  /// Create a trigger that starts sampling immediately and never stops.
  NoOpTrigger() : super();

  @override
  Function get fromJsonFunction => _$NoOpTriggerFromJson;
  factory NoOpTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<NoOpTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$NoOpTriggerToJson(this);
}

/// A trigger that starts sampling immediately and never stops.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ImmediateTrigger extends TriggerConfiguration {
  /// Create a trigger that starts sampling immediately and never stops.
  ImmediateTrigger() : super();

  @override
  Function get fromJsonFunction => _$ImmediateTriggerFromJson;
  factory ImmediateTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ImmediateTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$ImmediateTriggerToJson(this);
}

/// A trigger that triggers only once during a deployment.
///
/// In contrast to [ImmediateTrigger], which triggers every time the app is (re)started,
/// this [OneTimeTrigger] only triggers *once* during the life-time of a deployment.
/// Useful for triggering e.g., a demographic survey or collecting device
/// information.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OneTimeTrigger extends TriggerConfiguration {
  /// The timestamp of when this trigger was triggered.
  DateTime? triggerTimestamp;

  /// Has this trigger been triggered?
  bool get hasBeenTriggered => triggerTimestamp != null;

  /// Create a trigger that triggers once during a deployment.
  OneTimeTrigger() : super();

  @override
  Function get fromJsonFunction => _$OneTimeTriggerFromJson;
  factory OneTimeTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OneTimeTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$OneTimeTriggerToJson(this);
}

/// A trigger that trigger when the [trigger] method is called from Dart code.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PassiveTrigger extends TriggerConfiguration {
  /// Create a trigger that triggers when the [trigger] method is called.
  PassiveTrigger() : super();

  @JsonKey(includeFromJson: false, includeToJson: false)
  /// The [TriggerExecutor] that backs this trigger.
  ///
  /// Set automatically by the runtime when the trigger executor is created.
  /// Do not set this manually.
  late TriggerExecutor executor;

  /// Called when this trigger is to be triggered.
  void trigger() => executor.onTrigger();

  @override
  Function get fromJsonFunction => _$PassiveTriggerFromJson;
  factory PassiveTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PassiveTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$PassiveTriggerToJson(this);
}

/// A trigger that triggers after [delay] from the (re)start of the app.
///
/// The delay is measured from the **start of sensing**, i.e. typically when
/// the `start()` method is called on a [SmartphoneStudyController].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DelayedTrigger extends TriggerConfiguration {
  /// Delay before this trigger is executed.
  Duration delay;

  /// Create a trigger that delays for [delay] and then triggers.
  /// Default is no delay.
  DelayedTrigger({this.delay = const Duration()}) : super();

  @override
  Function get fromJsonFunction => _$DelayedTriggerFromJson;
  factory DelayedTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DelayedTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$DelayedTriggerToJson(this);
}

/// A trigger that triggers every [period].
///
/// Daily, weekly and monthly recurrent triggers can be specified using the
/// [RecurrentScheduledTrigger].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PeriodicTrigger extends TriggerConfiguration implements Schedulable {
  /// The period (reciprocal of frequency) of sampling.
  Duration period;

  /// Create a trigger that triggers every [period].
  PeriodicTrigger({required this.period}) : super();

  @override
  Function get fromJsonFunction => _$PeriodicTriggerFromJson;
  factory PeriodicTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PeriodicTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$PeriodicTriggerToJson(this);
}

/// A trigger that triggers on a specific date and time.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DateTimeTrigger extends TriggerConfiguration implements Schedulable {
  /// The scheduled date and time for resuming sampling.
  DateTime schedule;

  /// Create a trigger that triggers based on a [schedule].
  DateTimeTrigger({required this.schedule}) : super();

  @override
  Function get fromJsonFunction => _$DateTimeTriggerFromJson;
  factory DateTimeTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<DateTimeTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$DateTimeTriggerToJson(this);
}

/// A trigger that triggers based on a recurrent scheduled date and time.
///
/// Supports daily, weekly and monthly recurrences. Yearly recurrence is not
/// supported, since data sampling is not intended to run on such long time scales.
///
/// Here are a couple of examples:
///
/// ```
///  // trigger every day at 13:30
///  RecurrentScheduledTrigger(type: RecurrentType.daily, time: TimeOfDay(hour: 13, minute: 30));
///
///  // trigger every other day at 13:30
///  RecurrentScheduledTrigger(type: RecurrentType.daily, separationCount: 1, time: TimeOfDay(hour: 13, minute: 30));
///
///  // trigger every wednesday at 12:23
///  RecurrentScheduledTrigger(type: RecurrentType.weekly, dayOfWeek: DateTime.wednesday, time: TimeOfDay(hour: 12, minute: 23));
///
///  // trigger every 2nd monday at 12:23
///  RecurrentScheduledTrigger(type: RecurrentType.weekly, dayOfWeek: DateTime.monday, separationCount: 1, time: TimeOfDay(hour: 12, minute: 23));
///
///  // trigger monthly in the second week on a monday at 14:30
///  RecurrentScheduledTrigger(type: RecurrentType.monthly, weekOfMonth: 2, dayOfWeek: DateTime.monday, time: TimeOfDay(hour: 14, minute: 30));
///
///  // trigger quarterly on the 11th day of the first month in each quarter at 21:30
///  RecurrentScheduledTrigger(type: RecurrentType.monthly, dayOfMonth: 11, separationCount: 2, time: TimeOfDay(hour: 21, minute: 30));
/// ```
///
/// Thanks to Shantanu Kher for inspiration in his blog post on
/// [Again and Again! Managing Recurring Events In a Data Model](https://www.vertabelo.com/blog/technical-articles/again-and-again-managing-recurring-events-in-a-data-model).
/// We are, however, not using yearly recurrence.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RecurrentScheduledTrigger extends TriggerConfiguration
    implements Schedulable {
  static const int daysPerWeek = 7;
  static const int daysPerMonth = 30;

  /// The type of recurrence - daily, weekly or monthly.
  RecurrentType type;

  /// The time of day of this trigger.
  TimeOfDay time;

  /// End time and date. If [null], this trigger keeps sampling forever.
  DateTime? end;

  /// Separation between recurrences.
  ///
  /// This value signifies the interval (in days, weeks or months) before the next
  /// event instance is allowed. For example, if an event needs to be configured
  /// for every other week, then [separationCount] is `1`.
  /// The default value is `0`.
  int separationCount = 0;

  /// Maximum number of samplings.
  ///
  /// There are times when we do not know the exact end time and date for
  /// recurrent sampling. But we might know how many occurrences (samplings)
  /// are needed to complete it.
  int? maxNumberOfSampling;

  /// If weekly recurrence, specify which day of week.
  ///
  /// Stores which day of the week this sampling will take place according to [
  /// DateTime] standards, i.e. having Monday as the first day of the week and
  /// Sunday as the last.
  int? dayOfWeek;

  /// If monthly recurrence, specify the week in the month.
  ///
  /// [weekOfMonth] is used for samplings that are scheduled for a certain
  /// week of the month – i.e., the first, second, etc.
  /// Possible values are 1,2,3,4. The first week is the week of the first
  /// Monday of a month. For example, the first week of September 2020 is the
  /// week starting on Monday 2020-09-07.
  int? weekOfMonth;

  /// If monthly recurrence, specify the day of the month.
  ///
  /// Used in cases when an event is scheduled on a particular day of the month,
  /// say the 25th. Possible numbers are 1..31 counting from the start of a month.
  int? dayOfMonth;

  /// Create a trigger that triggers based on a recurrent scheduled date and time.
  RecurrentScheduledTrigger({
    this.type = RecurrentType.daily,
    this.time = const TimeOfDay(),
    this.end,
    this.separationCount = 0,
    this.maxNumberOfSampling,
    this.dayOfWeek,
    this.weekOfMonth,
    this.dayOfMonth,
    Duration? duration,
  }) : super() {
    assert(separationCount >= 0, 'Separation count must be zero or positive.');
    if (type == RecurrentType.weekly) {
      assert(
        dayOfWeek != null,
        'dayOfWeek must be specified in a weekly recurrence.',
      );
    } else if (type == RecurrentType.monthly) {
      assert(
        weekOfMonth != null || dayOfMonth != null,
        'Specify monthly recurrence using either dayOfMonth or weekOfMonth',
      );
      assert(
        dayOfMonth == null || (dayOfMonth! >= 1 && dayOfMonth! <= 31),
        'dayOfMonth must be in the range [1-31]',
      );
      assert(
        weekOfMonth == null || (weekOfMonth! >= 1 && weekOfMonth! <= 4),
        'weekOfMonth must be in the range [1-4]',
      );
    }
  }

  /// The next day in a monthly occurrence from the given [fromDate].
  DateTime nextMonthlyDay(DateTime fromDate) => fromDate
      .subtract(Duration(days: fromDate.weekday - 1))
      .add(Duration(days: 7 * weekOfMonth! + dayOfWeek! - 1));

  /// The date and time of the first occurrence of this trigger.
  DateTime get firstOccurrence {
    late DateTime firstDay;
    DateTime now = DateTime.now();
    DateTime start = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );

    switch (type) {
      case RecurrentType.daily:
        firstDay = (start.isAfter(now))
            ? start
            : start.add(const Duration(hours: 24));
        break;
      case RecurrentType.weekly:
        int days = dayOfWeek! - now.weekday;
        days = (days < 0) ? days + daysPerWeek : days;
        firstDay = start.add(Duration(days: days));
        // check if this is the same day, but a time slot earlier this day
        firstDay = (firstDay.isBefore(now))
            ? firstDay.add(const Duration(days: daysPerWeek))
            : firstDay;
        break;
      case RecurrentType.monthly:
        if (dayOfMonth != null) {
          // we have a trigger of the following type: collect quarterly on the 11th day of the first month in each quarter at 21:30
          //   RecurrentScheduledTrigger(type: RecurrentType.monthly, dayOfMonth: 11, separationCount: 2, time: Time(hour: 21, minute: 30));
          int days = dayOfMonth! - now.day;
          int month = (days > 0)
              ? now.month + separationCount
              : now.month + separationCount + 1;
          int year = now.year;
          if (month > 12) {
            year = now.year + 1;
            month = month - DateTime.monthsPerYear;
          }
          firstDay = DateTime(year, month, dayOfMonth!);
        } else {
          // we have a trigger of the following type: collect monthly in the second week on a monday at 14:30
          //   RecurrentScheduledTrigger(type: RecurrentType.monthly, weekOfMonth: 2, dayOfWeek: DateTime.monday, time: Time(hour: 14, minute: 30));
          firstDay = nextMonthlyDay(DateTime(now.year, now.month, 1));
          // check if this day is in the past - if so, move one month forward
          if (firstDay.isBefore(now)) {
            firstDay = nextMonthlyDay(DateTime(now.year, now.month + 1, 1));
          }
        }
        break;
    }

    return DateTime(
      firstDay.year,
      firstDay.month,
      firstDay.day,
      time.hour,
      time.minute,
      time.second,
    );
  }

  /// The period between the recurring samplings.
  Duration get period {
    switch (type) {
      case RecurrentType.daily:
        return Duration(days: separationCount + 1);
      case RecurrentType.weekly:
        return Duration(days: (separationCount + 1) * daysPerWeek);
      case RecurrentType.monthly:
        // @TODO - this is not a correct model...
        // the period in monthly recurring triggers is not fixed, but depends on the specific month(s)
        // but the current implementation of the [RecurrentScheduledTriggerExecutor] expects a fixed period
        return Duration(days: (separationCount + 1) * daysPerMonth);
    }
  }

  @override
  Function get fromJsonFunction => _$RecurrentScheduledTriggerFromJson;
  factory RecurrentScheduledTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<RecurrentScheduledTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$RecurrentScheduledTriggerToJson(this);

  @override
  String toString() =>
      '$runtimeType - type: $type, time: $time, separationCount: $separationCount, dayOfWeek: $dayOfWeek, firstOccurrence: $firstOccurrence, period; $period';
}

/// Type of recurrence for a [RecurrentScheduledTrigger].
enum RecurrentType {
  daily,
  weekly,
  monthly,
  //yearly,
}

/// A trigger that triggers based on a cron job specification.
///
/// Bases on the [`cron`](https://pub.dev/packages/cron) package.
/// See [crontab guru](https://crontab.guru) for a useful tool for specifying cron jobs.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CronScheduledTrigger extends TriggerConfiguration implements Schedulable {
  /// The cron job expression.
  String cronExpression;

  /// Create a cron scheduled trigger based on specifying:
  ///   * [minute] - The minute to trigger. `int` [0-59] or `null` (= match all).
  ///   * [hour] - The hour to trigger. `int` [0-23] or `null` (= match all).
  ///   * [day] - The day of the month to trigger. `int` [1-31] or `null` (= match all).
  ///   * [month] - The month to trigger. `int` [1-12] or `null` (= match all).
  ///   * [weekday] - The week day to trigger. `int` [0-6] or `null` (= match all).
  factory CronScheduledTrigger({
    int? minute,
    int? hour,
    int? day,
    int? month,
    int? weekday,
  }) {
    assert(
      minute == null || (minute >= 0 && minute <= 59),
      'minute must be in the range of [0-59] or null (=match all).',
    );
    assert(
      hour == null || (hour >= 0 && hour <= 23),
      'hour must be in the range of [0-23] or null (=match all).',
    );
    assert(
      day == null || (day >= 1 && day <= 31),
      'day must be in the range of [1-31] or null (=match all).',
    );
    assert(
      month == null || (month >= 1 && month <= 12),
      'month must be in the range of [1-12] or null (=match all).',
    );
    assert(
      weekday == null || (weekday >= 0 && weekday <= 6),
      'weekday must be in the range of [0-6] or null (=match all).',
    );
    return CronScheduledTrigger._(
      cronExpression: _cronToString(minute, hour, day, month, weekday),
    );
  }

  /// Create a [CronScheduledTrigger] based on a cron-formatted string expression.
  ///
  ///   * [cronExpression] - The cron expression as a `String`.
  ///   * [duration] - The duration (until stopped) of the the sampling.
  ///
  /// Cron format used is:
  ///
  ///    `<minutes> <hours> <days> <months> <weekdays>`
  ///
  /// For example:
  ///  * `42 19 * * *` is "Everyday at 19:42".
  ///  * `0 9 * * 1` is "Every Monday at 09:00".
  ///  * `0 0 1 * *` is "The first day of every month at midnight".
  ///
  /// Note the following:
  /// * the fields are separated by spaces
  /// * that `*` is used to signify "match all"
  /// * that the weekday field uses `0` for Sunday
  /// * that the number fields are numbered from `0` (minutes, weekdays) or `1` (hours, days, months)
  /// * that numbers are single values - ranges and lists are not supported
  /// * that number are to be stated as integers, and not a string with leading zeros (e.g., use `9` and not `09` for 9 o'clock)
  ///
  /// See e.g. [crontab guru](https://crontab.guru/) for help in formatting cron jobs.
  factory CronScheduledTrigger.parse({
    required String cronExpression,
    Duration? duration,
  }) => CronScheduledTrigger._(cronExpression: cronExpression);

  CronScheduledTrigger._({required this.cronExpression}) : super();

  static String _cronToString(
    int? minute,
    int? hour,
    int? day,
    int? month,
    int? weekday,
  ) => '${_cf(minute)} ${_cf(hour)} ${_cf(day)} ${_cf(month)} ${_cf(weekday)}';
  static String _cf(int? exp) => (exp == null) ? '*' : exp.toString();

  @override
  Function get fromJsonFunction => _$CronScheduledTriggerFromJson;
  factory CronScheduledTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CronScheduledTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$CronScheduledTriggerToJson(this);

  @override
  String toString() => "$runtimeType - cron expression: '$cronExpression'";
}

/// A trigger that triggers when some sampling event occurs.
///
/// For example, if [measureType] is [CompletedAppTask.dataType] the [triggerCondition]
/// can be a [CompletedAppTask] with a specific [CompletedAppTask.taskName].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class SamplingEventTrigger extends TriggerConfiguration {
  /// The data type of the event to look for.
  ///
  /// If [triggerCondition] is null, sampling will be triggered for all events
  /// of this type.
  String measureType;

  /// The specific sampling value to compare with for triggering this trigger.
  ///
  /// When comparing, the [Data.equivalentTo] method is used. Hence, the
  /// sampled data must be "equivalent" to this [triggerCondition] in order to
  /// trigger based on an event.
  /// Note that the `equivalentTo` method must be overwritten in
  /// application-specific [Data] classes to support this.
  ///
  /// If [triggerCondition] is null, sampling will be triggered on
  /// every sampling event that matches the specified [measureType].
  Data? triggerCondition;

  /// Create a trigger that triggers when a measure of [measureType] is collected,
  /// and checks the [triggerCondition] to determine if it should trigger.
  SamplingEventTrigger({required this.measureType, this.triggerCondition})
    : super();

  @override
  Function get fromJsonFunction => _$SamplingEventTriggerFromJson;
  factory SamplingEventTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<SamplingEventTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$SamplingEventTriggerToJson(this);
}

/// Takes a [Measurement] from a sampling stream and evaluates if an event has
/// occurred. Returns [true] if the event has occurred, [false] otherwise.
typedef ConditionalEventEvaluator = bool Function(Measurement measurement);

/// A trigger that triggers when some (other) sampling event
/// occurs and a application-specific condition is meet.
///
/// Note that the [triggerCondition] is a [ConditionalEvaluator] function,
/// which cannot be serialized to/from JSON.
/// Thus, even though this trigger can be de/serialized from/to JSON, its
/// [triggerCondition] cannot.
/// This implies that this function cannot be retrieved as part of a [StudyProtocol]
/// from a [DeploymentService] since it relies on specifying a Dart-specific function as
/// the [ConditionalEvaluator] methods. Hence, this trigger is mostly
/// useful when creating a [StudyProtocol] directly in the app using Dart code.
///
/// If you need to de/serialize an event trigger, use the [SamplingEventTrigger]
/// instead.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ConditionalSamplingEventTrigger extends TriggerConfiguration {
  /// The data type of the event to look for.
  String measureType;

  /// The [ConditionalEventEvaluator] function evaluating if the event
  /// condition is meet for triggering this trigger
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConditionalEventEvaluator? triggerCondition;

  /// Create a trigger that triggers when a measure of [measureType] is collected,
  /// and checks the [triggerCondition] to determine if the
  /// task should be triggered.
  ConditionalSamplingEventTrigger({
    required this.measureType,
    this.triggerCondition,
  }) : super();

  @override
  Function get fromJsonFunction => _$ConditionalSamplingEventTriggerFromJson;
  factory ConditionalSamplingEventTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ConditionalSamplingEventTrigger>(json);
  @override
  Map<String, dynamic> toJson() =>
      _$ConditionalSamplingEventTriggerToJson(this);
}

/// Evaluates if a [ConditionalPeriodicTrigger] should trigger.
/// Returns [true] if triggering should happen, [false] otherwise.
typedef ConditionalEvaluator = bool Function();

/// A trigger that periodically checks if an application-specific  triggering
/// condition is met.
///
/// Note that the [triggerCondition] is a [ConditionalEvaluator] function,
/// which cannot be serialized to/from JSON.
/// Thus, even though this trigger can be de/serialized from/to JSON, its
/// [triggerCondition] cannot.
/// This implies that this function cannot be retrieved as part of a [StudyProtocol]
/// from a [DeploymentService] since it relies on specifying a Dart-specific function as
/// the [ConditionalEvaluator] methods. Hence, this trigger is mostly
/// useful when creating a [StudyProtocol] directly in the app using Dart code.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ConditionalPeriodicTrigger extends TriggerConfiguration {
  /// The period of when to check the [triggerCondition].
  Duration period;

  /// The [ConditionalEventEvaluator] function evaluating if the event
  /// condition is meet for triggering this trigger
  @JsonKey(includeFromJson: false, includeToJson: false)
  ConditionalEvaluator? triggerCondition;

  /// Create a [ConditionalSamplingEventTrigger].
  ConditionalPeriodicTrigger({required this.period, this.triggerCondition})
    : super();

  @override
  Function get fromJsonFunction => _$ConditionalPeriodicTriggerFromJson;
  factory ConditionalPeriodicTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ConditionalPeriodicTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$ConditionalPeriodicTriggerToJson(this);
}

/// A daily trigger that triggers a random number of times within a defined
/// period of time of the day.
///
/// The random value is between the [minNumberOfTriggers] and [maxNumberOfTriggers]
/// numbers specified.
/// The time period is defined by a [startTime] and an [endTime].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class RandomRecurrentTrigger extends TriggerConfiguration
    implements Schedulable {
  /// Start time of the day where the trigger can happen.
  TimeOfDay startTime;

  /// End time of the day where the trigger can happen.
  TimeOfDay endTime;

  /// Minimum number of trigger per day.
  int minNumberOfTriggers;

  /// Maximum number of trigger per day.
  int maxNumberOfTriggers;

  /// The timestamp of when this trigger was triggered last.
  DateTime? lastTriggerTimestamp;

  /// Create a [RandomRecurrentTrigger].
  ///
  /// [minNumberOfTriggers] and [maxNumberOfTriggers] specified the range of
  /// the random samples (e.g., between 3 and 8 times pr. day).
  /// [startTime] and [endTime] specified the period within a day the sampling
  /// should take place (default is between 08:00 and 20:00).
  RandomRecurrentTrigger({
    this.minNumberOfTriggers = 0,
    this.maxNumberOfTriggers = 1,
    this.startTime = const TimeOfDay(hour: 8),
    this.endTime = const TimeOfDay(hour: 20),
  }) : super() {
    assert(
      startTime.isBefore(endTime),
      'startTime must be before endTime with a 24 hour period.',
    );
  }

  @override
  Function get fromJsonFunction => _$RandomRecurrentTriggerFromJson;
  factory RandomRecurrentTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<RandomRecurrentTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$RandomRecurrentTriggerToJson(this);
}

/// A trigger that triggers when the life cycle of an app changes.
///
/// The state changes that triggers are specified in [states].
/// If not specified (default) this trigger will trigger
/// on all [AppLifecycleState] changes.
///
/// Typically used to make sure to collect measures when the app life
/// cycle is changing, e.g., moved to the background or foreground.
/// Some measures - like audio, bluetooth, and health - can only be collected
/// when the app is in the foreground.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppLifecycleTrigger extends TriggerConfiguration {
  Set<AppLifecycleState> states = {};

  /// Create a [AppLifecycleTrigger] that triggers whenever the app state changes.
  /// If [states] is not specified, it will trigger on all state change events.
  AppLifecycleTrigger([Set<AppLifecycleState>? states]) : super() {
    this.states = states ?? AppLifecycleState.values.toSet();
  }

  @override
  Function get fromJsonFunction => _$AppLifecycleTriggerFromJson;
  factory AppLifecycleTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppLifecycleTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$AppLifecycleTriggerToJson(this);
}

/// A trigger that triggers based on the state of a [UserTask].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UserTaskTrigger extends TriggerConfiguration {
  /// The name of the task to look for, matching [TaskConfiguration.name].
  String taskName;

  /// The state of the user task for resuming this trigger
  UserTaskState triggerCondition;

  /// Create a [UserTaskTrigger].
  /// Default is to trigger when the task is marked as done.
  UserTaskTrigger({
    required this.taskName,
    this.triggerCondition = UserTaskState.done,
  }) : super();

  @override
  Function get fromJsonFunction => _$UserTaskTriggerFromJson;
  factory UserTaskTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<UserTaskTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$UserTaskTriggerToJson(this);
}

/// A trigger that triggers only if a [UserTask] with [taskName] is NOT already
/// on the task list.
///
/// Typically used to make sure that a specific task is always on the task list.
/// Note that the [NoUserTaskTriggerExecutor] only checks the task list once pr
/// minute, so a minute may pass before this trigger triggers.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class NoUserTaskTrigger extends TriggerConfiguration {
  /// The name of the task to look for, matching [TaskConfiguration.name].
  String taskName;

  /// Create a [NoUserTaskTrigger] that trigger is [taskName] is not on the task list.
  NoUserTaskTrigger({required this.taskName}) : super();

  @override
  Function get fromJsonFunction => _$NoUserTaskTriggerFromJson;
  factory NoUserTaskTrigger.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<NoUserTaskTrigger>(json);
  @override
  Map<String, dynamic> toJson() => _$NoUserTaskTriggerToJson(this);
}
