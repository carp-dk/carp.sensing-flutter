/// Collected data and the service that stores it.
///
/// Data is collected as [Measurement]s, grouped per data stream
/// ([DataStreamId]) into [DataStreamBatch]es and uploaded through a
/// [DataStreamService]. A [Measurement] only carries a [Data] payload and
/// timestamps; this library does not strip identifying information from the
/// payload, so the app must make sure the data meets the study's privacy
/// requirements. Combined with the study protocol, the provenance of the data
/// (when and why it was collected) is known.
///
/// Main types: [Measurement], [DataStreamId], [DataStreamBatch],
/// [DataStreamsConfiguration] and [DataStreamService].
///
/// See the [`carp-data`](https://github.com/carp-dk/carp.core-kotlin/blob/develop/docs/carp-data.md)
/// definition in Kotlin.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/common.dart';

part 'data/application/data_stream.dart';
part 'data/application/data_stream_service.dart';
part 'data/infrastructure/data_stream_requests.dart';

part 'data.g.dart';
