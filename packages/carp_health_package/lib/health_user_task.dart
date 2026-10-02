part of 'health_package.dart';

/// A [UserTask] without UI that collects health data when the user starts it.
///
/// Created by the [HealthUserTaskFactory] for a [HealthAppTask]. On start, it
/// asks its [HealthProbe] to request permission for the health data types,
/// resumes data collection, and marks itself done 30 seconds later. If
/// permission is denied or the task has no health probe, it logs a warning
/// and collects nothing. When done, it pauses data collection again.
class HealthUserTask extends UserTask {
  /// The [HealthAppTask] which specifies which health data to collect.
  HealthAppTask get healthAppTask => super.task as HealthAppTask;

  HealthUserTask(super.executor);

  @override
  void onStart() {
    // first initialize the background task executor
    super.onStart();

    // then check for permission to access health data
    try {
      var healthProbe =
          backgroundTaskExecutor.probes.firstWhere(
                (probe) => probe is HealthProbe,
              )
              as HealthProbe;

      // Always request permissions when starting the health user task.
      healthProbe.requestPermissions().then((granted) {
        if (granted) {
          debug(
            '$runtimeType - Got permissions to access health data. Now starting data collection.',
          );
          backgroundTaskExecutor.resume();
          Timer(const Duration(seconds: 30), () => onDone());
        } else {
          warning(
            '$runtimeType - Could not get permissions to access health data.',
          );
          return;
        }
      });
    } catch (error) {
      // if the health probe is not found in the list of probes, we cannot
      // access health data.
      warning(
        '$runtimeType - No health probe found in list of probes. Does the '
        'study protocol include any health data types?',
      );
    }
  }

  @override
  void onDone({dequeue = false, Data? result}) {
    super.onDone(dequeue: dequeue, result: result);
    backgroundTaskExecutor.pause();
  }
}

/// A [UserTaskFactory] that creates a [HealthUserTask] for each [AppTask] of
/// type [AppTask.HEALTH_ASSESSMENT_TYPE].
///
/// Registered in the [AppTaskController] by [HealthSamplingPackage.onRegister].
class HealthUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [AppTask.HEALTH_ASSESSMENT_TYPE];

  @override
  UserTask create(AppTaskExecutor executor) => HealthUserTask(executor);
}
