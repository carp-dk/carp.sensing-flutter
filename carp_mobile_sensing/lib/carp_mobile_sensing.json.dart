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

  // DeviceConfiguration classes
  FromJsonFactory().registerAll([
    MobileSensingSmartphone(),
    OnlineService(roleName: ''),
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
    Heartbeat(period: 1, deviceRoleName: '', deviceType: ''),
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

  // AppTaskController classes
  // FromJsonFactory().register(UserTaskSnapshotList());
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
