// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carp_polar_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolarAccelerometerSample _$PolarAccelerometerSampleFromJson(
  Map<String, dynamic> json,
) => PolarAccelerometerSample(
  timeStamp: DateTime.parse(json['timeStamp'] as String),
  x: (json['x'] as num).toInt(),
  y: (json['y'] as num).toInt(),
  z: (json['z'] as num).toInt(),
);

Map<String, dynamic> _$PolarAccelerometerSampleToJson(
  PolarAccelerometerSample instance,
) => <String, dynamic>{
  'timeStamp': instance.timeStamp.toIso8601String(),
  'x': instance.x,
  'y': instance.y,
  'z': instance.z,
};

PolarGyroscopeSample _$PolarGyroscopeSampleFromJson(
  Map<String, dynamic> json,
) => PolarGyroscopeSample(
  timeStamp: DateTime.parse(json['timeStamp'] as String),
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  z: (json['z'] as num).toDouble(),
);

Map<String, dynamic> _$PolarGyroscopeSampleToJson(
  PolarGyroscopeSample instance,
) => <String, dynamic>{
  'timeStamp': instance.timeStamp.toIso8601String(),
  'x': instance.x,
  'y': instance.y,
  'z': instance.z,
};

PolarMagnetometerSample _$PolarMagnetometerSampleFromJson(
  Map<String, dynamic> json,
) => PolarMagnetometerSample(
  timeStamp: DateTime.parse(json['timeStamp'] as String),
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  z: (json['z'] as num).toDouble(),
);

Map<String, dynamic> _$PolarMagnetometerSampleToJson(
  PolarMagnetometerSample instance,
) => <String, dynamic>{
  'timeStamp': instance.timeStamp.toIso8601String(),
  'x': instance.x,
  'y': instance.y,
  'z': instance.z,
};

