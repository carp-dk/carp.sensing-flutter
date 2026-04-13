part of 'health_package.dart';

/// A probe collecting health data from Apple Health or Google Health Connect.
///
/// Configuration of this probe is based on a [HealthSamplingConfiguration] which
/// again is a [HistoricSamplingConfiguration].
/// This means that when started, it will try to collect data back to the last
/// time data was collected.
///
/// Hence, this probe is suited for configuration using a trigger that
/// collects data on a regular basis. This could be a [PeriodicTrigger] or it
/// could be configured as an [AppTask] asking the user to collect the data
/// on a regular basis.
class HealthProbe extends Probe {
  final StreamController<Measurement> _ctrl = StreamController.broadcast();
  Stream<Measurement> get stream => _ctrl.stream;

  @override
  HealthSamplingConfiguration get samplingConfiguration =>
      super.samplingConfiguration as HealthSamplingConfiguration;

  @override
  HealthServiceManager get deviceManager =>
      super.deviceManager as HealthServiceManager;

  /// Check if the sampling configuration contains a valid list of [HealthDataType]
  /// for the current platform (iOS or Android).
  ///
  /// Removes any health data type(s) which are not supported on this platform.
  void validateHealthDataTypes() {
    List<HealthDataType> toRemove = [];
    for (var type in samplingConfiguration.healthDataTypes) {
      // is this type supported on the current platform?
      bool supported = (Platform.isIOS)
          ? dataTypesIOS.contains(type)
          : dataTypesAndroid.contains(type);

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

  /// Does this probe have permissions to access health data specified in
  /// the [samplingConfiguration]?
  Future<bool> hasPermissions() async => await deviceManager
      .hasHealthPermissions(samplingConfiguration.healthDataTypes);

  /// Request permission to access health data specified in the [samplingConfiguration]
  /// for this probe.
  ///
  /// Note that this will show the Permission dialog to the user, asking for
  /// access to the health data.
  /// If the user denies access, this method will return false.
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
