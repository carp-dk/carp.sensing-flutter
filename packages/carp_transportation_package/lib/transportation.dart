/// A library for mobility sampling: point-wise transportation mode
/// recognition, stage-wise mobility ([MoveStage]/[StopStage]), semantic activities, and
/// user corrections.
///
/// This package does not sense continuously from device sensors like most
/// other CARP sampling packages. Raw sensor data (location, acceleration,
/// rotation) is collected by the existing packages; this package defines the
/// data types produced by the mobility processing pipeline on top of it:
///
///  * [TransportationSample] - a point-wise sample with its embedding and
///    predicted transportation mode,
///  * [MoveStage] and [StopStage] - stage-level segments derived from consecutive
///    transportation samples,
///  * [MobilityActivity] - the semantic interpretation of a meaningful stop,
///  * [StageModeCorrection] - the user's correction of a stage's mode,
///  * [TransportationModelConfiguration] and [StageConfiguration] - the
///    one-time configuration of the recognition and segmentation components.
///
/// Since this data is produced by app-level processing (model inference,
/// segmentation, user interaction) rather than a continuous sensor stream,
/// this package uses a no-op [TransportationProbe]. App code adds data using
/// `probe.addMeasurement(Measurement.fromData(...))`.
library;

import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'transportation_data.dart';
part 'transportation_probes.dart';
part 'transportation_package.dart';
part 'transportation.g.dart';

// auto generate json code (.g files) with:
//   flutter pub run build_runner build --delete-conflicting-outputs
