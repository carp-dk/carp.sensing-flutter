/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../runtime.dart';

/// Collects data for one [Measure].
///
/// The data comes from a sensor, a connected device or a service.
/// A probe is the leaf of the executor tree. Each measure in a task gets its
/// own probe, created by the measure type's [SamplingPackage] through
/// [SamplingPackageRegistry.create]. Write a probe when you add a new measure
/// type to a sampling package; most extend one of the specialized probes below.
///
/// Key points:
///  * Lifecycle: see [Executor]. Subclasses implement [onInitialize],
///    [onResume] and [onPause]; the default ones do nothing.
///  * Emits [Measurement]s with [addMeasurement]; errors with [addError].
///  * Its [samplingConfiguration] is looked up in the measure, the
///    deployment and the sampling packages, in that order.
///  * [permissions] come from the [CamsDataTypeMetaData] of the measure type.
///    The [SmartphoneStudyController] asks for them up front; probes only
///    check them with [hasRequiredPermissions].
///
/// Specialized probes: [MeasurementProbe] (one measurement), [IntervalProbe]
/// (polling), [StreamProbe] (continuous stream), [PeriodicStreamProbe],
/// [BufferingPeriodicProbe], [BufferingIntervalStreamProbe] and
/// [BufferingPeriodicStreamProbe].
abstract class Probe extends AbstractExecutor<Measure> {
  /// The device manager of the device this probe collects data from.
  ///
  /// Set by [SamplingPackageRegistry.create].
  late DeviceManager deviceManager;

  /// Whether this probe is enabled.
  ///
  /// Not used by the CAMS runtime itself.
  bool enabled = true;

  /// The data type this probe collects, e.g. `dk.cachet.carp.steps`.
  String? get type => measure?.type;

  /// The [Measure] that configures this probe.
  Measure? get measure => configuration;

  /// The sampling configuration for this probe.
  ///
  /// Configuration is obtained in the following order:
  ///  * from the [Measure.overrideSamplingConfiguration]
  ///  * from the [DeviceConfiguration.defaultSamplingConfiguration] of the [deployment]
  ///  * from the [DeviceConfiguration.dataTypeSamplingSchemes] of the static device configuration
  ///  * from the [SamplingPackage.samplingSchemes] of the sampling packages
  ///
  /// Returns `null` in case no configuration is found.
  ///
  /// See also the section on [Sampling schemes and configurations](https://github.com/cph-cachet/carp.core-kotlin/blob/develop/docs/carp-common.md#sampling-schemes-and-configurations)
  /// in the CARP Core Framework. In addition to CARP Core, CARP Mobile Sensing
  /// also supports sampling schemes in the sampling packages, which are used
  /// as the 4th possible configuration in the list above.
  SamplingConfiguration? get samplingConfiguration =>
      measure?.overrideSamplingConfiguration ??
      deployment?.deviceConfiguration.defaultSamplingConfiguration?[measure?.type] ??
      deployment?.deviceConfiguration.dataTypeSamplingSchemes?[measure?.type]?.defaultSamplingConfiguration ??
      SamplingPackageRegistry().samplingSchemes[measure?.type]?.defaultSamplingConfiguration;

  /// Adds [measurement] to [measurements].
  ///
  /// If the [samplingConfiguration] is a [PersistentSamplingConfiguration],
  /// also sets its `lastTime` to now and saves the deployment, at most once
  /// per second.
  @override
  void addMeasurement(Measurement measurement) {
    // timestamp this sampling
    if (samplingConfiguration is PersistentSamplingConfiguration) {
      (samplingConfiguration as PersistentSamplingConfiguration).lastTime = DateTime.now().toUtc();
      // Save the checkpoint once per burst, not once per measurement.
      _saveCheckpoint ??= Timer(const Duration(seconds: 1), () {
        _saveCheckpoint = null;
        deployment?.hasBeenUpdated();
      });
    }
    super.addMeasurement(measurement);
  }

  Timer? _saveCheckpoint;

  List<Permission>? _permissions;

  /// The permissions this probe needs. Empty if none.
  ///
  /// Taken from the [CamsDataTypeMetaData] of its data [type].
  List<Permission> get permissions {
    if (_permissions == null) {
      var schema = SamplingPackageRegistry().samplingSchemes[type];
      _permissions = (schema != null && schema.dataType is CamsDataTypeMetaData)
          ? (schema.dataType as CamsDataTypeMetaData).permissions
          : [];
    }
    return _permissions!;
  }

