/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

// Identifiers for CACHET test devices:
//  * SENSE : B36B5B21 [03813-21-03667]
//  * H10   : B5FC172F [00634-17-03667]

/// A [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing)
/// sampling package that collects data from Polar H10, H9 and Verity Sense
/// heart rate sensors over Bluetooth Low Energy (BLE).
///
/// Register [PolarSamplingPackage] in the [SamplingPackageRegistry], add a
/// [PolarDevice] as a connected device to the protocol, and add measures of
/// the types below to a task that runs on that device.
///
/// Measure types (namespace `dk.cachet.carp.polar`):
///  * `dk.cachet.carp.polar.hr` : heart rate and RR intervals ([PolarHR]).
///  * `dk.cachet.carp.polar.ecg` : electrocardiogram (ECG) ([PolarECG]).
///  * `dk.cachet.carp.polar.accelerometer` : accelerometer ([PolarAccelerometer]).
///  * `dk.cachet.carp.polar.gyroscope` : gyroscope ([PolarGyroscope]).
///  * `dk.cachet.carp.polar.magnetometer` : magnetometer ([PolarMagnetometer]).
///  * `dk.cachet.carp.polar.ppg` : photoplethysmography (PPG) ([PolarPPG]).
///  * `dk.cachet.carp.polar.ppi` : pulse-to-pulse interval (PPI) ([PolarPPI]).
///
/// Platforms: Android and iOS (iOS 14 or later).
///
/// What each device supports:
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
///  * Photoplethysmography (PPG) values with a sampling rate of 55Hz (see [Polar SDK issue #202](https://github.com/polarofficial/polar-ble-sdk/issues/202#issuecomment-940645360)).
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
/// This package uses the [polar](https://pub.dev/packages/polar) Flutter plugin,
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

/// The sampling package for Polar devices.
///
/// It tells CARP Mobile Sensing which measure types a Polar device provides,
/// which [Probe] collects each of them, and which [PolarDeviceManager]
/// handles the connection to the device. Register it once, before a study
/// is deployed.
///
/// Key points:
///  * All measures run on a [PolarDevice] connected device, not on the phone.
///  * All measures are event-based and need no sampling configuration.
///  * Which measures work depends on the Polar device. A probe only starts if
///    the connected device reports the matching [PolarDataType] in
///    [PolarDeviceManager.dataTypes].
///  * [onRegister] registers the device and data types for JSON
///    deserialization, including the CAMS 1.x device type name.
///
/// ```dart
/// SamplingPackageRegistry().register(PolarSamplingPackage());
/// var polar = PolarDevice(roleName: 'hr-sensor');
/// protocol.addConnectedDevice(polar, phone);
/// protocol.addTaskControl(
///   ImmediateTrigger(),
///   BackgroundTask(measures: [Measure(type: PolarSamplingPackage.HR)]),
///   polar,
/// );
/// ```
///
/// See also [SamplingPackage], which this implements.
class PolarSamplingPackage implements SamplingPackage {
  /// The namespace of all Polar measure types.
  static const String POLAR_NAMESPACE = "${NameSpace.CARP}.polar";

  /// Measure type for accelerometer data ([PolarAccelerometer]).
  static const String ACCELEROMETER = "$POLAR_NAMESPACE.accelerometer";

  /// Measure type for gyroscope data ([PolarGyroscope]).
  static const String GYROSCOPE = "$POLAR_NAMESPACE.gyroscope";

  /// Measure type for magnetometer data ([PolarMagnetometer]).
  static const String MAGNETOMETER = "$POLAR_NAMESPACE.magnetometer";

  /// Measure type for photoplethysmography data ([PolarPPG]).
  static const String PPG = "$POLAR_NAMESPACE.ppg";

  /// Measure type for pulse-to-pulse intervals ([PolarPPI]).
  static const String PPI = "$POLAR_NAMESPACE.ppi";

  /// Measure type for ECG data ([PolarECG]).
  static const String ECG = "$POLAR_NAMESPACE.ecg";

  /// Measure type for heart rate data ([PolarHR]).
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

    // Backwards compatibility with CAMS 1.x (protocol API level < 2.0) where
    // the Polar device used the carp_core device namespace.
    FromJsonFactory().register(
      PolarDevice(),
      type: '${DeviceConfiguration.DEVICE_NAMESPACE}.PolarDevice',
    );
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
