import 'dart:async';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:test/test.dart';

/// A [StreamProbe] collecting from a stream that is controlled by the test.
class _TestStreamProbe extends StreamProbe {
  final controller = StreamController<Measurement>.broadcast();

  @override
  Future<bool> hasRequiredPermissions() async => true;

  @override
  Stream<Measurement> get stream => controller.stream;
}

void main() {
  setUp(() {
    CarpMobileSensing.ensureInitialized();
  });

  test(
    'Resuming a resumed stream probe collects each measurement once',
    () async {
      final probe = _TestStreamProbe();

      final collected = <Measurement>[];
      probe.measurements.listen(collected.add);

      await probe.onResume();
      // Resuming again must cancel the previous subscription. Overwriting it
      // would orphan a subscription that keeps delivering, and every measurement
      // would be collected once per resume.
      await probe.onResume();

      probe.controller.add(Measurement.fromData(FileData(filename: 'test')));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(collected.length, 1);

      await probe.onPause();
      await probe.controller.close();
    },
  );
}
