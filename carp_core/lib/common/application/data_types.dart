/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../common.dart';

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
  static const String GEOLOCATION = "$CARP_NAMESPACE.geolocation";

  /// Step count data, representing the number of steps a participant has taken
  /// in a specified time interval.
  static const String STEP_COUNT = "$CARP_NAMESPACE.stepcount";

  /// Electrocardiography (ECG) data, representing electrical activity of the
  /// heart for a single lead.
  static const String ECG = "$CARP_NAMESPACE.ecg";

  /// Photoplethysmography (PPG) data, representing blood volume changes measured
  /// at the skin's surface.
  static const String PPG = "$CARP_NAMESPACE.ppg";

  /// Represents the number of heart contractions (beats) per minute.
  static const String HEART_RATE = "$CARP_NAMESPACE.heartrate";

  /// The time interval between two consecutive heartbeats.
  static const String INTERBEAT_INTERVAL = "$CARP_NAMESPACE.interbeatinterval";

  /// Determines whether a sensor requiring contact with skin is making proper
  /// contact at a specific point in time.
  static const String SENSOR_SKIN_CONTACT = "$CARP_NAMESPACE.sensorskincontact";

  /// Single-channel electrodermal activity, represented as skin conductance.
  static const String EDA = "$CARP_NAMESPACE.eda";

  /// Rate of change in velocity, including gravity, along perpendicular x, y,
  /// and z axes in the device's coordinate system.
  static const String ACCELERATION = "$CARP_NAMESPACE.acceleration";

  /// Rate of change in velocity, excluding gravity, along perpendicular x, y,
  /// and z axes in the device's coordinate system.
  static const String NON_GRAVITATIONAL_ACCELERATION =
      "$CARP_NAMESPACE.nongravitationalacceleration";

  /// Rotation of the device in x,y,z (typically measured by a gyroscope).
  static const String ROTATION = "$CARP_NAMESPACE.rotation";

  /// Magnetic field around the device in x,y,z (typically measured by a magnetometer).
  static const String MAGNETIC_FIELD = "$CARP_NAMESPACE.magneticfield";

  /// Rate of rotation around perpendicular x, y, and z axes.
  static const String ANGULAR_VELOCITY = "$CARP_NAMESPACE.angularvelocity";

  /// The received signal strength of a wireless device.
  static const String SIGNAL_STRENGTH = "$CARP_NAMESPACE.signalstrength";

  /// A task which was started or stopped by a trigger, referring to identifiers
  /// in the study protocol.
  static const String TRIGGERED_TASK = "$CARP_NAMESPACE.triggeredtask";

  /// An interactive (i.e., involving the user) task which was completed.
  static const String COMPLETED_TASK = "$CARP_NAMESPACE.completedtask";

  /// Any error that may have occurred during data collection.
  static const String ERROR = "$CARP_NAMESPACE.error";

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
      DataTypeMetaData(type: GEOLOCATION, displayName: "Location"),
      DataTypeMetaData(
        type: STEP_COUNT,
        displayName: "Step Count",
        timeType: DataTimeType.TIME_SPAN,
      ),
      DataTypeMetaData(type: ECG, displayName: "Electrocardiography (ECG)"),
      DataTypeMetaData(type: PPG, displayName: "Photoplethysmography (PPG)"),
      DataTypeMetaData(type: HEART_RATE, displayName: "Heart Rate"),
      DataTypeMetaData(
        type: INTERBEAT_INTERVAL,
        displayName: "Interbeat Interval",
        timeType: DataTimeType.TIME_SPAN,
      ),
      DataTypeMetaData(
        type: SENSOR_SKIN_CONTACT,
        displayName: "Sensor Skin Contact",
      ),
      DataTypeMetaData(
        type: NON_GRAVITATIONAL_ACCELERATION,
        displayName: "Acceleration excl. Gravity",
      ),
      DataTypeMetaData(type: EDA, displayName: "Electrodermal Activity"),
      DataTypeMetaData(
        type: ACCELERATION,
        displayName: "Acceleration incl. Gravity",
      ),
      DataTypeMetaData(type: ROTATION, displayName: "Rotation"),
      DataTypeMetaData(type: MAGNETIC_FIELD, displayName: "Magnetic Field"),
      DataTypeMetaData(type: ANGULAR_VELOCITY, displayName: "Angular Velocity"),
      DataTypeMetaData(type: SIGNAL_STRENGTH, displayName: "Signal Strength"),
      DataTypeMetaData(type: TRIGGERED_TASK, displayName: "Triggered Task"),
      DataTypeMetaData(
        type: COMPLETED_TASK,
        displayName: "Completed Task",
        timeType: DataTimeType.TIME_SPAN,
      ),
      DataTypeMetaData(type: ERROR, displayName: "Error"),
    ]);
  }
}
