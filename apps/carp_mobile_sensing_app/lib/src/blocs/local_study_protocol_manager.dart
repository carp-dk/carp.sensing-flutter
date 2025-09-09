part of '../../main.dart';

/// This is a local [StudyProtocolManager] which provides a [SmartphoneStudyProtocol]
/// when running in local mode.
class LocalStudyProtocolManager implements StudyProtocolManager {
  @override
  Future<void> initialize() async {}

  @override
  Future<SmartphoneStudyProtocol> getStudyProtocol(String protocolId) async =>
      getSingleUserStudyProtocol(protocolId);

  StudyDescription get studyDescription => StudyDescription(
      title: 'CAMS App - Sensing Coverage Study',
      description:
          'The default study testing coverage of most measures. Used in the coverage tests.',
      purpose: 'To test sensing coverage',
      responsible: StudyResponsible(
        id: 'abc',
        title: 'professor',
        address: 'Ørsteds Plads',
        affiliation: 'Technical University of Denmark',
        email: 'abc@dtu.dk',
        name: 'Alex B. Christensen',
      ));

  DataEndPoint get dataEndPoint => (bloc.deploymentMode == DeploymentMode.local)
      ? SQLiteDataEndPoint()
      : CarpDataEndPoint(
          uploadMethod: CarpUploadMethod.stream,
        )
    // set the format of the data to upload - e.g. Open mHealth
    ..dataFormat = bloc.dataFormat;

  /// Create a study protocol for a single participant with examples from
  /// the different sampling packages.
  SmartphoneStudyProtocol getSingleUserStudyProtocol(String name) {
    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
      // Note that CAWS require a UUID for ownerId.
      // You can put anything here (as long as it is a valid UUID), and this will be replaced with
      // the ID of the user uploading the protocol.
      ownerId: '979b408d-784e-4b1b-bb1e-ff9204e072f3',
      name: name,
      studyDescription: studyDescription,
      dataEndPoint: dataEndPoint..dataFormat = bloc.dataFormat,
    );

    // always add a participant role to the protocol
    final participant = 'Participant';
    protocol.participantRoles?.add(ParticipantRole(participant, false));

