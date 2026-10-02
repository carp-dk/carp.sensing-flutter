/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movisens_package.dart';

/// Base class for probes that collect [MovisensData] from a Movisens device.
///
/// Each subclass maps the events of a Movisens BLE service to [MovisensData]
/// in [data]. The device is reached through [MovisensDeviceManager.device].
abstract class MovisensProbe extends StreamProbe {
  @override
  MovisensDeviceManager get deviceManager =>
      super.deviceManager as MovisensDeviceManager;

  @override
  Stream<Measurement>? get stream => data?.map(
    (event) =>
        Measurement.fromData(event, event.timestamp.microsecondsSinceEpoch),
  );

  /// The stream of data from the Movisens device. May be null if the device
  /// or the service is not available.
  Stream<MovisensData>? get data;
}

/// A probe collecting physical activity data.
///
/// Used for the [MovisensSamplingPackage.ACTIVITY] measure. Collects:
///  * [MovisensStepCount]
///  * [MovisensBodyPosition]
///  * [MovisensInclination]
///  * [MovisensMovementAcceleration]
///  * [MovisensMET]
///  * [MovisensMETLevel]
class MovisensActivityProbe extends MovisensProbe {
  final StreamGroup<MovisensData> _group = StreamGroup.broadcast();

  @override
  Stream<MovisensData>? get data => _group.stream;

  @override
  bool onInitialize() {
    // fast out if physical activity service does not exist
    if (deviceManager.device?.physicalActivityService == null) return false;

    _group.add(
      deviceManager.device?.physicalActivityService?.stepsEvents?.map(
            (event) => MovisensStepCount.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );
    _group.add(
      deviceManager.device?.physicalActivityService?.bodyPositionEvents?.map(
            (event) => MovisensBodyPosition.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );
    _group.add(
      deviceManager.device?.physicalActivityService?.inclinationEvents?.map(
            (event) => MovisensInclination.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );
    _group.add(
      deviceManager.device?.physicalActivityService?.movementAccelerationEvents
              ?.map(
                (event) =>
                    MovisensMovementAcceleration.fromMovisensEvent(event),
              ) ??
          Stream.empty(),
    );
    _group.add(
      deviceManager.device?.physicalActivityService?.metEvents?.map(
            (event) => MovisensMET.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );
    _group.add(
      deviceManager.device?.physicalActivityService?.metLevelEvents?.map(
            (event) => MovisensMETLevel.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );

    return true;
  }

  @override
  Future<bool> onResume() async {
    await deviceManager.device?.physicalActivityService?.enableNotify();
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    await deviceManager.device?.physicalActivityService?.enableNotify();
    return await super.onPause();
  }
}

/// A probe collecting heart rate (HR) data.
///
/// Used for the [MovisensSamplingPackage.HR] measure. Collects:
///  * [MovisensHR]
///  * [MovisensHRV]
///  * [MovisensIsHrvValid]
class MovisensHRProbe extends MovisensProbe {
  final StreamGroup<MovisensData> _group = StreamGroup.broadcast();

  @override
  Stream<MovisensData>? get data => _group.stream;

  @override
  bool onInitialize() {
    // fast out if HRV service does not exist
    if (deviceManager.device?.hrvService == null) return false;

    _group.add(
      deviceManager.device?.hrvService?.hrMeanEvents?.map(
            (event) => MovisensHR.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );
    _group.add(
      deviceManager.device?.hrvService?.rmssd?.map(
            (event) => MovisensHRV.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );
    _group.add(
      deviceManager.device?.hrvService?.hrvIsValidEvents?.map(
            (event) => MovisensIsHrvValid.fromMovisensEvent(event),
          ) ??
          Stream.empty(),
    );

    return true;
  }

  @override
  Future<bool> onResume() async {
    await deviceManager.device?.hrvService?.enableNotify();
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    await deviceManager.device?.hrvService?.enableNotify();
    return await super.onPause();
  }
}

/// A probe collecting electrodermal activity (EDA) data ([MovisensEDA]) for
/// the [MovisensSamplingPackage.EDA] measure.
class MovisensEDAProbe extends MovisensProbe {
  @override
  Stream<MovisensData>? get data => deviceManager
      .device
      ?.edaService
      ?.edaSclMeanEvents
      ?.map((event) => MovisensEDA.fromMovisensEvent(event));

  @override
  Future<bool> onResume() async {
    await deviceManager.device?.edaService?.enableNotify();
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    await deviceManager.device?.edaService?.enableNotify();
    return await super.onPause();
  }
}

/// A probe collecting skin temperature data ([MovisensSkinTemperature]) for
/// the [MovisensSamplingPackage.SKIN_TEMPERATURE] measure.
class MovisensSkinTemperatureProbe extends MovisensProbe {
  @override
  Stream<MovisensData>? get data => deviceManager
      .device
      ?.skinTemperatureService
      ?.skinTemperatureEvents
      ?.map((event) => MovisensSkinTemperature.fromMovisensEvent(event));

  @override
  Future<bool> onResume() async {
    await deviceManager.device?.skinTemperatureService?.enableNotify();
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    await deviceManager.device?.skinTemperatureService?.enableNotify();
    return await super.onPause();
  }
}

/// A probe collecting respiratory movement data ([MovisensRespiration]) for
/// the [MovisensSamplingPackage.RESPIRATION] measure.
///
/// Note that it currently enables notifications on the skin temperature
/// service, not the respiration service, when resumed.
class RespirationProbe extends MovisensProbe {
  @override
  Stream<MovisensData>? get data => deviceManager
      .device
      ?.respirationService
      ?.respiratoryMovementEvents
      ?.map((event) => MovisensRespiration.fromMovisensEvent(event));

  @override
  Future<bool> onResume() async {
    await deviceManager.device?.skinTemperatureService?.enableNotify();
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    await deviceManager.device?.skinTemperatureService?.enableNotify();
    return await super.onPause();
  }
}

/// A probe collecting tap marker events ([MovisensTapMarker]) for the
/// [MovisensSamplingPackage.TAP_MARKER] measure.
class MovisensTapMarkerProbe extends MovisensProbe {
  @override
  Stream<MovisensData>? get data => deviceManager
      .device
      ?.markerService
      ?.tapMarkerEvents
      ?.map((event) => MovisensTapMarker.fromMovisensEvent(event));

  @override
  Future<bool> onResume() async {
    await deviceManager.device?.markerService?.enableNotify();
    return await super.onResume();
  }

  @override
  Future<bool> onPause() async {
    await deviceManager.device?.markerService?.enableNotify();
    return await super.onPause();
  }
}
