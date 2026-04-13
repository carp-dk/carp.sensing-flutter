/// Implements open standards which can describe a study protocol, i.e.,
/// defining how a study should be run. Essentially, this subsystem has no
/// technical dependencies on any particular sensor technology or application as
/// it merely describes why, when, and what data should be collected.
///
///
/// Contain the the core CARP domain classes like [StudyProtocol], [TaskConfiguration],
/// and [Measure].
///
/// See the [`carp.protocols`](https://github.com/carp-dk/carp.core-kotlin/blob/develop/docs/carp-protocols.md)
/// definition in Kotlin.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/common.dart';

part 'protocols/domain/study_protocol.dart';
part 'protocols/application/protocol_classes.dart';
part 'protocols/application/protocol_service.dart';
part 'protocols/infrastructure/protocol_requests.dart';

part 'protocol.g.dart';
