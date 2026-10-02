/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Stores or uploads the [Measurement]s collected in a study deployment.
///
/// A data manager listens to the measurement stream of one deployment and
/// saves each measurement, e.g. to a file, a database, or a server. Which one
/// is used is set by the protocol's [DataEndPoint]: the [SmartphoneStudyController]
/// asks the [DataManagerRegistry] for a data manager of [DataEndPoint.type] and
/// calls [configure] with the deployment's measurements.
///
/// Key points:
///  * One instance per deployment. Several deployments can run at the same
///    time, so implementations must not share resources like the same file
///    or network socket.
///  * [onMeasurement] is called for each measurement; [onError] and [onDone]
///    for errors and the end of the stream.
///  * Call [close] to flush buffered data. The data manager cannot be used
///    after that.
///
/// See also [AbstractDataManager] to extend, the built-in [SQLiteDataManager],
/// [FileDataManager], and [ConsoleDataManager], and [DataManagerFactory] to
/// register your own.
abstract class DataManager {
  /// The deployment using this data manager.
  PrimaryDeviceDeployment get deployment;

  /// The ID of the study deployment that this manager is handling.
  String get studyDeploymentId;

  /// The type of this data manager as enumerated in [DataEndPointTypes].
  String get type;

  /// Configures the data manager with the study [deployment], the
  /// [dataEndPoint], and the stream of [measurements] to handle.
  ///
  /// Call this before any data is handled.
  Future<void> configure({
    required DataEndPoint dataEndPoint,
    required SmartphoneDeployment deployment,
    required Stream<Measurement> measurements,
  });

  /// Flushes any buffered data and closes this data manager.
  ///
  /// After calling [close] the data manager can no longer be used.
  Future<void> close();

  /// Stream of data manager events, see [DataManagerEventTypes].
  Stream<DataManagerEvent> get events;

  /// On each measurement collected, the [onMeasurement] handler is called.
  ///
  /// Implementations of this interface should handle how to save
  /// or upload the [measurement].
  Future<void> onMeasurement(Measurement measurement);

  /// When the data stream closes, the [onDone] handler is called.
  Future<void> onDone();

  /// When an error event is sent on the stream, the [onError] handler is called.
  Future<void> onError(Object error);
}

/// An event from a [DataManager], emitted on [DataManager.events].
class DataManagerEvent {
  /// The event type, see [DataManagerEventTypes].
  String type;

  /// An optional description of the event.
  String? message;

  /// Create a [DataManagerEvent].
  DataManagerEvent(this.type, [this.message]);

  @override
  String toString() => 'DataManagerEvent - type: $type, message: $message';
}

/// The known [DataManagerEvent.type] values.
///
/// Data managers can add their own types.
class DataManagerEventTypes {
  /// The data manager has been configured.
  static const String configured = 'configured';

  /// The data manager has been closed.
  static const String closed = 'closed';
}

/// A base [DataManager] to extend when you write your own data manager.
///
/// [configure] subscribes to the measurement stream and calls [onMeasurement]
/// for each measurement; you implement [onMeasurement] to store or upload it.
/// Errors on the stream are saved as [Error] measurements. Emits the
/// [DataManagerEventTypes.configured] and [DataManagerEventTypes.closed]
/// events.
abstract class AbstractDataManager implements DataManager {
  late SmartphoneDeployment _deployment;
  DataEndPoint? _dataEndPoint;
  StreamSubscription<Measurement>? _subscription;
  final StreamController<DataManagerEvent> _controller =
      StreamController.broadcast();

  /// The [DataEndPoint] that this data manager is handling.
  ///
  /// `null` until [configure] is called.
  DataEndPoint? get dataEndPoint => _dataEndPoint;

  @override
  SmartphoneDeployment get deployment => _deployment;

  @override
  String get studyDeploymentId => deployment.studyDeploymentId;

  @override
  @protected
  Stream<DataManagerEvent> get events => _controller.stream;

  /// Adds [event] to the [events] stream.
  @mustCallSuper
  @protected
  void addEvent(DataManagerEvent event) => _controller.add(event);

  @override
  @mustCallSuper
  Future<void> configure({
    required DataEndPoint dataEndPoint,
    required SmartphoneDeployment deployment,
    required Stream<Measurement> measurements,
  }) async {
    info('Configuring $runtimeType...');
    _deployment = deployment;
    _dataEndPoint = dataEndPoint;
    _subscription = measurements.listen(
      (measurement) => onMeasurement(measurement),
      onError: onError,
      onDone: onDone,
    );
    addEvent(DataManagerEvent(DataManagerEventTypes.configured));
  }

  /// When the data stream closes, the [onDone] handler is called.
  /// Default implementation is a no-op function. If another behavior is wanted,
  /// implementations of this abstract data manager should handle closing of
  /// the data stream.
  @override
  Future<void> onDone() async {}

  /// Saves [error] as an [Error] measurement via [onMeasurement].
  @override
  Future<void> onError(Object? error) async => await onMeasurement(
    Measurement.fromData(Error(message: error.toString())),
  );

  @override
  @mustCallSuper
  Future<void> close() async {
    info('Closing $runtimeType...');
    await _subscription?.cancel();
    addEvent(DataManagerEvent(DataManagerEventTypes.closed));
  }

  @override
  String toString() => runtimeType.toString();
}

/// Creates the [DataManager] for one [DataEndPoint.type].
///
/// Implement one for each data manager and register it in the
/// [DataManagerRegistry].
abstract class DataManagerFactory {
  /// The [DataEndPoint.type] that this factory handles, see [DataEndPointTypes].
  String get type;

  /// Creates a new [DataManager].
  DataManager create();
}

/// The registry of [DataManagerFactory]s, used to create a [DataManager] for a
/// [DataEndPoint].
///
/// A singleton. The client manager registers the factories for the built-in
/// data managers on configuration. To use your own data manager, [register]
/// its factory before the study is deployed.
class DataManagerRegistry {
  static final DataManagerRegistry _instance = DataManagerRegistry._();
  factory DataManagerRegistry() => _instance;
  final Map<String, DataManagerFactory> _registry = {};
  DataManagerRegistry._();

  /// Registers a [factory] for its [DataManagerFactory.type], replacing any
  /// existing one.
  void register(DataManagerFactory factory) =>
      _registry[factory.type] = factory;

  /// Registers all [factories], see [register].
  void registerAll(List<DataManagerFactory> factories) {
    for (var factory in factories) {
      register(factory);
    }
  }

  /// Creates a new data manager for the data endpoint [type], or `null` if no
  /// factory is registered for it.
  DataManager? create(String type) => _registry[type]?.create();
}
