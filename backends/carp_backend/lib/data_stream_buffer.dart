/*
 * Copyright 2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// A local buffer of data streams using the [SQLiteDataManager].
/// Works as a singleton accessed by `DataStreamBuffer()`.
class DataStreamBuffer {
  SmartphoneDeployment? _deployment;
  final _manager = SQLiteDataManager();

  Set<int> rows = {};

  SmartphoneDeployment? get deployment => _deployment;
  Database? get database => _manager.database;

  static final DataStreamBuffer _instance = DataStreamBuffer._();
  DataStreamBuffer._();

  /// Get the singleton [DataStreamBuffer].
  factory DataStreamBuffer() => _instance;

  /// Initialize this buffer by specifying which [deployment] it handles
  /// and the stream of [measurements] to buffer.
  Future<void> initialize(
    SmartphoneDeployment deployment,
    Stream<Measurement> measurements,
  ) async {
    info('Initializing $runtimeType...');
    _deployment = deployment;
    _manager.configure(
      dataEndPoint: SQLiteDataEndPoint(),
      deployment: deployment,
      measurements: measurements,
    );
  }

  /// Get the list of [DataStreamBatch] which has not yet been uploaded.
  /// Returns an empty list if no data needs to be uploaded.
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

  /// Get a [DataStreamBatch] of all data which has not been uploaded yet
  /// for the [stream].
  ///
  /// Returns null if no data is found.
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

  /// Clean up the database.
  ///
  /// If [delete] is true, all measurements which has been successfully uploaded
  /// is deleted. Otherwise they are kept, but marked as uploaded.
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

  /// Close this buffer. No more data can be added.
  Future<void> close() async => await database?.close();
}
