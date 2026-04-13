/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

// Identifiers for CACHET test devices:
//  * SENSE : B36B5B21 [03813-21-03667]
//  * H10   : B5FC172F [00634-17-03667]

/// A [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing)
/// sampling package for collecting data from the Polar H10, H9, and Polar Verity
/// Sense optical heart rate sensors as follows.
///
/// **H10 Heart rate sensor**
///
///  * Heart rate as beats per minute. RR Interval in ms and 1/1024 format.
///  * Electrocardiography (ECG) data in µV with sample rate 130Hz. Default epoch for timestamp is 1.1.2000.
///  * Accelerometer data with sample rates of 25Hz, 50Hz, 100Hz and 200Hz and range of 2G, 4G and 8G. Axis specific acceleration data in mG. Default epoch for timestamp is 1.1.2000
///  * Start and stop of internal recording and request for internal recording status. Recording supports RR, HR with one second sample time or HR with five second sample time.
///
/// **Polar Verity Sense optical heart rate sensor**
///
///  * Heart rate (HR) as beats per minute.
///  * Photoplethysmograpy (PPG) values with a sampling rate of 55Hz (see [Polar SDK issue #202](https://github.com/polarofficial/polar-ble-sdk/issues/202#issuecomment-940645360)).
///  * PP interval (milliseconds) representing cardiac pulse-to-pulse interval extracted from PPG signal.
///  * Accelerometer data with sample rate of 52Hz and range of 8G. Axis specific acceleration data in mG.
///  * Gyroscope data with sample rate of 52Hz and ranges of 250dps, 500dps, 1000dps and 2000dps. Axis specific gyroscope data in dps.
///  * Magnetometer data with sample rates of 10Hz, 20Hz, 50HZ and 100Hz and range of +/-50 Gauss. Axis specific magnetometer data in Gauss.
///
/// **H9 Heart rate sensor**
///
///  * Heart rate as beats per minute. RR Interval in ms and 1/1024 format.
///  * Heart rate broadcast.
///
/// This package uses the [polar](https://pub.dev/packages?q=polar) Flutter plugin,
/// which again builds upon the [official Polar SDK](https://github.com/polarofficial/polar-ble-sdk).
/// Please consult the Polar [technical documentation](https://github.com/polarofficial/polar-ble-sdk/tree/master/technical_documentation)
/// on the details on how to interpret the collected data.
library;

import 'dart:async';
import 'package:json_annotation/json_annotation.dart';
import 'package:polar/polar.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone, BLEHeartRateDevice;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'polar_data.dart';
part 'polar_probes.dart';
part "carp_polar_package.g.dart";
part 'polar_device_manager.dart';

/// The Polar sampling package supporting the following measures (depending on the
/// type of Polar device used):
///
///  * dk.cachet.carp.polar.accelerometer
///  * dk.cachet.carp.polar.gyroscope
///  * dk.cachet.carp.polar.magnetometer
///  * dk.cachet.carp.polar.ecg
///  * dk.cachet.carp.polar.ppi
///  * dk.cachet.carp.polar.ppg
///  * dk.cachet.carp.polar.hr
///
/// All measure types are continuos collection of Polar data from a Polar device,
/// which are:
///
///  * Event-based measures.
///  * Uses the [PolarDevice] connected device for data collection.
///  * No sampling configuration needed.
///
/// An example of a study protocol configuration is:
///
/// ```dart
///   // Create a Polar H10 heart rate sensor.
///   var polar = PolarDevice(
///     roleName: 'hr-sensor',
///     identifier: '1C709B20',
///     name: 'H10',
///     polarDeviceType: PolarDeviceType.H10,
///   );
///
///   // Add a background task that immediately starts collecting Polar HR and
///   // ECG data from the Polar device.
///   protocol.addTaskControl(
///      ImmediateTrigger(),
///      BackgroundTask(measures: [
///        Measure(type: PolarSamplingPackage.HR),
///        Measure(type: PolarSamplingPackage.ECG),
///      ]),
///      polar);
/// ```
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry.register(PolarSamplingPackage());
/// ```
class PolarSamplingPackage implements SamplingPackage {
  static const String POLAR_NAMESPACE = "${NameSpace.CARP}.polar";

  static const String ACCELEROMETER = "$POLAR_NAMESPACE.accelerometer";
  static const String GYROSCOPE = "$POLAR_NAMESPACE.gyroscope";
  static const String MAGNETOMETER = "$POLAR_NAMESPACE.magnetometer";
  static const String PPG = "$POLAR_NAMESPACE.ppg";
  static const String PPI = "$POLAR_NAMESPACE.ppi";
  static const String ECG = "$POLAR_NAMESPACE.ecg";
  static const String HR = "$POLAR_NAMESPACE.hr";

  final DeviceManager _deviceManager = PolarDeviceManager(
    PolarDevice.DEVICE_TYPE,
  );

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ACCELEROMETER,
            displayName: "Accelerometer",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: GYROSCOPE,
            displayName: "Gyroscope",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: MAGNETOMETER,
            displayName: "Magnetometer",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: ECG,
            displayName: "Electrocardiography (ECG)",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: PPI,
            displayName: "Peak-to-Peak Interval (PPI)",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: PPG,
            displayName: "Photoplethysmograpy (PPG)",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: HR,
            displayName: "Heart Rate (HR)",
            timeType: DataTimeType.POINT,
          ),
        ),
      ]);

  @override
  List<DataTypeMetaData> get dataTypes => samplingSchemes.dataTypes;

  @override
  void onRegister() {
    // register all data types
    FromJsonFactory().registerAll([
      PolarDevice(),
      PolarDeviceRegistration(
        identifier: '',
        bleAddress: '',
        polarDeviceType: PolarDeviceType.H10,
      ),
      PolarAccelerometer(samples: []),
      PolarGyroscope(samples: []),
      PolarMagnetometer(samples: []),
      PolarECG(samples: []),
      PolarPPG(type: PpgDataType.unknown, samples: []),
      PolarPPI(samples: []),
      PolarHR(samples: []),
    ]);
  }

  @override
  String get deviceType => PolarDevice.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;

  @override
  Probe? create(String type) {
    switch (type) {
      case ACCELEROMETER:
        return PolarAccelerometerProbe();
      case GYROSCOPE:
        return PolarGyroscopeProbe();
      case MAGNETOMETER:
        return PolarMagnetometerProbe();
      case ECG:
        return PolarECGProbe();
      case PPI:
        return PolarPPIProbe();
      case PPG:
        return PolarPPGProbe();
      case HR:
        return PolarHRProbe();
      default:
        return null;
    }
  }
}
