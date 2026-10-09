part of 'health_package.dart';

/// Collects health data from Apple Health or Google Health Connect.
///
/// Created by the [HealthSamplingPackage] for the [HealthSamplingPackage.HEALTH]
/// measure and configured by a [HealthSamplingConfiguration]. Each time it is
/// resumed, it fetches the configured health data types back to the last time
/// data was collected. Large catch-ups are written to SQLite in a background
/// isolate and only the last 7 days are emitted (see [_importInBackground]).
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
  HealthSamplingConfiguration get samplingConfiguration => super.samplingConfiguration as HealthSamplingConfiguration;

  @override
  HealthServiceManager get deviceManager => super.deviceManager as HealthServiceManager;

  /// Removes the health data types in [samplingConfiguration] that are not
  /// supported on the current platform (iOS or Android).
  ///
  /// Logs a warning for each removed type. Called when the probe is initialized.
  void validateHealthDataTypes() {
    List<HealthDataType> toRemove = [];
    for (var type in samplingConfiguration.healthDataTypes) {
      // is this type supported on the current platform?
      bool supported = (Platform.isIOS) ? dataTypeKeysIOS.contains(type) : dataTypeKeysAndroid.contains(type);

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
    samplingConfiguration.healthDataTypes.removeWhere((element) => toRemove.contains(element));
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
  Future<bool> hasPermissions() async =>
      await deviceManager.hasHealthPermissions(samplingConfiguration.healthDataTypes);

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
      permission = await deviceManager.requestHealthPermissions(samplingConfiguration.healthDataTypes);
    }
    return permission;
  }

  @override
  Future<bool> onResume() async {
    // Check if we have permissions to access health data and fast out if not.
    bool permission = await deviceManager.hasPermissions();
    if (!permission) {
      warning("$runtimeType - Cannot resume probe since we don't have permissions to access health data.");
      return false;
    }

    if (await super.onResume()) {
      DateTime start = samplingConfiguration.lastTime ?? DateTime.now().subtract(samplingConfiguration.past);
      DateTime end = DateTime.now();
      List<HealthDataType> healthDataTypes = samplingConfiguration.healthDataTypes;

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
        final count =
            await _importInBackground(start, end, healthDataTypes) ?? await _addToStream(start, end, healthDataTypes);
        debug('$runtimeType - Collected $count health data points of types: $healthDataTypes');

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

  /// Fetches the health data and writes it to SQLite in one batch, in a background
  /// isolate; only the last [_streamWindow] goes on the stream, for the UI cards.
  /// Returns the number of points, or null if the stream path must be used.
  Future<int?> _importInBackground(DateTime start, DateTime end, List<HealthDataType> types) async {
    final token = RootIsolateToken.instance;
    final deploymentId = deployment?.studyDeploymentId;
    final control = _taskControl;
    final usesSQLite = [DataEndPointTypes.SQLITE, DataEndPointTypes.CAWS].contains(deployment?.dataEndPoint?.type);
    // The stream applies privacy and data-format transforms; this path stores data as-is.
    final untransformed =
        (deployment?.privacySchemaName ?? NameSpace.CARP) == NameSpace.CARP &&
        (deployment?.dataEndPoint?.dataFormat ?? NameSpace.CARP) == NameSpace.CARP;
    if (!usesSQLite || !untransformed || token == null || deploymentId == null || control == null) return null;
    // The probe resumes periodically; don't start a second import of the same range.
    if (_importing) return 0;
    _importing = true;
    try {
      final (count, recent) = await _import(
        token,
        start,
        end,
        types,
        deploymentId,
        control.destinationDeviceRoleName ?? deployment!.deviceConfiguration.roleName,
        control.triggerId,
      );
      recent.forEach(addMeasurement);
      // addMeasurement stamps lastTime with "now" - reset it to [end], the time
      // the import actually covered, so points sampled meanwhile are not skipped.
      samplingConfiguration.lastTime = end.toUtc();
      deployment?.hasBeenUpdated();
      return count;
    } finally {
      _importing = false;
    }
  }

  /// The task control running this probe, which sets the trigger and role of the rows.
  /// Null if there are several, as then the stream would tag each row differently.
  TaskControl? get _taskControl => deployment?.taskControls
      .where((c) => deployment!.getTaskByName(c.taskName)?.measures?.any((m) => identical(m, measure)) ?? false)
      .singleOrNull;

  // Static, so the isolate closure only captures these arguments, not the probe.
  static Future<(int, List<Measurement>)> _import(
    RootIsolateToken token,
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
    String deploymentId,
    String roleName,
    int triggerId,
  ) => Isolate.run(() async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    DartPluginRegistrant.ensureInitialized(); // registers sqflite in this isolate
    CarpMobileSensing.ensureInitialized();

    final points = await Health().getHealthDataFromTypes(startTime: start, endTime: end, types: types);
    final measurements = points.map(_toMeasurement).toList();
    await SQLiteDataManager.writeAll(
      measurements,
      studyDeploymentId: deploymentId,
      deviceRoleName: roleName,
      triggerId: triggerId,
    );
    final since = DateTime.now().subtract(_streamWindow).microsecondsSinceEpoch;
    return (measurements.length, measurements.where((m) => m.sensorStartTime >= since).toList());
  });

  bool _importing = false;

  /// The period shown by the UI cards.
  static const _streamWindow = Duration(days: 7);

  /// Adds the health data to the [measurements] stream, on the main isolate.
  Future<int> _addToStream(DateTime start, DateTime end, List<HealthDataType> types) async {
    final points =
        await deviceManager.service?.getHealthDataFromTypes(startTime: start, endTime: end, types: types) ?? [];
    points.map(_toMeasurement).forEach(addMeasurement);
    return points.length;
  }

  static Measurement _toMeasurement(HealthDataPoint data) => Measurement(
    sensorStartTime: data.dateFrom.microsecondsSinceEpoch,
    sensorEndTime: data.dateTo.microsecondsSinceEpoch,
    data: HealthData.fromHealthDataPoint(data),
  );
}
