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
/// information on [dataEventType] and what [permissions] are needed on
/// runtime to collect this data type.
class CamsDataTypeMetaData extends DataTypeMetaData {
  /// How a data type is collected (one-time or event-based).
  DataEventType dataEventType;

  /// The list of permissions that are required for this data type.
  ///
  /// Note that this is the list of permissions needed for the probe collecting
  /// this data type. It **should not** include permission to access a device
  /// itself, such as Bluetooth permissions.
  /// Such permissions should be handled on the app level.
  ///
  /// See [PermissionGroup](https://pub.dev/documentation/permission_handler/latest/permission_handler/PermissionGroup-class.html)
  /// for a list of possible permissions.
  ///
  /// For Android permission in the Manifest.xml file,
  /// see [Manifest.permission](https://developer.android.com/reference/android/Manifest.permission.html)
  List<Permission> permissions;

  /// Create a new description of a data [type] with some [displayName].
  ///
  /// Default [timeType] is [DataTimeType.POINT],
  /// default [dataEventType] is [DataEventType.EVENT], and
  /// default [permissions] is empty (no permissions required).
  CamsDataTypeMetaData({
    required super.type,
    super.displayName,
    super.timeType,
    this.dataEventType = DataEventType.EVENT,
    this.permissions = const [],
  });

  /// Create a new description of a data type based on the [dataTypeMetaData].
  ///
  /// Default [dataEventType] is [DataEventType.EVENT], and
  /// default [permissions] is empty (no permissions required).
  CamsDataTypeMetaData.fromDataTypeMetaData({
    required DataTypeMetaData dataTypeMetaData,
    this.dataEventType = DataEventType.EVENT,
    this.permissions = const [],
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
