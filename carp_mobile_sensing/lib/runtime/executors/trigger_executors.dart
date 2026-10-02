/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// An event emitted on [TriggerExecutor.triggerEvents] when the trigger fires.
///
/// Carries no data.
class TriggerEvent {
  // TriggerConfiguration? trigger;
}

/// Runs a [TriggerConfiguration]: decides when its task should start or stop.
///
/// Each trigger type has its own executor, created by a [TriggerFactory] via
/// the [ExecutorFactory]. A [TaskControlExecutor] listens to [triggerEvents]
/// and controls its task on each event. Subclasses call [onTrigger] to fire;
/// pausing or disposing cancels [timer].
///
/// To add a new trigger type, extend this class and register a
/// [TriggerFactory] that creates it.
abstract class TriggerExecutor<TConfig extends TriggerConfiguration>
    extends AbstractExecutor<TConfig> {
  final StreamController<TriggerEvent> _controller =
      StreamController.broadcast();

  /// The stream of events triggered from this trigger executor.
  Stream<TriggerEvent> get triggerEvents => _controller.stream;

  /// A timer for subclasses to use. Cancelled on pause and dispose.
  Timer? timer;

  @override
  Stream<Measurement> get measurements => const Stream.empty();

  // Default operations is to do nothing in the following life-cycle methods.
  // Overridden in subclasses, if needed.

  @override
  bool onInitialize() => true;

  @override
  Future<bool> onResume() async => true;

  @override
  @mustCallSuper
  Future<bool> onPause() async {
    timer?.cancel();
    return true;
  }

  @override
  @mustCallSuper
  Future<void> onDispose() async {
    timer?.cancel();
  }

  /// Fires this trigger by adding a [TriggerEvent] to [triggerEvents].
  @mustCallSuper
  void onTrigger() => _controller.add(TriggerEvent());
}

/// A [TriggerExecutor] for a [Schedulable] trigger.
///
/// Its fire times can be computed ahead.
/// Used by [AppTaskControlExecutor] to schedule [AppTask] notifications in
/// advance, so they show up even if the app is not running.
abstract class SchedulableTriggerExecutor<TConfig extends TriggerConfiguration>
    extends TriggerExecutor<TConfig> {
  /// Returns the times this trigger fires between [from] and [to].
  ///
  /// Ordered by time, except for [RandomRecurrentTriggerExecutor].
  ///
  /// [max] limits the number of iterations; its default depends on the
  /// implementation.
  List<DateTime> getSchedule(DateTime from, DateTime to, [int max]);
}

/// Runs a [NoOpTrigger], i.e. never fires.
class NoOpTriggerExecutor extends TriggerExecutor<TriggerConfiguration> {}

/// Runs an [ImmediateTrigger], i.e. fires each time it is resumed.
class ImmediateTriggerExecutor extends TriggerExecutor<TriggerConfiguration> {
  @override
  Future<bool> onResume() async {
    onTrigger();
    return true;
  }
}

/// Runs a [OneTimeTrigger], i.e. fires only once per study deployment.
///
/// The fire time is saved in [OneTimeTrigger.triggerTimestamp] and persisted
/// with the deployment, so it does not fire again after an app restart.
class OneTimeTriggerExecutor extends TriggerExecutor<OneTimeTrigger> {
  @override
  Future<bool> onResume() async {
    if (!configuration!.hasBeenTriggered) {
      // Note that the trigger stamp is saved in the deployment configuration.
      // By called 'hasBeenUpdated', the deployment is marked as updated and
      // persisted with the new trigger timestamp.
      configuration!.triggerTimestamp = DateTime.now();
      deployment?.hasBeenUpdated();
      onTrigger();
    } else {
      warning(
        "$runtimeType - one time trigger already occurred at: ${configuration?.triggerTimestamp}. "
        'Will not trigger now.',
      );
      return false;
    }
    return true;
  }
}

