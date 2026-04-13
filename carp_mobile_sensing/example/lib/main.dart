/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

import 'package:flutter/material.dart' hide TimeOfDay;

// The CAMS packages
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

void main() => runApp(const MobileSensingApp());

/// This demo app shows a list of studies in a client manager of CARP Mobile Sensing.
/// Each list tile shows a study showing the study's description and runtime
/// status using a StreamBuilder that listens on the `events` stream from
/// the study.
///
/// You can add a new study using the floating action button (+) at the
/// bottom right corner. This adds a new study based on the protocol defined
/// below.
/// You can remove a study by long-pressing on the study's list tile.
///
/// You can start, pause, and resume data sampling for a study by tapping
/// on the study's list tile.
class MobileSensingApp extends StatelessWidget {
  const MobileSensingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    darkTheme: ThemeData.dark(),
    home: const StudyPage(),
  );
}

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => StudyPageState();
}

/// Shows a list of studies in a ListView.
class StudyPageState extends State<StudyPage> {
  /// The client manager used in this app.
  /// Note that a [SmartPhoneClientManager] is a singleton, so it can always be
  /// accessed using `SmartPhoneClientManager()`. But here is't shorter to just
  /// have a `client` property to use.
  SmartPhoneClientManager client = SmartPhoneClientManager();

  @override
  void initState() {
    // Set debug level for more detailed debugging information.
    Settings().debugLevel = DebugLevel.debug;

    // Configure the client. Note that the client can take a series of configuration
    // parameters, but here we're just using the default configurations.
    client.configure();

    // Listen on all the measurements and print them as json.
    SmartPhoneClientManager().measurements.listen(
      (measurement) => debugPrint(toJsonString(measurement)),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CARP Mobile Sensing')),
      body: ListenableBuilder(
        listenable: client,
        builder: (BuildContext context, Widget? child) => ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          itemCount: client.studies.length,
          itemBuilder: studyTileWithBorder,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addStudy,
        child: Icon(Icons.add),
      ),
    );
  }

