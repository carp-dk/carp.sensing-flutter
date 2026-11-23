import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_background');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('disable() clears isEnabled on success and keeps it on failure', () async {
    var disableResult = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'disableBackgroundExecution' ? disableResult : true,
    );

    expect(await BackgroundService().initialize(), isTrue);
    expect(await BackgroundService().enable(), isTrue);
    expect(BackgroundService().isEnabled, isTrue);

    expect(await BackgroundService().disable(), isFalse);
    expect(BackgroundService().isEnabled, isTrue);

    disableResult = true;
    expect(await BackgroundService().disable(), isTrue);
    expect(BackgroundService().isEnabled, isFalse);

    // Can be enabled again after disabling (e.g. leave and rejoin a study).
    expect(await BackgroundService().enable(), isTrue);
    expect(BackgroundService().isEnabled, isTrue);
  });
}
