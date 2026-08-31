/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

import 'dart:async';
import 'dart:convert';

import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_transportation_package/transportation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import 'transportation_pipeline.dart';

/// Sets up CARP Mobile Sensing for the transportation package:
///
///  * the phone's location service samples [Location] continuously
///    (`distance: 0`, so every location update is collected),
///  * a [ConditionalSamplingEventTrigger] fires once
///    [TransportationPipeline.batchSize] locations have been buffered,
///  * the triggered [FunctionTask] runs inference over the batch and adds one
///    [TransportationSample] per buffered location to the transportation probe,
///  * everything - locations and transportation samples - is stored in a local
///    SQLite database ([SQLiteDataEndPoint]).
class TransportationSensing {
  final SmartPhoneClientManager client = SmartPhoneClientManager();

  SmartphoneStudyController? controller;
  late final TransportationPipeline pipeline;

  /// distance: 0 - be notified of every location update, not only of moves of
  /// more than N meters, so batches fill up while standing still too.
  final LocationService _locationService = LocationService(
    accuracy: GeolocationAccuracy.high,
    distance: 0,
    interval: const Duration(seconds: 1),
  );

  /// The probe the pipeline's output is added to.
  ///
  /// This package uses a single no-op [TransportationProbe] per measure type,
  /// so any of them can be used to add data - it all ends up in the same
  /// measurement stream and, from there, in SQLite.
  ///
  /// Looked up on every use: the executors are initialized asynchronously
  /// after the study is resumed, so the probe does not exist yet at startup.
  TransportationProbe? get probe =>
      controller?.executor
              .lookupProbe(TransportationSamplingPackage.TRANSPORTATION_SAMPLE)
              .firstOrNull
          as TransportationProbe?;

  /// Register the packages, deploy a study storing data in SQLite, and start
  /// sampling.
  Future<void> initialize() async {
    Settings().debugLevel = DebugLevel.info;

    // The packages must be registered before the protocol below can use their
    // measure types.
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(TransportationSamplingPackage());

    pipeline = TransportationPipeline(
      emit: (data) => probe == null
          ? warning('$runtimeType - No transportation probe - dropping $data')
          : probe!.addMeasurement(Measurement.fromData(data)),
    );
    // ponytail: looking the probe up per emit is O(probes); fine for 7 probes.

    // Request location permission BEFORE configuring the client: CAMS connects
    // the LocationService when the study is deployed, and that connect fails
    // (and is never retried) unless permission is already granted. Asked via
    // permission_handler rather than the location plugin, which binds its
    // Android service asynchronously and throws if called too early.
    await Permission.locationWhenInUse.request();
    await LocationManager().configure(_locationService);

    await client.configure(
      enableBackgroundMode: false,
      enableNotifications: false,
    );

    // Remove studies restored from previous runs: their trigger condition is a
    // Dart function, which does not survive JSON (de)serialization, so a
    // restored study samples location but never runs inference.
    for (var study in [...client.studies]) {
      await client.removeStudy(study.studyDeploymentId, study.deviceRoleName);
    }

    final study = await client.addStudyFromProtocol(protocol);
    await client.tryDeployment(study.studyDeploymentId, study.deviceRoleName);

    controller = client.getStudyController(study);
    controller?.resume();
  }

  /// A protocol sampling location continuously and running mode inference on
  /// every batch of [TransportationPipeline.batchSize] locations, storing all
  /// of it in a local SQLite database on this phone.
  SmartphoneStudyProtocol get protocol {
    final protocol = SmartphoneStudyProtocol(
      ownerId: 'owner@dtu.dk',
      name: 'Transportation Example',
      // Store all measurements in the local `carp-data.db` SQLite database.
      dataEndPoint: SQLiteDataEndPoint(),
    );

    final phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    protocol.addConnectedDevice(_locationService, phone);

    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        name: 'Location Sampling',
        measures: [Measure(type: ContextSamplingPackage.LOCATION)],
      ),
      _locationService,
    );

    // Every batchSize'th location, run inference and emit the batch of
    // transportation samples it produces.
    protocol.addTaskControl(
      ConditionalSamplingEventTrigger(
        measureType: ContextSamplingPackage.LOCATION,
        triggerCondition: pipeline.isBatchReady,
      ),
      FunctionTask(
        name: 'Mode Inference',
        function: pipeline.runInference,
      ),
      phone,
    );

    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        name: 'Transportation Task',
        measures: [
          Measure(type: TransportationSamplingPackage.MODEL_CONFIGURATION),
          Measure(type: TransportationSamplingPackage.STAGE_CONFIGURATION),
          Measure(type: TransportationSamplingPackage.TRANSPORTATION_SAMPLE),
          Measure(type: TransportationSamplingPackage.MOVE),
          Measure(type: TransportationSamplingPackage.STOP),
          Measure(type: TransportationSamplingPackage.ACTIVITY),
          Measure(type: TransportationSamplingPackage.STAGE_MODE_CORRECTION),
        ],
      ),
      phone,
    );

    return protocol;
  }

  /// The stream of measurements as they are sampled - the same stream the
  /// SQLite data manager writes from.
  Stream<Measurement> get measurements =>
      controller?.measurements ?? const Stream.empty();

  /// The full path of the SQLite database the measurements are written to.
  String? get databaseName => _sqLiteDataManager?.databaseName;

  SQLiteDataManager? get _sqLiteDataManager =>
      controller?.dataManager is SQLiteDataManager
      ? controller!.dataManager as SQLiteDataManager
      : null;

  Database? get _database => _sqLiteDataManager?.database;

  /// Read back what is actually stored in SQLite: the number of stored
  /// measurements per data type, most frequent type first.
  Future<Map<String, int>> countStoredMeasurementsByType() async {
    final db = _database;
    if (db == null || !db.isOpen) return {};

    final rows = await db.rawQuery(
      'SELECT ${SQLiteDataManager.DATATYPE_COLUMN} AS type, COUNT(*) AS count '
      'FROM ${SQLiteDataManager.MEASUREMENT_TABLE_NAME} '
      'GROUP BY ${SQLiteDataManager.DATATYPE_COLUMN} '
      'ORDER BY COUNT(*) DESC',
    );

    return {for (var row in rows) row['type'] as String: row['count'] as int};
  }

  /// Read back the [limit] most recently stored measurements from SQLite,
  /// deserialized from the JSON stored in the database.
  Future<List<Measurement>> readStoredMeasurements({int limit = 20}) async {
    final db = _database;
    if (db == null || !db.isOpen) return [];

    final rows = await db.query(
      SQLiteDataManager.MEASUREMENT_TABLE_NAME,
      orderBy: '${SQLiteDataManager.ID_COLUMN} DESC',
      limit: limit,
    );

    return rows
        .map(
          (row) => Measurement.fromJson(
            json.decode(row[SQLiteDataManager.MEASUREMENT_COLUMN] as String)
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  void dispose() => controller?.dispose();
}