/// Runs a [PassiveTrigger], which the app fires from code.
///
/// Sets itself as the trigger's executor on initialize. Fires only while
/// resumed; calls in any other state are ignored.
class PassiveTriggerExecutor extends TriggerExecutor<PassiveTrigger> {
  @override
  bool onInitialize() {
    configuration!.executor = this;
    return true;
  }

  // Only fire when resumed - a trigger() call on a paused (or not-yet-resumed)
  // executor must be ignored, otherwise it would start the task while the
  // study is paused.
  @override
  void onTrigger() {
    if (state != ExecutorState.Resumed) return;
    super.onTrigger();
  }
}

/// Runs a [DelayedTrigger], i.e. fires once, a delay after it is resumed.
class DelayedTriggerExecutor extends TriggerExecutor<DelayedTrigger> {
  @override
  Future<bool> onResume() async {
    timer = Timer(configuration!.delay, () => onTrigger());
    return true;
  }
}

/// Runs an [ElapsedTimeTrigger], i.e. fires once, a set time after deployment.
///
/// The time is counted from when the study was deployed on this phone.
/// Does not fire if that time has already passed.
class ElapsedTimeTriggerExecutor
    extends SchedulableTriggerExecutor<ElapsedTimeTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to, [int? max]) {
    if (deployment?.deployed == null) return [];
    if (configuration?.elapsedTime == null) return [];
    final dd = deployment!.deployed.add(configuration!.elapsedTime!).toLocal();
    return (dd.isAfter(from) && dd.isBefore(to)) ? [dd] : [];
  }

  @override
  Future<bool> onResume() async {
    if (deployment?.deployed == null) {
      warning(
        '$runtimeType - This deployment does not have a start time. Cannot execute this trigger.',
      );
      return false;
    }

    if (configuration?.elapsedTime == null) {
      warning(
        '$runtimeType - This ElapsedTimeTrigger does not have a elapsedTime specified. Cannot execute this trigger.',
      );
      return false;
    }

    int delay =
        configuration!.elapsedTime!.inMilliseconds -
        (DateTime.now().millisecondsSinceEpoch -
            (deployment?.deployed.millisecondsSinceEpoch ?? 0));

    if (delay > 0) {
      timer = Timer(Duration(milliseconds: delay), () => onTrigger());
    } else {
      warning(
        '$runtimeType - the trigger time is in the past and should have happened already.',
      );
      return false;
    }

    return true;
  }
}

/// Runs a [PeriodicTrigger]: fires when resumed, then once per period.
class PeriodicTriggerExecutor
    extends SchedulableTriggerExecutor<PeriodicTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to, [int max = 100]) {
    final List<DateTime> schedule = [];
    DateTime timestamp = from;
    int count = 0;

    while (timestamp.isBefore(to) && count < max) {
      schedule.add(timestamp);
      timestamp = timestamp.add(configuration!.period);
      count++;
    }

    return schedule;
  }

  @override
  Future<bool> onResume() async {
    // Fire immediately on resume (matching getSchedule, which includes the
    // start time), then once per period.
    onTrigger();
    timer = Timer.periodic(configuration!.period, (_) => onTrigger());
    return true;
  }
}

/// Runs a [DateTimeTrigger]: fires once at the specified date and time.
///
/// Resuming fails if that time is in the past.
class DateTimeTriggerExecutor
    extends SchedulableTriggerExecutor<DateTimeTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to, [int? max]) =>
      (configuration!.schedule.isAfter(from) &&
          configuration!.schedule.isBefore(to))
      ? [configuration!.schedule]
      : [];

  @override
  Future<bool> onResume() async {
    if (configuration!.schedule.isBefore(DateTime.now())) {
      warning('The schedule of the DateTimeTrigger cannot be in the past.');
      return false;
    } else {
      var delay = configuration!.schedule.difference(DateTime.now());
      timer = Timer(delay, () => onTrigger());
    }
    return true;
  }
}

