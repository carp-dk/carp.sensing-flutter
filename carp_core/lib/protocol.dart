/// Study protocols: the definition of how a study is run.
///
/// A [StudyProtocol] describes why, when and what data should be collected,
/// without depending on any sensor technology or app. It combines devices,
/// tasks, triggers and measures from the common subsystem. Protocols are
/// managed through a [ProtocolService] and deployed with a `DeploymentService`.
///
/// Main types: [StudyProtocol], [ProtocolVersion], [ProtocolService] and
/// [ProtocolFactoryService].
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
