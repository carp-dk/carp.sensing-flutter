import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:test/test.dart';

/// A study removed and re-added with the same deployment id (e.g. local mode
/// leave + rejoin) must get fresh executors, not the cached old ones - or
/// every trigger fires and every probe samples twice.
void main() {
  setUpAll(() => CarpMobileSensing.ensureInitialized());

  test('disposing a deployment executor clears its cached executors', () async {
    final phone = Smartphone(roleName: 'phone');
    final task = BackgroundTask(
      name: 'task',
      measures: [Measure(type: DeviceSamplingPackage.FREE_MEMORY)],
    );
    final deployment = SmartphoneDeployment(
      studyDeploymentId: 'same-id',
      deviceConfiguration: phone,
      registration: DeviceRegistration(),
      tasks: {task},
      triggers: {'0': ImmediateTrigger()},
      taskControls: {TaskControl(triggerId: 0, task: task, targetDevice: phone)},
    );

    final executor = SmartphoneDeploymentExecutor()..initialize(deployment, deployment);
    final cached = ExecutorFactory().getTaskExecutor('same-id', task);
    expect(ExecutorFactory().getTriggerExecutor('same-id', 0), isNotNull);

    executor.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(ExecutorFactory().getTriggerExecutor('same-id', 0), isNull);
    expect(ExecutorFactory().getTaskExecutor('same-id', task), isNot(same(cached)));
  });
}
