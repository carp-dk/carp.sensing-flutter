// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carp_movesense_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovesenseDeviceInformation _$MovesenseDeviceInformationFromJson(
  Map<String, dynamic> json,
) =>
    MovesenseDeviceInformation(
        json['manufacturerName'] as String?,
        json['brandName'] as String?,
        json['productName'] as String?,
        json['variant'] as String?,
        json['design'] as String?,
        json['hardwareCompatibilityId'] as String?,
        json['serial'] as String?,
        json['pcbaSerial'] as String?,
        json['softwareVersion'] as String?,
        json['hardwareType'] as String?,
        json['additionalVersionInfo'] as String?,
        json['apiLevel'] as String?,
        json['address'] as String?,
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$MovesenseDeviceInformationToJson(
  MovesenseDeviceInformation instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData,
  'manufacturerName': ?instance.manufacturerName,
  'brandName': ?instance.brandName,
  'productName': ?instance.productName,
  'variant': ?instance.variant,
  'design': ?instance.design,
  'hardwareCompatibilityId': ?instance.hardwareCompatibilityId,
  'serial': ?instance.serial,
  'pcbaSerial': ?instance.pcbaSerial,
  'softwareVersion': ?instance.softwareVersion,
  'hardwareType': ?instance.hardwareType,
  'additionalVersionInfo': ?instance.additionalVersionInfo,
  'apiLevel': ?instance.apiLevel,
  'address': ?instance.address,
};

MovesenseStateChange _$MovesenseStateChangeFromJson(
  Map<String, dynamic> json,
) =>
    MovesenseStateChange(
        $enumDecode(_$MovesenseDeviceStateEnumMap, json['state']),
        (json['timestamp'] as num?)?.toInt(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$MovesenseStateChangeToJson(
  MovesenseStateChange instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData,
  'state': _$MovesenseDeviceStateEnumMap[instance.state]!,
  'timestamp': instance.timestamp,
};

const _$MovesenseDeviceStateEnumMap = {
  MovesenseDeviceState.unknown: 'unknown',
  MovesenseDeviceState.moving: 'moving',
  MovesenseDeviceState.notMoving: 'notMoving',
  MovesenseDeviceState.connected: 'connected',
  MovesenseDeviceState.disconnected: 'disconnected',
  MovesenseDeviceState.tap: 'tap',
  MovesenseDeviceState.doubleTap: 'doubleTap',
  MovesenseDeviceState.acceleration: 'acceleration',
  MovesenseDeviceState.freeFall: 'freeFall',
};

MovesenseHR _$MovesenseHRFromJson(Map<String, dynamic> json) =>
    MovesenseHR((json['hr'] as num).toDouble(), (json['rr'] as num?)?.toInt())
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$MovesenseHRToJson(MovesenseHR instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData,
      'hr': instance.hr,
      'rr': ?instance.rr,
    };

MovesenseECG _$MovesenseECGFromJson(Map<String, dynamic> json) =>
    MovesenseECG(
        (json['timestamp'] as num).toInt(),
        (json['samples'] as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$MovesenseECGToJson(MovesenseECG instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData,
      'timestamp': instance.timestamp,
      'samples': instance.samples,
    };

MovesenseTemperature _$MovesenseTemperatureFromJson(
  Map<String, dynamic> json,
) =>
    MovesenseTemperature(
        (json['timestamp'] as num).toInt(),
        (json['measurement'] as num).toInt(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$MovesenseTemperatureToJson(
  MovesenseTemperature instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'sensorSpecificData': ?instance.sensorSpecificData,
  'timestamp': instance.timestamp,
  'measurement': instance.measurement,
};

MovesenseIMU _$MovesenseIMUFromJson(Map<String, dynamic> json) =>
    MovesenseIMU(
        (json['timestamp'] as num).toInt(),
        (json['accelerometer'] as List<dynamic>)
            .map(
              (e) => MovesenseAccelerometerSample.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
        (json['gyroscope'] as List<dynamic>)
            .map(
              (e) =>
                  MovesenseGyroscopeSample.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        (json['magnetometer'] as List<dynamic>)
            .map(
              (e) => MovesenseMagnetometerSample.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      )
      ..$type = json['__type'] as String?
      ..sensorSpecificData = json['sensorSpecificData'] == null
          ? null
          : Data.fromJson(json['sensorSpecificData'] as Map<String, dynamic>);

Map<String, dynamic> _$MovesenseIMUToJson(MovesenseIMU instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'sensorSpecificData': ?instance.sensorSpecificData,
      'timestamp': instance.timestamp,
      'accelerometer': instance.accelerometer,
      'gyroscope': instance.gyroscope,
      'magnetometer': instance.magnetometer,
    };

MovesenseAccelerometerSample _$MovesenseAccelerometerSampleFromJson(
  Map<String, dynamic> json,
) => MovesenseAccelerometerSample(
  json['x'] as num,
  json['y'] as num,
  json['z'] as num,
);

Map<String, dynamic> _$MovesenseAccelerometerSampleToJson(
  MovesenseAccelerometerSample instance,
) => <String, dynamic>{'x': instance.x, 'y': instance.y, 'z': instance.z};

MovesenseGyroscopeSample _$MovesenseGyroscopeSampleFromJson(
  Map<String, dynamic> json,
) => MovesenseGyroscopeSample(
  json['x'] as num,
  json['y'] as num,
  json['z'] as num,
);

Map<String, dynamic> _$MovesenseGyroscopeSampleToJson(
  MovesenseGyroscopeSample instance,
) => <String, dynamic>{'x': instance.x, 'y': instance.y, 'z': instance.z};

MovesenseMagnetometerSample _$MovesenseMagnetometerSampleFromJson(
  Map<String, dynamic> json,
) => MovesenseMagnetometerSample(
  json['x'] as num,
  json['y'] as num,
  json['z'] as num,
);

Map<String, dynamic> _$MovesenseMagnetometerSampleToJson(
  MovesenseMagnetometerSample instance,
) => <String, dynamic>{'x': instance.x, 'y': instance.y, 'z': instance.z};

MovesenseDevice _$MovesenseDeviceFromJson(Map<String, dynamic> json) =>
    MovesenseDevice(
        roleName:
            json['roleName'] as String? ?? MovesenseDevice.DEFAULT_ROLE_NAME,
        isOptional: json['isOptional'] as bool? ?? true,
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          )
      ..serviceUuids = (json['serviceUuids'] as List<dynamic>)
          .map((e) => e as String)
          .toList()
      ..namePrefix = json['namePrefix'] as String?
      ..minRssi = (json['minRssi'] as num?)?.toInt()
      ..allowDuplicates = json['allowDuplicates'] as bool
      ..timeout = json['timeout'] == null
          ? null
          : Duration(microseconds: (json['timeout'] as num).toInt());

Map<String, dynamic> _$MovesenseDeviceToJson(MovesenseDevice instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration,
      'serviceUuids': instance.serviceUuids,
      'namePrefix': ?instance.namePrefix,
      'minRssi': ?instance.minRssi,
      'allowDuplicates': instance.allowDuplicates,
      'timeout': ?instance.timeout?.inMicroseconds,
    };

MovesenseDeviceRegistration _$MovesenseDeviceRegistrationFromJson(
  Map<String, dynamic> json,
) =>
    MovesenseDeviceRegistration(
        deviceDisplayName: json['deviceDisplayName'] as String?,
        registrationCreatedOn: json['registrationCreatedOn'] == null
            ? null
            : DateTime.parse(json['registrationCreatedOn'] as String),
        isConnected: json['isConnected'] as bool? ?? false,
        batteryChargingState:
            $enumDecodeNullable(
              _$BatteryChargingStateEnumMap,
              json['batteryChargingState'],
            ) ??
            BatteryChargingState.unknown,
        hardwareName: json['hardwareName'] as String?,
        bleAddress: json['bleAddress'] as String,
        bleName: json['bleName'] as String?,
        movesenseDeviceType:
            $enumDecodeNullable(
              _$MovesenseDeviceTypeEnumMap,
              json['movesenseDeviceType'],
            ) ??
            MovesenseDeviceType.UNKNOWN,
        deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
      )
      ..$type = json['__type'] as String?
      ..deviceId = json['deviceId'] as String
      ..serial = json['serial'] as String?;

Map<String, dynamic> _$MovesenseDeviceRegistrationToJson(
  MovesenseDeviceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'isConnected': instance.isConnected,
  'batteryChargingState':
      _$BatteryChargingStateEnumMap[instance.batteryChargingState]!,
  'hardwareName': ?instance.hardwareName,
  'bleAddress': instance.bleAddress,
  'bleName': ?instance.bleName,
  'serial': ?instance.serial,
  'movesenseDeviceType':
      _$MovesenseDeviceTypeEnumMap[instance.movesenseDeviceType]!,
  'deviceInfo': ?instance.deviceInfo,
};

const _$BatteryChargingStateEnumMap = {
  BatteryChargingState.unknown: 'unknown',
  BatteryChargingState.full: 'full',
  BatteryChargingState.normal: 'normal',
  BatteryChargingState.low: 'low',
  BatteryChargingState.critical: 'critical',
};

const _$MovesenseDeviceTypeEnumMap = {
  MovesenseDeviceType.UNKNOWN: 'UNKNOWN',
  MovesenseDeviceType.MD: 'MD',
  MovesenseDeviceType.HR_PLUS: 'HR_PLUS',
  MovesenseDeviceType.HR2: 'HR2',
  MovesenseDeviceType.FLASH: 'FLASH',
};
