/*
 * Copyright 2022 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_polar_package.dart';

// ------------------------------------------------------------------------
//               POLAR SAMPLES
// ------------------------------------------------------------------------

/// Base class for all Polar samples.
abstract class PolarSample {
  /// The timestamp when this sample was taken in microseconds.
  final DateTime timeStamp;

  PolarSample({required this.timeStamp});
}

/// Polar accelerometer sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarAccelerometerSample extends PolarSample {
  /// x axis value in milli-G (including gravity)
  final int x;

  /// y axis value in milli-G (including gravity)
  final int y;

  /// z axis value in milli-G (including gravity)
  final int z;

  PolarAccelerometerSample({
    required super.timeStamp,
    required this.x,
    required this.y,
    required this.z,
  });

  factory PolarAccelerometerSample.fromJson(Map<String, dynamic> json) =>
      _$PolarAccelerometerSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PolarAccelerometerSampleToJson(this);
}

/// Polar gyroscope sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarGyroscopeSample extends PolarSample {
  /// x axis value in deg/sec
  final double x;

  /// y axis value in deg/sec
  final double y;

  /// z axis value in deg/sec
  final double z;

  PolarGyroscopeSample({
    required super.timeStamp,
    required this.x,
    required this.y,
    required this.z,
  });

  factory PolarGyroscopeSample.fromJson(Map<String, dynamic> json) =>
      _$PolarGyroscopeSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PolarGyroscopeSampleToJson(this);
}

/// Polar magnetometer sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarMagnetometerSample extends PolarSample {
  /// x axis value in Gauss
  final double x;

  /// y axis value in Gauss
  final double y;

  /// z axis value in Gauss
  final double z;

  PolarMagnetometerSample({
    required super.timeStamp,
    required this.x,
    required this.y,
    required this.z,
  });

  factory PolarMagnetometerSample.fromJson(Map<String, dynamic> json) =>
      _$PolarMagnetometerSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PolarMagnetometerSampleToJson(this);
}

/// Polar PPG (Photoplethysmography) sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarPPGSample extends PolarSample {
  /// The PPG (Photoplethysmography) raw value received from the optical sensor.
  /// Based on [PpgDataType] the amount of channels varies. Typically ppg(n)
  /// channel + n ambient(s).
  final List<int> channelSamples;

  /// Constructor
  PolarPPGSample({required super.timeStamp, required this.channelSamples});

  factory PolarPPGSample.fromJson(Map<String, dynamic> json) =>
      _$PolarPPGSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PolarPPGSampleToJson(this);
}

/// Polar optical heart rate (OHR) pulse-to-pulse interval (PPI) sample.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarPPISample {
  /// Pulse-to-pulse interval (PPI) in milliseconds.
  final int ppi;

  /// Estimate of the expected absolute error in [ppi] in milliseconds.
  ///
  /// The value indicates the quality of the measured [ppi].
  /// When error estimate is below 10ms [ppi] readings are probably very accurate.
  /// Error estimate values over 30ms may be caused by movement artefact or too
  /// loose sensor-skin contact. See [skinContactStatus].
  final int errorEstimate;

  /// Heart rate (HR) in beats pr. minute (BPM).
  final int hr;

  /// True if PPI measurement was invalid due to acceleration or other reasons.
  final bool blockerBit;

  /// False if the device detects poor or no contact with the skin.
  final bool skinContactStatus;

  /// True if the Sensor Contact feature is supported.
  final bool skinContactSupported;

  PolarPPISample({
    required this.ppi,
    required this.errorEstimate,
    required this.hr,
    required this.blockerBit,
    required this.skinContactStatus,
    required this.skinContactSupported,
  });

  factory PolarPPISample.fromJson(Map<String, dynamic> json) =>
      _$PolarPPISampleFromJson(json);
  Map<String, dynamic> toJson() => _$PolarPPISampleToJson(this);
}

/// Polar heart rate (HR) sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarHRSample {
  /// Heart rate (HR) in BPM
  final int hr;

  /// RR interval in ms.
  final List<int> rrsMs;

  /// True if there is contact between the device and the user's skin.
  final bool contactStatus;

  /// True contact detection is supported on the device.
  final bool contactStatusSupported;

  PolarHRSample({
    required this.hr,
    required this.rrsMs,
    required this.contactStatus,
    required this.contactStatusSupported,
  });

  factory PolarHRSample.fromJson(Map<String, dynamic> json) =>
      _$PolarHRSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PolarHRSampleToJson(this);
}

/// Polar ECG sample
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarECGSample extends PolarSample {
  /// Voltage value in µVolts
  final int voltage;

  PolarECGSample({required super.timeStamp, required this.voltage});

  factory PolarECGSample.fromJson(Map<String, dynamic> json) =>
      _$PolarECGSampleFromJson(json);
  Map<String, dynamic> toJson() => _$PolarECGSampleToJson(this);
}

// ------------------------------------------------------------------------
//               POLAR => CARP SENSOR DATA
// ------------------------------------------------------------------------

class PolarSamples<T> extends SensorData {
  /// Samples
  final List<T> samples;

  PolarSamples({required this.samples});
}

/// Polar accelerometer data.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarAccelerometer extends PolarSamples<PolarAccelerometerSample> {
  PolarAccelerometer({required super.samples});

  /// Create a [PolarAccelerometer] based on the original Polar device
  /// [PolarAccData] sampling.
  PolarAccelerometer.fromPolarData(PolarAccData data)
    : this(
        samples: data.samples
            .map(
              (sample) => PolarAccelerometerSample(
                timeStamp: sample.timeStamp,
                x: sample.x,
                y: sample.y,
                z: sample.z,
              ),
            )
            .toList(),
      );

  @override
  Function get fromJsonFunction => _$PolarAccelerometerFromJson;
  factory PolarAccelerometer.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarAccelerometer;
  @override
  Map<String, dynamic> toJson() => _$PolarAccelerometerToJson(this);

  @override
  String get jsonType => PolarSamplingPackage.ACCELEROMETER;
}

/// Polar gyroscope data.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarGyroscope extends PolarSamples<PolarGyroscopeSample> {
  PolarGyroscope({required super.samples});

  /// Create a [PolarGyroscope] based on the original Polar device
  /// [PolarGyroData] sampling.
  PolarGyroscope.fromPolarData(PolarGyroData data)
    : this(
        samples: data.samples
            .map(
              (sample) => PolarGyroscopeSample(
                timeStamp: sample.timeStamp,
                x: sample.x,
                y: sample.y,
                z: sample.z,
              ),
            )
            .toList(),
      );

  @override
  Function get fromJsonFunction => _$PolarGyroscopeFromJson;
  factory PolarGyroscope.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarGyroscope;
  @override
  Map<String, dynamic> toJson() => _$PolarGyroscopeToJson(this);

  @override
  String get jsonType => PolarSamplingPackage.GYROSCOPE;
}

/// Polar magnetometer data.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarMagnetometer extends PolarSamples<PolarMagnetometerSample> {
  PolarMagnetometer({required super.samples});

  /// Create a [PolarMagnetometer] based on the original Polar device
  /// [PolarMagnetometerData] sampling.
  PolarMagnetometer.fromPolarData(PolarMagnetometerData data)
    : this(
        samples: data.samples
            .map(
              (sample) => PolarMagnetometerSample(
                timeStamp: sample.timeStamp,
                x: sample.x,
                y: sample.y,
                z: sample.z,
              ),
            )
            .toList(),
      );

  @override
  Function get fromJsonFunction => _$PolarMagnetometerFromJson;
  factory PolarMagnetometer.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarMagnetometer;
  @override
  Map<String, dynamic> toJson() => _$PolarMagnetometerToJson(this);

  @override
  String get jsonType => PolarSamplingPackage.MAGNETOMETER;
}

/// Polar optical heart rate (OHR) photoplethysmograpy (PPG) data.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarPPG extends PolarSamples<PolarPPGSample> {
  /// Type of OHR data.
  ///
  /// Varies based on what is type of optical sensor used in the device.
  PpgDataType type;

  PolarPPG({required this.type, required super.samples});

  /// Create a [PolarPPG] based on the original [PolarPpgData] reading.
  PolarPPG.fromPolarData(PolarPpgData data)
    : this(
        type: data.type,
        samples: data.samples
            .map(
              (sample) => PolarPPGSample(
                timeStamp: sample.timeStamp,
                channelSamples: sample.channelSamples,
              ),
            )
            .toList(),
      );

  @override
  Function get fromJsonFunction => _$PolarPPGFromJson;
  factory PolarPPG.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarPPG;
  @override
  Map<String, dynamic> toJson() => _$PolarPPGToJson(this);

  @override
  String get jsonType => PolarSamplingPackage.PPG;
}

/// Polar PP interval (PPI) in milliseconds.
/// Represents cardiac pulse-to-pulse interval extracted from PPG signal.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarPPI extends PolarSamples<PolarPPISample> {
  PolarPPI({required super.samples});

  /// Create a [PolarPPI] based on the original [PolarPpiData] reading.
  PolarPPI.fromPolarData(PolarPpiData data)
    : this(
        samples: data.samples
            .map(
              (sample) => PolarPPISample(
                ppi: sample.ppi,
                hr: sample.hr,
                errorEstimate: sample.errorEstimate,
                blockerBit: sample.blockerBit,
                skinContactSupported: sample.skinContactSupported,
                skinContactStatus: sample.skinContactStatus,
              ),
            )
            .toList(),
      );

  @override
  Function get fromJsonFunction => _$PolarPPIFromJson;
  factory PolarPPI.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarPPI;
  @override
  Map<String, dynamic> toJson() => _$PolarPPIToJson(this);

  @override
  String get jsonType => PolarSamplingPackage.PPI;
}

/// Polar ECG data.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarECG extends PolarSamples<PolarECGSample> {
  PolarECG({required super.samples});

  /// Create a [PolarECG] based on the original [PolarEcgData] reading.
  PolarECG.fromPolarData(PolarEcgData data)
    : this(
        samples: data.samples
            .map(
              (sample) => PolarECGSample(
                timeStamp: sample.timeStamp,
                voltage: sample.voltage,
              ),
            )
            .toList(),
      );

  @override
  Function get fromJsonFunction => _$PolarECGFromJson;
  factory PolarECG.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarECG;
  @override
  Map<String, dynamic> toJson() => _$PolarECGToJson(this);

  @override
  String get jsonType => PolarSamplingPackage.ECG;
}

/// Polar heart rate (HR).
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class PolarHR extends PolarSamples<PolarHRSample> {
  PolarHR({required super.samples});

  /// Create a [PolarHR] based on the original [PolarHrData] reading.
  PolarHR.fromPolarData(PolarHrData data)
    : this(
        samples: data.samples
            .map(
              (sample) => PolarHRSample(
                hr: sample.hr,
                rrsMs: sample.rrsMs,
                contactStatusSupported: sample.contactStatusSupported,
                contactStatus: sample.contactStatus,
              ),
            )
            .toList(),
      );

  @override
  Function get fromJsonFunction => _$PolarHRFromJson;
  factory PolarHR.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson(json) as PolarHR;
  @override
  Map<String, dynamic> toJson() => _$PolarHRToJson(this);
  @override
  String get jsonType => PolarSamplingPackage.HR;
}
