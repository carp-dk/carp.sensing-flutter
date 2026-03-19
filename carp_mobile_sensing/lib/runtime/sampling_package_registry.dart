/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// A registry of [SamplingPackage] packages.
///
/// This registry works as a singleton and is accessed using the `SamplingPackageRegistry()`
/// factory method.
///
/// This registry is mainly used to [register] any sampling packages used in a
/// CAMS app. See the [CAMS GitHub repro](https://github.com/cph-cachet/carp.sensing-flutter/tree/master)
/// for an overview of available sampling packages.
class SamplingPackageRegistry {
  final List<SamplingPackage> _packages = [];
  DataTypeSamplingSchemeMap? _combinedSchemas;

  static final SamplingPackageRegistry _instance = SamplingPackageRegistry._();

  /// Get the singleton [SamplingPackageRegistry].
  factory SamplingPackageRegistry() => _instance;

  /// A list of registered packages.
  List<SamplingPackage> get packages => _packages;

  SamplingPackageRegistry._() {
    // register the built-in packages
    register(DeviceSamplingPackage());
    register(SensorSamplingPackage());
    register(MonitoringSamplingPackage());
  }

  /// Register a sampling package.
  void register(SamplingPackage package) {
    _combinedSchemas = null;
    _packages.add(package);
    CarpDataTypes().add(package.samplingSchemes.dataTypes);

    // register the package's device in the device registry
    DeviceController().registerDevice(
      package.deviceType,
      package.deviceManager,
    );

    // call back to the package
    package.onRegister();
  }

  /// Lookup the [SamplingPackage]s that support the [type] of data.
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

  /// Create an instance of a probe based on its data type.
  ///
  /// This methods search this sampling package registry for a [SamplingPackage]
  /// which has a probe of the specified [type].
  ///
  /// Returns `null` if no probe is found for the specified [type].
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
