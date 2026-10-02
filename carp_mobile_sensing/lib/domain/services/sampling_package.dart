part of '../../domain.dart';

/// A plug-in that adds a set of measure types, and the probes that collect
/// them, to CAMS.
///
/// Each sampling package covers one type of device (the phone, a wearable, a
/// service) and is registered in the [SamplingPackageRegistry] at app start.
/// When a study runs, CAMS asks the package that supports a [Measure] type to
/// [create] a [Probe] for it.
///
/// A sampling package provides:
///  * [dataTypes] - the data types (measure types) it supports.
///  * [samplingSchemes] - the default [SamplingConfiguration] of each data type.
///  * [deviceType] and [deviceManager] - the device it collects data from.
///  * [create] - a factory for [Probe]s.
///
/// ```dart
/// // Register a sampling package before using its measures in a protocol.
/// SamplingPackageRegistry().register(ContextSamplingPackage());
/// ```
///
/// See also [SmartphoneSamplingPackage], the base for packages that collect
/// data from the phone itself.
abstract class SamplingPackage {
  /// The data types this package supports.
  List<DataTypeMetaData> get dataTypes;

  /// The default sampling schemes for all [dataTypes] in this package.
  ///
  /// All sampling packages should define a [DataTypeSamplingScheme] for each
  /// data type.
  DataTypeSamplingSchemeMap get samplingSchemes;

  /// Creates a new [Probe] of the specified [type].
  /// Note that [type] should be one of the [dataTypes] that this package supports.
  /// Returns null if a probe cannot be created for the [type].
  Probe? create(String type);

  /// The type of device this package collects data from.
  ///
  /// On registration, [deviceManager] is registered in the [DeviceController]
  /// under this type, which is matched with the devices in a deployment.
  ///
  /// Note that it is assumed that a sampling package only supports **one**
  /// type of device.
  String get deviceType;

  /// Get the [DeviceManager] for the device used by this package.
  DeviceManager get deviceManager;

  /// Called when this package is registered in the [SamplingPackageRegistry].
  ///
  /// Use it to register JSON deserialization functions and data transformers.
  void onRegister();
}

/// Base class for sampling packages that collect data from the phone itself.
///
/// All of them share one [SmartphoneDeviceManager]. [dataTypes] is derived
/// from [samplingSchemes], and [onRegister] does nothing; override it if needed.
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

/// The built-in [SamplingPackage] that monitors data sampling itself.
///
/// Its measure types are:
///  * [ERROR] - errors during data collection.
///  * [TRIGGERED_TASK] - a task was triggered.
///  * [COMPLETED_TASK] - a task was completed.
///  * [COMPLETED_APP_TASK] - an [AppTask] was completed.
///
/// These are collected by the CAMS runtime, not by a probe, so [create]
/// returns a [StubProbe]. [SmartphoneStudyProtocol] adds the first three to
/// each device automatically.
class MonitoringSamplingPackage extends SmartphoneSamplingPackage {
  /// Collect errors occurring during data collection.
  static const String ERROR = CarpDataTypes.ERROR;

  /// Collect data on a triggered [TaskConfiguration].
  static const String TRIGGERED_TASK = CarpDataTypes.TRIGGERED_TASK;

  /// Collect data whenever any [TaskConfiguration] has been completed.
  static const String COMPLETED_TASK = CarpDataTypes.COMPLETED_TASK;

  /// Collect data whenever an [AppTask] has been completed.
  static const String COMPLETED_APP_TASK = CamsDataTypes.COMPLETED_APP_TASK;

  @override
  DataTypeSamplingSchemeMap get samplingSchemes => DataTypeSamplingSchemeMap.from([
    DataTypeSamplingScheme(CarpDataTypes().types[CarpDataTypes.ERROR]!),
    DataTypeSamplingScheme(CarpDataTypes().types[CarpDataTypes.TRIGGERED_TASK]!),
    DataTypeSamplingScheme(CarpDataTypes().types[CarpDataTypes.COMPLETED_TASK]!),
    DataTypeSamplingScheme(CarpDataTypes().types[CamsDataTypes.COMPLETED_APP_TASK]!),
  ]);

  @override
  Probe? create(String type) => StubProbe(); // No probes created - these types of measures are handled in the core sampling logic
}
