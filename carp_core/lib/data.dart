/// Contains all pseudonymized data. When combined with the original study protocol,
/// the full provenance of the data (when/why it was collected) is known.
///
/// Contains the core data classes like [Measurement], [DataStreamBatch],
/// [DataStreamId], and defines the API of a [DataStreamService].
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
