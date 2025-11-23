/// This library contains the core domain model for the Copenhagen Research
/// Platform (CARP).
/// This is a Dart implementation of the [Kotlin CARP Core Domain Model](https://github.com/carp-dk/carp.core-kotlin/tree/develop).
/// This is used in the [CARP Mobile Sensing (CAMS)](https://pub.dev/packages/carp_mobile_sensing)
/// framework implemented in Flutter, and all of its [sub-packages](https://github.com/carp-dk/carp.sensing-flutter).
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
///    used by the [client] subsystems to run the protocol on concrete
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
///    collected, while a different data collectors on different devices may
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
/// Using [carp_serializable](https://pub.dev/packages/carp_serializable), this package also handles JSON serialization of all
/// objects between the Kotlin and Dart implementation.
/// In order to ensure initialization of json serialization, call:
///
/// `Core.ensureInitialized();`
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

/// Base class for the carp_core library.
///
/// In order to ensure initialization of json serialization, call:
///
/// `Core.ensureInitialized();`
///
class Core {
  static final _instance = Core._();
  factory Core() => _instance;
  Core._() {
    _registerFromJsonFunctions();
  }

  /// Returns the singleton instance of [Core].
  /// If it has not yet been initialized, this call makes sure to create and
  /// initialize it.
  static Core ensureInitialized() => _instance;
}
