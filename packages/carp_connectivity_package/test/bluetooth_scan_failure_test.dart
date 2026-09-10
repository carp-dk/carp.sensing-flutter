import 'package:carp_connectivity_package/connectivity.dart';
import 'package:carp_core/carp_core.dart' as carp;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:test/test.dart';

class _BluetoothProbe extends BluetoothProbe {
  @override
  PeriodicSamplingConfiguration get samplingConfiguration =>
      PeriodicSamplingConfiguration(
        interval: const Duration(minutes: 1),
        duration: const Duration(seconds: 4),
      );
}

void main() {
  test('scan startup failure is data, and late results cannot overwrite it', () async {
    // No native Bluetooth platform in this test: startScan fails asynchronously.
    final probe = _BluetoothProbe();
    probe.onSamplingStart();
    await Future<void>.delayed(Duration.zero);

    expect((await probe.getMeasurement())?.data, isA<carp.Error>());
    probe.onSamplingData(<ScanResult>[]);
    expect((await probe.getMeasurement())?.data, isA<carp.Error>());
  });
}
