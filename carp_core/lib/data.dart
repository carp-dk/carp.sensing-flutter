/// Collected data and the service that stores it.
///
/// Data is collected as [Measurement]s, grouped per data stream
/// ([DataStreamId]) into [DataStreamBatch]es and uploaded through a
/// [DataStreamService]. Data is pseudonymized: a measurement holds no
/// participant information. Combined with the study protocol, the full
/// provenance of the data (when and why it was collected) is known.
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