  /// Create a list tile for a study showing the study's description and runtime
  /// status using a StreamBuilder that listens on the `events` stream from
  /// the study.
  Widget studyTileWithBorder(BuildContext context, int index) {
    var study = client.studies[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: StreamBuilder<StudyStatusEvent>(
        stream: study.events, // listen to events from the study
        builder: (context, AsyncSnapshot<StudyStatusEvent> snapshot) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 8.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              isThreeLine: true,
              leading: Icon(switch (study.samplingState?.state) {
                ExecutorState.Resumed => Icons.pause,
                _ => Icons.play_arrow,
              }, size: 40),
              title: Text(
                'Study Deployment #$index',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'ID: ...-${study.studyDeploymentId.split('-').last}\n'
                'Status: ${study.status.name}\n'
                'Sampling: ${study.samplingState?.state.name}',
              ),
              trailing: executorStateIcon[study.samplingState?.state],
              onTap: () => runStudy(study),
              onLongPress: () => removeStudy(study),
            ),
          );
        },
      ),
    );
  }

  /// A set of icons to illustrate the [SmartphoneStudy.samplingState].
  static Map<ExecutorState, Icon> get executorStateIcon => {
    ExecutorState.Created: Icon(Icons.child_care),
    ExecutorState.Initialized: Icon(Icons.check),
    ExecutorState.Resumed: Icon(Icons.radio_button_checked),
    ExecutorState.Paused: Icon(Icons.radio_button_unchecked),
    ExecutorState.Undefined: Icon(Icons.error_outline),
  };

  /// Add and deploy a new study to the client's list of studies based on the
  /// either the [simpleProtocol] or [protocol] specified below.
  /// Note that we use the same protocol every time we add a study.
  /// Thus, all studies will be identical in terms of data collection.
  void addStudy() => client
      .addStudyFromProtocol(protocol)
      .then(
        (study) =>
            client.tryDeployment(study.studyDeploymentId, study.deviceRoleName),
      );

  /// Remove [study] from the client's list of studies.
  void removeStudy(SmartphoneStudy study) =>
      client.removeStudy(study.studyDeploymentId, study.deviceRoleName);

  /// Resume or pause [study] based on its current state.
  void runStudy(SmartphoneStudy study) => setState(() {
    var controller = client.getStudyController(study);

    if (study.isSampling) {
      controller?.pause();
    } else {
      controller?.resume();
    }
  });

  /// A simple study protocol that collects a few basic measures
  /// using this smartphone as the primary device.
  SmartphoneStudyProtocol get simpleProtocol => SmartphoneStudyProtocol.local(
    name: 'Simple Protocol',
    measures: [
      Measure(type: DeviceSamplingPackage.HEARTBEAT),
      Measure(type: DeviceSamplingPackage.FREE_MEMORY),
      Measure(type: DeviceSamplingPackage.BATTERY_STATE),
      Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
      Measure(type: DeviceSamplingPackage.APP_LIFECYCLE_EVENT),
      Measure(type: SensorSamplingPackage.STEP_EVENT),
      Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
    ],
  );

  SmartphoneStudyProtocol? _protocol;

  /// Create a new study protocol - advanced version.
  ///
  /// The code below shows many examples of how to add various types of
  /// measures and tasks to the protocol. Most of these are commented out,
  /// but you can uncomment them to see how they work.
  SmartphoneStudyProtocol get protocol {
    if (_protocol == null) {
      _protocol = SmartphoneStudyProtocol(
        ownerId: 'AB',
        name: 'Demo Protocol',
        dataEndPoint: SQLiteDataEndPoint(),
      );

      // Define which devices are used for data collection.
      //
      // In this case, its only this phone.
      // See the CARP Mobile Sensing app for a full-blown example of how to
      // use connected devices (e.g., a Polar heart rate monitor) and online
      // services (e.g., a weather service).
      var phone = Smartphone();
      _protocol?.addPrimaryDevice(phone);

      // Add a participant role
      _protocol?.addParticipantRole(ParticipantRole('Participant'));

      // Now add tasks and measures to the protocol.

      // Collect timezone info every time the app restarts and set up a heartbeat
      // measure to check that the app is still alive. Override the default sampling
      // interval for the heartbeat measure to 1 min (instead of 15 min).
      _protocol?.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(
          name: 'Timezone Task',
          measures: [
            Measure(type: DeviceSamplingPackage.TIMEZONE),
            Measure(type: DeviceSamplingPackage.HEARTBEAT)
              ..overrideSamplingConfiguration = IntervalSamplingConfiguration(
                interval: const Duration(minutes: 1),
              ),
          ],
        ),
        phone,
      );

      // Collect timezone info every 10 seconds.
      // Note that timezone is a one-time measure, so this can be collected
      // using a periodic trigger. Collecting it periodically does, however,
      // not make much sense. This is just to demonstrate the use of a periodic
      // trigger, which is useful for many other types of measures.
      _protocol?.addTaskControl(
        PeriodicTrigger(period: Duration(seconds: 10)),
        BackgroundTask(
          measures: [Measure(type: DeviceSamplingPackage.TIMEZONE)],
        ),
        phone,
      );

      // Collect device info only once, when this study is deployed.
      _protocol?.addTaskControl(
        OneTimeTrigger(),
        BackgroundTask(
          name: 'Device Info Task',
          measures: [Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)],
        ),
        phone,
      );

      // Add background measures from the [DeviceSamplingPackage] and
      // [SensorSamplingPackage] sampling packages.
      //
      // Note that some of these measures only works on Android:
      //  * screen events
      //  * ambient light
      //  * free memory (there seems to be a bug in the underlying sysinfo plugin)
      _protocol?.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(
          name: 'Background Measures Task',
          measures: [
            Measure(type: DeviceSamplingPackage.FREE_MEMORY)
              ..overrideSamplingConfiguration = IntervalSamplingConfiguration(
                interval: const Duration(seconds: 10),
              ),
            Measure(type: DeviceSamplingPackage.BATTERY_STATE),
            Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
            Measure(type: DeviceSamplingPackage.APP_LIFECYCLE_EVENT),
            Measure(type: SensorSamplingPackage.STEP_EVENT),
            Measure(type: SensorSamplingPackage.AMBIENT_LIGHT)
              ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
                interval: const Duration(seconds: 20),
                duration: const Duration(seconds: 5),
              ),
          ],
        ),
        phone,
      );

      // // Collect IMU data every 10 secs for 1 sec.
      // // Also shows how the sampling interval can be specified ("overridden").
      // // Default sampling interval is 200 ms. Note that it seems like setting the
      // // sampling interval does NOT work on Android (see also the docs on the
      // // sensor_plus package and on the Android sensor documentation:
      // //   https://developer.android.com/reference/android/hardware/SensorManager#registerListener(android.hardware.SensorEventListener,%20android.hardware.Sensor,%20int)
      // _protocol?.addTaskControl(
      //   PeriodicTrigger(period: const Duration(seconds: 10)),
      //   BackgroundTask(
      //     measures: [
      //       Measure(type: SensorSamplingPackage.ACCELERATION)
      //         ..overrideSamplingConfiguration = IntervalSamplingConfiguration(
      //             interval: const Duration(milliseconds: 500)),
      //       Measure(type: SensorSamplingPackage.ROTATION),
      //     ],
      //     duration: const Duration(seconds: 1),
      //   ),
      //   phone,
      // );

      // // Extract acceleration features every minute over 10 seconds
      // _protocol?.addTaskControl(
      //   ImmediateTrigger(),
      //   BackgroundTask(
      //     measures: [
      //       Measure(type: SensorSamplingPackage.ACCELERATION_FEATURES)
      //         ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
      //           interval: const Duration(minutes: 1),
      //           duration: const Duration(seconds: 10),
      //         ),
      //     ],
      //   ),
      //   phone,
      // );

      // // Example of how to start and stop sampling using the Control.Start and
      // // Control.Stop method
      // var task_1 = BackgroundTask(
      //   measures: [
      //     Measure(type: CarpDataTypes.ACCELERATION_TYPE_NAME),
      //     Measure(type: CarpDataTypes.ROTATION_TYPE_NAME),
      //   ],
      // );

      // var task_2 = BackgroundTask(
      //   measures: [Measure(type: DeviceSamplingPackage.BATTERY_STATE)],
      // );

      // // Start both task_1 and task_2
      // _protocol?.addTaskControls(
      //   ImmediateTrigger(),
      //   [task_1, task_2],
      //   phone,
      //   Control.Start,
      // );

      // // After a while, stop task_1 again
      // _protocol?.addTaskControl(
      //   DelayedTrigger(delay: const Duration(seconds: 10)),
      //   task_1,
      //   phone,
      //   Control.Stop,
      // );

      // Add a random trigger to collect device info at random times
      // _protocol?.addTaskControl(
      //   RandomRecurrentTrigger(
      //     startTime: TimeOfDay(hour: 07, minute: 45),
      //     endTime: TimeOfDay(hour: 22, minute: 30),
      //     minNumberOfTriggers: 2,
      //     maxNumberOfTriggers: 8,
      //   ),
      //   BackgroundTask()
      //     ..addMeasure(Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)),
      //   phone,
      //   Control.Start,
      // );

      // Add a ConditionalPeriodicTrigger to check periodically
      // _protocol?.addTaskControl(
      //     ConditionalPeriodicTrigger(
      //         period: const Duration(seconds: 20),
      //         triggerCondition: () => ('Jakob'.length == 5)),
      //     BackgroundTask()
      //       ..addMeasure(Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)),
      //     phone,
      //     Control.Start);

      // Collect device info after 30 secs
      // _protocol?.addTaskControl(
      //   ElapsedTimeTrigger(elapsedTime: const Duration(seconds: 30)),
      //   BackgroundTask(
      //     measures: [
      //       Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION),
      //     ],
      //   ),
      //   phone,
      // );

      // Add app task with notifications.
      //
      // This App Task is added for demo purpose and you should see  a notification
      // on the phone. When you click on it, the app task is started and collects
      // device information.
      // See the PulmonaryMonitor demo app for a full-scale example of how to use
      // the App Task model.
      //
      // Note that by design, iOS applications do not display notifications while
      // the app is in the foreground. So to see the notification, please
      // background the app after deploying the study.

      // Trigger an app task some secs after deployment and make a notification.
      _protocol?.addTaskControl(
        ElapsedTimeTrigger(elapsedTime: const Duration(seconds: 60)),
        AppTask(
          name: 'Device Info App Task',
          type: AppTask.SENSING_TYPE,
          title: "User Task",
          description: 'Please click here to collect Device Information.',
          measures: [Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)],
          notification: true,
        ),
        phone,
      );

      // // Add a cron job every day at 11:45
      // _protocol?.addTaskControl(
      //     CronScheduledTrigger.parse(cronExpression: '45 11 * * *'),
      //     AppTask(
      //       type: BackgroundSensingUserTask.SENSING_TYPE,
      //       title: "Cron - every day at 11:45",
      //       measures: [Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)],
      //       notification: true,
      //     ),
      //     phone);
    }

    return _protocol!;
  }
}
