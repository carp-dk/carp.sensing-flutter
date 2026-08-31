/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'transportation.dart';

/// A no-op probe for the transportation package.
///
/// None of this package's data types are collected from a continuous phone
/// sensor. Instead, the mobility processing pipeline runs on top of raw
/// sensor data already collected by other sampling packages:
///
///  * mode inference over a window of raw samples produces
///    [TransportationSample]s (added in batches),
///  * segmentation of consecutive samples produces [MoveStage] and [StopStage] stages
///    (added when newly created or modified),
///  * activity identification produces [MobilityActivity],
///  * the user's review of the results produces [StageModeCorrection].
///
/// In all cases, app-level code adds the resulting [Data] to this probe once
/// it is running, e.g.:
///
/// ```dart
/// transportationProbe.addMeasurement(Measurement.fromData(sample));
/// transportationProbe.addMeasurement(Measurement.fromData(move));
/// transportationProbe.addMeasurement(Measurement.fromData(correction));
/// ```
///
/// This mirrors how the `carp_survey_package`'s `SurveyProbe` works.
class TransportationProbe extends Probe {}
