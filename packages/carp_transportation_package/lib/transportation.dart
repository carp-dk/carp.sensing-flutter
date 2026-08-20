/// A library for classifying transportation modes on routes.
///
/// This package does not sense continuously from device sensors like most
/// other CARP sampling packages. Instead, it defines the data types used to:
///
///  * send a collected [Route] (a trace of GPS points) to a classification
///    server,
///  * receive back a [Mode] classification (the route split into segments,
///    each labelled with a detected transportation mode), and
///  * send [UserFeedback] when the user approves/rejects/corrects a segment's
///    mode, or labels a cluster of locations (e.g. home, work, restaurant).
///
/// Since data is not collected from a continuous sensor stream, but rather
/// submitted by app-level code (after a server round-trip or user
/// interaction), this package uses a no-op [TransportationProbe]. App code
/// adds data using `probe.addMeasurement(Measurement.fromData(...))`.
library;

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