PolarPPGSample _$PolarPPGSampleFromJson(Map<String, dynamic> json) =>
    PolarPPGSample(
      timeStamp: DateTime.parse(json['timeStamp'] as String),
      channelSamples: (json['channelSamples'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$PolarPPGSampleToJson(PolarPPGSample instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp.toIso8601String(),
      'channelSamples': instance.channelSamples,
    };

PolarPPISample _$PolarPPISampleFromJson(Map<String, dynamic> json) =>
    PolarPPISample(
      ppi: (json['ppi'] as num).toInt(),
      errorEstimate: (json['errorEstimate'] as num).toInt(),
      hr: (json['hr'] as num).toInt(),
      blockerBit: json['blockerBit'] as bool,
      skinContactStatus: json['skinContactStatus'] as bool,
      skinContactSupported: json['skinContactSupported'] as bool,
    );

Map<String, dynamic> _$PolarPPISampleToJson(PolarPPISample instance) =>
    <String, dynamic>{
      'ppi': instance.ppi,
      'errorEstimate': instance.errorEstimate,
      'hr': instance.hr,
      'blockerBit': instance.blockerBit,
      'skinContactStatus': instance.skinContactStatus,
      'skinContactSupported': instance.skinContactSupported,
    };

PolarHRSample _$PolarHRSampleFromJson(Map<String, dynamic> json) =>
    PolarHRSample(
      hr: (json['hr'] as num).toInt(),
      rrsMs: (json['rrsMs'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      contactStatus: json['contactStatus'] as bool,
      contactStatusSupported: json['contactStatusSupported'] as bool,
    );

Map<String, dynamic> _$PolarHRSampleToJson(PolarHRSample instance) =>
    <String, dynamic>{
      'hr': instance.hr,
      'rrsMs': instance.rrsMs,
      'contactStatus': instance.contactStatus,
      'contactStatusSupported': instance.contactStatusSupported,
    };

PolarECGSample _$PolarECGSampleFromJson(Map<String, dynamic> json) =>
    PolarECGSample(
      timeStamp: DateTime.parse(json['timeStamp'] as String),
      voltage: (json['voltage'] as num).toInt(),
    );

Map<String, dynamic> _$PolarECGSampleToJson(PolarECGSample instance) =>
    <String, dynamic>{
      'timeStamp': instance.timeStamp.toIso8601String(),
      'voltage': instance.voltage,
    };

PolarAccelerometer _$PolarAccelerometerFromJson(Map<String, dynamic> json) =>
    PolarAccelerometer(
        samples: (json['samples'] as List<dynamic>)
            .map(
              (e) =>
                  PolarAccelerometerSample.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$PolarAccelerometerToJson(PolarAccelerometer instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData,
      'samples': instance.samples,
    };

PolarGyroscope _$PolarGyroscopeFromJson(Map<String, dynamic> json) =>
    PolarGyroscope(
        samples: (json['samples'] as List<dynamic>)
            .map(
              (e) => PolarGyroscopeSample.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$PolarGyroscopeToJson(PolarGyroscope instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData,
      'samples': instance.samples,
    };

PolarMagnetometer _$PolarMagnetometerFromJson(Map<String, dynamic> json) =>
    PolarMagnetometer(
        samples: (json['samples'] as List<dynamic>)
            .map(
              (e) =>
                  PolarMagnetometerSample.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$PolarMagnetometerToJson(PolarMagnetometer instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData,
      'samples': instance.samples,
    };

PolarPPG _$PolarPPGFromJson(Map<String, dynamic> json) =>
    PolarPPG(
        type: $enumDecode(_$PpgDataTypeEnumMap, json['type']),
        samples: (json['samples'] as List<dynamic>)
            .map((e) => PolarPPGSample.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$PolarPPGToJson(PolarPPG instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData,
  'samples': instance.samples,
  'type': _$PpgDataTypeEnumMap[instance.type]!,
};

const _$PpgDataTypeEnumMap = {
  PpgDataType.ppg3_ambient1: 'ppg3_ambient1',
  PpgDataType.unknown: 'unknown',
};

PolarPPI _$PolarPPIFromJson(Map<String, dynamic> json) =>
    PolarPPI(
        samples: (json['samples'] as List<dynamic>)
            .map((e) => PolarPPISample.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$PolarPPIToJson(PolarPPI instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData,
  'samples': instance.samples,
};

PolarECG _$PolarECGFromJson(Map<String, dynamic> json) =>
    PolarECG(
        samples: (json['samples'] as List<dynamic>)
            .map((e) => PolarECGSample.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$PolarECGToJson(PolarECG instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData,
  'samples': instance.samples,
};

PolarHR _$PolarHRFromJson(Map<String, dynamic> json) =>
    PolarHR(
        samples: (json['samples'] as List<dynamic>)
            .map((e) => PolarHRSample.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$PolarHRToJson(PolarHR instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData,
  'samples': instance.samples,
};

PolarDevice _$PolarDeviceFromJson(Map<String, dynamic> json) =>
    PolarDevice(
        roleName: json['roleName'] as String? ?? PolarDevice.DEFAULT_ROLE_NAME,
        isOptional: json['isOptional'] as bool? ?? true,
        deviceType: $enumDecodeNullable(
          _$PolarDeviceTypeEnumMap,
          json['deviceType'],
        ),
        identifier: json['identifier'] as String?,
        name: json['name'] as String?,
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          )
      ..settings = json['settings'] == null
          ? null
          : PolarSensorSetting.fromJson(
              json['settings'] as Map<String, dynamic>,
            )
      ..address = json['address'] as String?
      ..rssi = (json['rssi'] as num?)?.toInt();

Map<String, dynamic> _$PolarDeviceToJson(PolarDevice instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration,
      'settings': ?instance.settings,
      'identifier': ?instance.identifier,
      'address': ?instance.address,
      'deviceType': ?_$PolarDeviceTypeEnumMap[instance.deviceType],
      'name': ?instance.name,
      'rssi': ?instance.rssi,
    };

const _$PolarDeviceTypeEnumMap = {
  PolarDeviceType.UNKNOWN: 'UNKNOWN',
  PolarDeviceType.H9: 'H9',
  PolarDeviceType.H10: 'H10',
  PolarDeviceType.SENSE: 'SENSE',
};