/// Runs a [RecurrentScheduledTrigger], e.g. every Monday at 9:00.
class RecurrentScheduledTriggerExecutor
    extends SchedulableTriggerExecutor<RecurrentScheduledTrigger> {
  @override
  List<DateTime> getSchedule(DateTime from, DateTime to, [int max = 100]) {
    List<DateTime> schedule = [];
    DateTime timestamp = configuration!.firstOccurrence;
    int count = 0;

    while (timestamp.isBefore(to) && count < max) {
      if (timestamp.isAfter(from)) schedule.add(timestamp);
      timestamp = timestamp.add(configuration!.period);
      count++;
    }

    return schedule;
  }

  @override
  Future<bool> onResume() async {
    Duration delay = configuration!.firstOccurrence.difference(DateTime.now());
    if (configuration!.end == null ||
        configuration!.end!.isAfter(DateTime.now())) {
      timer = Timer(delay, () async => onTrigger());
    }
    return true;
  }
}

/// Runs a [CronScheduledTrigger]: fires at the times of its cron expression.
class CronScheduledTriggerExecutor
    extends SchedulableTriggerExecutor<CronScheduledTrigger> {
  late cron.Cron _cron;
  cron.ScheduledTask? _task;

  CronScheduledTriggerExecutor() : super() {
    _cron = cron.Cron();
  }

  @override
  List<DateTime> getSchedule(DateTime from, DateTime to, [int max = 100]) {
    var cronIterator = Cron().parse(
      configuration!.cronExpression,
      Settings().timezone,
      tz.TZDateTime.from(from, tz.getLocation(Settings().timezone)),
    );
    final List<DateTime> schedule = [];
    int count = 0;

    while (cronIterator.next().isBefore(to) && count < max) {
      schedule.add(cronIterator.current());
      count++;
    }
    return schedule;
  }

  @override
  Future<bool> onResume() async {
    debug('creating cron job : $configuration');
    var schedule = cron.Schedule.parse(configuration!.cronExpression);
    _task = _cron.schedule(schedule, () async {
      debug('resuming cron job : ${DateTime.now().toString()}');
      onTrigger();
    });
    return true;
  }

  @override
  Future<bool> onPause() async {
    _task?.cancel();
    return super.onPause();
  }
}

/// Runs a [SamplingEventTrigger]: fires on matching measurements in the study.
///
/// A measurement matches if its type is [SamplingEventTrigger.measureType]
/// and its data is equivalent to [SamplingEventTrigger.triggerCondition].
/// Fires on every measurement of that type if there is no condition.
class SamplingEventTriggerExecutor
    extends TriggerExecutor<SamplingEventTrigger> {
  StreamSubscription<Measurement>? _subscription;

  @override
  Future<bool> onResume() async {
    // Fast out if no deployment.
    if (deployment == null) return false;

    SmartphoneStudy? study = SmartPhoneClientManager().getStudy(
      deployment!.studyDeploymentId,
      deployment!.deviceRoleName,
    );

    _subscription ??= SmartPhoneClientManager()
        .getStudyController(study!)
        ?.measurementsByType(configuration!.measureType)
        .distinct()
        .listen((measurement) {
          if (configuration?.triggerCondition == null) {
            // always trigger if the condition is null
            onTrigger();
          } else
          // check the trigger condition
          if (measurement.data.equivalentTo(configuration!.triggerCondition!)) {
            onTrigger();
          }
        });
    return true;
  }

  @override
  Future<bool> onPause() async {
    _subscription?.cancel();
    return super.onPause();
  }
}

/// Runs a [ConditionalSamplingEventTrigger]: fires on matching measurements.
///
/// A measurement matches if its type is
/// [ConditionalSamplingEventTrigger.measureType] and
/// [ConditionalSamplingEventTrigger.triggerCondition] returns true for it.
class ConditionalSamplingEventTriggerExecutor
    extends TriggerExecutor<ConditionalSamplingEventTrigger> {
  StreamSubscription<Measurement>? _subscription;

  @override
  Future<bool> onResume() async {
    // Fast out if no deployment.
    if (deployment == null) return false;

    SmartphoneStudy? study = SmartPhoneClientManager().getStudy(
      deployment!.studyDeploymentId,
      deployment!.deviceRoleName,
    );

    _subscription ??= SmartPhoneClientManager()
        .getStudyController(study!)
        ?.measurementsByType(configuration!.measureType)
        .listen((measurement) {
          if (configuration!.triggerCondition != null &&
              configuration!.triggerCondition!(measurement)) {
            onTrigger();
          }
        });
    return true;
  }

  @override
  Future<bool> onPause() async {
    _subscription?.cancel();
    return super.onPause();
  }
}