  /// Whether all [permissions] are granted. Returns false if checking fails.
  Future<bool> arePermissionsGranted() async {
    // fast out if no permissions to check
    if (permissions.isEmpty) return true;

    debug('$runtimeType - Checking permission for: $permissions');
    bool granted = true;

    try {
      for (var permission in permissions) {
        granted = granted && await permission.isGranted;
      }
    } catch (error) {
      addError('$runtimeType - Error trying to check permissions, error: $error');
      return false;
    }
    return granted;
  }

  /// Asks the user for any [permissions] not yet granted.
  ///
  /// Goes through [SmartPhoneClientManager.requestPermissions]. Returns true if all permissions are granted afterwards.
  Future<bool> requestPermissions() async {
    // fast out if already have permissions
    if (await arePermissionsGranted()) return true;

    debug('$runtimeType - Asking permission for: $permissions');
    await SmartPhoneClientManager().requestPermissions(permissions);
    return arePermissionsGranted();
  }

  /// Whether this probe is allowed to run.
  ///
  /// The [SmartphoneStudyController] asks for all deployment permissions up
  /// front ([SmartphoneStudyController.askForAllPermissions]), so probes only
  /// check. Always true on iOS: `permission_handler` reports Android-only groups
  /// (e.g. activityRecognition, phone) as denied there, and iOS prompts on
  /// first use.
  Future<bool> hasRequiredPermissions() async => Platform.isIOS ? true : await arePermissionsGranted();

  // default no-op implementation of callback methods below

  @override
  bool onInitialize() => true;

  @override
  Future<bool> onResume() async => true;

  @override
  Future<bool> onPause() async => true;
}

//---------------------------------------------------------------------------------------
//                                SPECIALIZED PROBES
//---------------------------------------------------------------------------------------

/// A probe that does nothing. Useful as a placeholder, e.g. in tests.
class StubProbe extends Probe {}

/// A probe that collects one [Measurement] when resumed, then pauses itself.
///
/// Subclasses implement [getMeasurement]. The probe pauses 5 seconds after
/// [getMeasurement] completes. See [DeviceProbe] for an example.
abstract class MeasurementProbe extends Probe {
  @override
  Future<bool> onResume() async {
    if (await hasRequiredPermissions()) {
      getMeasurement().then((measurement) {
        if (measurement != null) addMeasurement(measurement);
        // automatically stop this probe after it is done collecting the measurement
        Future.delayed(const Duration(seconds: 5), () => pause());
      }, onError: (Object error, StackTrace? stackTrace) => addError(error, stackTrace));
      return true;
    } else {
      return false;
    }
  }

  /// Collects the [Measurement]. Implemented by subclasses.
  ///
  /// Can return `null` if no data is available.
  /// Can return an [Error] measurement if an error occurs.
  Future<Measurement?> getMeasurement();
}

/// A probe that collects a [Measurement] with [getMeasurement] at an interval.
///
/// The interval is [IntervalSamplingConfiguration.interval].
/// Resuming fails if the [samplingConfiguration] has no interval.
/// See [MemoryProbe] for an example.
abstract class IntervalProbe extends MeasurementProbe {
  Timer? _timer;

  @override
  IntervalSamplingConfiguration? get samplingConfiguration =>
      super.samplingConfiguration as IntervalSamplingConfiguration;

