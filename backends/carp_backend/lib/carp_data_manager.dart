/*
 * Copyright 2018-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

class CarpDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.CAWS;

  @override
  DataManager create() => CarpDataManager();

  CarpDataManagerFactory() : super() {
    CarpDataManager();
  }
}

/// Upload CAMS measurement to the CARP Web Services (CAWS) backend.
///
/// Upload of data to CAWS can happen in three ways, as specified in
/// [CarpUploadMethod]:
///
///   * [CarpUploadMethod.stream] - Upload data as data streams (the default method).
///   * [CarpUploadMethod.datapoint] - Upload each data point separately using
///       the old DataPoint batch endpoint in CAWS.
///   * [CarpUploadMethod.file] - Collect measurements in a SQLite DB file and
///       upload as a `db` file
///
/// Data is buffered locally in a [DataStreamBuffer] and uploaded to CAWS
/// on a regular basis, as specified in the [CarpDataEndPoint.uploadInterval].
/// However, if debug mode is set to "debug", data is uploaded every minute.
///
/// If the [CarpDataEndPoint.onlyUploadOnWiFi] is set to `true`, data is only
/// uploaded when the device is connected to a WiFi network.
/// The [CarpDataManager] listens to connectivity changes and only uploads data
/// when the device is connected to the internet.
class CarpDataManager extends AbstractDataManager {
  late CarpDataEndPoint carpEndPoint;
  DataStreamBuffer buffer = DataStreamBuffer();
  Timer? uploadTimer;
  List<ConnectivityResult> _connectivity = [];

  /// Make sure to create and initialize the [CarpDataManager].
  static void ensureInitialized() =>
      FromJsonFactory().register(CarpDataEndPoint());

  CarpDataManager() : super() {
    CarpMobileSensing.ensureInitialized();
    FromJsonFactory().register(CarpDataEndPoint());
  }

  @override
  String get type => DataEndPointTypes.CAWS;

  /// Should data be compressed / zipped before upload?
  bool get compress => carpEndPoint.compress;
  set compress(bool compress) => carpEndPoint.compress = compress;

  /// The connectivity status of this data manager.
  List<ConnectivityResult> get connectivity => _connectivity;
  set connectivity(List<ConnectivityResult> status) {
    _connectivity = status;
    info("$runtimeType - Network connectivity status set to '$status'");
  }

  @override
  Future<void> configure({
    required DataEndPoint dataEndPoint,
    required SmartphoneDeployment deployment,
    required Stream<Measurement> measurements,
  }) async {
    info("$runtimeType - Initializing, endpoint: $dataEndPoint");
    assert(dataEndPoint is CarpDataEndPoint);
    await super.configure(
      dataEndPoint: dataEndPoint,
      deployment: deployment,
      measurements: measurements,
    );
    carpEndPoint = dataEndPoint as CarpDataEndPoint;

    assert(
      CarpService().isConfigured,
      'CarpService is not configured -- cannot upload data to this end point.',
    );

    buffer.initialize(deployment, measurements);

    // Set up a timer that uploads data on a regular basis depending on debug level
    int uploadInterval = Settings().debugLevel == DebugLevel.debug
        ? 1
        : carpEndPoint.uploadInterval;

    uploadTimer = Timer.periodic(
      Duration(minutes: uploadInterval),
      (_) => uploadBufferedMeasurements(),
    );

    // Check the current connectivity status and listen for changes
    Connectivity().checkConnectivity().then((status) => connectivity = status);
    Connectivity().onConnectivityChanged.listen(
      (status) => connectivity = status,
    );

    if (!CarpDataStreamService().isConfigured) {
      CarpDataStreamService().configureFrom(CarpService());
    }
  }

  @override
  Future<void> onMeasurement(Measurement measurement) async {}

  /// Upload buffered measurements to CAWS.
  Future<void> uploadBufferedMeasurements() async {
    debug("$runtimeType - Starting upload of data batches...");

    // fast exit if not connected
    if (connectivity.contains(ConnectivityResult.none)) {
      warning('$runtimeType - Offline - cannot upload buffered data.');
      return;
    }

    // fast exit if only upload on wifi and we're not on wifi
    if (carpEndPoint.onlyUploadOnWiFi &&
        !connectivity.contains(ConnectivityResult.wifi)) {
      warning(
        '$runtimeType - WiFi required by the data endpoint, but no wifi connectivity - '
        'cannot upload buffered data.',
      );
      return;
    }

    // now start trying to upload data...
    try {
      // check if authenticated to CAWS and fast exit if not
      if (!CarpAuthService().authenticated) {
        warning('No user authenticated to CAWS. Cannot upload data.');
        return;
      }

      // check if token has expired, and try to refresh token, if so
      if (CarpAuthService().currentUser.token!.hasExpired) {
        try {
          await CarpAuthService().refresh();
        } catch (error) {
          warning(
            '$runtimeType - Failed to refresh access token - $error. '
            'Cannot upload data.',
          );
          return;
        }
      }

      final batches = await buffer.getDataStreamBatches();

      switch (carpEndPoint.uploadMethod) {
        case CarpUploadMethod.stream:
          await CarpDataStreamService().appendToDataStreams(
            studyDeploymentId,
            batches,
            compress: compress,
          );
          addEvent(
            DataManagerEvent(CarpDataManagerEventTypes.dataStreamAppended),
          );
          break;
        case CarpUploadMethod.datapoint:
          await uploadDataStreamBatchesAsDataPoint(batches);
          addEvent(
            DataManagerEvent(CarpDataManagerEventTypes.dataPointsBatchUploaded),
          );
          break;
        case CarpUploadMethod.file:
          // TODO - implement file method.
          warning('$runtimeType - CarpUploadMethod.file not supported (yet).');
          break;
      }

      // Count the total amount of measurements and check if any measurement
      // has a separate file to be uploaded
      var count = 0;
      for (var batch in batches) {
        count += batch.measurements.length;
        for (var measurement in batch.measurements) {
          if (measurement.data is FileData) {
            var fileData = measurement.data as FileData;
            if (fileData.upload) uploadFile(fileData);
          }
        }
      }

      info(
        "$runtimeType - Upload of data batches done. "
        "${batches.length} batches with $count measurements in total uploaded.",
      );

      // if everything is uploaded successfully, then clean up the DB
      await buffer.cleanup(carpEndPoint.deleteWhenUploaded);
    } catch (error) {
      warning('$runtimeType - Data upload failed - $error');
    }
  }

  DataPointReference? _dataPointReference;
  DataPointReference get dataPointReference =>
      _dataPointReference ??= CarpService().dataPointReference();

  /// Transform all measurements in all [batches] to [DataPoint]s and upload
  /// them to CAWS using the DataPoint batch upload endpoint.
  Future<void> uploadDataStreamBatchesAsDataPoint(
    List<DataStreamBatch> batches,
  ) async {
    final List<DataPoint> dataPoints = [];
    for (var batch in batches) {
      for (var measurement in batch.measurements) {
        var dataPoint = DataPoint(
          DataPointHeader(
            studyId: deployment.studyDeploymentId,
            userId: CarpService().study?.participantId,
            dataFormat: measurement.dataType,
            deviceRoleName:
                measurement.taskControl?.targetDevice?.roleName ??
                deployment.deviceConfiguration.roleName,
            triggerId: measurement.taskControl?.triggerId.toString() ?? '0',
            startTime: DateTime.fromMicrosecondsSinceEpoch(
              measurement.sensorStartTime,
            ).toUtc(),
            endTime: measurement.sensorEndTime == null
                ? null
                : DateTime.fromMicrosecondsSinceEpoch(
                    measurement.sensorEndTime!,
                  ).toUtc(),
          ),
          measurement.data,
        );
        dataPoints.add(dataPoint);
      }
    }

    info(
      '$runtimeType - Batch uploading data points to CAWS, N=${dataPoints.length}',
    );
    dataPointReference.batch(dataPoints);
  }

  /// Upload a file attachment to CAWS, i.e. one that is referenced
  /// in a [FileData] data object.
  Future<void> uploadFile(FileData data) async {
    if (data.path == null) {
      warning(
        '$runtimeType - No path to local FileData specified when trying to upload file - data: $data.',
      );
      return;
    }

    info(
      "$runtimeType - File attachment upload to CAWS started - path : '${data.path}'",
    );

    try {
      final file = File(data.path!);

      if (!file.existsSync()) {
        warning(
          '$runtimeType - The file attachment is not found - skipping upload.',
        );
      } else {
        final String deviceID = DeviceInfoService().deviceID.toString();
        data.metadata!['device_id'] = deviceID;
        data.metadata!['study_id'] = deployment.studyId ?? '';
        data.metadata!['study_deployment_id'] = deployment.studyDeploymentId;

        // start upload
        final FileUploadTask uploadTask = CarpService()
            .getFileStorageReference()
            .upload(file, data.metadata);

        // await the upload is successful
        CarpFileResponse response = await uploadTask.onComplete;

        addEvent(
          DataManagerEvent(CarpDataManagerEventTypes.fileUploaded, file.path),
        );
        info(
          "$runtimeType - File upload to CAWS finished - server file id:${response.id}.",
        );

        // delete the local file once uploaded?
        if (carpEndPoint.deleteWhenUploaded) {
          file.delete();
          addEvent(
            FileDataManagerEvent(
              FileDataManagerEventTypes.fileDeleted,
              file.path,
            ),
          );
        }
      }
    } catch (error) {
      warning('$runtimeType - Error uploading file attachment - $error');
    }
  }

  @override
  Future<void> close() async {
    uploadTimer?.cancel();
    await uploadBufferedMeasurements();
    await super.close();
  }

  @override
  String toString() => '$runtimeType - ';
}

/// An enumeration of file data manager event types
class CarpDataManagerEventTypes extends DataManagerEventTypes {
  static const String dataPointsBatchUploaded = 'data_points_batch_uploaded';
  static const String dataStreamAppended = 'data_stream_appended';
  static const String fileUploaded = 'file_uploaded';
}