/// Runs a [ConditionalPeriodicTrigger]: fires when its condition returns true.
///
/// The condition is checked when resumed and then once per period.
class ConditionalPeriodicTriggerExecutor
    extends TriggerExecutor<ConditionalPeriodicTrigger> {
  @override
  Future<bool> onResume() async {
    void check() {
      if (configuration!.triggerCondition != null &&
          configuration!.triggerCondition!()) {
        onTrigger();
      }
    }

    // check the condition immediately on resume, then once per period.
    check();
    timer = Timer.periodic(configuration!.period, (_) => check());
    return true;
  }
}

/// Runs a [RandomRecurrentTrigger]: fires a random number of times per day.
///
/// The times are random, between [startTime] and [endTime]. A daily cron job
/// at [startTime] sets up the timers for the day. If resumed after
/// [startTime], the timers for today are set up right away, unless
/// [hasBeenScheduledForToday] is true.
class RandomRecurrentTriggerExecutor
    extends SchedulableTriggerExecutor<RandomRecurrentTrigger> {
  final cron.Cron _cron = cron.Cron();
  List<Timer> _timers = [];

  TimeOfDay get startTime => configuration!.startTime;
  TimeOfDay get endTime => configuration!.endTime;
  int get minNumberOfTriggers => configuration!.minNumberOfTriggers;
  int get maxNumberOfTriggers => configuration!.maxNumberOfTriggers;

  /// A new random number of triggers for a day. Changes on every read.
  int get numberOfSampling =>
      Random().nextInt(maxNumberOfTriggers) + minNumberOfTriggers;

  /// A new list of random times between [startTime] and [endTime].
  /// Changes on every read.
  List<TimeOfDay> get samplingTimes {
    List<TimeOfDay> samplingTimes = [];
    for (int i = 0; i <= numberOfSampling; i++) {
      samplingTimes.add(randomTime);
    }
    debug('Random sampling times: $samplingTimes');
    return samplingTimes;
  }

  /// A new random time between [startTime] and [endTime]. Changes on every read.
  TimeOfDay get randomTime {
    TimeOfDay randomTime = const TimeOfDay();
    do {
      int randomHour =
          startTime.hour +
          ((endTime.hour - startTime.hour == 0)
              ? 0
              : Random().nextInt(endTime.hour - startTime.hour));
      int randomMinutes = Random().nextInt(60);
      randomTime = TimeOfDay(hour: randomHour, minute: randomMinutes);
    } while (!(randomTime.isAfter(startTime) && randomTime.isBefore(endTime)));

    return randomTime;
  }

  /// Today's date as `year-month-day`, without zero padding. Used in logs.
  String get todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Whether the timers for today have already been set up.
  ///
  /// Based on [RandomRecurrentTrigger.lastTriggerTimestamp].
  bool get hasBeenScheduledForToday {
    // fast out if no timestamp is set previously
    if (configuration?.lastTriggerTimestamp == null) return false;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final sinceLastTime =
        now.millisecond - configuration!.lastTriggerTimestamp!.millisecond;
    final sinceMidnight = now.millisecond - midnight.millisecond;

    return (sinceLastTime < sinceMidnight);
  }

  @override
  List<DateTime> getSchedule(DateTime from, DateTime to, [int max = 100]) {
    assert(to.isAfter(from));
    final List<DateTime> schedule = [];

    final startDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);
    var day = startDay;
    var count = 0;

    while (day.isBefore(toDay) && count < max) {
      for (var time in samplingTimes) {
        final date = DateTime(
          day.year,
          day.month,
          day.day,
          time.hour,
          time.minute,
          time.second,
        );
        if (date.isAfter(from) && date.isBefore(to)) schedule.add(date);
      }

      day = day.add(const Duration(days: 1));
      count++;
    }
    return schedule;
  }

  @override
  Future<bool> onResume() async {
    // sampling might be started after [startTime] or the app wasn't running at [startTime]
    // therefore, first check if the random timers have been scheduled for today
    if (TimeOfDay.now().isAfter(startTime)) {
      if (!hasBeenScheduledForToday) {
        debug(
          '$runtimeType - timers has not been scheduled for today ($todayString) - scheduling now',
        );
        _scheduleTimers();
      }
    }

    // set up a cron job that generates the random triggers once pr day at [startTime]
    final cronJob = '${startTime.minute} ${startTime.hour} * * *';
    debug('$runtimeType - creating cron job : $cronJob');

    _cron.schedule(cron.Schedule.parse(cronJob), () async {
      debug('$runtimeType - resuming cron job : ${DateTime.now().toString()}');
      _scheduleTimers();
    });
    return true;
  }

  void _scheduleTimers() {
    // empty the list of timers.
    _timers = [];

    // get a random number of trigger times for today, and for each set up a
    // timer that triggers the super.onTrigger() method.
    for (var time in samplingTimes) {
      // find the delay - note, that none of the delays can be negative,
      // since we are at [startTime] or after
      Duration delay = time.difference(TimeOfDay.now());
      debug('$runtimeType - setting up timer for : $time, delay: $delay');
      Timer timer = Timer(delay, () async => onTrigger());
      _timers.add(timer);
    }

    // mark this day as scheduled
    configuration!.lastTriggerTimestamp = DateTime.now();
  }
}

