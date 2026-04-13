import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_serializable/carp_serializable.dart';

void main() {
  late StudyProtocol protocol;

  setUp(() {
    Core.ensureInitialized();

    protocol = StudyProtocol(
      // Note that CAWS require a UUID for ownerId.
      // You can put anything here (as long as it is a valid UUID), and this will be replaced with
      // the ID of the user uploading the protocol.
      ownerId: '979b408d-784e-4b1b-bb1e-ff9204e072f3',
      name: 'Test Study Protocol',
      description: 'For testing purposes.',
    );

    final phone_1 = Smartphone(roleName: 'phone_1');
    final phone_2 = Smartphone(roleName: 'phone_2');
    // final monitor = DefaultDeviceConfiguration(roleName: 'hr_monitor');
    // final bike = AltBeacon(roleName: 'bike' );
    final monitor = AltBeacon(roleName: 'hr_monitor');
    final bike = AltBeacon(roleName: 'bike');

    protocol
      ..addParticipantRole(ParticipantRole('Runner'))
      ..addParticipantRole(ParticipantRole('Cyclist'))
      ..addPrimaryDevice(phone_1)
      ..addPrimaryDevice(phone_2)
      ..addConnectedDevice(monitor, phone_1)
      ..addConnectedDevice(bike, phone_1)
      ..changeDeviceAssignment(phone_1, AssignedTo(roleNames: {'Runner'}))
      ..changeDeviceAssignment(phone_2, AssignedTo(roleNames: {'Cyclist'}));

    protocol.addTaskControl(
      // TriggerConfiguration(sourceDeviceRoleName: phone.roleName),
      TriggerConfiguration(),
      BackgroundTask(
        name: 'Start measures',
        duration: const Duration(hours: 1),
        measures: [
          Measure(type: CarpDataTypes.ACCELERATION),
          Measure(type: CarpDataTypes.GEOLOCATION),
          Measure(type: CarpDataTypes.STEP_COUNT),
        ],
      ),
      phone_1,
      Control.Start,
    );

    protocol.addTaskControl(
      ElapsedTimeTrigger(
        sourceDeviceRoleName: phone_1.roleName,
        elapsedTime: const Duration(hours: 1),
      ),
      BackgroundTask(
        // name: 'Start Heart Monitor',
        duration: const Duration(hours: 1),
        measures: [
          Measure(type: CarpDataTypes.ECG),
          Measure(type: CarpDataTypes.EDA),
          Measure(type: CarpDataTypes.HEART_RATE),
        ],
      ),
      phone_1,
      Control.Start,
    );

    protocol.addTaskControl(
      ElapsedTimeTrigger(
        // sourceDeviceRoleName: phone.roleName,
        elapsedTime: const Duration(hours: 1),
      ),
      BackgroundTask(
        // name: 'Start Heart Monitor',
        duration: const Duration(hours: 1),
        measures: [
          Measure(type: CarpDataTypes.ACCELERATION),
          Measure(type: CarpDataTypes.SIGNAL_STRENGTH),
        ],
      ),
      phone_2,
      Control.Stop,
    );

    // The following override with a BatteryAwareSamplingConfiguration does NOT WORK
    // when uploading to CAWS.....
    // Measure measure = Measure(type: 'dk.cachet.carp.steps');
    // measure.overrideSamplingConfiguration = BatteryAwareSamplingConfiguration(
    //     normal: GranularitySamplingConfiguration(Granularity.Detailed),
    //     low: GranularitySamplingConfiguration(Granularity.Balanced),
    //     critical: GranularitySamplingConfiguration(Granularity.Coarse));

    // protocol.addTaskControl(
    //   ManualTrigger(),
    //   BackgroundTask()..addMeasure(measure),
    //   phone_1,
    //   Control.Start,
    // );
  });

  test('StudyProtocol -> JSON', () async {
    print(toJsonString(protocol));
    expect(protocol.triggers.length, 3);
    expect(protocol.triggers.keys.first, '0');
    expect(protocol.tasks.length, 3);
    expect(protocol.taskControls.length, 3);
    expect(protocol.participantRoles?.length, 2);
    expect(protocol.assignedDevices?.length, 2);
  });

  test('Invitation & Registration -> JSON', () async {
    StudyProtocol trackPatientStudy = StudyProtocol(
      ownerId: 'abc@dtu.dk',
      name: 'Tracking',
    )..addPrimaryDevice(Smartphone());

    Smartphone patientPhone =
        trackPatientStudy.primaryDevices.first as Smartphone;

    // This is called by `StudyService` when deploying a participant group.
    var invitation = ParticipantInvitation(
      participantId: const Uuid().v1,
      assignedRoles: AssignedTo.all(),
      identity: EmailAccountIdentity("test@test.com"),
      invitation: StudyInvitation(
        "Movement study",
        "This study tracks your movements.",
      ),
    );

    print(toJsonString(invitation));

    var registration = patientPhone.createRegistration(
      deviceId: "xxxxxxxxx",
      deviceDisplayName: "Pixel 6 Pro (Android 12)",
    );
    expect(registration, isNotNull);

    print(toJsonString(registration));
  });

  test('Add Request -> JSON', () async {
    print(toJsonString(Add(protocol)));
    // expect(toJsonString(expected), toJsonString(request));
  });

  test('JSON -> StudyProtocol', () async {
    final loadedJson = File(
      'test/json/carp.core-dart/study_protocol.json',
    ).readAsStringSync();

    final loadedProtocol = StudyProtocol.fromJson(
      json.decode(loadedJson) as Map<String, dynamic>,
    );
    print(toJsonString(loadedProtocol));

    expect(loadedProtocol.ownerId, protocol.ownerId);
    expect(
      loadedProtocol.primaryDevices.first.roleName,
      protocol.primaryDevices.first.roleName,
    );
    expect(loadedProtocol.triggers['1'], isA<ElapsedTimeTrigger>());
    expect(
      (loadedProtocol.triggers['1'] as ElapsedTimeTrigger).elapsedTime?.inHours,
      1,
    );

    final studyJson = toJsonString(loadedProtocol);

    final protocolFromJson = StudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), equals(studyJson));
  });

  test('JSON -> Invitations', () async {
    final loadedJson = File(
      'test/json/carp.core-dart/invitations.json',
    ).readAsStringSync();

    final jsonList = json.decode(loadedJson) as List<dynamic>;

    final invitations = jsonList
        .map(
          (invitation) => ActiveParticipationInvitation.fromJson(
            invitation as Map<String, dynamic>,
          ),
        )
        .toList();

    print(toJsonString(invitations));

    expect(invitations, isList);
    // check if we can read the studyId as a plain string
    expect(invitations[0].studyId, isNotNull);
    // check if we can read the studyId as JSON
    expect(invitations[invitations.length - 1].studyId, isNotNull);
  });

  test('JSON -> MACAddressDeviceRegistration', () async {
    // MACAddressDeviceRegistration macAddress = MACAddressDeviceRegistration(
    //     macAddress: '00:00:00:00:00:00', deviceDisplayName: 'Test MAC Address');
    // print(toJsonString(macAddress));

    final loadedJson = File(
      'test/json/carp.core-dart/mac_address.json',
    ).readAsStringSync();
    final loadedMacAddress = MACAddressDeviceRegistration.fromJson(
      json.decode(loadedJson) as Map<String, dynamic>,
    );
    expect(loadedMacAddress.macAddress, '00:00:00:00:00:00');
    expect(loadedMacAddress.deviceDisplayName, 'Test MAC Address');

    print(toJsonString(loadedMacAddress));
  });

  test('ScheduledTrigger', () async {
    var st = ScheduledTrigger(
      time: const TimeOfDay(hour: 12),
      recurrenceRule: RecurrenceRule(Frequency.DAILY, interval: 2),
    );
    expect(
      st.recurrenceRule.toString(),
      RecurrenceRule.fromString('RRULE:FREQ=DAILY;INTERVAL=2').toString(),
    );
    print(st);

    st = ScheduledTrigger(
      time: const TimeOfDay(hour: 12),
      recurrenceRule: RecurrenceRule(
        Frequency.DAILY,
        interval: 2,
        end: End.count(3),
      ),
    );
    expect(
      st.recurrenceRule.toString(),
      RecurrenceRule.fromString(
        'RRULE:FREQ=DAILY;INTERVAL=2;COUNT=3',
      ).toString(),
    );
    print(st);

    st = ScheduledTrigger(
      time: const TimeOfDay(hour: 12),
      recurrenceRule: RecurrenceRule(
        Frequency.DAILY,
        interval: 2,
        end: End.until(const Duration(days: 30)),
      ),
    );
    expect(
      st.recurrenceRule.toString(),
      RecurrenceRule.fromString(
        'RRULE:FREQ=DAILY;INTERVAL=2;UNTIL=2592000000',
      ).toString(),
    );
    print(st);
  });

  test('DataStreamBatch -> JSON', () async {
    String studyDeploymentId = "c9cc5317-48da-45f2-958e-58bc07f34681";
    DataStreamBatch batch = DataStreamBatch(
      dataStream: DataStreamId(
        studyDeploymentId: studyDeploymentId,
        deviceRoleName: 'phone',
        dataType: 'dk.cachet.carp.geolocation',
      ),
      firstSequenceId: 0,
      measurements: [
        Measurement(
          sensorStartTime: DateTime.now().millisecondsSinceEpoch,
          data: Geolocation(
            latitude: 55.68061908805645,
            longitude: 12.582050313435703,
          ),
          // ..sensorSpecificData = SignalStrength(rssi: 23),
        ),
        Measurement(
          sensorStartTime: DateTime.now().millisecondsSinceEpoch,
          data: Geolocation(
            latitude: 55.680802203873114,
            longitude: 12.581802212861367,
          ),
        ),
      ],
      triggerIds: {0},
    );

    print(toJsonString(batch));
    expect(batch.measurements, isNotEmpty);
  });

  test('RequiredDataStreams -> JSON', () async {
    var streams = StudyDeployment(protocol).requiredDataStreams;
    print(toJsonString(streams));
    expect(streams.expectedDataStreams, isNotEmpty);
  });

  test('WebTask', () async {
    var task = WebTask(
      url:
          'https://cans.cachet.dk/portal/playground/studies/\$DEPLOYMENT_ID/settings?participant=\$PARTICIPANT_ID&trigger_id=\$TRIGGER_ID',
    );

    expect(
      task.getUrl('12345-1234', 'ecec573e-442b-4563-8e2c-62b7693011df', 1),
      'https://cans.cachet.dk/portal/playground/studies/ecec573e-442b-4563-8e2c-62b7693011df/settings?participant=12345-1234&trigger_id=1',
    );
  });

  group('Study Deployment Status', () {
    test(' - Invited', () async {
      String plainJson = File(
        'test/json/carp.core-dart/study_deployment_status_invited.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      print(toJsonString(status));

      expect(status.status, StudyDeploymentStatusTypes.Invited);
      var deviceStatus = status.getDeviceStatusByRoleName('Primary Phone');
      expect(
        deviceStatus.remainingDevicesToRegisterBeforeDeployment!.length,
        1,
      );
      expect(deviceStatus.canBeDeployed, true);
      expect(deviceStatus.canObtainDeviceDeployment, false);
      expect(deviceStatus.isReadyForDeployment, false);
    });

    test(' - Running', () async {
      String plainJson = File(
        'test/json/carp.core-dart/study_deployment_status_running.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      print(toJsonString(status));

      expect(status.status, StudyDeploymentStatusTypes.Running);
      var deviceStatus = status.getDeviceStatusByRoleName('Primary Phone');
      expect(deviceStatus.canBeDeployed, null);
      expect(deviceStatus.canObtainDeviceDeployment, true);
      expect(deviceStatus.isReadyForDeployment, true);
    });

    test(' - Family - Invited', () async {
      String plainJson = File(
        'test/json/carp.core-dart/study_deployment_status_family_1.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      print(toJsonString(status));

      expect(status.status, StudyDeploymentStatusTypes.Invited);
      var deviceStatus = status.getDeviceStatusByRoleName("Father's Phone");
      expect(deviceStatus.status, DeviceDeploymentStatusTypes.Unregistered);
      expect(
        deviceStatus.remainingDevicesToRegisterBeforeDeployment!.length,
        2,
      );
      expect(deviceStatus.canBeDeployed, true);
      expect(deviceStatus.canObtainDeviceDeployment, false);
      expect(deviceStatus.isReadyForDeployment, false);

      deviceStatus = status.getDeviceStatusByRoleName("Mother's Phone");
      expect(deviceStatus.status, DeviceDeploymentStatusTypes.Unregistered);
      expect(
        deviceStatus.remainingDevicesToRegisterBeforeDeployment!.length,
        2,
      );
      expect(deviceStatus.canBeDeployed, true);
      expect(deviceStatus.canObtainDeviceDeployment, false);
      expect(deviceStatus.isReadyForDeployment, false);
    });

    test(' - Family - Mother Registered', () async {
      String plainJson = File(
        'test/json/carp.core-dart/study_deployment_status_family_2.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      print(toJsonString(status));

      expect(status.status, StudyDeploymentStatusTypes.DeployingDevices);
      var deviceStatus = status.getDeviceStatusByRoleName("Father's Phone");
      expect(deviceStatus.status, DeviceDeploymentStatusTypes.Unregistered);
      expect(
        deviceStatus.remainingDevicesToRegisterBeforeDeployment!.length,
        1,
      );
      expect(deviceStatus.canBeDeployed, true);
      expect(deviceStatus.canObtainDeviceDeployment, false);
      expect(deviceStatus.isReadyForDeployment, false);

      deviceStatus = status.getDeviceStatusByRoleName("Mother's Phone");
      expect(deviceStatus.status, DeviceDeploymentStatusTypes.Registered);
      expect(
        deviceStatus.remainingDevicesToRegisterBeforeDeployment!.length,
        1,
      );
      expect(deviceStatus.canBeDeployed, true);
      expect(deviceStatus.canObtainDeviceDeployment, false);
      expect(deviceStatus.isReadyForDeployment, false);
    });

    test(' - Family - Mother & Father Registered', () async {
      String plainJson = File(
        'test/json/carp.core-dart/study_deployment_status_family_3.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      print(toJsonString(status));

      expect(status.status, StudyDeploymentStatusTypes.DeployingDevices);
      var deviceStatus = status.getDeviceStatusByRoleName("Father's Phone");
      expect(deviceStatus.status, DeviceDeploymentStatusTypes.Registered);
      expect(
        deviceStatus.remainingDevicesToRegisterBeforeDeployment!.isEmpty,
        true,
      );
      expect(deviceStatus.canBeDeployed, true);
      expect(deviceStatus.canObtainDeviceDeployment, true);
      expect(deviceStatus.isReadyForDeployment, true);

      deviceStatus = status.getDeviceStatusByRoleName("Mother's Phone");
      expect(deviceStatus.status, DeviceDeploymentStatusTypes.Registered);
      expect(
        deviceStatus.remainingDevicesToRegisterBeforeDeployment!.isEmpty,
        true,
      );
      expect(deviceStatus.canBeDeployed, true);
      expect(deviceStatus.canObtainDeviceDeployment, true);
      expect(deviceStatus.isReadyForDeployment, true);
    });
  });

  test('DataStreamsConfiguration -> JSON', () async {
    String studyDeploymentId = "c9cc5317-48da-45f2-958e-58bc07f34681";
    DataStreamsConfiguration configuration = DataStreamsConfiguration(
      studyDeploymentId: studyDeploymentId,
      expectedDataStreams: {
        ExpectedDataStream(
          deviceRoleName: 'phone',
          dataType: 'dk.cachet.carp.geolocation',
        ),
        ExpectedDataStream(
          deviceRoleName: 'phone',
          dataType: 'dk.cachet.carp.stepcount',
        ),
      },
    );

    print(toJsonString(configuration));
    expect(configuration.expectedDataStreams, isNotEmpty);
  });

  group('Data Types', () {
    test('- Data', () async {
      final allData = [
        Acceleration(x: 1, y: 2, z: 3),
        Rotation(x: 4, y: 5, z: 6),
        MagneticField(x: 7, y: 8, z: 9),
        Geolocation(latitude: 55.6808, longitude: 12.5818),
        Geolocation(latitude: 55.6808, longitude: 12.5818),
        SignalStrength(rssi: -65),
        EDA(microSiemens: 0.5),
        StepCount(steps: 12),
        ECG(milliVolt: [0, 1, 0, -1]),
        HeartRate(bpm: 72),
        StepCount(steps: 1000),
        CompletedTask(taskName: 'Test Task'),
        TriggeredTask(
          triggerId: 1,
          taskName: 'Test Task',
          destinationDeviceRoleName: 'phone',
          control: Control.Start,
        ),
        Error(message: 'An error occurred'),
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

    test('- InputData', () async {
      final allData = [
        CustomInput(value: {'key': 'value'}),
        SexInput(value: Sex.Female),
        PhoneNumberInput(countryCode: '+45', number: '12345678'),
        SocialSecurityNumberInput(
          country: 'DK',
          socialSecurityNumber: '123456-7890',
        ),
        FullNameInput(firstName: 'John', middleName: 'A.', lastName: 'Doe'),
        AddressInput(street: 'Main St', city: 'Anytown'),
        DiagnosisInput(diagnosis: 'Flu', icd11Code: '123456'),
        InformedConsentInput(
          userId: '12345',
          name: 'John Doe',
          consent: 'true',
          signatureImage: 'blob',
        ),
        NoteInput(note: 'This is a note.'),
        EducationalDegreeInput(
          level: IscedLevel.ISCED_6,
          details: 'BSc in Computer Science',
        ),
        OnboardingResearcherInput(
          researcherId: 'res-123',
          researcherName: 'Dr. Smith',
          institutionName: 'University X',
        ),
        PreferredLanguageInput(languageCode: 'en', region: 'UK'),
        OccupationInput(
          roles: ['Software Developer', 'Tester', 'Manager'],
          other: '',
        ),
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
}
