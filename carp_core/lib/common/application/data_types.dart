/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../carp_core_common.dart';

/// Contains meta data about [type].
class DataTypeMetaData {
  /// Unique fully qualified name for the data type this meta data relates to.
  String type;

  /// A name which can be used to display to the user which data is collected.
  String displayName;

  /// Determines how [Data] for [type] is stored temporally (a point in time or
  /// as a time span).
  DataTimeType timeType;

  DataTypeMetaData({
    required this.type,
    this.displayName = '',
    this.timeType = DataTimeType.POINT,
  });
}

/// Describes how [Data] for a [DataType] is stored temporally.
enum DataTimeType {
  /// Data is related to one specific point in time.
  POINT,

  /// Data is related to a period of time between two specific points in time.
  TIME_SPAN,
}

/// Contains CARP data type definitions, as defined in CARP Core.
class CarpDataTypes {
  static final CarpDataTypes _instance = CarpDataTypes._();
  factory CarpDataTypes() => _instance;

  /// The [DataType] namespace of all CARP data type definitions.
  static const String CARP_NAMESPACE = "dk.cachet.carp";

  /// Geographic location data, representing latitude and longitude within the
  /// World Geodetic System 1984.
  static const String GEOLOCATION_TYPE_NAME = "$CARP_NAMESPACE.geolocation";

  /// Step count data, representing the number of steps a participant has taken
  /// in a specified time interval.
  static const String STEP_COUNT_TYPE_NAME = "$CARP_NAMESPACE.stepcount";

  /// Electrocardiography (ECG) data, representing electrical activity of the
  /// heart for a single lead.
  static const String ECG_TYPE_NAME = "$CARP_NAMESPACE.ecg";

  /// Photoplethysmography (PPG) data, representing blood volume changes measured
  /// at the skin's surface.
  static const String PPG_TYPE_NAME = "$CARP_NAMESPACE.ppg";

  /// Represents the number of heart contractions (beats) per minute.
  static const String HEART_RATE_TYPE_NAME = "$CARP_NAMESPACE.heartrate";

  /// The time interval between two consecutive heartbeats.
  static const String INTERBEAT_INTERVAL_TYPE_NAME =
      "$CARP_NAMESPACE.interbeatinterval";

  /// Determines whether a sensor requiring contact with skin is making proper
  /// contact at a specific point in time.
  static const String SENSOR_SKIN_CONTACT_TYPE_NAME =
      "$CARP_NAMESPACE.sensorskincontact";

  /// Single-channel electrodermal activity, represented as skin conductance.
  static const String EDA_TYPE_NAME = "$CARP_NAMESPACE.eda";

  /// Rate of change in velocity, including gravity, along perpendicular x, y,
  /// and z axes in the device's coordinate system.
  static const String ACCELERATION_TYPE_NAME = "$CARP_NAMESPACE.acceleration";

  /// Rate of change in velocity, excluding gravity, along perpendicular x, y,
  /// and z axes in the device's coordinate system.
  static const String NON_GRAVITATIONAL_ACCELERATION_TYPE_NAME =
      "$CARP_NAMESPACE.nongravitationalacceleration";

  /// Rotation of the device in x,y,z (typically measured by a gyroscope).
  static const String ROTATION_TYPE_NAME = "$CARP_NAMESPACE.rotation";

  /// Magnetic field around the device in x,y,z (typically measured by a magnetometer).
  static const String MAGNETIC_FIELD_TYPE_NAME =
      "$CARP_NAMESPACE.magneticfield";

  /// Rate of rotation around perpendicular x, y, and z axes.
  static const String ANGULAR_VELOCITY_TYPE_NAME =
      "$CARP_NAMESPACE.angularvelocity";

  /// The received signal strength of a wireless device.
  static const String SIGNAL_STRENGTH_TYPE_NAME =
      "$CARP_NAMESPACE.signalstrength";

  /// A task which was started or stopped by a trigger, referring to identifiers
  /// in the study protocol.
  static const String TRIGGERED_TASK_TYPE_NAME =
      "$CARP_NAMESPACE.triggeredtask";

  /// An interactive (i.e., involving the user) task which was completed.
  static const String COMPLETED_TASK_TYPE_NAME =
      "$CARP_NAMESPACE.completedtask";

  /// Any error that may have occurred during data collection.
  static const String ERROR_TYPE_NAME = "$CARP_NAMESPACE.error";

  /// A map of all CARP data types.
  Map<String, DataTypeMetaData> types = {};

  /// Add a list of data types to the list of available data types.
  void add(List<DataTypeMetaData> newTypes) {
    for (var type in newTypes) {
      types[type.type] = type;
    }
  }

  /// Get a list of all available data types.
  List<String> get all => types.keys.toList();

  CarpDataTypes._() {
    add([
      DataTypeMetaData(type: GEOLOCATION_TYPE_NAME, displayName: "Location"),
      DataTypeMetaData(
        type: STEP_COUNT_TYPE_NAME,
        displayName: "Step Count",
        timeType: DataTimeType.TIME_SPAN,
      ),
      DataTypeMetaData(
        type: ECG_TYPE_NAME,
        displayName: "Electrocardiography (ECG)",
      ),
      DataTypeMetaData(
        type: PPG_TYPE_NAME,
        displayName: "Photoplethysmography (PPG)",
      ),
      DataTypeMetaData(type: HEART_RATE_TYPE_NAME, displayName: "Heart Rate"),
      DataTypeMetaData(
        type: INTERBEAT_INTERVAL_TYPE_NAME,
        displayName: "Interbeat Interval",
        timeType: DataTimeType.TIME_SPAN,
      ),
      DataTypeMetaData(
        type: SENSOR_SKIN_CONTACT_TYPE_NAME,
        displayName: "Sensor Skin Contact",
      ),
      DataTypeMetaData(
        type: NON_GRAVITATIONAL_ACCELERATION_TYPE_NAME,
        displayName: "Acceleration excl. Gravity",
      ),
      DataTypeMetaData(
        type: EDA_TYPE_NAME,
        displayName: "Electrodermal Activity",
      ),
      DataTypeMetaData(
        type: ACCELERATION_TYPE_NAME,
        displayName: "Acceleration incl. Gravity",
      ),
      DataTypeMetaData(type: ROTATION_TYPE_NAME, displayName: "Rotation"),
      DataTypeMetaData(
        type: MAGNETIC_FIELD_TYPE_NAME,
        displayName: "Magnetic Field",
      ),
      DataTypeMetaData(
        type: ANGULAR_VELOCITY_TYPE_NAME,
        displayName: "Angular Velocity",
      ),
      DataTypeMetaData(
        type: SIGNAL_STRENGTH_TYPE_NAME,
        displayName: "Signal Strength",
      ),
      DataTypeMetaData(
        type: TRIGGERED_TASK_TYPE_NAME,
        displayName: "Triggered Task",
      ),
      DataTypeMetaData(
        type: COMPLETED_TASK_TYPE_NAME,
        displayName: "Completed Task",
        timeType: DataTimeType.TIME_SPAN,
      ),
      DataTypeMetaData(type: ERROR_TYPE_NAME, displayName: "Error"),
    ]);
  }
}
