import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:test/test.dart';

/// A disposed executor must ignore initialize/resume - this is what stops a
/// study removed mid-configuration from restarting sampling.
void main() {
  test(
    'disposed deployment executor cannot be initialized or resumed',
    () async {
      final deployment = SmartphoneDeployment(
        deviceConfiguration: Smartphone(roleName: 'phone'),
        registration: DefaultDeviceRegistration(),
      );
      final executor = SmartphoneDeploymentExecutor();
      executor.initialize(deployment, deployment);
      expect(executor.state, ExecutorState.Initialized);

      executor.dispose();
      await Future.delayed(Duration.zero);
      expect(executor.state, ExecutorState.Disposed);

      executor.initialize(deployment, deployment);
      executor.resume();
      expect(executor.state, ExecutorState.Disposed);
    },
  );
}
