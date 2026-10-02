/// The CARP Mobile Sensing (CAMS) framework for Flutter: cross-platform
/// (Android and iOS) mobile sensing.
///
/// Import this library to get all of CAMS. It extends the domain model of
/// [carp_core](https://pub.dev/packages/carp_core) and is split into
/// onion layers, following domain-driven design (DDD):
///
///  * [domain] - the CAMS domain model: protocol, devices, triggers, tasks,
///    data endpoints, and the service interfaces (e.g. [DataManager]).
///  * [runtime] - executes a study on the phone, starting from
///    [SmartPhoneClientManager] (called the "application" layer in DDD).
///  * [infrastructure] - on-phone implementations of the services, like
///    [SQLiteDataManager] and [SmartphoneDeploymentService].
///  * [sampling_packages] - the built-in sampling packages
///    ([DeviceSamplingPackage], [SensorSamplingPackage]).
///
/// Call [CarpMobileSensing.ensureInitialized] (done by the client manager)
/// before you deserialize any CAMS object from JSON.
/// See the [CAMS documentation](https://docs.carp.dk/carp-mobile-sensing/).
library;

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone, BLEHeartRateDevice;

import 'domain.dart';
import 'runtime.dart';
import 'sampling_packages.dart';

export 'domain.dart';
export 'runtime.dart';
export 'infrastructure.dart';
export 'sampling_packages.dart';

part 'carp_mobile_sensing.json.dart';

/// Singleton that initializes the carp_mobile_sensing library.
///
/// Creating it registers the JSON deserialization functions of all CAMS
/// domain classes in the [FromJsonFactory], and the CAMS data types in
/// [CarpDataTypes] (via [CamsDataTypes]). Call
/// [CarpMobileSensing.ensureInitialized] before you deserialize a
/// [SmartphoneStudyProtocol] or other CAMS object from JSON.
/// [SmartPhoneClientManager] does this for you.
class CarpMobileSensing {
  static final _instance = CarpMobileSensing._();

  CarpMobileSensing._() {
    Core.ensureInitialized();
    CamsDataTypes();
    _registerFromJsonFunctions();
  }

  /// The singleton [CarpMobileSensing] instance.
  factory CarpMobileSensing() => _instance;

  /// Returns the singleton instance of [CarpMobileSensing].
  ///
  /// Creates and initializes it on the first call. Safe to call many times.
  static CarpMobileSensing ensureInitialized() => _instance;
}

/// A generic exception thrown by CAMS when sensing fails.
class SensingException implements Exception {
  /// A description of the error, if any.
  dynamic message;
  SensingException([this.message]);

  @override
  String toString() => '$runtimeType - $message';
}
