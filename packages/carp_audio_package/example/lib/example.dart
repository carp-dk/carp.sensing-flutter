// ignore_for_file: depend_on_referenced_packages

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_audio_package/media.dart';

/// This is a very simple example of how this sampling package is used with
/// CARP Mobile Sensing (CAMS).
/// NOTE, however, that the code below will not run.
/// See the documentation on how to use CAMS: https://github.com/cph-cachet/carp.sensing-flutter/wiki
void main() async {
  // register this sampling package before using its measures
  SamplingPackageRegistry().register(MediaSamplingPackage());

  // Create a study protocol
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Audio Sensing Example',
  );

  // Define which devices are used for data collection
  // In this case, its only this smartphone
  Smartphone phone = Smartphone();
  protocol.addPrimaryDevice(phone);

  // Add an task that immediately starts collecting noise.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(measures: [Measure(type: MediaSamplingPackage.NOISE)]),
    phone,
  );

  // Collect noise, but change the default sampling configuration
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: MediaSamplingPackage.NOISE)
          ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
            interval: const Duration(seconds: 30),
            duration: const Duration(seconds: 5),
          ),
      ],
    ),
    phone,
  );

  // Sample an audio recording
  var audioTask = BackgroundTask(
    measures: [Measure(type: MediaSamplingPackage.AUDIO)],
  );

  // Start the audio task after 20 secs and stop it after 40 secs
  protocol
    ..addTaskControl(
      DelayedTrigger(delay: const Duration(seconds: 20)),
      audioTask,
      phone,
      Control.Start,
    )
    ..addTaskControl(
      DelayedTrigger(delay: const Duration(seconds: 40)),
      audioTask,
      phone,
      Control.Stop,
    );
}
