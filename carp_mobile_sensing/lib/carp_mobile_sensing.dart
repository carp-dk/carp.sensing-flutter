/// This library contains the software architecture for the CARP Mobile Sensing
/// (CAMS) framework implemented in Flutter.
/// Supports cross-platform (iOS and Android) mobile sensing.
///
/// The CAMS software architecture is a domain-drive design (DDD) model using an
/// onion-based layout with the following onion layers:
///
///  * [domain] - contains the core domain model for CAMS which extends the domain
///             model of the [carp_core](https://pub.dev/packages/carp_core) domain model.
///             This also include definition of service interfaces.
///  * [runtime] - contains the business logic for executing a sensing study (normally
///              called 'application' in DDD).
///  * [infrastructure] - contains specific implementation of the services used.
///  * [sampling_packages] - contains the build-in sampling packages.
///
/// Domain-driven design (DDD) is a software design approach that focuses on modeling
/// the software to match the domain, or the subject area, that the software is
/// intended for. DDD helps developers create software that is aligned with the
/// business needs and terminology of the domain experts, users, and stakeholders.
/// From [Domain-Driven Design (DDD): A Guide to Building Scalable, High-Performance Systems](https://romanglushach.medium.com/domain-driven-design-ddd-a-guide-to-building-scalable-high-performance-systems-5314a7fe053c) by Roman Glushach.
///
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

/// Base class for the carp_mobile_sensing library.
///
/// In order to ensure initialization of json serialization, call:
///
///    CarpMobileSensing.ensureInitialized();
///
class CarpMobileSensing {
  static final _instance = CarpMobileSensing._();

  CarpMobileSensing._() {
    Core.ensureInitialized();
    CamsDataTypes();
    _registerFromJsonFunctions();
  }

  /// The singleton [CarpMobileSensing] instance.
  factory CarpMobileSensing() => _instance;

  /// Returns a the singleton instance of [CarpMobileSensing].
  /// If it has not yet been initialized, this call makes sure to create and
  /// initialize it.
  static CarpMobileSensing ensureInitialized() => _instance;
}

/// Generic sensing exception.
class SensingException implements Exception {
  dynamic message;
  SensingException([this.message]);

  @override
  String toString() => '$runtimeType - $message';
}
