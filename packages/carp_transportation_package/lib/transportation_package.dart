/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'transportation.dart';

/// A [SamplingPackage] for mobility data processing and recognition.
///
/// Unlike most sampling packages, this package does not sense continuously
/// from a phone sensor. Raw sensor samples (location, acceleration, rotation)
/// are collected by the existing sampling packages; this package defines the
/// data types produced by the mobility processing pipeline on top of them:
///
///  * [MODEL_CONFIGURATION] / [STAGE_CONFIGURATION] - one-time configuration
///    of the recognition and segmentation components.
///  * [TRANSPORTATION_SAMPLE] - point-wise samples with predicted mode
///    ([TransportationSample]), collected in batches after inference.
///  * [MOVE] / [STOP] - stage-level segments ([MoveStage], [StopStage]), emitted when
///    newly created or modified.
///  * [ACTIVITY] - the semantic interpretation of a stop ([MobilityActivity]).
///  * [STAGE_MODE_CORRECTION] - the user's correction of a stage's predicted
///    mode ([StageModeCorrection]).
///
/// All types are collected via the same no-op [TransportationProbe] - app code
/// calls `probe.addMeasurement(...)` once data is available.
///
/// An example of a study protocol configuration might be:
///
/// ```dart
///   protocol.addTaskControl(
///       ImmediateTrigger(),
///       BackgroundTask()
///         ..addMeasure(Measure(type: TransportationSamplingPackage.TRANSPORTATION_SAMPLE))
///         ..addMeasure(Measure(type: TransportationSamplingPackage.MOVE))
///         ..addMeasure(Measure(type: TransportationSamplingPackage.STOP)),
///       phone);
/// ```
///
/// To use this package, register it using:
///
/// ```dart
///   SamplingPackageRegistry().register(TransportationSamplingPackage());
/// ```
class TransportationSamplingPackage extends SmartphoneSamplingPackage {
  static const String TRANSPORTATION_NAMESPACE =
      "${NameSpace.CARP}.transportation";

  /// Measure type for the transportation model configuration.
  ///  * One-time measure - collected when the recognition component is
  ///    initialized.
  ///  * Uses the [Smartphone] primary device for data collection.
  static const String MODEL_CONFIGURATION =
      "$TRANSPORTATION_NAMESPACE.modelconfiguration";

  /// Measure type for the stage segmentation configuration.
  ///  * One-time measure - collected when the segmentation component is
  ///    initialized.
  ///  * Uses the [Smartphone] primary device for data collection.
  static const String STAGE_CONFIGURATION =
      "$TRANSPORTATION_NAMESPACE.stageconfiguration";

  /// Measure type for point-wise transportation samples.
  ///  * Event-based measure - emitted in batches after mode inference.
  ///  * Uses the [Smartphone] primary device for data collection.
  static const String TRANSPORTATION_SAMPLE =
      "$TRANSPORTATION_NAMESPACE.transportationsample";

  /// Measure type for stage-level moving segments.
  ///  * Event-based measure - emitted when a [MoveStage] is created or modified.
  ///  * Uses the [Smartphone] primary device for data collection.
  static const String MOVE = "$TRANSPORTATION_NAMESPACE.move";

  /// Measure type for stage-level still segments.
  ///  * Event-based measure - emitted when a [StopStage] is created or modified.
  ///  * Uses the [Smartphone] primary device for data collection.
  static const String STOP = "$TRANSPORTATION_NAMESPACE.stop";

  /// Measure type for the semantic interpretation of a stop.
  ///  * Event-based measure - emitted when an activity is identified.
  ///  * Uses the [Smartphone] primary device for data collection.
  static const String ACTIVITY = "$TRANSPORTATION_NAMESPACE.activity";

  /// Measure type for a user correction of a stage's transportation mode.
  ///  * Event-based measure - emitted when the user submits a correction.
  ///  * Uses the [Smartphone] primary device for data collection.
  static const String STAGE_MODE_CORRECTION =
      "$TRANSPORTATION_NAMESPACE.stagemodecorrection";

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: MODEL_CONFIGURATION,
            displayName: "Transportation Model Configuration",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: STAGE_CONFIGURATION,
            displayName: "Stage Segmentation Configuration",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: TRANSPORTATION_SAMPLE,
            displayName: "Point-wise Transportation Sample",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: MOVE,
            displayName: "MoveStage Stage",
            timeType: DataTimeType.TIME_SPAN,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: STOP,
            displayName: "StopStage Stage",
            timeType: DataTimeType.TIME_SPAN,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ACTIVITY,
            displayName: "Mobility Activity",
            timeType: DataTimeType.TIME_SPAN,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: STAGE_MODE_CORRECTION,
            displayName: "Stage Mode Correction",
            timeType: DataTimeType.POINT,
          ),
        ),
      ]);

  @override
  Probe? create(String type) =>
      samplingSchemes.types.contains(type) ? TransportationProbe() : null;

  @override
  void onRegister() {
    // register all data types for correct (de)serialization
    FromJsonFactory().registerAll([
      TransportationModelConfiguration(),
      StageConfiguration(userId: ''),
      TransportationSample(
        sampleId: 0,
        timestamp: DateTime.now(),
        latitude: 0,
        longitude: 0,
      ),
      MoveStage(
        stageId: 0,
        startSampleId: 0,
        endSampleId: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        startLatitude: 0,
        startLongitude: 0,
        endLatitude: 0,
        endLongitude: 0,
      ),
      StopStage(
        stageId: 0,
        startSampleId: 0,
        endSampleId: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        centroidLatitude: 0,
        centroidLongitude: 0,
      ),
      MobilityActivity(
        activityId: 0,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      ),
      StageModeCorrection(
        userId: '',
        date: DateTime.now(),
        stageId: 0,
        originalMode: TransportationMode.unknown,
        correctedMode: TransportationMode.unknown,
        feedbackTime: DateTime.now(),
      ),
    ]);
  }
}
