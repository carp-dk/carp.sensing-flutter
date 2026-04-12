// ignore_for_file: depend_on_referenced_packages

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_survey_package/survey.dart';
import 'package:research_package/research_package.dart';
import 'package:cognition_package/cognition_package.dart';

/// This is a very simple example of how this sampling package is used with
/// CARP Mobile Sensing (CAMS).
/// NOTE, however, that the code below will not run.
/// See the documentation on how to use CAMS: https://github.com/cph-cachet/carp.sensing-flutter/wiki
void main() async {
  // register this sampling package before using its measures
  SamplingPackageRegistry().register(SurveySamplingPackage());

  // Create a study protocol
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Survey Example',
  );

  // Define which devices are used for data collection.
  // In this case, its only this smartphone
  Smartphone phone = Smartphone();
  protocol.addPrimaryDevice(phone);

  // Add a task control to the protocol that triggers every day at 13:00,
  // issuing a WHO-5 survey while also collecting device and
  // ambient light information when survey is initiated by the user.
  protocol.addTaskControl(
    RecurrentScheduledTrigger(
      type: RecurrentType.daily,
      time: TimeOfDay(hour: 13),
    ),
    RPAppTask(
      type: AppTask.SURVEY_TYPE,
      name: 'WHO-5 Survey',
      rpTask: who5Task,
      measures: [
        Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION),
        Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
      ],
    ),
    phone,
  );

  // Add a Parkinson's assessment consisting of;
  //  * an instruction step
  //  * a timer step that collects accelerometer and gyroscope data while the user is holding the phone
  //  * a Flanker test (from cognition package).
  //  * a Tapping Activity test (from cognition package).
  //
  // Accelerometer and gyroscope data is collected while the user is performing
  // the task in oder to assess tremor.
  protocol.addTaskControl(
    PeriodicTrigger(period: const Duration(hours: 2)),
    RPAppTask(
      type: AppTask.COGNITIVE_ASSESSMENT_TYPE,
      title: "Parkinson's' Assessment",
      description: "A simple task assessing finger tapping speed.",
      minutesToComplete: 3,
      rpTask: RPOrderedTask(
        identifier: "parkinsons_assessment",
        steps: [
          RPInstructionStep(
            identifier: 'parkinsons_instruction',
            title: "Parkinsons' Disease Assessment",
            text:
                "In the following pages, you will be asked to solve two simple test which will help assess your symptoms on a daily basis. "
                "Each test has an instruction page, which you should read carefully before starting the test.\n\n"
                "Please sit down comfortably and hold the phone in one hand while performing the test with the other.",
          ),
          RPTimerStep(
            identifier: 'RPTimerStepID',
            timeout: const Duration(seconds: 6),
            title:
                "Please stand up. "
                "Hold the phone in your dominant hand and lift it in a straight arm until you hear the sound.",
            playSound: true,
          ),
          RPFlankerActivity(
            identifier: 'flanker_1',
            lengthOfTest: 30,
            numberOfCards: 10,
          ),
          RPTappingActivity(identifier: 'tapping_1', lengthOfTest: 10),
        ],
      ),
      measures: [
        Measure(type: SensorSamplingPackage.ACCELERATION),
        Measure(type: SensorSamplingPackage.ROTATION),
      ],
    ),
    phone,
  );
}
