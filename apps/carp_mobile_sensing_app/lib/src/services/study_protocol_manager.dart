part of '../../main.dart';

/// This is a local [StudyProtocolManager] which provides a [SmartphoneStudyProtocol]
/// when running in local mode.
///
/// It create a study protocol for a single participant with example measures
/// from different sampling packages.
class LocalStudyProtocolManager implements StudyProtocolManager {
  @override
  Future<void> initialize() async {}

  @override
  Future<SmartphoneStudyProtocol> getStudyProtocol(String protocolId) async {
    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
      applicationName: SmartphoneStudyProtocol.CAMS_DEMO_APP_NAME,
      name: 'CAMS App - Demo Study Protocol',
      studyDescription: StudyDescription(
        title: 'CAMS App - Demo Study',
        description:
            'A study demonstrating most measures and probes. Used for the demo app.',
      ),
      dataEndPoint: (bloc.deploymentMode == DeploymentMode.local)
          ? SQLiteDataEndPoint()
          : CarpDataEndPoint(
              uploadMethod: CarpUploadMethod.stream,
              deleteWhenUploaded: false,
            ),
    );

    // Always add at least one participant role to the protocol
    final participant = 'Participant';
    protocol.participantRoles?.add(ParticipantRole(participant, false));

    // Define the primary device as a mobile sensing smartphone (i.e., this app)
    final phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // Collect device and application information every time sensing starts
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        name: 'Device Info Task',
        measures: [
          Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION),
          Measure(type: DeviceSamplingPackage.APPLICATION_INFORMATION),
        ],
      ),
      phone,
    );

    // Build-in measure from sensor and device sampling packages
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: DeviceSamplingPackage.HEARTBEAT),
          Measure(type: DeviceSamplingPackage.FREE_MEMORY),
          Measure(type: DeviceSamplingPackage.BATTERY_STATE),
          Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
          Measure(type: DeviceSamplingPackage.APP_LIFECYCLE_EVENT),
          Measure(type: SensorSamplingPackage.STEP_EVENT),
          Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
        ],
      ),
      phone,
    );

    // // A random trigger - 3-8 times during time period of 8-20
    // protocol.addTaskControl(
    //     RandomRecurrentTrigger(
    //       startTime: TimeOfDay(hour: 8),
    //       endTime: TimeOfDay(hour: 20),
    //       minNumberOfTriggers: 3,
    //       maxNumberOfTriggers: 8,
    //     ),
    //     BackgroundTask(measures: [
    //       Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)
    //     ]),
    //     phone);

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

    // Add an app task that triggers after deployment with a notification.
    protocol.addTaskControl(
      ElapsedTimeTrigger(elapsedTime: const Duration(minutes: 3)),
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

    //
    // --------- CONTEXT PACKAGE EXAMPLES -------------
    //

    // Activity measure using the phone
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [Measure(type: ContextSamplingPackage.ACTIVITY)],
      ),
      phone,
    );

    // Define the location service and add it as a 'device'
    final locationService = LocationService(
      // used for debugging when the phone is laying still on the table
      // remove the location filter to get real location data when moving around
      distance: 0,
    );
    protocol.addConnectedDevice(locationService, phone);

    // Background task that collects location on a regular basis
    // protocol.addTaskControl(
    //   PeriodicTrigger(period: Duration(seconds: 20)),
    //   BackgroundTask(
    //     measures: [
    //       Measure(type: ContextSamplingPackage.LOCATION)
    //         // Override the default sampling configuration to just get
    //         // a single location sample each time the task is triggered.
    //         ..overrideSamplingConfiguration = LocationSamplingConfiguration(
    //           once: true,
    //         ),
    //     ],
    //   ),
    //   locationService,
    // );

    // Background task that continuously collects location and mobility features
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: ContextSamplingPackage.LOCATION),
          Measure(type: ContextSamplingPackage.MOBILITY),
        ],
      ),
      locationService,
    );

    // Define the weather service and add it as a 'device'
    WeatherService weatherService = WeatherService(apiKey: openWeatherApiKey);
    protocol.addConnectedDevice(weatherService, phone);

    // Background task that collects weather every 5 minutes.
    protocol.addTaskControl(
      PeriodicTrigger(period: Duration(minutes: 5)),
      BackgroundTask(measures: [Measure(type: ContextSamplingPackage.WEATHER)]),
      weatherService,
    );

    // // Define the online air quality service and add it as a 'device'
    // AirQualityService airQualityService =
    //     AirQualityService(apiKey: airQualityApiKey);
    // protocol.addConnectedDevice(airQualityService, phone);

    // // Background task that air quality every 30 minutes.
    // protocol.addTaskControl(
    //     PeriodicTrigger(period: Duration(minutes: 30)),
    //     BackgroundTask()
    //       ..addMeasure(Measure(type: ContextSamplingPackage.AIR_QUALITY)),
    //     airQualityService);

    //
    // --------- MEDIA PACKAGE EXAMPLES -------------
    //

    // Collect noise, but change the default sampling configuration
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: MediaSamplingPackage.NOISE)
            ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
              interval: const Duration(seconds: 23),
              duration: const Duration(seconds: 5),
            ),
        ],
      ),
      phone,
    );

    // // sample an audio recording
    // var audioTask = BackgroundTask(measures: [
    //   Measure(type: MediaSamplingPackage.AUDIO),
    // ]);

    // // start the audio task after 20 secs and record for 20 secs
    // protocol
    //   ..addTaskControl(
    //     DelayedTrigger(delay: const Duration(seconds: 20)),
    //     audioTask,
    //     phone,
    //     Control.Start,
    //   )
    //   ..addTaskControl(
    //     DelayedTrigger(delay: const Duration(seconds: 40)),
    //     audioTask,
    //     phone,
    //     Control.Stop,
    //   );

    //
    // --------- CONNECTIVITY PACKAGE EXAMPLES -------------
    //

    // Collect connectivity data, but change the default sampling configuration for Bluetooth
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: ConnectivitySamplingPackage.CONNECTIVITY),
          Measure(type: ConnectivitySamplingPackage.WIFI),
          Measure(type: ConnectivitySamplingPackage.BLUETOOTH)
            ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
              interval: const Duration(seconds: 33),
              duration: const Duration(seconds: 5),
            ),
        ],
      ),
      phone,
    );

    //
    // --------- COMMUNICATION PACKAGE EXAMPLES -------------
    //

    // Background task that collects SMS messages in/out
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        measures: [Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE)],
      ),
      phone,
    );

    // Background task that collects the logs for:
    //  * SMS log (in/out)
    //  * phone call log (in/out)
    //  * calendar entries
    // Triggers every time the app is resumed (i.e., comes to the foreground).
    protocol.addTaskControl(
      // AppLifecycleTrigger({AppLifecycleState.resumed}),
      PeriodicTrigger(period: const Duration(minutes: 1)),
      BackgroundTask(
        measures: [
          // Measure(type: CommunicationSamplingPackage.PHONE_LOG),
          // Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE_LOG),
          Measure(type: CommunicationSamplingPackage.CALENDAR),
        ],
      ),
      phone,
    );

    //
    // --------- APP PACKAGE EXAMPLES -------------
    //

    // Add a task that collects the list of installed apps
    // and a log of app usage activity
    protocol.addTaskControl(
      // PeriodicTrigger(period: const Duration(minutes: 1)),
      ImmediateTrigger(),
      BackgroundTask(
        measures: [
          Measure(type: AppsSamplingPackage.APPS),
          Measure(type: AppsSamplingPackage.APP_USAGE),
        ],
      ),
      phone,
    );

    //
    // --------- eSENSE PACKAGE EXAMPLES -------------
    //

    // // Define the sSense device and add its measures
    // ESenseDevice eSense = ESenseDevice(samplingRate: 10);
    // protocol.addConnectedDevice(eSense, phone);

    // protocol.addTaskControl(
    //   ImmediateTrigger(),
    //   BackgroundTask(
    //     measures: [
    //       Measure(type: ESenseSamplingPackage.ESENSE_BUTTON),
    //       Measure(type: ESenseSamplingPackage.ESENSE_SENSOR),
    //     ],
    //   ),
    //   eSense,
    // );

    //
    // --------- POLAR PACKAGE EXAMPLES -------------
    //

    // define the Polar device and add its measures
    // var polar = PolarDevice(
    //   identifier: 'B5FC172F',
    //   name: 'Polar H10 HR Monitor',
    //   deviceType: PolarDeviceType.H10,
    // );
    var polar = PolarDevice();
    protocol.addConnectedDevice(polar, phone);

    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        name: 'Polar Task',
        measures: [
          Measure(type: PolarSamplingPackage.HR),
          // Measure(type: PolarSamplingPackage.ECG),
          // Measure(type: PolarSamplingPackage.PPG),
          // Measure(type: PolarSamplingPackage.PPI),
        ],
      ),
      polar,
    );

    //
    // --------- MOVESENSE PACKAGE EXAMPLES -------------
    //
    // Known DTU Movensense devices:
    //  - Movesense MD : 220330000122 : 0C:8C:DC:3F:B2:CD
    //  - Movesense    : 233830000687 : 0C:8C:DC:1B:23:3E
    //  - Movesense    : 233830000652 : 0C:8C:DC:1B:23:1B

    // var movesense = MovesenseDevice(
    //   address: '0C:8C:DC:1B:23:1B',
    //   name: 'Movesense 23383000 0652',
    // );

    // protocol.addConnectedDevice(movesense, phone);

    // protocol.addTaskControl(
    //     ImmediateTrigger(),
    //     BackgroundTask(measures: [
    //       Measure(type: MovesenseSamplingPackage.STATE),
    //       Measure(type: MovesenseSamplingPackage.HR),
    //       Measure(type: MovesenseSamplingPackage.ECG),
    //     ]),
    //     movesense);

    //
    // --------- C3+ PACKAGE EXAMPLES -------------
    //
    // Known DTU C3+ devices: ED:AD:D4:3D:3F:72

    // var c3 = CortriumDevice(
    //   name: 'Cortrium C3+',
    //   btleAddress: 'ED:AD:D4:3D:3F:72',
    // );

    // protocol.addConnectedDevice(c3, phone);

    // protocol.addTaskControl(
    //     ImmediateTrigger(),
    //     BackgroundTask(measures: [
    //       Measure(type: CortriumSamplingPackage.ECG),
    //       // Measure(type: CortriumSamplingPackage.BUTTON),
    //       Measure(type: CortriumSamplingPackage.BATTERY),
    //       Measure(type: CortriumSamplingPackage.ACCELEROMETER),
    //       Measure(type: CortriumSamplingPackage.HR),
    //     ]),
    //     c3);

    //
    // --------- HEALTH PACKAGE EXAMPLES -------------
    //

    // Create and add a health service
    final healthService = HealthService();
    protocol.addConnectedDevice(healthService, phone);

    // Add a periodic task that collects health data on a regular basis.
    //
    // Note that we are using the HealthSamplingPackage.getHealthMeasure()
    // method to create a measure that collects multiple health data types.
    //
    // Also note that health measures are collected using a [HealthSamplingConfiguration]
    // which is a [HistoricSamplingConfiguration], meaning that data is collected
    // going back in time until the last collected data point.
    protocol.addTaskControl(
      // PeriodicTrigger(period: Duration(minutes: 60)),
      PeriodicTrigger(period: Duration(minutes: 5)),
      BackgroundTask(
        measures: [
          HealthSamplingPackage.getHealthMeasure([
            HealthDataType.STEPS,
            HealthDataType.BASAL_ENERGY_BURNED,
            HealthDataType.WEIGHT,
            // SLEEP_SESSION is not available on iOS - should be removed on runtime
            HealthDataType.SLEEP_SESSION,
            // EDA is not available on Android - should be removed on runtime
            HealthDataType.ELECTRODERMAL_ACTIVITY,
          ]),
        ],
      ),
      healthService,
    );

    return protocol;
  }

  @override
  Future<bool> saveStudyProtocol(String studyId, StudyProtocol protocol) async {
    throw UnimplementedError();
  }
}
