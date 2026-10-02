/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// A [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing)
/// sampling package that collects data from [Movisens](https://www.movisens.com/en/)
/// sensors over Bluetooth Low Energy (BLE).
///
/// Register [MovisensSamplingPackage] in the [SamplingPackageRegistry], add a
/// [MovisensDevice] as a connected device to the protocol, and add measures
/// of the types below to a task that runs on that device.
///
/// Measure types (namespace `dk.cachet.carp.movisens`):
///  * `dk.cachet.carp.movisens.activity` : steps, body position, inclination, movement acceleration and MET.
///  * `dk.cachet.carp.movisens.hr` : heart rate (HR) and heart rate variability (HRV).
///  * `dk.cachet.carp.movisens.eda` : electrodermal activity (EDA).
///  * `dk.cachet.carp.movisens.skin_temperature` : skin temperature.
///  * `dk.cachet.carp.movisens.respiration` : respiratory movement.
///  * `dk.cachet.carp.movisens.tap_marker` : taps by the user on the sensor.
///
/// Platforms: Android and iOS.
///
/// Devices:
///
///  * [Move4](https://www.movisens.com/en/products/activity-sensor/) Activity Sensor.
///  * [EcgMove4](https://www.movisens.com/en/products/ecg-sensor/) ECG and Activity Sensor.
///  * [EdaMove4](https://www.movisens.com/en/products/eda-and-activity-sensor/) EDA and Activity Sensor
///  * [LightMove4](https://www.movisens.com/en/products/light-and-activity-sensor/) Light and Activity Sensor.
///
/// Not all measures are supported by all devices. For example, you need an
/// EdaMove4 to measure EDA and an EcgMove4 to measure HR.
///
/// This package uses the [movisens_flutter](https://pub.dev/packages/movisens_flutter) Flutter plugin,
/// which again builds upon the [official Movisens BLE Protocol](https://docs.movisens.com/BluetoothLowEnergy/#introduction).
/// Please consult the Movisens [technical documentation](https://docs.movisens.com/BluetoothLowEnergy/#communication-with-the-sensor)
/// on the details on how to interpret the collected data.
library;

import 'dart:convert';
import 'dart:async';
import 'package:async/async.dart';
import 'package:movisens_flutter/movisens_flutter.dart' as movisens;
import 'package:json_annotation/json_annotation.dart';
import 'package:openmhealth_schemas/openmhealth_schemas.dart' as omh;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'movisens_data.dart';
part 'movisens_probes.dart';
part "carp_movisens_package.g.dart";
part 'movisens_transformers.dart';
part 'movisens_device_manager.dart';

/// The sampling package for Movisens devices.
///
/// It tells CARP Mobile Sensing which measure types a Movisens device
/// provides, which [MovisensProbe] collects each of them, and which
/// [MovisensDeviceManager] handles the connection to the device. Register it
/// once, before a study is deployed.
///
/// Key points:
///  * All measures run on a [MovisensDevice] connected device, not on the phone.
///  * All measures are event-based and need no sampling configuration.
///  * Not all measures are supported by all Movisens devices. For example, you
///    need an EdaMove4 to measure EDA and an EcgMove4 to measure HR.
///  * [onRegister] registers the device and data types for JSON
///    deserialization. It also adds heart rate and step count transformers to
///    the OMH schema, and a heart rate transformer to the FHIR schema, if
///    these schemas are already registered.
///
/// ```dart
/// SamplingPackageRegistry().register(MovisensSamplingPackage());
/// var movisens = MovisensDevice(sex: Sex.Female, height: 165, weight: 60);
/// protocol.addConnectedDevice(movisens, phone);
/// protocol.addTaskControl(
///   ImmediateTrigger(),
///   BackgroundTask(measures: [Measure(type: MovisensSamplingPackage.ACTIVITY)]),
///   movisens,
/// );
/// ```
///
/// See also [SamplingPackage], which this implements.
class MovisensSamplingPackage implements SamplingPackage {
  /// The namespace of all Movisens measure types.
  static const String MOVISENS_NAMESPACE = "${NameSpace.CARP}.movisens";

  /// Measure type for physical activity. Collected by [MovisensActivityProbe].
  static const String ACTIVITY = "$MOVISENS_NAMESPACE.activity";

  /// Measure type for heart rate and HRV. Collected by [MovisensHRProbe].
  /// Needs an EcgMove4.
  static const String HR = "$MOVISENS_NAMESPACE.hr";

