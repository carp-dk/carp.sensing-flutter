/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:flutter/material.dart' hide TimeOfDay;

import 'trigger_example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();
  runApp(const CARPMobileSensingApp());
}

class CARPMobileSensingApp extends StatelessWidget {
  const CARPMobileSensingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CARP Mobile Sensing Demo',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const ConsolePage(title: 'CARP Mobile Sensing Demo'),
  );
}

class ConsolePage extends StatefulWidget {
  final String title;
  const ConsolePage({super.key, required this.title});
  @override
  Console createState() => Console();
}

/// A simple UI with a console that shows the sensed data in a json format.
class Console extends State<ConsolePage> {
  String _log = '';

  @override
  void initState() {
    super.initState();
    Settings().debugLevel = DebugLevel.debug;
    Settings().init().then((_) {
      Sensing().init().then((_) {
        log('Client state : ${SmartPhoneClientManager().state}');
      });
    });
  }

  @override
  void dispose() {
    Sensing().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SingleChildScrollView(
      child: StreamBuilder(
        stream: SmartPhoneClientManager().measurements,
        builder: (context, AsyncSnapshot<Measurement> snapshot) => Text(
          (snapshot.hasData) ? _log += toJsonString(snapshot.data) : _log,
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: restart,
      tooltip: 'Start/Stop study',
      child: StreamBuilder<ExecutorState>(
        stream: Sensing().controller?.executor.stateEvents,
        initialData: ExecutorState.Created,
        builder: (_, _) =>
            Sensing().isRunning ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
    ),
  );

  /// Add [msg] to the console log.
  void log(String msg) => setState(() => _log += '$msg\n');

  /// Clear the console log.
  void clearLog() => setState(() => _log = '');

  /// Restart (start/stop) sampling.
  void restart() {
    setState(() {
      Sensing().isRunning ? Sensing().pause() : Sensing().resume();
    }); // to update the play/stop icon
  }
}

/// This class handles sensing logic.
///
/// This example is useful for creating a Business Logical Object (BLOC) in a
/// Flutter app.
///
/// For a much more elaborate example of a app using CAMS, see the CARP Mobile
/// Sensing App at https://github.com/cph-cachet/carp.sensing-flutter/tree/master/apps/carp_mobile_sensing_app
class Sensing {
  static final Sensing _instance = Sensing._();
  Sensing._() {
    ExecutorFactory().registerTriggerFactory(RemoteTriggerFactory());
  }

  /// The singleton Sensing instance.
  factory Sensing() => _instance;

  /// The study deployed on this phone.
  SmartphoneStudy? study;

  /// Initialize sensing.
  Future<void> init() async {
    // Get the protocol. See below for how to configure a study protocol.
    final protocol = await LocalStudyProtocolManager().getStudyProtocol('');

    // Create and configure a client manager for this phone, add the protocol
    // and start the study.
    await SmartPhoneClientManager().configure();
    study = await SmartPhoneClientManager().addStudyFromProtocol(protocol);
    SmartPhoneClientManager().start();

    // Listening on the data stream and print them as json.
    SmartPhoneClientManager().measurements.listen(
      (data) => print(toJsonString(data)),
    );
  }

  /// The study runtime controller for this [study]
  SmartphoneStudyController? get controller => (study != null)
      ? SmartPhoneClientManager().getStudyController(study!)
      : null;

  /// Is sensing running, i.e. has the study executor been started?
  // bool get isRunning => controller?.executor.state == ExecutorState.resumed;
  bool get isRunning => study?.samplingStatus == ExecutorState.Resumed;

  /// Start sensing
  void resume() => controller?.resume();

  /// Stop sensing
  void pause() => controller?.pause();

  /// Dispose sensing
  void dispose() => SmartPhoneClientManager().dispose();
}

/// This is a simple local [StudyProtocolManager].
///
/// This class shows how to configure a [StudyProtocol] with devices,
/// triggers, tasks, measures, and task controls.
class LocalStudyProtocolManager implements StudyProtocolManager {
  @override
  Future<void> initialize() async {}

  /// Create a new CAMS study protocol.
  @override
  Future<SmartphoneStudyProtocol> getStudyProtocol(String id) async {
    // Create a protocol. Note that the [id] is not used for anything.
    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
      ownerId: 'AB',
      name: 'Protocol - id: $id',
      dataEndPoint: SQLiteDataEndPoint(),
    );

    // Define which devices are used for data collection.
    //
    // In this case, its only this phone.
    // See the CARP Mobile Sensing app for a full-blown example of how to
    // use connected devices (e.g., a Polar heart rate monitor) and online
    // services (e.g., a weather service).
    var phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // Add a participant role
    protocol.addParticipantRole(ParticipantRole('Participant'));

    // Collect timezone info every time the app restarts.
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(measures: [Measure(type: DeviceSamplingPackage.TIMEZONE)]),
      phone,
    );

    // Collect device info only once, when this study is deployed.
    protocol.addTaskControl(
      OneTimeTrigger(),
      BackgroundTask(
        measures: [Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)],
      ),
      phone,
    );

    // Add background measures from the [DeviceSamplingPackage] and
    // [SensorSamplingPackage] sampling packages.

    // Note that some of these measures only works on Android:
    //  * screen events
    //  * ambient light
    //  * free memory (there seems to be a bug in the underlying sysinfo plugin)

    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
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
    // protocol.addTaskControl(
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

    // Extract acceleration features every minute over 10 seconds
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: SensorSamplingPackage.ACCELERATION_FEATURES)
            ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
              interval: const Duration(minutes: 1),
              duration: const Duration(seconds: 10),
            ),
        ],
      ),
      phone,
    );

    // // Example of how to start and stop sampling using the Control.Start and
    // // Control.Stop method
    // var task_1 = BackgroundTask(
    //   measures: [
    //     Measure(type: CarpDataTypes.ACCELERATION_TYPE_NAME),
    //     Measure(type: CarpDataTypes.ROTATION_TYPE_NAME),
    //   ],
    // );

    // var task_2 = BackgroundTask(
    //   measures: [
    //     Measure(type: DeviceSamplingPackage.BATTERY_STATE),
    //   ],
    // );

    // // Start both task_1 and task_2
    // protocol.addTaskControls(
    //   ImmediateTrigger(),
    //   [task_1, task_2],
    //   phone,
    //   Control.Start,
    // );

    // // After a while, stop task_1 again
    // protocol.addTaskControl(
    //   DelayedTrigger(delay: const Duration(seconds: 10)),
    //   task_1,
    //   phone,
    //   Control.Stop,
    // );

    // // add a random trigger to collect device info at random times
    // protocol.addTaskControl(
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

    // // add a ConditionalPeriodicTrigger to check periodically
    // protocol.addTaskControl(
    //     ConditionalPeriodicTrigger(
    //         period: const Duration(seconds: 20),
    //         triggerCondition: () => ('Jakob'.length == 5)),
    //     BackgroundTask()
    //       ..addMeasure(Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)),
    //     phone,
    //     Control.Start);

    // // Collect device info after 30 secs
    // protocol.addTaskControl(
    //   ElapsedTimeTrigger(elapsedTime: const Duration(seconds: 30)),
    //   BackgroundTask(
    //     measures: [
    //       Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION),
    //     ],
    //   ),
    //   phone,
    // );

    // Add app tasks with notifications.
    //
    // These App Tasks are added for demo purpose and you should see notifications
    // on the phone. However, nothing will happen when you click on it.
    // See the PulmonaryMonitor demo app for a full-scale example of how to use
    // the App Task model.

    // // Add a task after deployment and make a notification.
    // protocol.addTaskControl(
    //   ElapsedTimeTrigger(elapsedTime: const Duration(seconds: 10)),
    //   AppTask(
    //     type: BackgroundSensingUserTask.SENSING_TYPE,
    //     title: "Elapsed Time Trigger - App Task",
    //     description: 'Collection of Device Information.',
    //     measures: [Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)],
    //     notification: true,
    //   ),
    //   phone,
    // );

    // // Add a cron job every day at 11:45
    // protocol.addTaskControl(
    //     CronScheduledTrigger.parse(cronExpression: '45 11 * * *'),
    //     AppTask(
    //       type: BackgroundSensingUserTask.SENSING_TYPE,
    //       title: "Cron - every day at 11:45",
    //       measures: [Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)],
    //       notification: true,
    //     ),
    //     phone);

    return protocol;
  }

  @override
  Future<bool> saveStudyProtocol(String studyId, StudyProtocol protocol) async {
    throw UnimplementedError();
  }
}
