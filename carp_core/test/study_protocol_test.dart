import 'package:carp_core/carp_core.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => Core.ensureInitialized());

  // A protocol with one primary device and one task which is started by a
  // trigger, i.e., with a [TaskControl] for the task.
  StudyProtocol protocolWithTask(TaskConfiguration task) {
    final device = Smartphone(roleName: 'phone');

    return StudyProtocol(ownerId: 'owner', name: 'protocol')
      ..addPrimaryDevice(device)
      ..addTaskControl(ElapsedTimeTrigger(elapsedTime: const Duration(hours: 1)), task, device);
  }

  group('StudyProtocol.removeTask', () {
    test('removes the task and its task controls', () {
      final task = BackgroundTask(
        name: 'background',
        measures: [Measure(type: CarpDataTypes.STEP_COUNT)],
      );
      final protocol = protocolWithTask(task);

      expect(protocol.tasks, contains(task));
      expect(protocol.taskControls, hasLength(1));

      protocol.removeTask(task);

      expect(protocol.tasks, isNot(contains(task)));
      expect(protocol.getTasksForDeviceRoleName('phone'), isNot(contains(task)));
      expect(protocol.taskControls, isEmpty);
    });

    test('removes all task controls of a task used by more than one trigger', () {
      final device = Smartphone(roleName: 'phone');
      final task = BackgroundTask(
        name: 'background',
        measures: [Measure(type: CarpDataTypes.STEP_COUNT)],
      );
      final protocol = StudyProtocol(ownerId: 'owner', name: 'protocol')
        ..addPrimaryDevice(device)
        ..addTaskControl(ElapsedTimeTrigger(elapsedTime: const Duration(hours: 1)), task, device)
        ..addTaskControl(
          ScheduledTrigger(time: const TimeOfDay(hour: 8), recurrenceRule: RecurrenceRule(Frequency.DAILY)),
          task,
          device,
        );

      expect(protocol.taskControls, hasLength(2));

      protocol.removeTask(task);

      expect(protocol.taskControls, isEmpty);
      expect(protocol.triggers, hasLength(2), reason: 'triggers are not removed by removeTask');
    });

    test('keeps task controls of other tasks', () {
      final device = Smartphone(roleName: 'phone');
      final removed = BackgroundTask(
        name: 'removed',
        measures: [Measure(type: CarpDataTypes.STEP_COUNT)],
      );
      final kept = BackgroundTask(
        name: 'kept',
        measures: [Measure(type: CarpDataTypes.GEOLOCATION)],
      );
      final protocol = StudyProtocol(ownerId: 'owner', name: 'protocol')
        ..addPrimaryDevice(device)
        ..addTaskControl(ElapsedTimeTrigger(elapsedTime: const Duration(hours: 1)), removed, device)
        ..addTaskControl(ElapsedTimeTrigger(elapsedTime: const Duration(hours: 2)), kept, device);

      protocol.removeTask(removed);

      expect(protocol.tasks, isNot(contains(removed)));
      expect(protocol.tasks, contains(kept));
      expect(protocol.taskControls, hasLength(1));
      expect(protocol.taskControls.first.taskName, 'kept');
    });
  });
}