  /// Measure type for electrodermal activity ([MovisensEDA]). Needs an EdaMove4.
  static const String EDA = "$MOVISENS_NAMESPACE.eda";

  /// Measure type for respiratory movement ([MovisensRespiration]).
  static const String RESPIRATION = "$MOVISENS_NAMESPACE.respiration";

  /// Measure type for skin temperature ([MovisensSkinTemperature]).
  static const String SKIN_TEMPERATURE = "$MOVISENS_NAMESPACE.skin_temperature";

  /// Measure type for user taps on the sensor ([MovisensTapMarker]).
  static const String TAP_MARKER = "$MOVISENS_NAMESPACE.tap_marker";

  final DeviceManager _deviceManager = MovisensDeviceManager(
    MovisensDevice.DEVICE_TYPE,
  );

  @override
  void onRegister() {
    FromJsonFactory().register(MovisensDevice());

    // Backwards compatibility with CAMS 1.x (protocol API level < 2.0) where
    // the Movisens device used the carp_core device namespace.
    FromJsonFactory().register(
      MovisensDevice(),
      type: '${DeviceConfiguration.DEVICE_NAMESPACE}.MovisensDevice',
    );

    // register all data types
    FromJsonFactory().registerAll([
      MovisensStepCount(deviceId: '', type: '', steps: 0),
      MovisensBodyPosition(deviceId: '', type: '', bodyPosition: 'Chest'),
      MovisensInclination(deviceId: '', type: '', x: 0, y: 0, z: 0),
      MovisensMovementAcceleration(
        deviceId: '',
        type: '',
        movementAcceleration: 0,
      ),
      MovisensMET(deviceId: '', type: '', met: 0),
      MovisensMETLevel(
        deviceId: '',
        type: '',
        sedentary: 0,
        light: 0,
        moderate: 0,
        vigorous: 0,
      ),
      MovisensHR(deviceId: '', type: '', hr: 0),
      MovisensEDA(deviceId: '', type: '', edaSclMean: 0),
      MovisensSkinTemperature(deviceId: '', type: '', skinTemperature: 0),
      MovisensRespiration(deviceId: '', type: '', value: 0),
      MovisensTapMarker(deviceId: '', type: '', tapMarker: 1),
    ]);

    // registering the transformers from CARP to OMH and FHIR for heart rate and step count.
    // we assume that there are OMH and FHIR schemas created and registered already...
    DataTransformerSchemaRegistry()
        .lookup(NameSpace.OMH)
        ?.add(MovisensData.HR_MEAN, OMHHeartRateDataPoint.transformer);
    DataTransformerSchemaRegistry()
        .lookup(NameSpace.OMH)
        ?.add(MovisensData.STEPS, OMHStepCountDataPoint.transformer);
    DataTransformerSchemaRegistry()
        .lookup(NameSpace.FHIR)
        ?.add(MovisensData.HR_MEAN, FHIRHeartRateObservation.transformer);
  }

  @override
  String get deviceType => MovisensDevice.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;

  /// Creates the [MovisensProbe] for the measure [type], or null if [type] is
  /// not a Movisens measure type.
  @override
  Probe? create(String type) {
    switch (type) {
      case ACTIVITY:
        return MovisensActivityProbe();
      case HR:
        return MovisensHRProbe();
      case EDA:
        return MovisensEDAProbe();
      case SKIN_TEMPERATURE:
        return MovisensSkinTemperatureProbe();
      case RESPIRATION:
        return RespirationProbe();
      case TAP_MARKER:
        return MovisensTapMarkerProbe();
      default:
        return null;
    }
  }

  @override
  List<DataTypeMetaData> get dataTypes => samplingSchemes.dataTypes;

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ACTIVITY,
            displayName: "Physical Activity",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: HR,
            displayName: "Heart Rate (HR) data",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: EDA,
            displayName: "Elecrodermal Activity (EDA)",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: SKIN_TEMPERATURE,
            displayName: "Skin Temperature",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: RESPIRATION,
            displayName: "Respiration",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: TAP_MARKER,
            displayName: "Tap markers by the user.",
            timeType: DataTimeType.POINT,
          ),
        ),
      ]);
}

/// The location on the body where the Movisens device is placed.
///
/// Set in [MovisensDevice.sensorLocation] and sent to the device on connect,
/// since the device's algorithms depend on it.
enum SensorLocation {
  RightSideHip,
  Chest,
  RightWrist,
  LeftWrist,
  LeftAnkle,
  RightAnkle,
  RightThigh,
  LeftThigh,
  RightUpperArm,
  LeftUpperArm,
  LeftSideHip,
}
