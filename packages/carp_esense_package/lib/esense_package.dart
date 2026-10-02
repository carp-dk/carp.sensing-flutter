/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'esense.dart';

/// The sampling package for the [eSense](https://www.esense.io) earable.
///
/// Collects button and motion sensor events from an eSense earable over
/// Bluetooth Low Energy (BLE), using the
/// [esense_flutter](https://pub.dev/packages/esense_flutter) plugin. Works on
/// Android and iOS and needs the [ESenseDevice] connected device, which is
/// handled by an [ESenseDeviceManager].
///
/// Measure types:
///  * `dk.cachet.carp.esense.button` ([ESENSE_BUTTON]): button pressed / released events.
///  * `dk.cachet.carp.esense.sensor` ([ESENSE_SENSOR]): accelerometer and gyroscope events.
///
/// Key points:
///  * Both measures are event-based and need no sampling configuration.
///  * Creates an [ESenseButtonProbe] or an [ESenseSensorProbe] for each measure.
///  * Registers [ESenseDevice], [ESenseButton] and [ESenseSensor] for JSON
///    deserialization, including the CAMS 1.x device type.
///
/// Example of a protocol that collects eSense data as soon as the study starts:
///
/// ```dart
///   final eSense = ESenseDevice(samplingRate: 10);
///   protocol.addConnectedDevice(eSense, phone);
///
///   protocol.addTaskControl(
///       ImmediateTrigger(),
///       BackgroundTask(measures: [
///         Measure(type: ESenseSamplingPackage.ESENSE_BUTTON),
///         Measure(type: ESenseSamplingPackage.ESENSE_SENSOR),
///       ]),
///       eSense);
/// ```
///
/// Register this package before running a study:
///
/// ```dart
///   SamplingPackageRegistry().register(ESenseSamplingPackage());
/// ```
class ESenseSamplingPackage implements SamplingPackage {
  /// The namespace of the eSense measure types, `dk.cachet.carp.esense`.
  static const String ESENSE_NAMESPACE = "${NameSpace.CARP}.esense";

  /// Measure type for continuous collection of eSense button events
  /// (pressed/released) as [ESenseButton] data.
  static const String ESENSE_BUTTON = "$ESENSE_NAMESPACE.button";

  /// Measure type for continuous collection of eSense sensor events
  /// (accelerometer and gyroscope) as [ESenseSensor] data.
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

    // Backwards compatibility with CAMS 1.x (protocol API level < 2.0) where
    // the eSense device used the carp_core device namespace.
    FromJsonFactory().register(
      ESenseDevice(),
      type: '${DeviceConfiguration.DEVICE_NAMESPACE}.ESenseDevice',
    );

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
