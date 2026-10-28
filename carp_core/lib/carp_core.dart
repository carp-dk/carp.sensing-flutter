/// The core domain model of the Copenhagen Research Platform (CARP) in Dart.
///
/// This is a Dart implementation of the [Kotlin CARP Core domain model](https://github.com/carp-dk/carp.core-kotlin/tree/develop).
/// It is used by [CARP Mobile Sensing (CAMS)](https://pub.dev/packages/carp_mobile_sensing)
/// and all of its [sub-packages](https://github.com/carp-dk/carp.sensing-flutter).
/// This package defines the types only; it does not collect any data itself.
///
/// Following CARP Core, this package consists of five sub-systems:
///
///  * [protocol] - supports the creation and management of [StudyProtocol]s
///    defining how a study should run. Essentially, this subsystem
///    has no technical dependencies on any particular sensor technology or
///    application as the containing study protocols merely describe why, when,
///    and what data should be collected.
///  * [deployment] - maps the information specified in a study
///    protocol to runtime configurations called [StudyDeployment]s, which is
///    used by the [client] subsystem to run the protocol on concrete
///    devices (e.g., a [SmartphoneClient]) and allow researchers to
///    monitor their state. To start collecting data, participants need to be invited,
///    the deployment information has to be fetched, and devices need to be
///    registered to collect the measures specified in the study protocol.
///  * [client] - the runtime which performs the actual data collection
///    on a device (e.g., a smartphone). This subsystem contains
///    reusable components which understand the runtime configuration derived
///    from a study protocol by the [deployment] subsystem.
///    Integrations with sensors are loaded through a [DeviceDataCollector]
///    plug-in system to decouple sensing from the abstract deployment information.
///    For example, a study deployment may specify that [Geolocation] should be
///    collected, while different data collectors on different devices may
///    collect this information using different OS-specific sensors or APIs.
///  * [data] - handles all data collected by a client. Data is collected
///    as [Measurement]s which again holds [Data] objects. Data collection happens
///    pseudonymized as each measurement does not contain any information about
///    the participant collecting this data. However, in combination with
///    the original study protocol, the full provenance of the data (when/why
///    it was collected) is known.
///  * [common] - implements base types and helper classes used
///    by all subsystems. Primarily, this contains the built-in types used
///    to define study protocols which subsequently get passed to the deployments
///    and clients subsystem.
///
/// Using [carp_serializable](https://pub.dev/packages/carp_serializable), all
/// objects serialize to the same JSON as the Kotlin implementation.
/// To register the JSON deserializers, call [Core.ensureInitialized] once at
/// startup.
///
library;

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/deployment.dart';
import 'package:carp_core/common.dart';
import 'package:carp_core/protocol.dart';
import 'package:carp_core/data.dart';

export 'client.dart';
export 'common.dart';
export 'data.dart';
export 'deployment.dart';
export 'protocol.dart';

part 'carp_core.json.dart';

/// Entry point that initializes the carp_core library.
///
/// Creating the singleton registers the `fromJson` functions of all
/// carp_core types in [FromJsonFactory]. Call [Core.ensureInitialized] once
/// before deserializing any CARP JSON. CARP Mobile Sensing calls it for you in
/// `CarpMobileSensing.ensureInitialized()`.
class Core {
  static final _instance = Core._();
  factory Core() => _instance;
  Core._() {
    _registerFromJsonFunctions();
  }

  /// Returns the singleton instance of [Core], creating it on first call.
  ///
  /// Safe to call more than once; registration happens only once.
  static Core ensureInitialized() => _instance;
}