    // define the primary device(s)
    Smartphone phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // build-in measure from sensor and device sampling packages
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: SensorSamplingPackage.STEP_COUNT),
          Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
          Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
          Measure(type: DeviceSamplingPackage.FREE_MEMORY),
          Measure(type: DeviceSamplingPackage.BATTERY_STATE),
        ]),
        phone);

    // // a random trigger - 3-8 times during time period of 8-20
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

    //
    // --------- CONTEXT PACKAGE EXAMPLES -------------
    //

    // activity measure using the phone
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(
            measures: [Measure(type: ContextSamplingPackage.ACTIVITY)]),
        phone);

    // Define the online location service and add it as a 'device'
    // final locationService = LocationService();

    final locationService = LocationService(
      // used for debugging when the phone is laying still on the table
      distance: 0,
    );
    protocol.addConnectedDevice(locationService, phone);

    // Add a background task that collects location on a regular basis
    protocol.addTaskControl(
        PeriodicTrigger(period: Duration(seconds: 20)),
        BackgroundTask(measures: [
          Measure(type: ContextSamplingPackage.LOCATION)
            ..overrideSamplingConfiguration =
                LocationSamplingConfiguration(once: true),
        ]),
        locationService);

    // // Add a background task that continuously collects location and mobility
    // protocol.addTaskControl(
    //     ImmediateTrigger(),
    //     BackgroundTask(measures: [
    //       Measure(type: ContextSamplingPackage.LOCATION),
    //       Measure(type: ContextSamplingPackage.MOBILITY),
    //     ]),
    //     locationService);

    // Define the online weather service and add it as a 'device'
    WeatherService weatherService = WeatherService(apiKey: openWeatherApiKey);
    protocol.addConnectedDevice(weatherService, phone);

    // Add a background task that collects weather every 5 minutes.
    protocol.addTaskControl(
        PeriodicTrigger(period: Duration(minutes: 5)),
        BackgroundTask(
            measures: [Measure(type: ContextSamplingPackage.WEATHER)]),
        weatherService);

    // // Define the online air quality service and add it as a 'device'
    // AirQualityService airQualityService =
    //     AirQualityService(apiKey: airQualityApiKey);
    // protocol.addConnectedDevice(airQualityService, phone);

    // // Add a background task that air quality every 30 minutes.
    // protocol.addTaskControl(
    //     PeriodicTrigger(period: Duration(minutes: 30)),
    //     BackgroundTask()
    //       ..addMeasure(Measure(type: ContextSamplingPackage.AIR_QUALITY)),
    //     airQualityService);

    //
    // --------- MEDIA PACKAGE EXAMPLES -------------
    //

    // collect noise, but change the default sampling configuration
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: MediaSamplingPackage.NOISE)
            ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
              interval: const Duration(seconds: 23),
              duration: const Duration(seconds: 5),
            ),
        ]),
        phone);

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

    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: ConnectivitySamplingPackage.CONNECTIVITY),
          Measure(type: ConnectivitySamplingPackage.WIFI),
          Measure(type: ConnectivitySamplingPackage.BLUETOOTH)
            ..overrideSamplingConfiguration = PeriodicSamplingConfiguration(
              interval: const Duration(seconds: 33),
              duration: const Duration(seconds: 5),
            ),
        ]),
        phone);

    //
    // --------- COMMUNICATION PACKAGE EXAMPLES -------------
    //

    // Add an automatic task that collects SMS messages in/out
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(
          measures: [
            Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE),
          ],
        ),
        phone);

    // Add an automatic task that collects the logs for:
    //  * SMS log (in/out)
    //  * phone call log (in/out)
    //  * calendar entries
    //
    // every 30 minutes.
    protocol.addTaskControl(
        PeriodicTrigger(period: Duration(minutes: 30)),
        BackgroundTask(
          measures: [
            Measure(type: CommunicationSamplingPackage.PHONE_LOG),
            Measure(type: CommunicationSamplingPackage.TEXT_MESSAGE_LOG),
            Measure(type: CommunicationSamplingPackage.CALENDAR),
          ],
        ),
        phone);

    //
    // --------- APP PACKAGE EXAMPLES -------------
    //

    // Add a task that collects the list of installed apps
    // and a log of app usage activity
    protocol.addTaskControl(
        // PeriodicTrigger(period: const Duration(minutes: 1)),
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: AppsSamplingPackage.APPS),
          Measure(type: AppsSamplingPackage.APP_USAGE),
        ]),
        phone);

    //
    // --------- eSENSE PACKAGE EXAMPLES -------------
    //

    // Define the sSense device and add its measures
    ESenseDevice eSense = ESenseDevice(
      deviceName: 'eSense-0332',
      samplingRate: 10,
    );
    protocol.addConnectedDevice(eSense, phone);

    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: ESenseSamplingPackage.ESENSE_BUTTON),
          Measure(type: ESenseSamplingPackage.ESENSE_SENSOR)
        ]),
        eSense);

    //
    // --------- POLAR PACKAGE EXAMPLES -------------
    //

    // define the Polar device and add its measures
    // var polar = PolarDevice(
    //   identifier: 'B5FC172F',
    //   name: 'Polar H10 HR Monitor',
    //   deviceType: PolarDeviceType.H10,
    // );
    // var polar = PolarDevice(
    //   identifier: 'B36B5B21',
    //   name: 'Polar HR Sense',
    //   deviceType: PolarDeviceType.SENSE,
    // );

    // protocol.addConnectedDevice(polar, phone);

    // protocol.addTaskControl(
    //     ImmediateTrigger(),
    //     BackgroundTask(measures: [
    //       Measure(type: PolarSamplingPackage.HR),
    //       // Measure(type: PolarSamplingPackage.ECG),
    //       // Measure(type: PolarSamplingPackage.PPG),
    //       // Measure(type: PolarSamplingPackage.PPI),
    //     ]),
    //     polar);

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

    var c3 = CortriumDevice(
      name: 'Cortrium C3+',
      identifier: 'ED:AD:D4:3D:3F:72',
    );

    protocol.addConnectedDevice(c3, phone);

    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: CortriumSamplingPackage.ECG),
          // Measure(type: CortriumSamplingPackage.BUTTON),
          Measure(type: CortriumSamplingPackage.BATTERY),
          Measure(type: CortriumSamplingPackage.ACCELEROMETER),
        ]),
        c3);

    //
    // --------- HEALTH PACKAGE EXAMPLES -------------
    //

    // Create and add a health service
    final healthService = HealthService();
    protocol.addConnectedDevice(healthService, phone);

    protocol.addTaskControl(
        // PeriodicTrigger(period: Duration(minutes: 60)),
        PeriodicTrigger(period: Duration(minutes: 1)),
        BackgroundTask(measures: [
          HealthSamplingPackage.getHealthMeasure([
            HealthDataType.STEPS,
            HealthDataType.BASAL_ENERGY_BURNED,
            HealthDataType.WEIGHT,
            // SLEEP_SESSION is not available on iOS - should be removed on runtime
            HealthDataType.SLEEP_SESSION,
            // EDA is not available on Android - should be removed on runtime
            HealthDataType.ELECTRODERMAL_ACTIVITY,
          ])
        ]),
        healthService);

    return protocol;
  }

  /// Create a study protocol for a family with several participants:
  ///
  ///   * father
  ///   * mother
  ///   * child
  ///
  /// Each participant is configured to sample different measures.
  ///
  /// Also illustrates how to add [ExpectedParticipantData]
  /// to a study protocol.
  SmartphoneStudyProtocol getFamilyStudyProtocol(String name) {
    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
      ownerId: 'abc@dtu.dk',
      name: name,
      studyDescription: studyDescription,
      dataEndPoint: dataEndPoint..dataFormat = bloc.dataFormat,
    );

    final father = 'Father';
    final mother = 'Mother';
    final child = 'Child';

    // add participant roles
    protocol.addParticipantRole(ParticipantRole(father));
    protocol.addParticipantRole(ParticipantRole(mother));
    protocol.addParticipantRole(ParticipantRole(child));

    // define and assign the primary device(s)
    Smartphone fatherPhone = Smartphone(roleName: "$father's Phone");
    protocol.addPrimaryDevice(fatherPhone);
    Smartphone motherPhone = Smartphone(roleName: "$mother's Phone");
    protocol.addPrimaryDevice(motherPhone);
    Smartphone childPhone = Smartphone(roleName: "$child's Phone");
    protocol.addPrimaryDevice(childPhone);

    protocol.changeDeviceAssignment(
        fatherPhone, AssignedTo(roleNames: {father}));
    protocol.changeDeviceAssignment(
        motherPhone, AssignedTo(roleNames: {mother}));
    protocol.changeDeviceAssignment(childPhone, AssignedTo(roleNames: {child}));

    // add expected participant data for all participants
    protocol.addExpectedParticipantData(ExpectedParticipantData(
        attribute: ParticipantAttribute(inputDataType: SexInput.type)));
    protocol.addExpectedParticipantData(ExpectedParticipantData(
        attribute: ParticipantAttribute(
      inputDataType: InformedConsentInput.type,
    )));

    // add expected participant data for the mother
    protocol.addExpectedParticipantData(ExpectedParticipantData(
        attribute: ParticipantAttribute(inputDataType: FullNameInput.type),
        assignedTo: AssignedTo(roleNames: {mother})));

    // build-in measure from sensor and device sampling packages
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: SensorSamplingPackage.STEP_COUNT),
          Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
          Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
          Measure(type: DeviceSamplingPackage.FREE_MEMORY),
          Measure(type: DeviceSamplingPackage.BATTERY_STATE),
        ]),
        fatherPhone);

    // a random trigger - 3-8 times during time period of 8-20
    protocol.addTaskControl(
        RandomRecurrentTrigger(
          startTime: TimeOfDay(hour: 8),
          endTime: TimeOfDay(hour: 20),
          minNumberOfTriggers: 3,
          maxNumberOfTriggers: 8,
        ),
        BackgroundTask()
          ..addMeasure(Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)),
        fatherPhone);

    // activity measure using the phone
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask()
          ..addMeasure(Measure(type: ContextSamplingPackage.ACTIVITY)),
        motherPhone);

    // define the location service and add it as a 'device' to all three participants
    LocationService locationService = LocationService();
    protocol.addConnectedDevice(locationService, fatherPhone);
    protocol.addConnectedDevice(locationService, motherPhone);
    protocol.addConnectedDevice(locationService, childPhone);

    // add a background task that continuously collects location and mobility
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: ContextSamplingPackage.LOCATION),
          Measure(type: ContextSamplingPackage.MOBILITY),
        ]),
        locationService);

    // define the online weather service and add it to the father's phone
    WeatherService weatherService = WeatherService(apiKey: openWeatherApiKey);
    protocol.addConnectedDevice(weatherService, fatherPhone);

    // add a background task that collects weather every 30 minutes.
    protocol.addTaskControl(
        PeriodicTrigger(period: Duration(minutes: 30)),
        BackgroundTask()
          ..addMeasure(Measure(type: ContextSamplingPackage.WEATHER)),
        weatherService);

    // define the online air quality service and add it to the mother's phone
    AirQualityService airQualityService =
        AirQualityService(apiKey: airQualityApiKey);
    protocol.addConnectedDevice(airQualityService, motherPhone);

    // add a background task that air quality every 30 minutes.
    protocol.addTaskControl(
        PeriodicTrigger(period: Duration(minutes: 30)),
        BackgroundTask(measures: [
          Measure(type: ContextSamplingPackage.AIR_QUALITY),
        ]),
        airQualityService);

    // collect noise from the child's phone
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: MediaSamplingPackage.NOISE),
        ]),
        childPhone);

    // collect connectivity info from the child's phone
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: ConnectivitySamplingPackage.CONNECTIVITY),
          Measure(type: ConnectivitySamplingPackage.WIFI),
          Measure(type: ConnectivitySamplingPackage.BLUETOOTH),
        ]),
        childPhone);

    // // Add an automatic task that collects SMS messages in/out
    // protocol.addTaskControl(
    //     ImmediateTrigger(),
    //     AutomaticTask()
    //       ..addMeasures(SamplingPackageRegistry().common.getMeasureList(
    //         types: [
    //           CommunicationSamplingPackage.TEXT_MESSAGE,
    //         ],
    //       )),
    //     phone);

    // // Add an automatic task that collects the logs for:
    // //  * in/out SMS
    // //  * in/out phone calls
    // //  * calendar entries
    // protocol.addTaskControl(
    //     ImmediateTrigger(),
    //     AutomaticTask()
    //       ..addMeasures(SamplingPackageRegistry().common.getMeasureList(
    //         types: [
    //           CommunicationSamplingPackage.PHONE_LOG,
    //           CommunicationSamplingPackage.TEXT_MESSAGE_LOG,
    //           CommunicationSamplingPackage.CALENDAR,
    //         ],
    //       )),
    //     phone);

    // // Add an automatic task that collects the list of installed apps
    // // and a log of app usage activity
    // protocol.addTaskControl(
    //     PeriodicTrigger(
    //       period: const Duration(minutes: 1),
    //       duration: const Duration(seconds: 10),
    //     ),
    //     AutomaticTask()
    //       ..addMeasures(SamplingPackageRegistry().common.getMeasureList(
    //         types: [
    //           AppsSamplingPackage.APPS,
    //           AppsSamplingPackage.APP_USAGE,
    //         ],
    //       )),
    //     phone);

    // define the eSense device and add it to the mother's phone
    var eSense = ESenseDevice(
      deviceName: 'eSense-0332',
      samplingRate: 10,
    );
    protocol.addConnectedDevice(eSense, motherPhone);

    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask()
          ..addMeasure(Measure(type: ESenseSamplingPackage.ESENSE_BUTTON))
          ..addMeasure(Measure(type: ESenseSamplingPackage.ESENSE_SENSOR)),
        eSense);

    // define the Polar device and add it to the father's phone

    // PolarDevice polar = PolarDevice(
    //   identifier: 'B5FC172F',
    //   name: 'Polar H10 HR Monitor',
    //   polarDeviceType: PolarDeviceType.H10,
    // );
    var polar = PolarDevice(
      identifier: 'B36B5B21',
      name: 'Polar PVS',
      deviceType: PolarDeviceType.SENSE,
    );

    protocol.addConnectedDevice(polar, fatherPhone);

    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask()..addMeasure(Measure(type: PolarSamplingPackage.HR)),
        // ..addMeasure(Measure(type: PolarSamplingPackage.ECG))
        // ..addMeasure(Measure(type: PolarSamplingPackage.PPG))
        // ..addMeasure(Measure(type: PolarSamplingPackage.PPI)),
        polar);

    return protocol;
  }

  @override
  Future<bool> saveStudyProtocol(String studyId, StudyProtocol protocol) async {
    throw UnimplementedError();
  }
}