/// Runs a [UserTaskTrigger]: fires when a matching [UserTask] changes state.
///
/// A task matches if it has the trigger's task name and changes to the
/// trigger's [UserTaskState].
class UserTaskTriggerExecutor extends TriggerExecutor<UserTaskTrigger> {
  StreamSubscription<UserTask>? _subscription;

  @override
  Future<bool> onResume() async {
    // listen for event of the specified type and trigger as needed
    _subscription ??= AppTaskController().userTaskEvents.listen((
      userTask,
    ) async {
      if (userTask.task.name == configuration!.taskName &&
          userTask.state == configuration!.triggerCondition) {
        onTrigger();
      }
    });
    return true;
  }

  @override
  Future<bool> onPause() async {
    _subscription?.cancel();
    return super.onPause();
  }
}

/// Runs a [NoUserTaskTrigger]: fires when its task is not on the task queue.
///
/// The queue is [AppTaskController.userTaskQueue].
/// Checks when resumed and then once per minute. A task that is done or
/// expired counts as not on the queue.
class NoUserTaskTriggerExecutor extends TriggerExecutor<NoUserTaskTrigger> {
  @override
  Future<bool> onResume() async {
    // enqueue immediately if not already on the list, then keep checking once
    // pr minute - otherwise the first check (and task) is delayed a full minute.
    // A notified, started or canceled task is still on the list - only a done
    // or expired one is not.
    void enqueueIfMissing() {
      if (!AppTaskController().userTaskQueue.any((task) =>
          task.name == configuration!.taskName &&
          task.state != UserTaskState.done &&
          task.state != UserTaskState.expired)) {
        onTrigger();
      }
    }

    enqueueIfMissing();
    // Use the inherited [timer], which the base onPause()/onDispose() cancel.
    timer = Timer.periodic(Duration(minutes: 1), (_) => enqueueIfMissing());

    return true;
  }
}

/// Runs an [AppLifecycleTrigger]: fires when the app enters a listed state.
///
/// The states are the trigger's [AppLifecycleState]s.
class AppLifecycleTriggerExecutor extends TriggerExecutor<AppLifecycleTrigger>
    with WidgetsBindingObserver {
  @override
  Future<bool> onResume() async {
    WidgetsBinding.instance.addObserver(this);
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    WidgetsBinding.instance.removeObserver(this);
    return await super.onPause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      (configuration?.states.contains(state) ?? false) ? onTrigger() : null;
}
