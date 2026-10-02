// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

A _$AFromJson(Map<String, dynamic> json) =>
    A((json['index'] as num?)?.toInt() ?? 0)..$type = json['__type'] as String?;

Map<String, dynamic> _$AToJson(A instance) => <String, dynamic>{
  '__type': instance.$type,
  'index': instance.index,
};

B _$BFromJson(Map<String, dynamic> json) =>
    B((json['index'] as num?)?.toInt() ?? 0, json['str'] as String?)
      ..$type = json['__type'] as String?;

Map<String, dynamic> _$BToJson(B instance) => <String, dynamic>{
  if (instance.$type case final value?) '__type': value,
  'index': instance.index,
  if (instance.str case final value?) 'str': value,
};

C _$CFromJson(Map<String, dynamic> json) => C(
  (json['index'] as num).toInt(),
  B.fromJson(json['b'] as Map<String, dynamic>),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$CToJson(C instance) => <String, dynamic>{
  '__type': instance.$type,
  'index': instance.index,
  'b': instance.b.toJson(),
};
