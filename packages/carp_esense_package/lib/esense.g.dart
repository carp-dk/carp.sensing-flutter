// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'esense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ESenseButton _$ESenseButtonFromJson(Map<String, dynamic> json) =>
    ESenseButton(
        deviceName: json['device_name'] as String,
        pressed: json['pressed'] as bool,
      )
      ..$type = json['__type'] as String?
      ..timestamp = DateTime.parse(json['timestamp'] as String);

Map<String, dynamic> _$ESenseButtonToJson(ESenseButton instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'device_name': instance.deviceName,
      'pressed': instance.pressed,
    };

ESenseSensor _$ESenseSensorFromJson(Map<String, dynamic> json) => ESenseSensor(
  deviceName: json['device_name'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  packetIndex: (json['packet_index'] as num?)?.toInt(),
  accel: (json['accel'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  gyro: (json['gyro'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$ESenseSensorToJson(ESenseSensor instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'timestamp': instance.timestamp.toIso8601String(),
      'device_name': instance.deviceName,
      'packet_index': ?instance.packetIndex,
      'accel': ?instance.accel,
      'gyro': ?instance.gyro,
    };

ESenseDevice _$ESenseDeviceFromJson(Map<String, dynamic> json) =>
    ESenseDevice(
        roleName: json['roleName'] as String? ?? ESenseDevice.DEFAULT_ROLE_NAME,
        isOptional: json['isOptional'] as bool? ?? true,
        samplingRate: (json['samplingRate'] as num?)?.toInt() ?? 10,
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

Map<String, dynamic> _$ESenseDeviceToJson(ESenseDevice instance) =>
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
      'samplingRate': instance.samplingRate,
    };
