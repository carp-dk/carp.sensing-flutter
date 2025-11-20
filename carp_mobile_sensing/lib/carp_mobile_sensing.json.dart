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
    RecurrentScheduledTrigger(
      type: RecurrentType.daily,
      time: const TimeOfDay(),
    ),
    SamplingEventTrigger(measureType: ''),
    ConditionalPeriodicTrigger(period: const Duration()),
    ConditionalSamplingEventTrigger(measureType: ''),
    CronScheduledTrigger(),
    RandomRecurrentTrigger(
      startTime: const TimeOfDay(hour: 1),
      endTime: const TimeOfDay(hour: 2),
    ),
    UserTaskTrigger(taskName: 'ignored', triggerCondition: UserTaskState.done),
    NoUserTaskTrigger(taskName: 'ignored'),
  ]);

  // Data classes
  FromJsonFactory().registerAll([
    Heartbeat(period: 1, deviceRoleName: '', deviceType: ''),
    CompletedAppTask(taskName: '', taskType: ''),
    FileData(filename: ''),
    DeviceInformation(),
    BatteryState(),
    FreeMemory(),
    ScreenEvent(),
    Timezone(''),
    AmbientLight(3, 5, 7, 3),
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
