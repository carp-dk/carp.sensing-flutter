/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// The [DataManager] interface is used to upload [Measurement] objects to any
/// data manager that implements this interface.
///
/// Note that each instance of a data manager supports one deployment
/// ([PrimaryDeviceDeployment]). A data manager should hence be able to handle
/// separate data management of concurrently running deployments.
/// Hence, caution on resource starvation should be considered, such as not
/// accessing the same file or network socket.
abstract class DataManager {
  /// The deployment using this data manager.
  PrimaryDeviceDeployment get deployment;

  /// The ID of the study deployment that this manager is handling.
  String get studyDeploymentId;

  /// The type of this data manager as enumerated in [DataEndPointTypes].
  String get type;

  /// Configure the data manager by specifying the study [deployment], the
  /// [dataEndPoint], and the stream of [measurements] events to handle.
  Future<void> configure({
    required DataEndPoint dataEndPoint,
    required SmartphoneDeployment deployment,
    required Stream<Measurement> measurements,
  });

  /// Flush any buffered data and close this data manager.
  /// After calling [close] the data manager can no longer be used.
  Future<void> close();

  /// Stream of data manager events.
  Stream<DataManagerEvent> get events;

  /// On each measurement collected, the [onMeasurement] handler is called.
  ///
  /// Implementations of this interface should handle how to save
  /// or upload the [measurement].
  Future<void> onMeasurement(Measurement measurement);

  /// When the data stream closes, the [onDone] handler is called.
  Future<void> onDone();

  /// When an error event is send on the stream, the [onError] handler is called.
  Future<void> onError(Object error);
}

/// An event for a data manager.
class DataManagerEvent {
  /// The event type, see [DataManagerEventTypes].
  String type;

  /// What is this event about?
  String? message;

  /// Create a [DataManagerEvent].
  DataManagerEvent(this.type, [this.message]);

  @override
  String toString() => 'DataManagerEvent - type: $type, message: $message';
}

/// An enumeration of data manager event types.
class DataManagerEventTypes {
  static const String configured = 'configured';
  static const String closed = 'closed';
}

/// An abstract [DataManager] implementation useful for extension.
///
/// Takes data from a [Stream<Measurement>] and uploads it.
/// Also supports JSON encoding via the [toJsonString] method.
abstract class AbstractDataManager implements DataManager {
  late SmartphoneDeployment _deployment;
  DataEndPoint? _dataEndPoint;
  StreamSubscription<Measurement>? _subscription;
  final StreamController<DataManagerEvent> _controller =
      StreamController.broadcast();

  /// The [DataEndPoint] that this data manager is handling.
  /// Set in the [configure] method.
  DataEndPoint? get dataEndPoint => _dataEndPoint;

  @override
  SmartphoneDeployment get deployment => _deployment;

  @override
  String get studyDeploymentId => deployment.studyDeploymentId;

  @override
  @protected
  Stream<DataManagerEvent> get events => _controller.stream;

  /// Add [event] to the [events] stream.
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

  @override
  Future<void> onError(Object? error) async => await onMeasurement(
    Measurement.fromData(Error(message: error.toString())),
  );

  @override
  @mustCallSuper
  Future<void> close() async {
    info('Closing $runtimeType...');
    _subscription?.cancel();
    addEvent(DataManagerEvent(DataManagerEventTypes.closed));
  }

  @override
  String toString() => runtimeType.toString();
}

/// A factory which can create a [DataManager] based on the `type` of an
/// [DataEndPoint].
abstract class DataManagerFactory {
  /// The [DataEndPoint] type.
  String get type;

  /// Create a [DataManager].
  DataManager create();
}

/// A registry of [DataManagerFactory]s.
///
/// In order to be able to create a new [DataManager], you must [register] a
/// [DataManagerFactory] here, which then later is used to call [create]
/// an appropriate [DataManager] for a specific [DataEndPoint] type.
class DataManagerRegistry {
  static final DataManagerRegistry _instance = DataManagerRegistry._();
  factory DataManagerRegistry() => _instance;
  final Map<String, DataManagerFactory> _registry = {};
  DataManagerRegistry._();

  /// Register a [DataManagerFactory] which can create a [DataManager] for
  /// a specific data endpoint type.
  void register(DataManagerFactory factory) =>
      _registry[factory.type] = factory;

  /// Register all [factories].
  /// A convenient way to call [register] for multiple types.
  void registerAll(List<DataManagerFactory> factories) {
    for (var factory in factories) {
      register(factory);
    }
  }

  /// Create a new data manager based on [type].
  DataManager? create(String type) => _registry[type]?.create();
}
