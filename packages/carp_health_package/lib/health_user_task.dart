part of 'health_package.dart';

/// A non-UI user task that collects health data in the background.
///
/// When started, it will ask for permission to access the health data listed
/// in the [HealthAppTask].
class HealthUserTask extends UserTask {
  // Health health = Health();

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

class HealthUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [AppTask.HEALTH_ASSESSMENT_TYPE];

  @override
  UserTask create(AppTaskExecutor executor) => HealthUserTask(executor);
}
