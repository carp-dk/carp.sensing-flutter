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
  final List<Permission> _permissions = [];
  DataTypeSamplingSchemeMap? _combinedSchemas;

  static final SamplingPackageRegistry _instance = SamplingPackageRegistry._();

  /// Get the singleton [SamplingPackageRegistry].
  factory SamplingPackageRegistry() => _instance;

  /// A list of registered packages.
  List<SamplingPackage> get packages => _packages;

  /// The list of [Permission]s needed for **all** packages (combined list).
  List<Permission> get permissions => _permissions;

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
    // for (var permission in package.permissions) {
    //   if (!_permissions.contains(permission)) _permissions.add(permission);
    // }
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

/// Interface for a sampling package.
///
/// A sampling package provides information on:
///  * [dataTypes] - the data types supported
///  * [samplingSchemes] - the default [DataTypeSamplingSchemeMap] containing
///     a set of [SamplingConfiguration]s for each data type.
///  * [deviceType] - what type of device this package supports
///  * [permissions] - a list of [Permission]s needed for this package
///
/// It also contains factory methods for:
///  * creating a [Probe] based on a [Measure] type
///  * getting a [DeviceManager] for the [deviceType]
abstract class SamplingPackage {
  /// The list of data type this package supports.
  List<DataTypeMetaData> get dataTypes;

  /// The default sampling schemes for all [dataTypes] in this package.
  ///
  /// All sampling packages should defined a [DataTypeSamplingScheme] for each
  /// data type.
  DataTypeSamplingSchemeMap get samplingSchemes;

  /// Creates a new [Probe] of the specified [type].
  /// Note that [type] should be one of the [dataTypes] that this package supports.
  /// Returns null if a probe cannot be created for the [type].
  Probe? create(String type);

  /// What device type is this package using?
  ///
  /// This device type is matched with the [DeviceConfiguration.roleName] when a
  /// [PrimaryDeviceConfiguration] is deployed on the phone and executed by a
  /// [SmartphoneStudyController].
  ///
  /// Note that it is assumed that a sampling package only supports **one**
  /// type of device.
  String get deviceType;

  /// Get the [DeviceManager] for the device used by this package.
  DeviceManager get deviceManager;

  /// Callback method when this package is being registered.
  void onRegister();
}

/// An abstract class for all sampling packages that run on the phone itself.
///
/// Note that the default implementation of [permissions] and [onRegister] are
/// no-op operations and should hence be overridden in subclasses, if needed.
abstract class SmartphoneSamplingPackage extends SamplingPackage {
  // all smartphone sampling packages uses the same static device manager
  static final _deviceManager = SmartphoneDeviceManager();

  @override
  List<DataTypeMetaData> get dataTypes => samplingSchemes.dataTypes;

  @override
  String get deviceType => _deviceManager.deviceType;

  @override
  DeviceManager get deviceManager => _deviceManager;

  @override
  void onRegister() {}
}

class NoOpSamplingPackage extends SmartphoneSamplingPackage {
  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.ERROR_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.TRIGGERED_TASK_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.COMPLETED_TASK_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CamsDataTypes.HEARTBEAT_TYPE_NAME]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CamsDataTypes.COMPLETED_APP_TASK_TYPE_NAME]!,
        ),
      ]);

  @override
  Probe? create(String type) => null;
}
