/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Describes how a data type is collected (one-time or event-based).
enum DataEventType {
  /// Data is collected once.
  ONE_TIME,

  /// Data is collected continuously based on events from the sensor.
  EVENT,
}

/// Contains CAMS-specific meta data about a specific data type to be collected.
///
/// In addition to core [DataTypeMetaData], which stores the [type], [displayName],
/// and [timeType] of the data, this [CamsDataTypeMetaData] also stores
/// information on the [dataEventType].
///
/// Note that a data type does **not** declare permissions. Permissions belong
/// to the device that collects the data - see [DeviceManager.permissions] -
/// and are requested when that device is connected.
class CamsDataTypeMetaData extends DataTypeMetaData {
  /// How a data type is collected (one-time or event-based).
  DataEventType dataEventType;

  /// Create a new description of a data [type] with some [displayName].
  ///
  /// Default [timeType] is [DataTimeType.POINT] and
  /// default [dataEventType] is [DataEventType.EVENT].
  CamsDataTypeMetaData({
    required super.type,
    super.displayName,
    super.timeType,
    this.dataEventType = DataEventType.EVENT,
  });

  /// Create a new description of a data type based on the [dataTypeMetaData].
  ///
  /// Default [dataEventType] is [DataEventType.EVENT].
  CamsDataTypeMetaData.fromDataTypeMetaData({
    required DataTypeMetaData dataTypeMetaData,
    this.dataEventType = DataEventType.EVENT,
  }) : super(
         type: dataTypeMetaData.type,
         displayName: dataTypeMetaData.displayName,
         timeType: dataTypeMetaData.timeType,
       );
}

/// Contains CAMS data type definitions similar to CARP Core [CarpDataTypes].
class CamsDataTypes {
  static final CamsDataTypes _instance = CamsDataTypes._();
  factory CamsDataTypes() => _instance;

  static const String COMPLETED_APP_TASK =
      '${CarpDataTypes.CARP_NAMESPACE}.completedapptask';
  static const String FILE = '${CarpDataTypes.CARP_NAMESPACE}.file';

  CamsDataTypes._() {
    CarpDataTypes().add([
      DataTypeMetaData(
        type: COMPLETED_APP_TASK,
        displayName: "Completed AppTask",
        timeType: DataTimeType.POINT,
      ),
      DataTypeMetaData(
        type: FILE,
        displayName: "File",
        timeType: DataTimeType.POINT,
      ),
    ]);
  }
}
