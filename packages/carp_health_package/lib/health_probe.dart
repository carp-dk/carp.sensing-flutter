part of 'health_package.dart';

/// Collects health data from Apple Health or Google Health Connect.
///
/// Created by the [HealthSamplingPackage] for the [HealthSamplingPackage.HEALTH]
/// measure and configured by a [HealthSamplingConfiguration]. Each time it is
/// resumed, it fetches the configured health data types back to the last time
/// data was collected and emits one [HealthData] measurement per data point.
/// Use it with a trigger that runs regularly, such as a [PeriodicTrigger], or
/// from a [HealthAppTask] that the user starts.
///
/// Key points:
///  * On initialize, it removes types not supported on this platform and adds
///    the rest to the [HealthServiceManager].
///  * It collects nothing if permissions are missing, the type list is empty,
///    or the start time is after the end time.
///  * It pauses itself 20 seconds after a collection.
///  * Errors from the `health` plugin are logged and the resume fails.
class HealthProbe extends Probe {
  final StreamController<Measurement> _ctrl = StreamController.broadcast();

  /// A stream that only carries collection errors.
  ///
  /// Measurements are emitted on [measurements], not on this stream.
  Stream<Measurement> get stream => _ctrl.stream;

  @override
  HealthSamplingConfiguration get samplingConfiguration =>
      super.samplingConfiguration as HealthSamplingConfiguration;

  @override
  HealthServiceManager get deviceManager =>
      super.deviceManager as HealthServiceManager;

  /// Removes the health data types in [samplingConfiguration] that are not
  /// supported on the current platform (iOS or Android).
  ///
  /// Logs a warning for each removed type. Called when the probe is initialized.
  void validateHealthDataTypes() {
    List<HealthDataType> toRemove = [];
    for (var type in samplingConfiguration.healthDataTypes) {
      // is this type supported on the current platform?
      bool supported = (Platform.isIOS)
          ? dataTypeKeysIOS.contains(type)
          : dataTypeKeysAndroid.contains(type);

      if (!supported) {
        warning(
          "$runtimeType - Health data type '$type' is not supported on this platform "
          "(${Platform.operatingSystem}). "
          "Type is ignored.",
        );
        toRemove.add(type);
      }
    }
    // remove all types we don't support on this platform
    samplingConfiguration.healthDataTypes.removeWhere(
      (element) => toRemove.contains(element),
    );
  }

  @override
  bool onInitialize() {
    validateHealthDataTypes();
    deviceManager.addTypes(samplingConfiguration.healthDataTypes);
    return true;
  }

  /// Whether permission is granted to read the health data types in the
  /// [samplingConfiguration].
  ///
  /// See [HealthServiceManager.hasHealthPermissions] for the iOS caveat.
  Future<bool> hasPermissions() async => await deviceManager
      .hasHealthPermissions(samplingConfiguration.healthDataTypes);

  /// Requests permission to read the health data types in the
  /// [samplingConfiguration], if not already granted.
  ///
  /// Note that this shows the permission dialog to the user, asking for
  /// access to the health data.
  /// If the user denies access, this method returns false.
  ///
  /// Note that on Android, if the user denies access to the health data types
  /// TWICE, then the permissions are permanently denied and the app cannot ask
  /// anymore. In this case, this method cannot be used to request permissions.
  /// Instead, the user must manually go to the settings of the phone and enable
  /// the permissions.
  @override
  Future<bool> requestPermissions() async {
    bool permission = await hasPermissions();
    if (!permission) {
      permission = await deviceManager.requestHealthPermissions(
        samplingConfiguration.healthDataTypes,
      );
    }
    return permission;
  }

  @override
  Future<bool> onResume() async {
    // Check if we have permissions to access health data and fast out if not.
    bool permission = await deviceManager.hasPermissions();
    if (!permission) {
      warning(
        "$runtimeType - Cannot resume probe since we don't have permissions to access health data.",
      );
      return false;
    }

    if (await super.onResume()) {
      DateTime start =
          samplingConfiguration.lastTime ??
          DateTime.now().subtract(samplingConfiguration.past);
      DateTime end = DateTime.now();
      List<HealthDataType> healthDataTypes =
          samplingConfiguration.healthDataTypes;

      if (healthDataTypes.isEmpty) {
        warning(
          "$runtimeType - Trying to collect health data but the list of health data type to collect is empty. "
          "Did you add any types to the protocol which are available on this platform (iOS or Android)?",
        );
        return false;
      }
      if (start.isAfter(end)) {
        warning(
          "$runtimeType - Trying to collect health data but the start time ($start) is after the end time ($end). "
          "No data collected.",
        );
        return false;
      }

      debug(
        '$runtimeType - Collecting health data, types: $healthDataTypes, start: ${start.toUtc()}, end: ${end.toUtc()}',
      );

      try {
        List<HealthDataPoint>? healthDataPoints =
            await deviceManager.service?.getHealthDataFromTypes(
              startTime: start,
              endTime: end,
              types: healthDataTypes,
            ) ??
            [];
        debug(
          '$runtimeType - Retrieved ${healthDataPoints.length} health data points of types: $healthDataTypes',
        );

        // Convert HealthDataPoint to measurements and add them the measurements stream.
        for (var data in healthDataPoints) {
          addMeasurement(
            Measurement(
              sensorStartTime: data.dateFrom.microsecondsSinceEpoch,
              sensorEndTime: data.dateTo.microsecondsSinceEpoch,
              data: HealthData.fromHealthDataPoint(data),
            ),
          );
        }

        // Automatically pause this probe after it is done adding the measurements.
        Future.delayed(const Duration(seconds: 20), () => pause());
      } catch (exception) {
        var msg = "$runtimeType - Error collecting health data. $exception";
        warning(msg);
        _ctrl.addError(msg);
        return false;
      }
    }
    return true;
  }
}
