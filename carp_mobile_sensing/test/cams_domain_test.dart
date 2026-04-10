import 'dart:convert';
import 'dart:io';

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:test/test.dart';

void main() {
  late SmartphoneStudyProtocol primaryProtocol;
  late Smartphone primaryPhone;
  DeviceConfiguration eSense;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUp(() {
    // Initialization of serialization
    CarpMobileSensing();

    DeviceInfoService().init();

    // Create a new study protocol.
    primaryProtocol = SmartphoneStudyProtocol(
      ownerId: 'user@dtu.dk',
      name: 'patient_tracking',
      applicationName:
          'carp_mobile_sensing_example', // this should match the app name in the pubspec.yaml file of the app executing this protocol
      studyDescription: StudyDescription(
        title: 'A Test',
        purpose: 'Testing',
        description: 'A testing protocol',
        responsible: StudyResponsible(
          id: 'abc',
          title: 'professor',
          address: 'Ørsteds Plads',
          affiliation: 'Technical University of Denmark',
          email: 'abc@dtu.dk',
          name: 'Alex B. Christensen',
        ),
      ),
      dataEndPoint: SQLiteDataEndPoint(),
    );

    // Define which devices are used for data collection.
    primaryPhone = Smartphone();
    eSense = DefaultDeviceConfiguration(roleName: 'eSense');

    primaryProtocol
      ..addPrimaryDevice(primaryPhone)
      ..addConnectedDevice(eSense, primaryPhone);

    // Define what needs to be measured, on which device, when.
    List<Measure> measures = [
      Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
      Measure(type: SensorSamplingPackage.ACCELERATION),
      Measure(type: SensorSamplingPackage.STEP_EVENT),
    ];

    var task = BackgroundTask(name: 'Start measures')..addMeasures(measures);
    primaryProtocol.addTaskControl(
      TriggerConfiguration(),
      task,
      primaryPhone,
      Control.Start,
    );

    // adding all measure from the sampling packages to one one trigger and one task
    primaryProtocol.addTaskControl(
      ImmediateTrigger(), // a simple trigger that starts immediately
      BackgroundTask()
        ..measures = SamplingPackageRegistry().dataTypes
            .map((type) => Measure(type: type.type))
            .toList(),
      primaryPhone,
      Control.Start,
    );

    // collect device info only once
    primaryProtocol.addTaskControl(
      OneTimeTrigger(),
      BackgroundTask()
        ..addMeasure(Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)),
      primaryPhone,
      Control.Start,
    );

    var sensingAppTask =
        AppTask(
          type: AppTask.SENSING_TYPE,
          title: "Location, Weather & Air Quality",
          description: "Collect location, weather and air quality",
        )..addMeasures([
          Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
          Measure(type: SensorSamplingPackage.STEP_EVENT),
        ]);

    primaryProtocol.addTaskControl(
      ImmediateTrigger(),
      sensingAppTask,
      primaryPhone,
      Control.Start,
    );

    primaryProtocol.addTaskControl(
      UserTaskTrigger(
        taskName: sensingAppTask.name,
        triggerCondition: UserTaskState.done,
      ),
      sensingAppTask,
      primaryPhone,
      Control.Start,
    );

    // adding two measures to another device
    primaryProtocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..addMeasure(Measure(type: DeviceSamplingPackage.FREE_MEMORY))
        ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT)),
      eSense,
      Control.Start,
    );
    primaryProtocol.addParticipantRole(ParticipantRole('Participant'));

    primaryProtocol.addExpectedParticipantData(
      ExpectedParticipantData(
        attribute: ParticipantAttribute(inputDataType: 'dk.cachet.carp.sex'),
        assignedTo: AssignedTo(roleNames: {'Participant'}),
      ),
    );

    primaryProtocol.addApplicationData('uiTheme', 'black');
  });

  group('Data Type', () {
    test('- monitor data types', () async {
      final allData = [
        Heartbeat(deviceType: 'Smartphone', deviceRoleName: 'phone'),
        Error(message: 'An error occurred'),
        TriggeredTask(
          triggerId: 0,
          taskName: '',
          destinationDeviceRoleName: '',
          control: Control.Start,
        ),
        CompletedTask(taskName: 'task1'),
      ];

      for (var data in allData) {
        final dataJson = toJsonString(data);
        final dataFromJson = Function.apply(data.fromJsonFunction, [
          json.decode(dataJson) as Map<String, dynamic>,
        ]);
        print(toJsonString(dataFromJson));
        expect(toJsonString(dataFromJson), equals(dataJson));
      }
    });
    test('- sensor data types', () async {
      final allData = [
        FileData(filename: 'file.txt'),
        DeviceInformation(platform: 'Android', deviceId: 'abcd1234'),
        BatteryState(50, BatteryState.STATE_CHARGING),
        FreeMemory(2048000),
        ScreenEvent('SCREEN_ON'),
        Timezone('Europe/Copenhagen'),
        AppLifecycleEvent('resumed'),
        Heartbeat(deviceType: 'Smartphone', deviceRoleName: 'phone'),
        AmbientLight.fromLuxReadings([10, 20, 30, 40, 50]),
        AccelerationFeatures()..avgResultAcceleration = 9.81,
      ];

      for (var data in allData) {
        final dataJson = toJsonString(data);
        final dataFromJson = Function.apply(data.fromJsonFunction, [
          json.decode(dataJson) as Map<String, dynamic>,
        ]);
        print(toJsonString(dataFromJson));
        expect(toJsonString(dataFromJson), equals(dataJson));
      }
    });

    test('- completed app task data types', () async {
      final allData = [
        CompletedAppTask(taskName: 'audio', taskType: AppTask.AUDIO_TYPE),
        CompletedAppTask(
          taskName: '',
          taskType: AppTask.COGNITIVE_ASSESSMENT_TYPE,
        ),
        CompletedAppTask(taskName: 'image', taskType: AppTask.IMAGE_TYPE),
        CompletedAppTask(
          taskName: 'informed consent',
          taskType: AppTask.INFORMED_CONSENT_TYPE,
        ),
        CompletedAppTask(taskName: 'sensing', taskType: AppTask.SENSING_TYPE),
        CompletedAppTask(taskName: 'survey', taskType: AppTask.SURVEY_TYPE),
        CompletedAppTask(taskName: 'video', taskType: AppTask.VIDEO_TYPE),
      ];

      for (var data in allData) {
        final dataJson = toJsonString(data);
        final dataFromJson = Function.apply(data.fromJsonFunction, [
          json.decode(dataJson) as Map<String, dynamic>,
        ]);
        print(toJsonString(dataFromJson));
        expect(toJsonString(dataFromJson), equals(dataJson));
      }
    });
  });

  group('Measurement', () {
    test('Measurement -> JSON', () async {
      final measurement = Measurement.fromData(
        DeviceInformation(platform: 'iOS', deviceId: '1234abcd'),
      );
      expect(measurement.data, isA<DeviceInformation>());
      expect(measurement.dataType, DeviceInformation().dataType);
      print(toJsonString(measurement));
    });

    test('JSON File -> Measurement', () async {
      final plainJson = File('test/json/measurement.json').readAsStringSync();

      final measurement = Measurement.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      expect(measurement.data, isA<Timezone>());
      print(toJsonString(measurement));
    });
  });

  group('StudyProtocol', () {
    test('SmartphoneStudyProtocol -> JSON', () async {
      print(toJsonString(primaryProtocol));
      expect(
        primaryProtocol.protocolApiLevel,
        SmartphoneStudyProtocol.CAMS_PROTOCOL_API_LEVEL,
      );
      expect(primaryProtocol.ownerId, 'user@dtu.dk');
      expect(primaryProtocol.primaryDevices.length, 1);
      expect(primaryProtocol.connectedDevices?.length, 1);
      expect(primaryProtocol.triggers.length, 8);
      expect(primaryProtocol.triggers.keys.first, '0');
      expect(primaryProtocol.tasks.length, 7);
      expect(primaryProtocol.taskControls.length, 8);
      expect(primaryProtocol.expectedParticipantData?.length, 1);

      // used in the test below
      await writeToFile(toJsonString(primaryProtocol), 'study_protocol.json');
    });

    test(
      'SmartphoneStudyProtocol -> JSON -> SmartphoneStudyProtocol :: deep assert',
      () async {
        print(toJsonString(primaryProtocol));
        final studyJson = toJsonString(primaryProtocol);

        SmartphoneStudyProtocol protocolFromJson =
            SmartphoneStudyProtocol.fromJson(
              json.decode(studyJson) as Map<String, dynamic>,
            );
        print(toJsonString(protocolFromJson));
        expect(toJsonString(protocolFromJson), equals(studyJson));
      },
    );

    test('JSON File -> SmartphoneStudyProtocol', () async {
      String plainJson = File(
        'test/json/study_protocol.json',
      ).readAsStringSync();

      final protocol = SmartphoneStudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      expect(
        primaryProtocol.protocolApiLevel,
        SmartphoneStudyProtocol.CAMS_PROTOCOL_API_LEVEL,
      );
      expect(protocol.ownerId, primaryProtocol.ownerId);
      expect(
        protocol.primaryDevices.first.roleName,
        Smartphone.DEFAULT_ROLE_NAME,
      );
      expect(protocol.dataEndPoint?.type, DataEndPointTypes.SQLITE);
      expect(protocol.expectedParticipantData?.length, 1);
      expect(protocol.getApplicationData('uiTheme'), 'black');

      print(toJsonString(protocol));
    });

    test('SmartphoneDeployment -> JSON', () async {
      final deployment = SmartphoneDeployment.fromSmartphoneStudyProtocol(
        studyDeploymentId: '1234',
        primaryDeviceRoleName: 'phone',
        protocol: primaryProtocol,
      );

      print(toJsonString(deployment));
      expect(deployment.deviceConfiguration.roleName, 'phone');
      expect(deployment.connectedDevices.length, 1);
      expect(deployment.triggers.length, 8);
      expect(deployment.triggers.keys.first, '0');
      expect(deployment.tasks.length, 7);
      expect(deployment.taskControls.length, 8);
      expect(deployment.dataEndPoint?.type, DataEndPointTypes.SQLITE);
      expect(deployment.expectedParticipantData.length, 1);
      expect(deployment.getApplicationData('uiTheme'), 'black');

      await writeToFile(toJsonString(deployment), 'study_deployment.json');
    });

    test(
      'SmartphoneDeployment -> JSON -> SmartphoneDeployment :: deep assert',
      () async {
        final deployment = SmartphoneDeployment.fromSmartphoneStudyProtocol(
          studyDeploymentId: '1234',
          primaryDeviceRoleName: 'phone',
          protocol: primaryProtocol,
        );
        print(toJsonString(deployment));
        expect(deployment.dataEndPoint?.type, DataEndPointTypes.SQLITE);
        expect(deployment.expectedParticipantData.length, 1);
        expect(deployment.getApplicationData('uiTheme'), 'black');

        final studyJson = toJsonString(deployment);
        final deploymentFromJson = SmartphoneDeployment.fromJson(
          json.decode(studyJson) as Map<String, dynamic>,
        );
        print(toJsonString(deploymentFromJson));
        expect(toJsonString(deploymentFromJson), equals(studyJson));
      },
    );

    test('JSON File -> SmartphoneDeployment', () async {
      final plainJson = File(
        'test/json/study_deployment.json',
      ).readAsStringSync();

      final deployment = SmartphoneDeployment.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      print(toJsonString(deployment));

      expect(
        primaryProtocol.protocolApiLevel,
        SmartphoneStudyProtocol.CAMS_PROTOCOL_API_LEVEL,
      );
      expect(deployment.deviceConfiguration.roleName, 'phone');
      expect(deployment.connectedDevices.length, 1);
      expect(deployment.triggers.length, 8);
      expect(deployment.triggers.keys.first, '0');
      expect(deployment.tasks.length, 7);
      expect(deployment.taskControls.length, 8);
      expect(deployment.dataEndPoint?.type, DataEndPointTypes.SQLITE);
      expect(deployment.expectedParticipantData.length, 1);
      expect(deployment.getApplicationData('uiTheme'), 'black');
    });
  });

  test('Triggers -> JSON -> Triggers', () async {
    primaryProtocol.addTaskControl(
      DelayedTrigger(delay: const Duration(seconds: 10)),
      BackgroundTask()
        ..addMeasure(Measure(type: SensorSamplingPackage.STEP_EVENT))
        ..addMeasure(Measure(type: DeviceSamplingPackage.SCREEN_EVENT)),
      primaryPhone,
      Control.Start,
    );

    primaryProtocol.addTaskControl(
      PeriodicTrigger(period: const Duration(minutes: 1)), // collect every min.
      BackgroundTask()
        ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT))
        ..addMeasure(Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)),
      primaryPhone,
      Control.Start,
    );

    RecurrentScheduledTrigger t1, t2, t3, t4;

    // collect every day at 13:30.
    t1 = RecurrentScheduledTrigger(
      type: RecurrentType.daily,
      time: const TimeOfDay(hour: 21, minute: 30),
      duration: const Duration(seconds: 1),
    );
    print('$t1');
    primaryProtocol.addTaskControl(
      t1,
      BackgroundTask()
        ..addMeasure(Measure(type: DeviceSamplingPackage.FREE_MEMORY)),
      primaryPhone,
      Control.Start,
    );

    // collect every other day at 13:30.
    t2 = RecurrentScheduledTrigger(
      type: RecurrentType.daily,
      time: const TimeOfDay(hour: 13, minute: 30),
      separationCount: 1,
      duration: const Duration(seconds: 1),
    );
    print('$t2');
    primaryProtocol.addTaskControl(
      t2,
      BackgroundTask()
        ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT))
        ..addMeasure(Measure(type: DeviceSamplingPackage.FREE_MEMORY)),
      primaryPhone,
      Control.Start,
    );

    // collect every wednesday at 12:23.
    t3 = RecurrentScheduledTrigger(
      type: RecurrentType.weekly,
      time: const TimeOfDay(hour: 12, minute: 23),
      dayOfWeek: DateTime.wednesday,
      duration: const Duration(seconds: 1),
    );
    print('$t3');
    primaryProtocol.addTaskControl(
      t3,
      BackgroundTask()
        ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT))
        ..addMeasure(Measure(type: DeviceSamplingPackage.BATTERY_STATE)),
      primaryPhone,
      Control.Start,
    );

    // collect every 2nd monday at 12:23.
    t4 = RecurrentScheduledTrigger(
      type: RecurrentType.weekly,
      time: const TimeOfDay(hour: 12, minute: 23),
      dayOfWeek: DateTime.monday,
      separationCount: 1,
      duration: const Duration(seconds: 1),
    );
    print('$t4');
    primaryProtocol.addTaskControl(
      t4,
      BackgroundTask()
        ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT))
        ..addMeasure(Measure(type: DeviceSamplingPackage.SCREEN_EVENT)),
      primaryPhone,
      Control.Start,
    );

    // when battery level is 10% then sample light
    primaryProtocol.addTaskControl(
      SamplingEventTrigger(
        measureType: DeviceSamplingPackage.BATTERY_STATE,
        triggerCondition: BatteryState(10),
      ),
      BackgroundTask()
        ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT)),
      primaryPhone,
      Control.Start,
    );

    // when the screen is turned off then get device info
    primaryProtocol.addTaskControl(
      SamplingEventTrigger(
        measureType: DeviceSamplingPackage.SCREEN_EVENT,
        triggerCondition: ScreenEvent('SCREEN_OFF'),
      ),
      BackgroundTask()
        ..addMeasure(Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION)),
      primaryPhone,
      Control.Start,
    );

    primaryProtocol.addTaskControl(
      ConditionalSamplingEventTrigger(
        measureType: DeviceSamplingPackage.BATTERY_STATE,
        triggerCondition: (measurement) =>
            (measurement.data as BatteryState).batteryLevel == 10,
      ),
      BackgroundTask()
        ..addMeasure(Measure(type: SensorSamplingPackage.AMBIENT_LIGHT)),
      primaryPhone,
      Control.Start,
    );

    final studyJson = toJsonString(primaryProtocol);

    print(studyJson);

    SmartphoneStudyProtocol protocol_2 = SmartphoneStudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(protocol_2.ownerId, primaryProtocol.ownerId);

    print('#1 : $primaryProtocol');

    SmartphoneStudyProtocol protocolFromJson = SmartphoneStudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), equals(studyJson));
    print('#2 : $protocolFromJson');
  });

  test('Sampling configurations', () async {
    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
      ownerId: 'user@dtu.dk',
      name: 'sampling_configurations',
    );

    Smartphone phone = Smartphone();

    phone.defaultSamplingConfiguration!
      ..addAll(DeviceSamplingPackage().samplingSchemes.configurations)
      ..addAll(SensorSamplingPackage().samplingSchemes.configurations);

    protocol.addPrimaryDevice(phone);

    expect(
      protocol.primaryDevice.defaultSamplingConfiguration?.keys.contains(
        DeviceSamplingPackage().samplingSchemes.configurations.keys.first,
      ),
      true,
    );
    expect(
      protocol.primaryDevice.defaultSamplingConfiguration?.keys.contains(
        SensorSamplingPackage().samplingSchemes.configurations.keys.first,
      ),
      true,
    );
    print(toJsonString(protocol));
  });

  test('Register Device', () async {
    await DeviceInfoService().init();

    StudyDeploymentStatus status_1 = await (SmartphoneDeploymentService()
        .createStudyDeployment(primaryProtocol));
    print(status_1);
    assert(status_1.status == StudyDeploymentStatusTypes.Invited);

    StudyDeploymentStatus? status_2 = await (SmartphoneDeploymentService()
        .registerDevice(
          status_1.studyDeploymentId,
          'esense',
          DefaultDeviceRegistration(),
        ));
    print(status_2);
    assert(status_2?.studyDeploymentId == status_1.studyDeploymentId);
    assert(status_2?.status == StudyDeploymentStatusTypes.DeployingDevices);
    assert(status_2 == status_1);

    StudyDeploymentStatus? status_3 = await SmartphoneDeploymentService()
        .registerDevice(
          status_1.studyDeploymentId,
          'nonsense',
          DefaultDeviceRegistration(),
        );
    assert(status_3?.status == StudyDeploymentStatusTypes.DeployingDevices);
    assert(status_3?.studyDeploymentId == status_1.studyDeploymentId);
    print(status_3);
  });

  test('Study Deployment', () async {
    StudyDeploymentStatus status_1 = await SmartphoneDeploymentService()
        .createStudyDeployment(primaryProtocol);

    print(toJsonString(status_1));
    // we expect the phone and eSense devices
    expect(status_1.deviceStatusList.length, 2);
    expect(status_1.status, StudyDeploymentStatusTypes.Invited);
    expect(
      status_1.deviceStatusList[0].device.roleName,
      Smartphone.DEFAULT_ROLE_NAME,
    );
    // the phone as a primary device is always registered by the SmartphoneDeploymentService
    expect(
      status_1.deviceStatusList[0].status,
      DeviceDeploymentStatusTypes.Registered,
    );
    // but we do not expect the eSense device to be registered (yet)
    expect(status_1.deviceStatusList[1].device.roleName, 'eSense');
    expect(
      status_1.deviceStatusList[1].status,
      DeviceDeploymentStatusTypes.Unregistered,
    );

    // now register the eSense device
    StudyDeploymentStatus? status_2 = await SmartphoneDeploymentService()
        .registerDevice(
          status_1.studyDeploymentId,
          'eSense',
          DefaultDeviceRegistration(),
        );

    print(toJsonString(status_2));
    expect(status_2?.studyDeploymentId, status_1.studyDeploymentId);
    expect(status_1.deviceStatusList[1].device.roleName, 'eSense');

    // now we expect the eSense device to be registered
    expect(
      status_1.deviceStatusList[1].status,
      DeviceDeploymentStatusTypes.Registered,
    );

    SmartphoneDeployment? deployment = await SmartphoneDeploymentService()
        .getDeviceDeployment(status_1.studyDeploymentId);
    print(deployment);
    print(toJsonString(deployment));
    expect(deployment?.studyDeploymentId, status_1.studyDeploymentId);
    expect(deployment?.tasks.length, primaryProtocol.tasks.length);
    expect(deployment?.triggers.length, primaryProtocol.triggers.length);
    expect(
      deployment?.taskControls.length,
      primaryProtocol.taskControls.length,
    );

    StudyDeploymentStatus? status_3 = await SmartphoneDeploymentService()
        .deployed(status_1.studyDeploymentId);
    expect(status_3?.status, StudyDeploymentStatusTypes.Running);
    expect(status_3?.studyDeploymentId, status_1.studyDeploymentId);
    print(toJsonString(status_3));
    expect(
      status_3?.deviceStatusList[0].status,
      DeviceDeploymentStatusTypes.Deployed,
    );
    expect(
      status_3?.deviceStatusList[1].status,
      DeviceDeploymentStatusTypes.Deployed,
    );
  });
}
