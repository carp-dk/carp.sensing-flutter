// ignore_for_file: depend_on_referenced_packages

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_esense_package/esense.dart';

/// This is a very simple example of how this sampling package is used as part
/// of defining a study protocol in CARP Mobile Sensing (CAMS).
///
/// NOTE, however, that the code below will not run on it own. A study protocol
/// needs to be deployed and executed in the CAMS framework.
///
/// See the documentation on how to use CAMS:
/// https://docs.carp.dk/carp-mobile-sensing/
void main() async {
  // Register this sampling package before using its measures
  SamplingPackageRegistry().register(ESenseSamplingPackage());

  // Create a study protocol
  var protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'eSense Sensing Example',
  );

  // Define which devices are used for data collection - both phone and eSense
  // and add them to the protocol.
  var phone = Smartphone();
  var eSense = ESenseDevice(samplingRate: 10);

  protocol
    ..addPrimaryDevice(phone)
    ..addConnectedDevice(eSense, phone);

  // Add a background task that immediately starts collecting step counts,
  // ambient light, screen activity, and battery level from the phone.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: SensorSamplingPackage.STEP_EVENT),
        Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
        Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
        Measure(type: DeviceSamplingPackage.BATTERY_STATE),
      ],
    ),
    phone,
  );

  // Add a background task that immediately starts collecting eSense button and
  // sensor events from the eSense device.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: ESenseSamplingPackage.ESENSE_BUTTON),
        Measure(type: ESenseSamplingPackage.ESENSE_SENSOR),
      ],
    ),
    eSense,
  );
}
