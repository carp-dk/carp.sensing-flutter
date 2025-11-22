/// This library contains the core domain model for the Copenhagen Research
/// Platform (CARP).
/// This is used in the [CARP Mobile Sensing (CAMS)](https://pub.dev/packages/carp_mobile_sensing)
/// framework implemented in Flutter.
///
/// This is a Dart implementation of the [Kotlin CARP Core Domain Model](https://github.com/carp-dk/carp.core-kotlin/tree/develop).
///
/// In order to ensure initialization of json serialization, call:
///
/// `Core.ensureInitialized();`
///
library;

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/deployment.dart';
import 'package:carp_core/common.dart';
import 'package:carp_core/protocols.dart';
import 'package:carp_core/data.dart';

export 'client.dart';
export 'common.dart';
export 'data.dart';
export 'deployment.dart';
export 'protocols.dart';

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
