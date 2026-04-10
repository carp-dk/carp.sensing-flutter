// ignore_for_file: depend_on_referenced_packages

import 'dart:ui';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_apps_package/apps.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

/// This is a very simple example of how this sampling package is used with
/// CARP Mobile Sensing (CAMS).
/// NOTE, however, that the code below will not run.
/// See the documentation on how to use CAMS: https://github.com/cph-cachet/carp.sensing-flutter/wiki
void main() async {
  // Register this sampling package before using its measures
  SamplingPackageRegistry().register(AppsSamplingPackage());

  // Create a study protocol
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Apps Sensing Example',
  );

  // Define which devices are used for data collection
  // In this case, its only this smartphone
  Smartphone phone = Smartphone();
  protocol.addPrimaryDevice(phone);

  // Add an background task that collects the list of installed apps
  // and a log of app usage activity
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: AppsSamplingPackage.APPS),
        Measure(type: AppsSamplingPackage.APP_USAGE),
      ],
    ),
    phone,
  );

  // Add an background task that collects app usage activity when this app
  // changes state to foreground.
  protocol.addTaskControl(
    AppLifecycleTrigger({AppLifecycleState.resumed}),
    BackgroundTask(measures: [Measure(type: AppsSamplingPackage.APP_USAGE)]),
    phone,
  );
}
