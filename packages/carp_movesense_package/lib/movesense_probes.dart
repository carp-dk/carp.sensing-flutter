/*
 * Copyright 2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movesense_package.dart';

abstract class _MovesenseStreamProbe extends StreamProbe {
  int? _subscriptionId;

  final StreamController<String> _streamController =
      StreamController.broadcast();

  @override
  MovesenseDeviceManager get deviceManager =>
      super.deviceManager as MovesenseDeviceManager;

  String? get _serial => deviceManager.serial;

  final String _uri;
  final Function _converter;

  _MovesenseStreamProbe(this._uri, this._converter);

  @override
  Stream<Measurement>? get stream => deviceManager.isConnected
      ? _streamController.stream
            .map(
              (event) => Measurement.fromData(
                _converter.call(jsonDecode(event)) as Data,
              ),
            )
            .skip(10) // skip first 10 measurements to allow sensor to stabilize
      : null;

  @override
  Future<bool> onResume() async {
    var completer = Completer<bool>();

    // fast out if not connected to device
    if (_serial == null) return false;

    // fast out of already subscribed to this type of measurement
    if (_subscriptionId != null) return false;

    try {
      _subscriptionId = Mds.subscribe(
        "$_serial/$_uri",
        "{}",
        // onSuccess
        (data, status) {
          debug('$runtimeType - OnSuccess, data: $data, status: $status');
          completer.complete(super.onResume());
        },
        // onError
        (error, status) {
          var errorMsg = '$runtimeType - Error, error: $error, status: $status';
          warning(errorMsg);
          _streamController.addError(errorMsg);
          _subscriptionId = null;
          completer.complete(false);
        },
        // onNotification
        (data) {
          _streamController.add(data);
        },
        // onSubscriptionError
        (error, status) {
          var errorMsg =
              '$runtimeType - Subscription Error, error: $error, status: $status';
          warning(errorMsg);
          _streamController.addError(errorMsg);
          _subscriptionId = null;
          completer.complete(false);
        },
      );
    } catch (error) {
      var errorMsg =
          '$runtimeType - Error when trying to subscribe to device - serial: $_serial, uri: $_uri, error: $error';
      warning(errorMsg);
      _streamController.addError(errorMsg);
      _subscriptionId = null;
      completer.complete(false);
    }

    return completer.future;
  }

  @override
  Future<bool> onPause() async {
    super.onPause();

    if (_subscriptionId != null) Mds.unsubscribe(_subscriptionId!);
    _subscriptionId = null;

    return true;
  }
}

/// A probe collecting [MovesenseHR] events.
class MovesenseHRProbe extends _MovesenseStreamProbe {
  MovesenseHRProbe() : super("Meas/HR", MovesenseHR.fromMovesenseData);
}

/// A probe collecting [MovesenseECG] events at 125 Hz.
class MovesenseECGProbe extends _MovesenseStreamProbe {
  MovesenseECGProbe() : super("Meas/ECG/125", MovesenseECG.fromMovesenseData);
}

/// A probe collecting [MovesenseTemperature] events.
///
/// Note that not all type of Movesense devices supports temperature.
class MovesenseTemperatureProbe extends _MovesenseStreamProbe {
  MovesenseTemperatureProbe()
    : super("Meas/Temp", MovesenseTemperature.fromMovesenseData);
}

/// A probe collecting [MovesenseIMU] events at 13 Hz (lowest).
class MovesenseIMUProbe extends _MovesenseStreamProbe {
  MovesenseIMUProbe() : super("Meas/IMU9/13", MovesenseIMU.fromMovesenseData);
}

/// A probe collecting [MovesenseStateChange] events.
/// See [MovesenseDeviceState] for an enumeration of possible states.
///
/// However, due to hardware limitation in Movesense we can only subscribe to
/// maximum one (!) state changes
/// See https://github.com/petri-lipponen-movesense/mdsflutter/issues/15
///
/// Seems like the only states we can listen to is the connectors and single tap
/// events. This has been tested on the MD and HR2 devices.
///
/// Therefore, this probe **only** listens to single tap events.
class MovesenseStateChangeProbe extends _MovesenseStreamProbe {
  MovesenseStateChangeProbe()
    : super("System/States/4", MovesenseStateChange.fromMovesenseData);
}

/// A probe collecting [MovesenseDeviceInformation] from the connected
/// Movesense device.
class MovesenseDeviceProbe extends MeasurementProbe {
  @override
  Future<Measurement?> getMeasurement() async {
    var completer = Completer<Measurement>();
    var serial = (deviceManager as MovesenseDeviceManager).serial;

    // fast out if not connected
    if (!deviceManager.isConnected) return null;

    // fast out if no serial number (typically not connected)
    if (serial == null) return null;

    Mds.get(
      Mds.createRequestUri(serial, "/Info"),
      "{}",
      ((info, statusCode) {
        var data = MovesenseDeviceInformation.fromMovesenseData(
          json.decode(info),
        );
        completer.complete(Measurement.fromData(data));
      }),
      (error, statusCode) {
        completer.completeError('$runtimeType - error: $error');
      },
    );

    return completer.future;
  }
}

// MULTI STATE CHANGE PROBE BELOW - with notes

/// Enumeration of the type of state changes available on the Movesense device.
/// See https://www.movesense.com/docs/esw/api_reference/#systemstates
enum MovesenseState { movement, battery, connectors, doubleTap, tap, freeFall }

// State Change overview. The following table shows the state change types
// available on the different devices. This is based on testing of physical
// device. Can't find any documentation on this in the Movesense documentation
//
//   type      | MD | HR+ | HR2
//  -----------+----+-----+-----
//  movement   | -  |  ?  |  -
//  connectors | +  |  ?  |  +
//  doubleTap  | -  |  ?  |  -
//  tap        | +  |  ?  |  +
//  freeFall   | -  |  ?  |  -

/// A probe collecting all possible [MovesenseStateChange] events.
/// See [MovesenseDeviceState] for an enumeration of possible states.
///
/// In contrast to the [MovesenseStateChangeProbe], this probe tries to
/// collect all the different types of state changes. However, due to hardware
/// limitation on the device, this often will not succeed.
///
/// Therefore, this probe is not used at the moment.
class MovesenseMultiStateChangeProbe extends StreamProbe {
  /// A map from state id to subscription id.
  final Map<int, int> _subscriptionIDs = {};
  final StreamController<String> _subscriptionController =
      StreamController.broadcast();

  @override
  MovesenseDeviceManager get deviceManager =>
      super.deviceManager as MovesenseDeviceManager;

  @override
  Future<bool> onResume() async {
    _addStateSubscription(MovesenseState.movement);
    _addStateSubscription(MovesenseState.connectors);
    _addStateSubscription(MovesenseState.doubleTap);
    _addStateSubscription(MovesenseState.tap);
    _addStateSubscription(MovesenseState.freeFall);

    return super.onResume();
  }

  @override
  Stream<Measurement>? get stream => deviceManager.isConnected
      ? _subscriptionController.stream.map(
          (event) => Measurement.fromData(
            MovesenseStateChange.fromMovesenseData(jsonDecode(event)),
          ),
        )
      : null;

  void _addStateSubscription(MovesenseState state) {
    int stateId = state.index;

    // fast out of already subscribed to this type of state change.
    if (_subscriptionIDs.containsKey(stateId)) return;

    try {
      final int id = Mds.subscribe(
        "${deviceManager.serial}/System/States/$stateId",
        "{}",
        (data, status) {
          debug(
            '$runtimeType - OnSuccess, stateId: $stateId, data: $data, status: $status',
          );
        },
        (error, status) {
          warning(
            '$runtimeType - OnError, stateId: $stateId, error: $error, status: $status',
          );
          _subscriptionController.addError(error);
        },
        (data) {
          debug(
            '$runtimeType - OnNotification, stateId: $stateId, data: $data',
          );
          _subscriptionController.add(data);
        },
        (error, status) {
          warning(
            '$runtimeType - OnSubscriptionError, stateId: $stateId, error: $error, status: $status',
          );
          _subscriptionController.addError(error);
        },
      );

      _subscriptionIDs[stateId] = id;
    } catch (error) {
      warning('$runtimeType - Error, stateId: $stateId, error: $error');
      _subscriptionController.addError(error);
    }
  }

  @override
  Future<bool> onPause() async {
    super.onPause();

    // unsubscribed to all state subscriptions
    for (var id in _subscriptionIDs.values) {
      Mds.unsubscribe(id);
    }
    _subscriptionIDs.clear();

    return true;
  }
}
