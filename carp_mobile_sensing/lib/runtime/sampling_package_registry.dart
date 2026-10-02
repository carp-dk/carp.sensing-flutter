/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// The singleton registry of all [SamplingPackage]s used in an app.
///
/// An app registers each external sampling package here at startup, before
/// it configures the [SmartPhoneClientManager]. The registry then knows which
/// measure types, [Probe]s and devices are available on this phone.
///
/// Key points:
///  * The built-in [DeviceSamplingPackage], [SensorSamplingPackage] and
///    [MonitoringSamplingPackage] are always registered.
///  * [register] also adds the package's data types to [CarpDataTypes] and its
///    [DeviceManager] to the [DeviceController].
///  * [create] makes a new [Probe] for a measure type; used by the executors.
///
/// See the [CAMS GitHub repo](https://github.com/carp-dk/carp.sensing-flutter)
/// for an overview of available sampling packages.
///
/// ```dart
/// SamplingPackageRegistry().register(ContextSamplingPackage());
/// await SmartPhoneClientManager().configure();
/// ```
class SamplingPackageRegistry {
  final List<SamplingPackage> _packages = [];
  DataTypeSamplingSchemeMap? _combinedSchemas;

  static final SamplingPackageRegistry _instance = SamplingPackageRegistry._();

  /// Returns the singleton [SamplingPackageRegistry].
  factory SamplingPackageRegistry() => _instance;

  /// The registered packages, in registration order.
  List<SamplingPackage> get packages => _packages;

  SamplingPackageRegistry._() {
    // register the built-in packages
    register(DeviceSamplingPackage());
    register(SensorSamplingPackage());
    register(MonitoringSamplingPackage());
  }

  /// Registers [package].
  ///
  /// Also adds the package's data types to [CarpDataTypes], registers its
  /// [SamplingPackage.deviceManager] in the [DeviceController], and calls
  /// [SamplingPackage.onRegister].
  void register(SamplingPackage package) {
    _combinedSchemas = null;
    _packages.add(package);
    CarpDataTypes().add(package.samplingSchemes.dataTypes);

    // register the package's device in the device registry
    DeviceController().registerDevice(package.deviceType, package.deviceManager);

    // call back to the package
    package.onRegister();
  }

  /// Returns the [SamplingPackage]s that support the data [type].
  ///
  /// Typically, only one package supports a specific type. However, if
  /// more than one package does, all packages are returned.
  /// Can be an empty list.
  Set<SamplingPackage> lookup(String type) {
    final Set<SamplingPackage> supportedPackages = {};

    for (var package in packages) {
      if (package.samplingSchemes.contains(type)) {
        supportedPackages.add(package);
      }
    }

    return supportedPackages;
  }

  /// The combined list of all data types in all packages.
  List<DataTypeMetaData> get dataTypes {
    List<DataTypeMetaData> dataTypes = [];
    for (var package in packages) {
      dataTypes.addAll(package.samplingSchemes.dataTypes);
    }
    return dataTypes;
  }

  /// The combined sampling schemes for all measure types in all packages.
  ///
  /// Used as the last fallback for a [Probe.samplingConfiguration] and to find
  /// the permissions a measure needs.
  DataTypeSamplingSchemeMap get samplingSchemes {
    if (_combinedSchemas == null) {
      _combinedSchemas = DataTypeSamplingSchemeMap();
      // join sampling schemas from each registered sampling package.
      for (var package in packages) {
        _combinedSchemas!.addSamplingSchema(package.samplingSchemes);
      }
    }
    return _combinedSchemas!;
  }

  /// Creates a new [Probe] for the data [type].
  ///
  /// Asks the first registered package that supports [type] to create the
  /// probe, and sets the probe's [Probe.deviceManager] to the package's device
  /// manager. If more than one package supports [type], a warning is logged.
  ///
  /// Returns `null` if no probe is found for [type], e.g., when the probe is
  /// not available on this OS or its package is not registered.
  Probe? create(String type) {
    Probe? probe;

    final packages = lookup(type);

    if (packages.isNotEmpty) {
      if (packages.length > 1) {
        warning(
          "$runtimeType - It seems like the data type '$type' is defined in more than one sampling package. "
          "Is using the probe provided in the ${packages.first} package.",
        );
      }
      probe = packages.first.create(type);
      probe?.deviceManager = packages.first.deviceManager;
    }

    return probe;
  }
}
