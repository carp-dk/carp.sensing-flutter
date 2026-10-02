/*
 * Copyright 2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// A local SQLite buffer of measurements waiting to be uploaded to CAWS.
///
/// Used by [CarpDataManager]. Stores measurements with a [SQLiteDataManager]
/// and reads them back as [DataStreamBatch]es, one per expected data stream.
/// A singleton (`DataStreamBuffer()`), since it is backed by a single,
/// app-wide `carp-data.db` file.
///
/// Call [initialize], then [getDataStreamBatches] to read pending data, and
/// [cleanup] once it is uploaded.
class DataStreamBuffer {
  SmartphoneDeployment? _deployment;
  final _manager = SQLiteDataManager();

  /// Database row IDs of the measurements returned by the last
  /// [getDataStreamBatch] calls. Cleared by [cleanup].
  Set<int> rows = {};

  /// The deployment whose data is buffered. `null` before [initialize]
  /// and after [detach].
  SmartphoneDeployment? get deployment => _deployment;

  /// The underlying SQLite database, or `null` if not open.
  Database? get database => _manager.database;

  static final DataStreamBuffer _instance = DataStreamBuffer._();
  DataStreamBuffer._();

  /// The singleton [DataStreamBuffer].
  factory DataStreamBuffer() => _instance;

  /// Starts buffering [measurements] from [deployment].
  Future<void> initialize(
    SmartphoneDeployment deployment,
    Stream<Measurement> measurements,
  ) async {
    info('Initializing $runtimeType...');
    _deployment = deployment;
    await _manager.configure(
      dataEndPoint: SQLiteDataEndPoint(),
      deployment: deployment,
      measurements: measurements,
    );
  }

  /// All buffered data not yet uploaded, one [DataStreamBatch] per data stream.
  ///
  /// Returns an empty list if there is no data or no [deployment].
  Future<List<DataStreamBatch>> getDataStreamBatches() async {
    List<DataStreamBatch> batches = [];

    if (deployment != null) {
      for (var stream in deployment!.expectedDataStreams) {
        var batch = await getDataStreamBatch(stream);
        if (batch != null) batches.add(batch);
      }
    }
    return batches;
  }

  /// All data not yet uploaded for [stream], as one [DataStreamBatch].
  ///
  /// Adds the returned rows to [rows] so [cleanup] can mark them as uploaded.
  /// Requires [initialize] first. Returns `null` if there is no data.
  Future<DataStreamBatch?> getDataStreamBatch(ExpectedDataStream stream) async {
    DataStreamId dataStream = DataStreamId(
      studyDeploymentId: deployment!.studyDeploymentId,
      deviceRoleName: stream.deviceRoleName,
      dataType: stream.dataType,
    );

    int firstSequenceId = 0;
    List<Measurement> measurements = [];
    Set<int> triggerIds = {};

    debug(
      "$runtimeType - getting data stream batch for device "
      "'${stream.deviceRoleName}' and data type '${stream.dataType}'.",
    );

    // get all measurement not uploaded yet for this stream
    const where =
        '${SQLiteDataManager.UPLOADED_COLUMN} = ? AND '
        '${SQLiteDataManager.DEPLOYMENT_ID_COLUMN} = ? AND '
        '${SQLiteDataManager.DEVICE_ROLE_NAME_COLUMN} = ? AND '
        '${SQLiteDataManager.DATATYPE_COLUMN} = ?';
    final List<Map<String, dynamic>> maps =
        await database?.query(
          SQLiteDataManager.MEASUREMENT_TABLE_NAME,
          where: where,
          whereArgs: [
            0,
            dataStream.studyDeploymentId,
            dataStream.deviceRoleName,
            dataStream.dataType,
          ],
        ) ??
        [];

    // fast out if there is no data
    if (maps.isEmpty) return null;

    for (var element in maps) {
      int row =
          int.tryParse(element[SQLiteDataManager.ID_COLUMN].toString()) ?? 0;
      // save the row id of what is uploaded
      rows.add(row);
      int? triggerId = int.tryParse(
        element[SQLiteDataManager.TRIGGER_ID_COLUMN].toString(),
      );
      if (triggerId != null) triggerIds.add(triggerId);

      final jsonString =
          element[SQLiteDataManager.MEASUREMENT_COLUMN] as String;
      final measurement = Measurement.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
      measurements.add(measurement);
    }
    firstSequenceId = rows.reduce(min);

    return DataStreamBatch(
      dataStream: dataStream,
      firstSequenceId: firstSequenceId,
      measurements: measurements,
      triggerIds: triggerIds,
    );
  }

  /// Removes the measurements in [rows] from the buffer, then clears [rows].
  ///
  /// If [delete] is `true`, they are deleted. Otherwise they are kept but
  /// marked as uploaded. Call it after a successful upload.
  Future<void> cleanup([bool delete = true]) async {
    final args = rows.join(',');
    int? count = 0;
    if (delete) {
      var sql =
          'DELETE FROM ${SQLiteDataManager.MEASUREMENT_TABLE_NAME} WHERE '
          '${SQLiteDataManager.ID_COLUMN} IN ($args)';
      count = await database?.rawDelete(sql);
    } else {
      var sql =
          'UPDATE ${SQLiteDataManager.MEASUREMENT_TABLE_NAME} SET '
          '${SQLiteDataManager.UPLOADED_COLUMN} = 1 WHERE ${SQLiteDataManager.ID_COLUMN} IN ($args)';
      count = await database?.rawUpdate(sql);
    }
    rows = {};
    debug(
      '$runtimeType - cleaned up. '
      'N=$count records ${delete ? 'deleted' : 'marked as uploaded'}.',
    );
  }

  /// Stop buffering measurements, but keep the database and its data intact.
  ///
  /// Used when a [CarpDataManager] is replaced on a deployment update: the
  /// database is shared app-wide, so it must outlive any single manager.
  Future<void> detach() async {
    await _manager.close();
    _deployment = null;
  }

  /// Closes the database. No more data can be added.
  Future<void> close() async => await database?.close();
}
