part of 'carp_core.dart';

bool _fromJsonFunctionsRegistered = false;

// Register all the fromJson functions for the domain classes.
void _registerFromJsonFunctions() {
  if (_fromJsonFunctionsRegistered) return;

  // DEPLOYMENT
  FromJsonFactory().registerAll([
    DefaultDeviceRegistration(),
    AltBeaconDeviceRegistration(),
  ]);

  // register all the different device deployment status types - see [DeviceDeploymentStatusTypes]
  final device = DefaultDeviceConfiguration(roleName: '');
  FromJsonFactory().register(DeviceDeploymentStatus(device: device));
  FromJsonFactory().register(
    DeviceDeploymentStatus(device: device),
    type:
        'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.NotDeployed',
  );
  FromJsonFactory().register(
    DeviceDeploymentStatus(device: device),
    type:
        'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.Unregistered',
  );
  FromJsonFactory().register(
    DeviceDeploymentStatus(device: device),
    type:
        'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.Registered',
  );
  FromJsonFactory().register(
    DeviceDeploymentStatus(device: device),
    type:
        'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.Deployed',
  );
  FromJsonFactory().register(
    DeviceDeploymentStatus(device: device),
    type:
        'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.Running',
  );
  FromJsonFactory().register(
    DeviceDeploymentStatus(device: device),
    type:
        'dk.cachet.carp.deployments.application.DeviceDeploymentStatus.NeedsRedeployment',
  );

  // register all the different study deployment status types - see [StudyDeploymentStatus]
  FromJsonFactory().register(StudyDeploymentStatus(studyDeploymentId: ''));
  FromJsonFactory().register(
    StudyDeploymentStatus(studyDeploymentId: ''),
    type:
        'dk.cachet.carp.deployments.application.StudyDeploymentStatus.Invited',
  );
  FromJsonFactory().register(
    StudyDeploymentStatus(studyDeploymentId: ''),
    type:
        'dk.cachet.carp.deployments.application.StudyDeploymentStatus.DeployingDevices',
  );
  FromJsonFactory().register(
    StudyDeploymentStatus(studyDeploymentId: ''),
    type:
        'dk.cachet.carp.deployments.application.StudyDeploymentStatus.DeploymentReady',
  );
  FromJsonFactory().register(
    StudyDeploymentStatus(studyDeploymentId: ''),
    type:
        'dk.cachet.carp.deployments.application.StudyDeploymentStatus.Running',
  );
  FromJsonFactory().register(
    StudyDeploymentStatus(studyDeploymentId: ''),
    type:
        'dk.cachet.carp.deployments.application.StudyDeploymentStatus.Stopped',
  );

  // PROTOCOL
  final config = SamplingConfiguration();

  FromJsonFactory().registerAll([
    TriggerConfiguration(),
    ElapsedTimeTrigger(elapsedTime: const Duration()),
    ManualTrigger(),
    ScheduledTrigger(
      recurrenceRule: RecurrenceRule(Frequency.DAILY),
      time: const TimeOfDay(),
    ),
    TaskConfiguration(),
    BackgroundTask(),
    CustomProtocolTask(studyProtocol: ''),
    WebTask(url: ''),
    Measure(type: ''),
    SamplingConfiguration(),
    NoOptionsSamplingConfiguration(),
    BatteryAwareSamplingConfiguration(
      critical: config,
      low: config,
      normal: config,
    ),
    GranularitySamplingConfiguration(Granularity.Balanced),
    DeviceConfiguration(roleName: ''),
    DefaultDeviceConfiguration(roleName: ''),
    PrimaryDeviceConfiguration(roleName: ''),
    CustomProtocolDevice(),
    Smartphone(),
    WebBrowser(),
    AltBeacon(),
    // BLEHeartRateDevice(),
    ParticipantAttribute(inputDataType: ''),
    AssignedTo(),
    AssignedTo(roleNames: {'AA'}),
    AccountIdentity(),
    EmailAccountIdentity(''),
    UsernameAccountIdentity(''),
    MACAddressDeviceRegistration(macAddress: ''),
  ]);

  // REQUESTS
  FromJsonFactory().registerAll([
    GetActiveParticipationInvitations(''),
    GetParticipantData(''),
    GetParticipantDataList(['']),
    SetParticipantData(''),
    CreateStudyDeployment(StudyProtocol(name: '', ownerId: ''), []),
    GetStudyDeploymentStatus(''),
    GetStudyDeploymentStatusList(['']),
    RegisterDevice('', '', DefaultDeviceRegistration()),
    UnregisterDevice('', ''),
    GetDeviceDeploymentFor('', ''),
    DeviceDeployed('', '', DateTime.now()),
    Stop(''),
    Add(StudyProtocol(ownerId: '', name: ''), ''),
    AddVersion(StudyProtocol(ownerId: '', name: ''), ''),
    UpdateParticipantDataConfiguration('', null, null),
    GetBy('', null),
    GetAllForOwner(''),
    GetVersionHistoryFor(''),
    CreateCustomProtocol('', '', '', ''),
    OpenDataStreams(
      DataStreamsConfiguration(studyDeploymentId: '', expectedDataStreams: {}),
    ),
    AppendToDataStreams('', []),
    GetDataStream(
      DataStreamId(studyDeploymentId: '', deviceRoleName: '', dataType: ''),
      0,
    ),
    CloseDataStreams([]),
    RemoveDataStreams([]),
  ]);

  // DATA TYPES
  FromJsonFactory().registerAll([
    // Data(),
    // SensorData(),
    Acceleration(),
    Rotation(),
    MagneticField(),
    Geolocation(),
    SignalStrength(),
    StepCount(),
    HeartRate(),
    ECG(),
    EDA(),
    CompletedTask(taskName: ''),
    TriggeredTask(
      triggerId: 0,
      taskName: '',
      destinationDeviceRoleName: '',
      control: Control.Start,
    ),
    Error(message: ''),
  ]);

  // INPUT DATA TYPES
  FromJsonFactory().registerAll([
    CustomInput(value: ''),
    SexInput(value: Sex.Female),
    FullNameInput(),
    AddressInput(),
    PhoneNumberInput(countryCode: '', number: ''),
    SocialSecurityNumberInput(socialSecurityNumber: '', country: ''),
    InformedConsentInput(name: '', userId: '', consent: '', signatureImage: ''),
    DiagnosisInput(icd11Code: ''),
  ]);

  _fromJsonFunctionsRegistered = true;
}
