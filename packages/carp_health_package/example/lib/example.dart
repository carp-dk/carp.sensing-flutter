// ignore_for_file: depend_on_referenced_packages

import 'dart:ui';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_health_package/health_package.dart';
import 'package:health/health.dart';

/// This is a very simple example of how this sampling package is used with
/// CARP Mobile Sensing (CAMS).
/// NOTE, however, that the code below will not run.
/// See the documentation on how to use CAMS: https://github.com/cph-cachet/carp.sensing-flutter/wiki
void main() async {
  // Register this sampling package before using its measures
  SamplingPackageRegistry().register(HealthSamplingPackage());

  // Create a study protocol
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Health Sensing Example',
  );

  // Define which devices are used for data collection.

  // First add this smartphone.
  final phone = Smartphone();
  protocol.addPrimaryDevice(phone);

  // Create and add a health service (device)
  final healthService = HealthService();
  protocol.addConnectedDevice(healthService, phone);

  // Automatically collect the set of health data every hour.
  //
  // Note that the [HealthSamplingConfiguration] is a [HistoricSamplingConfiguration]
  // which samples data back in time until last time, data was sampled.
  protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 60)),
    BackgroundTask(
      measures: [
        HealthSamplingPackage.getHealthMeasure([
          HealthDataType.STEPS,
          HealthDataType.BASAL_ENERGY_BURNED,
          HealthDataType.WEIGHT,
          HealthDataType.SLEEP_SESSION,
        ]),
      ],
    ),
    healthService,
  );

  // Automatically collect another set of health data every hour
  //
  // Note, however, that the service defined above DOES NOT have this list of
  // health data specified, and has therefore not asked for permission to access
  // this new set of health data.
  // However, on Apple Health, for example, the user has an option to "Turn All Categories On",
  // and if the use has done this, the all the data listed below is accessible.
  protocol.addTaskControl(
    PeriodicTrigger(period: Duration(minutes: 60)),
    BackgroundTask()..addMeasure(
      HealthSamplingPackage.getHealthMeasure([
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
      ]),
    ),
    healthService,
  );

  // Create a health app task for the user to collect his own health data once pr. day
  protocol.addTaskControl(
    PeriodicTrigger(period: Duration(hours: 24)),
    HealthAppTask(
      title: "Press here to collect your physical health data",
      description:
          "This will collect your weight, exercise time, steps, and sleep "
          "time from the Health database on the phone.",
      types: [
        HealthDataType.WEIGHT,
        HealthDataType.STEPS,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.SLEEP_SESSION,
      ],
    ),
    phone,
  );

  // Create a app task with a WHO-5 survey that also collects some health data.
  // protocol.addTaskControl(
  //     RecurrentScheduledTrigger(
  //       type: RecurrentType.daily,
  //       time: TimeOfDay(hour: 13),
  //     ),
  //     RPAppTask(
  //         type: SurveyUserTask.SURVEY_TYPE,
  //         name: 'WHO-5 Survey',
  //         rpTask: who5Task,
  //         measures: [
  //           Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
  //           HealthSamplingPackage.getHealthMeasure([
  //             HealthDataType.HEART_RATE,
  //             HealthDataType.STEPS,
  //           ])
  //         ]),
  //     phone);

  // Automatically collect the set of health data when the app resumes, i.e. comes
  // to the foreground.
  //
  // Note that the [HealthSamplingConfiguration] is a [HistoricSamplingConfiguration]
  // which samples data back in time until last time, data was sampled.
  protocol.addTaskControl(
    AppLifecycleTrigger({AppLifecycleState.resumed}),
    BackgroundTask(
      measures: [
        HealthSamplingPackage.getHealthMeasure([
          HealthDataType.STEPS,
          HealthDataType.BASAL_ENERGY_BURNED,
          HealthDataType.WEIGHT,
          HealthDataType.SLEEP_SESSION,
        ]),
      ],
    ),
    healthService,
  );
}
