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

/// CAMS metadata about a data type: how it is collected and which permissions
/// it needs.
///
/// Extends the carp_core [DataTypeMetaData] ([type], [displayName], and
/// [timeType]) with the [dataEventType] and the runtime [permissions].
/// Sampling packages use it in their [DataTypeSamplingScheme]s, and CAMS asks
/// for the [permissions] before a [Probe] starts.
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
  ///
  /// Declare the Android group; on iOS the Android-only groups are returned as
  /// their iOS counterpart ([Permission.activityRecognition] ->
  /// [Permission.sensors], [Permission.bluetoothScan] -> [Permission.bluetooth]).
  List<Permission> get permissions => Platform.isIOS ? _permissions.map(_onIOS).toList() : _permissions;
  set permissions(List<Permission> permissions) => _permissions = permissions;
  List<Permission> _permissions;

  /// Creates a new description of a data [type] with some [displayName].
  ///
  /// Default [timeType] is [DataTimeType.POINT],
  /// default [dataEventType] is [DataEventType.EVENT], and
  /// default [permissions] is empty (no permissions required).
  CamsDataTypeMetaData({
    required super.type,
    super.displayName,
    super.timeType,
    this.dataEventType = DataEventType.EVENT,
    List<Permission> permissions = const [],
  }) : _permissions = permissions;

  /// Creates a new description of a data type based on `dataTypeMetaData`.
  ///
  /// Default [dataEventType] is [DataEventType.EVENT], and
  /// default [permissions] is empty (no permissions required).
  CamsDataTypeMetaData.fromDataTypeMetaData({
    required DataTypeMetaData dataTypeMetaData,
    this.dataEventType = DataEventType.EVENT,
    List<Permission> permissions = const [],
  }) : _permissions = permissions,
       super(
         type: dataTypeMetaData.type,
         displayName: dataTypeMetaData.displayName,
         timeType: dataTypeMetaData.timeType,
       );
}

/// Maps an Android-only [permission] to its iOS counterpart.
///
/// permission_handler has no iOS strategy for these Android-only groups - they
/// come back permanentlyDenied without a dialog - so ask for the iOS one.
Permission _onIOS(Permission permission) => switch (permission) {
  Permission.activityRecognition => Permission.sensors,
  Permission.bluetoothScan => Permission.bluetooth,
  _ => permission,
};

/// The data types that CAMS adds to carp_core [CarpDataTypes].
///
/// Creating the singleton registers [COMPLETED_APP_TASK] and [FILE] in
/// [CarpDataTypes]. [CarpMobileSensing] does this on initialization.
class CamsDataTypes {
  static final CamsDataTypes _instance = CamsDataTypes._();
  factory CamsDataTypes() => _instance;

  /// The data type of [CompletedAppTask].
  static const String COMPLETED_APP_TASK = '${CarpDataTypes.CARP_NAMESPACE}.completedapptask';

  /// The data type of [FileData].
  static const String FILE = '${CarpDataTypes.CARP_NAMESPACE}.file';

  CamsDataTypes._() {
    CarpDataTypes().add([
      DataTypeMetaData(type: COMPLETED_APP_TASK, displayName: "Completed AppTask", timeType: DataTimeType.POINT),
      DataTypeMetaData(type: FILE, displayName: "File", timeType: DataTimeType.POINT),
    ]);
  }
}
