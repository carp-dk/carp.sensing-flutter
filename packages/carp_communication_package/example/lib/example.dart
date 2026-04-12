import 'dart:ui';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_communication_package/communication.dart';

/// This is a very simple example of how this sampling package is used with
/// CARP Mobile Sensing (CAMS).
/// NOTE, however, that the code below will not run.
/// See the documentation on how to use CAMS: https://github.com/cph-cachet/carp.sensing-flutter/wiki
void main() async {
  // Register this sampling package before using its measures
  SamplingPackageRegistry().register(CommunicationSamplingPackage());

  // Create a study protocol
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Communication Sensing Example',
  );

  // Define which devices are used for data collection
  // In this case, it is only this smartphone
  Smartphone phone = Smartphone();
  protocol.addPrimaryDevice(phone);

  // Add a background task that collects incoming SMS messages
  protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
          measures: [Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE)]),
      phone);

  // Add a background task that collects the logs for:
  //  * in/out SMS
  //  * in/out phone calls
  //  * calendar entries
  // every 3 hours
  protocol.addTaskControl(
      PeriodicTrigger(period: const Duration(hours: 3)),
      BackgroundTask(measures: [
        Measure(type: CommunicationSamplingPackage.PHONE_LOG),
        Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE_LOG),
        Measure(type: CommunicationSamplingPackage.CALENDAR),
      ]),
      phone);

  // Add a background task that collects the calendar entries for the past 7
  // days (max), every time the app is resumed (i.e., when coming to foreground).
  protocol.addTaskControl(
      AppLifecycleTrigger({AppLifecycleState.resumed}),
      BackgroundTask(measures: [
        Measure(type: CommunicationSamplingPackage.CALENDAR)
          ..overrideSamplingConfiguration =
              HistoricSamplingConfiguration(past: const Duration(days: 7)),
      ]),
      phone);
}
