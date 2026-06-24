import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:carp_serializable/carp_serializable.dart';

void main() {
  setUp(() {
    CarpMobileSensing.ensureInitialized();
  });

  group('Sampling Configurations', () {
    test('Sampling Packages.', () {
      var schemes = DeviceSamplingPackage().samplingSchemes;
      expect(schemes.configurations.length, 8);

      print(schemes);
    });
  });

  group('Triggers', () {
    test(' - RecurrentScheduledTrigger - success', () {
      RecurrentScheduledTrigger t;

      // collect every day at 13:30
      t = RecurrentScheduledTrigger(
        type: RecurrentType.daily,
        time: const TimeOfDay(hour: 18, minute: 55),
      );
      //print(toJsonString(t));
      print('${t.firstOccurrence} - ${t.period}');
      expect(t.period.inHours, 24);

      // collect every day at 22:30
      t = RecurrentScheduledTrigger(
        type: RecurrentType.daily,
        time: const TimeOfDay(hour: 22, minute: 30),
        duration: const Duration(seconds: 1),
      );
      print('${t.firstOccurrence} - ${t.period}');
      expect(t.period.inHours, 24);

      // collect every other day at 13:30
      t = RecurrentScheduledTrigger(
        type: RecurrentType.daily,
        separationCount: 1,
        time: const TimeOfDay(hour: 13, minute: 30),
        duration: const Duration(seconds: 1),
      );
      print('${t.firstOccurrence} - ${t.period}');
      expect(t.period.inDays, 2);

      // collect every wednesday at 12:23
      t = RecurrentScheduledTrigger(
        type: RecurrentType.weekly,
        dayOfWeek: DateTime.wednesday,
        time: const TimeOfDay(hour: 12, minute: 23),
        duration: const Duration(seconds: 1),
      );
      print('${t.firstOccurrence} - ${t.period}');
      expect(t.period.inDays, 7);

      // collect every thursday at 14:23
      t = RecurrentScheduledTrigger(
        type: RecurrentType.weekly,
        dayOfWeek: DateTime.thursday,
        time: const TimeOfDay(hour: 14, minute: 23),
        duration: const Duration(seconds: 1),
      );
      print('${t.firstOccurrence} - ${t.period}');
      expect(t.period.inDays, 7);

      // collect every 2nd thursday at 14:00
      t = RecurrentScheduledTrigger(
        type: RecurrentType.weekly,
        dayOfWeek: DateTime.thursday,
        separationCount: 1,
        time: const TimeOfDay(hour: 14, minute: 00),
        duration: const Duration(seconds: 1),
      );
      print(
        'weekly, Thursday at 14:00 :: first : ${t.firstOccurrence} - period : ${t.period.inDays}',
      );
      expect(t.period.inDays, 2 * 7);

      // the monthly trigger from iPDM-GO app
      t = RecurrentScheduledTrigger(
        type: RecurrentType.monthly,
        dayOfMonth: 1,
        time: const TimeOfDay(hour: 18),
        duration: const Duration(seconds: 1),
      );
      print(
        'monthly, 1st day of month at 18:00 :: first : ${t.firstOccurrence} - period : ${t.period.inDays}',
      );
      expect(t.period.inDays, 1 * 30);

      // collect quarterly on the 11th day of the first month
      // in each quarter at 21:30
      t = RecurrentScheduledTrigger(
        type: RecurrentType.monthly,
        dayOfMonth: 11,
        separationCount: 2,
        time: const TimeOfDay(hour: 21, minute: 30),
        duration: const Duration(seconds: 1),
      );
      print(
        'quarterly, 11th day of month at 21:30 :: first : ${t.firstOccurrence} - period : ${t.period.inDays}',
      );
      expect(t.period.inDays, 3 * 30);

      // collect monthly in the second week on a monday at 14:30
      t = RecurrentScheduledTrigger(
        type: RecurrentType.monthly,
        weekOfMonth: 2,
        dayOfWeek: DateTime.tuesday,
        time: const TimeOfDay(hour: 14, minute: 30),
        duration: const Duration(seconds: 1),
      );
      print(
        'monthly, 2nd week of month on Tuesday at 14:30 :: first : ${t.firstOccurrence} - period : ${t.period.inDays}',
      );
      expect(t.firstOccurrence.weekday, DateTime.tuesday);
      expect(t.period.inDays, 30);

      // collect quarterly as above,
      t = RecurrentScheduledTrigger(
        type: RecurrentType.monthly,
        dayOfMonth: 11,
        separationCount: 2,
        time: const TimeOfDay(hour: 21, minute: 30),
        duration: const Duration(seconds: 1),
      );
      print(
        'quarterly, 11th day of month at 21:30 :: first : ${t.firstOccurrence} - period : ${t.period.inDays}',
      );
      expect(t.period.inDays, 3 * 30);
    });

    test(' - RecurrentScheduledTrigger - scheduling I', () {
      RecurrentScheduledTrigger t;

      // collect every day at 13:30
      t = RecurrentScheduledTrigger(
        type: RecurrentType.daily,
        time: const TimeOfDay(hour: 13, minute: 30),
        duration: const Duration(seconds: 1),
      );
      //print(toJsonString(t));
      print(t);
      print('${t.firstOccurrence} - ${t.period}');
      expect(t.period.inHours, 24);

      final from = DateTime.now();
      final to = from.add(const Duration(days: 5));
      final ex = RecurrentScheduledTriggerExecutor();
      ex.initialize(t);

      List<DateTime> schedule = ex.getSchedule(from, to);
      print(schedule);
      for (var time in schedule) {
        assert(time.isAfter(from));
        assert(time.isBefore(to));
      }
    });

    test(' - RecurrentScheduledTrigger - scheduling II', () {
      RecurrentScheduledTrigger t;

      t = RecurrentScheduledTrigger(
        type: RecurrentType.weekly,
        dayOfWeek: DateTime.wednesday,
        time: const TimeOfDay(hour: 12, minute: 23),
        duration: const Duration(seconds: 1),
      );
      print(t);
      print('${t.firstOccurrence} - ${t.period}');
      expect(t.period.inDays, 7);

      final from = DateTime.now();
      final to = from.add(const Duration(days: 25));
      final ex = RecurrentScheduledTriggerExecutor();
      ex.initialize(t);

      List<DateTime> schedule = ex.getSchedule(from, to);
      print(schedule);
      for (var time in schedule) {
        assert(time.isAfter(from));
        assert(time.isBefore(to));
      }
    });

    test(' - RecurrentScheduledTrigger - assert failures', () {
      // Each of the following violates a constructor assert and must throw.
      final invalid = <Function()>[
        // separationCount must be >= 0
        () => RecurrentScheduledTrigger(
              type: RecurrentType.daily,
              separationCount: -1,
              time: const TimeOfDay(hour: 13, minute: 30),
            ),
        // weekly recurrence requires dayOfWeek
        () => RecurrentScheduledTrigger(
              type: RecurrentType.weekly,
              time: const TimeOfDay(hour: 12, minute: 23),
            ),
        // monthly recurrence requires weekOfMonth or dayOfMonth
        () => RecurrentScheduledTrigger(
              type: RecurrentType.monthly,
              dayOfWeek: DateTime.monday,
              time: const TimeOfDay(hour: 14, minute: 30),
            ),
        // dayOfMonth must be in [1-31]
        () => RecurrentScheduledTrigger(
              type: RecurrentType.monthly,
              dayOfMonth: 43,
              separationCount: 2,
              time: const TimeOfDay(hour: 21, minute: 30),
            ),
        // weekOfMonth must be in [1-4]
        () => RecurrentScheduledTrigger(
              type: RecurrentType.monthly,
              weekOfMonth: 12,
              dayOfWeek: DateTime.monday,
              time: const TimeOfDay(hour: 14, minute: 30),
            ),
      ];

      for (final construct in invalid) {
        expect(construct, throwsA(isA<AssertionError>()));
      }
    });

    test(' - CronScheduledTrigger', () {
      print('cron job at 12:00 every day.');
      CronScheduledTrigger t = CronScheduledTrigger.parse(
        cronExpression: '0 12 * * *',
      );
      print(t);
      print(toJsonString(t));

      t = CronScheduledTrigger(minute: 0, hour: 12);
      print(t);

      final from = DateTime.now();
      final to = from.add(const Duration(days: 5));
      final ex = CronScheduledTriggerExecutor();
      ex.initialize(t);

      List<DateTime> schedule = ex.getSchedule(from, to);
      print(schedule);
      for (var time in schedule) {
        assert(time.isAfter(from));
        assert(time.isBefore(to));
      }

      // t = CronScheduledTrigger(
      //   minute: 10,
      //   hour: 12,
      //   day: 5,
      //   month: DateTime.april,
      //   weekday: DateTime.tuesday,
      //   duration: Duration(seconds: 1),
      // );
      // print(t);
    });

    test(' - RandomRecurrentTrigger', () {
      RandomRecurrentTrigger t = RandomRecurrentTrigger(
        // startTime: Time(hour: 8, minute: 0),
        // endTime: Time(hour: 20, minute: 0),
        startTime: const TimeOfDay(hour: 8, minute: 56),
        endTime: const TimeOfDay(hour: 20, minute: 10),
        // startTime: Time(hour: 8, minute: 0),
        // endTime: Time(hour: 8, minute: 30),
        minNumberOfTriggers: 2,
        maxNumberOfTriggers: 8,
      );
      print(toJsonString(t));

      final ex = RandomRecurrentTriggerExecutor();
      ex.initialize(t);
      List<TimeOfDay> times = ex.samplingTimes;
      print(times);
      for (var time in times) {
        assert(time.isAfter(t.startTime));
        assert(time.isBefore(t.endTime));
      }

      final from = DateTime.now();
      final to = from.add(const Duration(days: 5));
      List<DateTime> schedule = ex.getSchedule(from, to);
      print(schedule);
      for (var time in schedule) {
        assert(time.isAfter(from));
        assert(time.isBefore(to));
      }
    });

    test(' - ConditionalPeriodicTrigger', () {
      ConditionalPeriodicTrigger t = ConditionalPeriodicTrigger(
        period: const Duration(minutes: 1),
        triggerCondition: () {
          return ('jakob'.length == 5);
        },
      );
      print(toJsonString(t));

      ConditionalPeriodicTriggerExecutor ex =
          ConditionalPeriodicTriggerExecutor();
      print(ex);
    });
  });

  /// One use case per trigger, matched to its expected firing outcome.
  ///
  /// Each test drives the executor's life-cycle ([initialize] / [resume] /
  /// [pause]) and counts the [TriggerEvent]s emitted on [triggerEvents] - the
  /// same stream a [TaskControlExecutor] listens to in order to start/stop the
  /// triggered task.
  group('Trigger execution use cases', () {
    // Subscribe to [executor] and return the growing list of fired events.
    // Must be called inside a FakeAsync zone, with [executor] also constructed
    // inside that zone, so its broadcast stream is driven by fake time.
    List<TriggerEvent> firings(TriggerExecutor executor) {
      final events = <TriggerEvent>[];
      executor.triggerEvents.listen(events.add);
      return events;
    }

    test(' - NoOpTrigger - never fires', () {
      // Use case: a placeholder trigger that should do nothing.
      FakeAsync().run((fake) {
        final ex = NoOpTriggerExecutor()..initialize(NoOpTrigger());
        final events = firings(ex);
        ex.resume();
        fake.elapse(const Duration(minutes: 1));
        expect(events, isEmpty);
      });
    });

    test(' - ImmediateTrigger - fires once on resume, never again', () {
      // Use case: start sampling as soon as the study runs.
      FakeAsync().run((fake) {
        final ex = ImmediateTriggerExecutor()..initialize(ImmediateTrigger());
        final events = firings(ex);
        ex.resume();
        fake.flushMicrotasks();
        expect(events, hasLength(1), reason: 'fires at resume (t=0)');
        fake.elapse(const Duration(minutes: 1));
        expect(events, hasLength(1), reason: 'never fires again');
      });
    });

    test(' - OneTimeTrigger - fires only on the first resume', () {
      // Use case: a one-off survey that must not re-fire on app restart.
      FakeAsync().run((fake) {
        final ex = OneTimeTriggerExecutor()..initialize(OneTimeTrigger());
        final events = firings(ex);

        ex.resume();
        fake.flushMicrotasks();
        expect(events, hasLength(1), reason: 'fires on first resume');

        ex.pause();
        fake.flushMicrotasks();
        ex.resume(); // already triggered -> stays silent
        fake.elapse(const Duration(minutes: 1));
        expect(events, hasLength(1), reason: 'does not re-fire');
      });
    });

    test(' - PassiveTrigger - fires only when trigger() is called', () {
      // Use case: task started programmatically from Dart, never on its own.
      FakeAsync().run((fake) {
        final trigger = PassiveTrigger();
        final ex = PassiveTriggerExecutor()..initialize(trigger);
        final events = firings(ex);

        // The executor registers itself, so trigger() routes to triggerEvents.
        expect(trigger.executor, same(ex));

        ex.resume();
        fake.elapse(const Duration(minutes: 1));
        expect(events, isEmpty, reason: 'never fires on its own');

        trigger.trigger();
        fake.flushMicrotasks();
        expect(events, hasLength(1), reason: 'fires on trigger()');
      });
    });

    test(' - DelayedTrigger - fires once, exactly after the delay', () {
      // Use case: start sampling 50 ms into the study, once.
      FakeAsync().run((fake) {
        final ex = DelayedTriggerExecutor()
          ..initialize(DelayedTrigger(delay: const Duration(milliseconds: 50)));
        final events = firings(ex);

        ex.resume();
        fake.flushMicrotasks();
        expect(events, isEmpty, reason: 'nothing at t=0');

        fake.elapse(const Duration(milliseconds: 49));
        expect(events, isEmpty, reason: 'nothing just before the delay');

        fake.elapse(const Duration(milliseconds: 1)); // t=50ms
        expect(events, hasLength(1), reason: 'fires at t=50ms');

        fake.elapse(const Duration(minutes: 1));
        expect(events, hasLength(1), reason: 'fires only once');
      });
    });

    test(' - PeriodicTrigger - fires immediately then once per period', () {
      // Use case: sample now, then on a fixed cadence for as long as the study
      // runs. With a 30 ms period, by t=110ms expect 4 fires: t = 0, 30, 60, 90.
      FakeAsync().run((fake) {
        final ex = PeriodicTriggerExecutor()
          ..initialize(
              PeriodicTrigger(period: const Duration(milliseconds: 30)));
        final events = firings(ex);

        ex.resume();
        fake.flushMicrotasks();
        expect(events, hasLength(1), reason: 'fires immediately at t=0');

        fake.elapse(const Duration(milliseconds: 30)); // t=30
        expect(events, hasLength(2));
        fake.elapse(const Duration(milliseconds: 30)); // t=60
        expect(events, hasLength(3));
        fake.elapse(const Duration(milliseconds: 30)); // t=90
        expect(events, hasLength(4));
        fake.elapse(const Duration(milliseconds: 19)); // t=109
        expect(events, hasLength(4), reason: 'no extra fire before t=120ms');

        ex.pause();
      });
    });

    test(' - DateTimeTrigger - fires once at the scheduled time', () {
      // Use case: fire at a specific (future) wall-clock time.
      FakeAsync().run((fake) {
        final ex = DateTimeTriggerExecutor()
          ..initialize(DateTimeTrigger(
            schedule: DateTime.now().add(const Duration(milliseconds: 50)),
          ));
        final events = firings(ex);

        ex.resume();
        fake.flushMicrotasks();
        expect(events, isEmpty, reason: 'nothing at t=0');

        fake.elapse(const Duration(milliseconds: 100));
        expect(events, hasLength(1), reason: 'fires at the scheduled time');

        fake.elapse(const Duration(minutes: 1));
        expect(events, hasLength(1), reason: 'fires only once');
      });
    });

    test(' - ConditionalPeriodicTrigger - checks immediately then per period',
        () {
      // Use case: sample now and on a cadence, gated by a condition. The
      // condition is checked immediately on resume, then once per period. With
      // a 30 ms period, by t=90ms expect 4 fires: t = 0, 30, 60, 90.
      FakeAsync().run((fake) {
        final ex = ConditionalPeriodicTriggerExecutor()
          ..initialize(ConditionalPeriodicTrigger(
            period: const Duration(milliseconds: 30),
            triggerCondition: () => true,
          ));
        final events = firings(ex);

        ex.resume();
        fake.flushMicrotasks();
        expect(events, hasLength(1), reason: 'checks immediately at t=0');

        fake.elapse(const Duration(milliseconds: 30)); // t=30
        expect(events, hasLength(2));
        fake.elapse(const Duration(milliseconds: 30)); // t=60
        expect(events, hasLength(3));
        fake.elapse(const Duration(milliseconds: 30)); // t=90
        expect(events, hasLength(4));
        ex.pause();
      });
    });

    test(' - ConditionalPeriodicTrigger - never fires while condition false',
        () {
      FakeAsync().run((fake) {
        final ex = ConditionalPeriodicTriggerExecutor()
          ..initialize(ConditionalPeriodicTrigger(
            period: const Duration(milliseconds: 30),
            triggerCondition: () => false,
          ));
        final events = firings(ex);

        ex.resume();
        fake.elapse(const Duration(milliseconds: 110));
        expect(events, isEmpty);
        ex.pause();
      });
    });

    // The triggers below fire from runtime sources that need a running client
    // (study controller measurements, the AppTask queue, or Flutter's widget
    // binding). They are covered by their getSchedule() tests above where
    // applicable; add end-to-end firing tests when a test harness with a live
    // SmartPhoneClientManager / AppTaskController is available.
    test(' - ElapsedTimeTrigger - fires after elapsedTime since deployment',
        () {}, skip: 'needs a SmartphoneDeployment with a deployed timestamp');
    test(' - SamplingEventTrigger - fires on a matching measurement', () {},
        skip: 'needs a live SmartPhoneClientManager study controller');
    test(' - ConditionalSamplingEventTrigger - fires when condition matches',
        () {}, skip: 'needs a live SmartPhoneClientManager study controller');
    test(' - UserTaskTrigger - fires on a user task state change', () {},
        skip: 'needs a live AppTaskController user-task stream');
    test(' - NoUserTaskTrigger - fires while the task is not enqueued', () {},
        skip: 'needs a live AppTaskController user-task queue');
    test(' - AppLifecycleTrigger - fires on app lifecycle changes', () {},
        skip: 'needs Flutter WidgetsBinding lifecycle events');
  });
}
