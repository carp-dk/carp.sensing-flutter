/*
 * Copyright 2018-2023 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// Creates [CarpDataManager]s for the `CAWS` data endpoint type.
///
/// Register it before deploying a study that uses a [CarpDataEndPoint]:
/// `DataManagerRegistry().register(CarpDataManagerFactory())`.
class CarpDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.CAWS;

  @override
  DataManager create() => CarpDataManager();

  CarpDataManagerFactory() : super() {
    CarpDataManager();
  }
}

/// A data manager that uploads measurements to CARP Web Services (CAWS).
///
/// Handles a [CarpDataEndPoint]. It is created by the [CarpDataManagerFactory]
/// when a deployment with this data endpoint starts, and receives the
/// deployment's stream of [Measurement]s.
///
/// Key points:
///  * Measurements are buffered in a local [DataStreamBuffer] and uploaded every
///    [CarpDataEndPoint.uploadInterval] minutes (every minute in debug mode).
///  * [CarpDataEndPoint.uploadMethod] selects the upload method:
///    [CarpUploadMethod.stream] (default) or [CarpUploadMethod.datapoint].
///    [CarpUploadMethod.file] is not implemented.
///  * Uploads are skipped when offline, when [CarpDataEndPoint.onlyUploadOnWiFi]
///    is set and there is no WiFi, or when no user is authenticated in
///    [CarpAuthService]. Data stays in the buffer until the next try.
///  * [FileData] attachments with `upload` set are uploaded to CAWS file storage.
///  * Emits [CarpDataManagerEventTypes] events on its event stream.
///  * [CarpService] must be configured before [configure] is called.
class CarpDataManager extends AbstractDataManager {
  /// The data endpoint this manager uploads to. Set by [configure].
  late CarpDataEndPoint carpEndPoint;

  /// The local buffer of measurements not yet uploaded.
  DataStreamBuffer buffer = DataStreamBuffer();

  /// The timer that calls [uploadBufferedMeasurements]. Set by [configure].
  Timer? uploadTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<ConnectivityResult> _connectivity = [];

  /// Registers [CarpDataEndPoint] for JSON deserialization.
  ///
  /// Call this before deserializing a protocol that uses a [CarpDataEndPoint].
  static void ensureInitialized() => FromJsonFactory().register(CarpDataEndPoint());

  /// Creates a [CarpDataManager] and registers [CarpDataEndPoint] for JSON
  /// deserialization.
  CarpDataManager() : super() {
    CarpMobileSensing.ensureInitialized();
    FromJsonFactory().register(CarpDataEndPoint());
  }

  @override
  String get type => DataEndPointTypes.CAWS;

  /// Whether data is compressed before upload. See [CarpDataEndPoint.compress].
  bool get compress => carpEndPoint.compress;
  set compress(bool compress) => carpEndPoint.compress = compress;

  /// The latest known network connectivity of the phone.
  ///
  /// Kept up to date by listening to connectivity changes after [configure].
  List<ConnectivityResult> get connectivity => _connectivity;
  set connectivity(List<ConnectivityResult> status) {
    _connectivity = status;
    info("$runtimeType - Network connectivity status set to '$status'");
  }

  /// Configures this manager to buffer [measurements] from [deployment] and
  /// upload them to [dataEndPoint], which must be a [CarpDataEndPoint].
  ///
  /// Starts the upload timer and listens for connectivity changes.
  @override
  Future<void> configure({
    required DataEndPoint dataEndPoint,
    required SmartphoneDeployment deployment,
    required Stream<Measurement> measurements,
  }) async {
    info("$runtimeType - Initializing, endpoint: $dataEndPoint");
    assert(dataEndPoint is CarpDataEndPoint);
    await super.configure(dataEndPoint: dataEndPoint, deployment: deployment, measurements: measurements);
    carpEndPoint = dataEndPoint as CarpDataEndPoint;

    assert(CarpService().isConfigured, 'CarpService is not configured -- cannot upload data to this end point.');

    await buffer.initialize(deployment, measurements);

    // Set up a timer that uploads data on a regular basis depending on debug level
    int uploadInterval = Settings().debugLevel == DebugLevel.debug ? 1 : carpEndPoint.uploadInterval;

    uploadTimer = Timer.periodic(Duration(minutes: uploadInterval), (_) => uploadBufferedMeasurements());

    // Check the current connectivity status and listen for changes
    Connectivity().checkConnectivity().then((status) => connectivity = status);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((status) => connectivity = status);

    if (!CarpDataStreamService().isConfigured) {
      CarpDataStreamService().configureFrom(CarpService());
    }
  }

  @override
  Future<void> onMeasurement(Measurement measurement) async {}

  /// Uploads all buffered measurements to CAWS.
  ///
  /// Refreshes an expired access token first. Does nothing if offline, if WiFi
  /// is required but missing, or if no user is authenticated. On success the
  /// buffer is cleaned up according to [CarpDataEndPoint.deleteWhenUploaded].
  /// Errors are logged, not thrown.
  Future<void> uploadBufferedMeasurements() async {
    debug("$runtimeType - Starting upload of data batches...");

    // fast exit if not connected
    if (connectivity.contains(ConnectivityResult.none)) {
      warning('$runtimeType - Offline - cannot upload buffered data.');
      return;
    }

    // fast exit if only upload on wifi and we're not on wifi
    if (carpEndPoint.onlyUploadOnWiFi && !connectivity.contains(ConnectivityResult.wifi)) {
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
          await CarpDataStreamService().appendToDataStreams(studyDeploymentId, batches, compress: compress);
          addEvent(DataManagerEvent(CarpDataManagerEventTypes.dataStreamAppended));
          break;
        case CarpUploadMethod.datapoint:
          await uploadDataStreamBatchesAsDataPoint(batches);
          addEvent(DataManagerEvent(CarpDataManagerEventTypes.dataPointsBatchUploaded));
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

  /// The CAWS DataPoint endpoint used by [CarpUploadMethod.datapoint].
  DataPointReference get dataPointReference => _dataPointReference ??= CarpService().dataPointReference();

  /// Converts all measurements in [batches] to [DataPoint]s and uploads them
  /// using the CAWS DataPoint batch endpoint.
  ///
  /// Used by [CarpUploadMethod.datapoint].
  Future<void> uploadDataStreamBatchesAsDataPoint(List<DataStreamBatch> batches) async {
    final List<DataPoint> dataPoints = [];
    for (var batch in batches) {
      for (var measurement in batch.measurements) {
        var dataPoint = DataPoint(
          DataPointHeader(
            studyId: deployment.studyDeploymentId,
            userId: CarpService().study?.participantId,
            dataFormat: measurement.dataType,
            deviceRoleName: measurement.taskControl?.targetDevice?.roleName ?? deployment.deviceConfiguration.roleName,
            triggerId: measurement.taskControl?.triggerId.toString() ?? '0',
            startTime: DateTime.fromMicrosecondsSinceEpoch(measurement.sensorStartTime).toUtc(),
            endTime: measurement.sensorEndTime == null
                ? null
                : DateTime.fromMicrosecondsSinceEpoch(measurement.sensorEndTime!).toUtc(),
          ),
          measurement.data,
        );
        dataPoints.add(dataPoint);
      }
    }

    info('$runtimeType - Batch uploading data points to CAWS, N=${dataPoints.length}');
    dataPointReference.batch(dataPoints);
  }

  /// Uploads the file referenced by [data] to CAWS file storage.
  ///
  /// Adds device and deployment IDs to the file metadata. Deletes the local
  /// file afterwards if [CarpDataEndPoint.deleteWhenUploaded] is `true`.
  /// Errors are logged, not thrown.
  Future<void> uploadFile(FileData data) async {
    if (data.path == null) {
      warning('$runtimeType - No path to local FileData specified when trying to upload file - data: $data.');
      return;
    }

    info("$runtimeType - File attachment upload to CAWS started - path : '${data.path}'");

    try {
      final file = File(data.path!);

      if (!file.existsSync()) {
        warning('$runtimeType - The file attachment is not found - skipping upload.');
      } else {
        final String deviceID = DeviceInfoService().deviceID.toString();
        data.metadata!['device_id'] = deviceID;
        data.metadata!['study_id'] = deployment.studyId ?? '';
        data.metadata!['study_deployment_id'] = deployment.studyDeploymentId;

        // start upload
        final FileUploadTask uploadTask = CarpService().getFileStorageReference().upload(file, data.metadata);

        // await the upload is successful
        CarpFileResponse response = await uploadTask.onComplete;

        addEvent(DataManagerEvent(CarpDataManagerEventTypes.fileUploaded, file.path));
        info("$runtimeType - File upload to CAWS finished - server file id:${response.id}.");

        // delete the local file once uploaded?
        if (carpEndPoint.deleteWhenUploaded) {
          file.delete();
          addEvent(FileDataManagerEvent(FileDataManagerEventTypes.fileDeleted, file.path));
        }
      }
    } catch (error) {
      warning('$runtimeType - Error uploading file attachment - $error');
    }
  }

  /// Stops the upload timer, makes a final upload, and detaches from the
  /// [buffer] without closing its shared database.
  @override
  Future<void> close() async {
    uploadTimer?.cancel();
    await _connectivitySubscription?.cancel();

    // Stop receiving measurements before the final flush.
    await super.close();
    await uploadBufferedMeasurements();

    // Only detach from the buffer. Its database is shared app-wide (a single
    // `carp-data.db`), so closing it would break the replacement manager.
    await buffer.detach();
  }

  @override
  String toString() => '$runtimeType - ';
}

/// The types of [DataManagerEvent]s emitted by a [CarpDataManager].
class CarpDataManagerEventTypes extends DataManagerEventTypes {
  /// A batch of data points was uploaded using [CarpUploadMethod.datapoint].
  static const String dataPointsBatchUploaded = 'data_points_batch_uploaded';

  /// Buffered data was appended to the CAWS data streams.
  static const String dataStreamAppended = 'data_stream_appended';

  /// A [FileData] attachment was uploaded to CAWS file storage.
  static const String fileUploaded = 'file_uploaded';
}
