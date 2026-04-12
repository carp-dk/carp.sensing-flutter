// ignore_for_file: depend_on_referenced_packages

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_movisens_package/carp_movisens_package.dart';

/// This is a very simple example of how this sampling package is used with
/// CARP Mobile Sensing (CAMS).
/// NOTE, however, that the code below will not run.
/// See the documentation on how to use CAMS: https://github.com/cph-cachet/carp.sensing-flutter/wiki
void main() async {
  // register this sampling package before using its measures
  SamplingPackageRegistry().register(MovisensSamplingPackage());

  // Create a study protocol
  var protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Movisens Example',
  );

  // Define which devices are used for data collection - both phone and Movisens
  // and add them to the protocol.
  // Note that the Movisens device is added as a connected device to the phone.
  var phone = Smartphone();
  var movisens = MovisensDevice(
    sensorLocation: SensorLocation.Chest,
    sex: Sex.Male,
    height: 175,
    weight: 75,
    age: 25,
  );

  protocol
    ..addPrimaryDevice(phone)
    ..addConnectedDevice(movisens, phone);

  // Adding a movisens measure
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      name: 'Movisens Task',
      measures: [Measure(type: MovisensSamplingPackage.ACTIVITY)],
    ),
    movisens,
  );
}
