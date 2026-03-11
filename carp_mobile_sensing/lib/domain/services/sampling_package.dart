part of '../../domain.dart';

/// Interface for a sampling package.
///
/// A sampling package provides information on:
///  * [dataTypes] - the data types supported
///  * [samplingSchemes] - the default [DataTypeSamplingSchemeMap] containing
///     a set of [SamplingConfiguration]s for each data type.
///  * [deviceType] - what type of device this package supports
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

/// A [SamplingPackage] containing data types, sampling schemas and probes
/// for monitoring data sampling:
///
///  - errors
///  - task triggering
///  - task completion, including [AppTask] completion
class MonitoringSamplingPackage extends SmartphoneSamplingPackage {
  /// Collect errors occurring during data collection
  static const String ERROR = CarpDataTypes.ERROR;

  /// Collect data on a triggered [TaskConfiguration].
  static const String TRIGGERED_TASK = CarpDataTypes.TRIGGERED_TASK;

  /// Collect data whenever any [TaskConfiguration] has been completed.
  static const String COMPLETED_TASK = CarpDataTypes.COMPLETED_TASK;

  /// Collect data whenever an [AppTask] has been completed.
  static const String COMPLETED_APP_TASK = CamsDataTypes.COMPLETED_APP_TASK;

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(CarpDataTypes().types[CarpDataTypes.ERROR]!),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.TRIGGERED_TASK]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CarpDataTypes.COMPLETED_TASK]!,
        ),
        DataTypeSamplingScheme(
          CarpDataTypes().types[CamsDataTypes.COMPLETED_APP_TASK]!,
        ),
      ]);

  @override
  Probe? create(String type) => StubProbe(); // No probes created - these types of measures are handled in the core sampling logic
}
