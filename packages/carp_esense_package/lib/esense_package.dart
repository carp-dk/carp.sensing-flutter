/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'esense.dart';

/// A sampling package for collecting context information from the
/// [eSense](http://www.esense.io) device supporting the following measures:
///
///  * dk.cachet.carp.esense.button
///  * dk.cachet.carp.esense.sensor
///
/// Both measure types are continuous collection of eSense data from an eSense
/// device, which are:
///
///  * Event-based measure.
///  * Uses the [ESenseDevice] connected device for data collection.
///  * No sampling configuration needed.
///
/// An example of a study protocol configuration might be:
///
/// ```dart
///   // Add a background task that immediately starts collecting eSense button
///   // and sensor events from the eSense device.
///   protocol.addTriggeredTask(
///       ImmediateTrigger(),
///       BackgroundTask()
///         ..addMeasure(Measure(type: ESenseSamplingPackage.ESENSE_BUTTON))
///         ..addMeasure(Measure(type: ESenseSamplingPackage.ESENSE_SENSOR)),
///       eSense);
/// ```
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry.register(ESenseSamplingPackage());
/// ```
class ESenseSamplingPackage implements SamplingPackage {
  static const String ESENSE_NAMESPACE = "${NameSpace.CARP}.esense";

  /// Measure type for continuous collection of eSense button events (pressed/released).
  static const String ESENSE_BUTTON = "$ESENSE_NAMESPACE.button";

  /// Measure type for continuous collection of eSense sensor events
  /// (accelerometer & gyroscope).
  static const String ESENSE_SENSOR = "$ESENSE_NAMESPACE.sensor";

  final DeviceManager _deviceManager = ESenseDeviceManager(
    ESenseDevice.DEVICE_TYPE,
  );

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ESENSE_BUTTON,
            displayName: "eSense Button Events",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ESENSE_SENSOR,
            displayName: "eSense Movement Events",
            timeType: DataTimeType.TIME_SPAN,
          ),
        ),
      ]);

  @override
  List<DataTypeMetaData> get dataTypes => samplingSchemes.dataTypes;

  @override
  Probe? create(String type) => switch (type) {
    ESENSE_BUTTON => ESenseButtonProbe(),
    ESENSE_SENSOR => ESenseSensorProbe(),
    _ => null,
  };

  @override
  void onRegister() {
    FromJsonFactory().registerAll([
      ESenseDevice(),
      BLEDeviceRegistration(bleAddress: ''),
    ]);

    // register all data types
    FromJsonFactory().registerAll([
      ESenseButton(deviceName: 'deviceName', pressed: true),
      ESenseSensor(deviceName: 'deviceName'),
    ]);
  }

  @override
  String get deviceType => ESenseDevice.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;
}