  @override
  Future<bool> onResume() async {
    if (await hasRequiredPermissions()) {
      Duration? interval = samplingConfiguration?.interval;
      if (interval != null) {
        _timer ??= Timer.periodic(interval, (_) async {
          try {
            var measurement = await getMeasurement();
            if (measurement != null) addMeasurement(measurement);
          } catch (error) {
            addError(error);
          }
        });
      } else {
        warning(
          '$runtimeType - no valid interval found in sampling configuration: $samplingConfiguration. '
          'Is a valid IntervalSamplingConfiguration provided?',
        );
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> onPause() async {
    _timer?.cancel();
    _timer = null;
    return true;
  }
}

/// A probe that forwards every [Measurement] from a [stream] while resumed.
///
/// Subclasses implement [stream]. Resuming fails if [stream] is null, e.g.
/// when its device is not connected. See [ScreenProbe] for an example.
abstract class StreamProbe extends Probe {
  StreamSubscription<Measurement>? _subscription;
  Stream<Measurement>? _stream;

  /// The stream of [Measurement]s to forward. Implemented by subclasses.
  ///
  /// Read on the first resume after creation or a pause.
  Stream<Measurement>? get stream;

  @override
  Future<bool> onResume() async {
    if (await hasRequiredPermissions()) {
      _stream ??= stream;
      if (_stream == null) {
        warning(
          "Trying to start the stream probe '$runtimeType' which does not provide a measurement stream. "
          'Have you initialized this probe correctly or is the device connected?',
        );
        return false;
      } else {
        // Resuming an already resumed probe would otherwise orphan the old
        // subscription, which keeps delivering.
        await _subscription?.cancel();
        _subscription = _stream?.listen(_onData, onError: _onError, onDone: _onDone);
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> onPause() async {
    await _subscription?.cancel();
    _stream = null;
    return true;
  }

  void _onData(Measurement measurement) => addMeasurement(measurement);
  void _onError(Object error) => addError(error);
  void _onDone() => _measurementsController.close();
}

/// A [StreamProbe] that listens to its [stream] only in sampling windows.
///
/// Every [PeriodicSamplingConfiguration.interval] it listens for
/// [PeriodicSamplingConfiguration.duration] and forwards all measurements in
/// that window. Subclasses implement [stream].
///
/// Pausing cancels the current window and stops new windows from starting.
abstract class PeriodicStreamProbe extends StreamProbe {
  Timer? _timer;

  @override
  PeriodicSamplingConfiguration? get samplingConfiguration =>
      super.samplingConfiguration as PeriodicSamplingConfiguration;

  @override
  Future<bool> onResume() async {
    if (await hasRequiredPermissions()) {
      if (stream == null) {
        warning(
          "Trying to start the stream probe '$runtimeType' which does not provide a measurement stream. "
          'Have you initialized this probe correctly?',
        );
        return false;
      } else {
        Duration? interval = samplingConfiguration?.interval;
        Duration? duration = samplingConfiguration?.duration;
        if (interval != null && duration != null) {
          // create a recurrent timer that starts sampling
          _timer = Timer.periodic(interval, (timer) {
            _subscription = stream?.listen(_onData, onError: _onError, onDone: _onDone);
            // create a timer that stops the sampling after the specified duration.
            Timer(duration, () async => await _subscription?.cancel());
          });
        } else {
          warning(
            '$runtimeType - no valid interval and duration found in sampling configuration: $samplingConfiguration. '
            'Is a valid PeriodicSamplingConfiguration provided?',
          );
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> onPause() async {
    _timer?.cancel();
    return await super.onPause();
  }
}

/// A probe that collects data in sampling windows, one measurement per window.
///
/// Uses a [PeriodicSamplingConfiguration]: every
/// [PeriodicSamplingConfiguration.interval] it calls [onSamplingStart], and
/// after [PeriodicSamplingConfiguration.duration] it calls [onSamplingEnd]
/// and adds the result of [getMeasurement]. On pause, any buffered data is
/// collected with [getMeasurement] too.
abstract class BufferingPeriodicProbe extends MeasurementProbe {
  /// The timer that starts each sampling window.
  Timer? timer;

  @override
  PeriodicSamplingConfiguration? get samplingConfiguration =>
      super.samplingConfiguration as PeriodicSamplingConfiguration;

  @override
  Future<bool> onResume() async {
    if (await hasRequiredPermissions()) {
      Duration? interval = samplingConfiguration?.interval;
      Duration? duration = samplingConfiguration?.duration;
      if (interval != null && duration != null) {
        // create a recurrent timer that every [interval] starts the buffering
        timer = Timer.periodic(interval, (Timer t) {
          onSamplingStart();
          // create a timer that stops the buffering after the specified [duration].
          Timer(duration, () async {
            onSamplingEnd();
            // collect the measurement
            try {
              Measurement? measurement = await getMeasurement();
              if (measurement != null) addMeasurement(measurement);
            } catch (error) {
              addError(error);
            }
          });
        });
      } else {
        warning(
          '$runtimeType - no valid interval and duration found in sampling configuration: $samplingConfiguration. '
          'Is a valid PeriodicSamplingConfiguration provided?',
        );
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> onPause() async {
    timer?.cancel();

    // check if there are some buffered data that needs to be collected before pausing
    try {
      Measurement? measurement = await getMeasurement();
      if (measurement != null) addMeasurement(measurement);
    } catch (error) {
      addError(error);
    }
    return true;
  }

  /// Handler called when sampling period starts.
  void onSamplingStart();

  /// Handler called when sampling period ends.
  void onSamplingEnd();

  /// Returns the [Measurement] for the last sampling window.
  ///
  /// Implemented by subclasses.
  ///
  /// Can return `null` if no data is available.
  /// Can return an [Error] if an error occurs.
  @override
  Future<Measurement?> getMeasurement();
}

/// A probe that buffers a [bufferingStream] and emits one measurement per interval.
///
/// The interval is [IntervalSamplingConfiguration.interval].
/// Subclasses implement [bufferingStream], [onSamplingData] (called per event)
/// and [getMeasurement] (called per interval).
///
/// Unlike [BufferingPeriodicStreamProbe], it listens to [bufferingStream]
/// all the time while resumed, not only in sampling windows.
abstract class BufferingIntervalStreamProbe extends StreamProbe {
  Timer? _timer;
  StreamSubscription<dynamic>? _bufferingStreamSubscription;

  @override
  IntervalSamplingConfiguration? get samplingConfiguration =>
      super.samplingConfiguration as IntervalSamplingConfiguration;

  @override
  Future<bool> onResume() async {
    if (await hasRequiredPermissions()) {
      Duration? interval = samplingConfiguration?.interval;
      if (interval != null) {
        _bufferingStreamSubscription = bufferingStream.listen(onSamplingData, onError: _onError, onDone: _onDone);
        _timer = Timer.periodic(interval, (_) async {
          try {
            Measurement? measurement = await getMeasurement();
            if (measurement != null) addMeasurement(measurement);
          } catch (error) {
            addError(error);
          }
        });
      } else {
        warning(
          '$runtimeType - no valid interval found in sampling configuration: $samplingConfiguration. '
          'Is a valid IntervalSamplingConfiguration provided?',
        );
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> onPause() async {
    _timer?.cancel();
    await _bufferingStreamSubscription?.cancel();
    return await super.onPause();
  }

  /// The stream of events to buffer. Implemented by subclasses.
  Stream<dynamic> get bufferingStream;

  /// Called for each event on [bufferingStream]; buffers it.
  void onSamplingData(dynamic event);

  /// Returns the [Measurement] for the data buffered since the last call.
  /// Called every interval. Implemented by subclasses.
  ///
  /// Can return `null` if no data is available.
  /// Can return an [Error] if an error occurs.
  Future<Measurement?> getMeasurement();
}

/// A probe that buffers a [bufferingStream] in sampling windows.
///
/// It emits one measurement per window.
/// Uses a [PeriodicSamplingConfiguration]: every
/// [PeriodicSamplingConfiguration.interval] it calls [onSamplingStart] and
/// listens to [bufferingStream] for [PeriodicSamplingConfiguration.duration].
/// Each event goes to [onSamplingData]. When the window ends, it calls
/// [onSamplingEnd] and adds the result of [getMeasurement].
///
/// Unlike [BufferingIntervalStreamProbe], it listens to [bufferingStream]
/// only inside sampling windows. See [LightProbe] for an example, which
/// turns the light readings of each window into one [AmbientLight]
/// measurement.
abstract class BufferingPeriodicStreamProbe extends PeriodicStreamProbe {
  StreamSubscription<dynamic>? _bufferingStreamSubscription;
  Timer? _durationTimer;

  // we don't use the stream in the super class so we give it an empty non-null stream
  @override
  Stream<Measurement> get stream => const Stream.empty();

  @override
  Future<bool> onResume() async {
    if (await hasRequiredPermissions()) {
      Duration? interval = samplingConfiguration?.interval;
      Duration? duration = samplingConfiguration?.duration;
      if (interval != null && duration != null) {
        _timer = Timer.periodic(interval, (Timer t) {
          onSamplingStart();
          _bufferingStreamSubscription = bufferingStream.listen(onSamplingData, onError: _onError, onDone: _onDone);
          _durationTimer = Timer(duration, () async {
            await _bufferingStreamSubscription?.cancel();
            onSamplingEnd();
            try {
              Measurement? measurement = await getMeasurement();
              if (measurement != null) addMeasurement(measurement);
            } catch (error) {
              addError(error);
            }
          });
        });
      } else {
        warning(
          '$runtimeType - no valid interval and duration found in sampling configuration: $samplingConfiguration. '
          'Is a valid PeriodicSamplingConfiguration provided?',
        );
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> onPause() async {
    _durationTimer?.cancel();
    await _bufferingStreamSubscription?.cancel();

    return await super.onPause();
  }

  // Sub-classes should implement the following handler methods.

  /// The stream of events to buffer. Implemented by subclasses.
  Stream<dynamic> get bufferingStream;

  /// Called when a sampling window starts, before listening.
  void onSamplingStart();

  /// Called when a sampling window ends, before [getMeasurement].
  void onSamplingEnd();

  /// Called for each event on [bufferingStream]; buffers it.
  void onSamplingData(dynamic event);

  /// Returns the [Measurement] for the last sampling window.
  ///
  /// Implemented by subclasses.
  ///
  /// Can return `null` if no data is available.
  /// Can return an [Error] if an error occurs.
  Future<Measurement?> getMeasurement();
}
