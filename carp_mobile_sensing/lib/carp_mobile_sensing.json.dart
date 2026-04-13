part of 'carp_mobile_sensing.dart';

bool _fromJsonFunctionsRegistered = false;

/// Register all the fromJson functions for the domain classes.
void _registerFromJsonFunctions() {
  if (_fromJsonFunctionsRegistered) return;

  // Protocol classes
  FromJsonFactory().registerAll([
    StudyResponsible(id: '', name: ''),
    DataEndPoint(type: ''),
    FileDataEndPoint(),
    SQLiteDataEndPoint(),
    StudyDescription(title: ''),
  ]);

  // Device Configuration & Registration classes
  FromJsonFactory().registerAll([
    Smartphone(),
    BLEDevice(roleName: ''),
    BLEHeartRateDevice(roleName: ''),
    ServiceConfiguration(roleName: ''),
    HardwareDeviceRegistration(),
    SmartphoneRegistration(),
    BLEDeviceRegistration(bleAddress: ''),
    ServiceRegistration(),
  ]);

  // Task classes
  FromJsonFactory().registerAll([
    AppTask(type: ''),
    FunctionTask(),
    MonitoringTask(),
  ]);

  // Trigger classes
  FromJsonFactory().registerAll([
    NoOpTrigger(),
    ImmediateTrigger(),
    OneTimeTrigger(),
    DelayedTrigger(delay: const Duration()),
    PeriodicTrigger(period: const Duration()),
    DateTimeTrigger(schedule: DateTime.now()),
    RecurrentScheduledTrigger(),
    SamplingEventTrigger(measureType: ''),
    ConditionalPeriodicTrigger(period: const Duration()),
    ConditionalSamplingEventTrigger(measureType: ''),
    CronScheduledTrigger(),
    RandomRecurrentTrigger(),
    UserTaskTrigger(taskName: 'ignored', triggerCondition: UserTaskState.done),
    NoUserTaskTrigger(taskName: 'ignored'),
    AppLifecycleTrigger(),
  ]);

  // Data classes
  FromJsonFactory().registerAll([
    Error(message: ''),
    TriggeredTask(
      triggerId: 0,
      taskName: '',
      destinationDeviceRoleName: '',
      control: Control.Start,
    ),
    AppLifecycleEvent(''),
    CompletedTask(taskName: ''),
    CompletedAppTask(taskName: '', taskType: ''),
    Heartbeat(deviceRoleName: '', deviceType: ''),
    FileData(filename: ''),
    DeviceInformation(),
    ApplicationInformation(
      appName: '',
      packageName: '',
      version: '',
      buildNumber: '',
    ),
    BatteryState(),
    FreeMemory(),
    ScreenEvent(),
    Timezone(''),
    AmbientLight(3, 5, 7, 3),
    StepEvent(steps: 0),
  ]);

  // CompletedAppTask sub-classes for different AppTask types
  FromJsonFactory().registerAll([
    CompletedAppTask(taskName: '', taskType: AppTask.AUDIO_TYPE),
    CompletedAppTask(taskName: '', taskType: AppTask.COGNITIVE_ASSESSMENT_TYPE),
    CompletedAppTask(taskName: '', taskType: AppTask.IMAGE_TYPE),
    CompletedAppTask(taskName: '', taskType: AppTask.INFORMED_CONSENT_TYPE),
    CompletedAppTask(taskName: '', taskType: AppTask.SENSING_TYPE),
    CompletedAppTask(taskName: '', taskType: AppTask.SURVEY_TYPE),
    CompletedAppTask(taskName: '', taskType: AppTask.VIDEO_TYPE),
  ]);

  // Sampling Configuration classes
  FromJsonFactory().registerAll([
    PersistentSamplingConfiguration(),
    HistoricSamplingConfiguration(),
    IntervalSamplingConfiguration(interval: Duration.zero),
    PeriodicSamplingConfiguration(
      interval: Duration.zero,
      duration: Duration.zero,
    ),
    BatteryAwareSamplingConfiguration(
      normal: PersistentSamplingConfiguration(),
      low: PersistentSamplingConfiguration(),
      critical: PersistentSamplingConfiguration(),
    ),
  ]);

  // Sampling State classes
  FromJsonFactory().registerAll([
    SmartphoneDeploymentExecutorSamplingState(ExecutorState.Resumed, '', []),
    TaskControlExecutorSamplingState(ExecutorState.Resumed, 0, ''),
  ]);

  // AppTaskController classes
  FromJsonFactory().register(
    UserTaskSnapshot(
      '',
      AppTask(type: 'ignored'),
      UserTaskState.canceled,
      DateTime.now(),
      DateTime.now(),
      DateTime.now(),
      true,
      '',
      '',
    ),
  );

  _fromJsonFunctionsRegistered = true;
}
