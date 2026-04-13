// ignore_for_file: depend_on_referenced_packages

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_polar_package/carp_polar_package.dart';

/// This is a very simple example of how this sampling package is used as part
/// of defining a study protocol in CARP Mobile Sensing (CAMS).
///
/// NOTE, however, that the code below will not run on it own. A study protocol
/// needs to be deployed and executed in the CAMS framework.
///
/// See the documentation on how to use CAMS:
/// https://github.com/cph-cachet/carp.sensing-flutter/wiki
void main() async {
  // register this sampling package before using its measures
  SamplingPackageRegistry().register(PolarSamplingPackage());

  // Create a study protocol
  var protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Polar Sensing Example',
  );

  // Define which devices are used for data collection - both phone and polar device
  // and add them to the protocol.
  var phone = Smartphone();
  var polar = PolarDevice(roleName: 'hr-sensor');

  // Add both devices
  protocol
    ..addPrimaryDevice(phone)
    ..addConnectedDevice(polar, phone);

  // Add a background task that immediately starts collecting step counts,
  // ambient light, screen activity, and battery level from the phone.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask()
      ..addMeasure(Measure(type: SensorSamplingPackage.STEP_EVENT))
      ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT))
      ..addMeasure(Measure(type: DeviceSamplingPackage.SCREEN_EVENT))
      ..addMeasure(Measure(type: DeviceSamplingPackage.BATTERY_STATE)),
    phone,
  );

  // Add a background task that immediately starts collecting HR and ECG data
  // from the Polar device.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: PolarSamplingPackage.HR),
        Measure(type: PolarSamplingPackage.ECG),
      ],
    ),
    polar,
  );
}
