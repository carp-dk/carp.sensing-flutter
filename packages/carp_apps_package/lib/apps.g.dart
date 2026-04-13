// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apps.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Apps _$AppsFromJson(Map<String, dynamic> json) => Apps(
  (json['installedApps'] as List<dynamic>)
      .map((e) => App.fromJson(e as Map<String, dynamic>))
      .toList(),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AppsToJson(Apps instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'installedApps': instance.installedApps.map((e) => e.toJson()).toList(),
};

App _$AppFromJson(Map<String, dynamic> json) => App(
  name: json['name'] as String?,
  packageName: json['packageName'] as String?,
  versionName: json['versionName'] as String?,
  versionCode: (json['versionCode'] as num?)?.toInt(),
  installTimeMillis: (json['installTimeMillis'] as num?)?.toInt(),
)..framework = json['framework'] as String?;

Map<String, dynamic> _$AppToJson(App instance) => <String, dynamic>{
  'name': ?instance.name,
  'packageName': ?instance.packageName,
  'versionName': ?instance.versionName,
  'versionCode': ?instance.versionCode,
  'installTimeMillis': ?instance.installTimeMillis,
  'framework': ?instance.framework,
};

AppUsage _$AppUsageFromJson(Map<String, dynamic> json) => AppUsage(
  DateTime.parse(json['start'] as String),
  DateTime.parse(json['end'] as String),
  (json['usage'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, AppUsageInfo.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AppUsageToJson(AppUsage instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'start': instance.start.toIso8601String(),
  'end': instance.end.toIso8601String(),
  'usage': instance.usage.map((k, e) => MapEntry(k, e.toJson())),
};

AppUsageInfo _$AppUsageInfoFromJson(Map<String, dynamic> json) => AppUsageInfo(
  json['name'] as String,
  json['packageName'] as String,
  Duration(microseconds: (json['usage'] as num).toInt()),
  DateTime.parse(json['startDate'] as String),
  DateTime.parse(json['endDate'] as String),
  DateTime.parse(json['lastForeground'] as String),
);

Map<String, dynamic> _$AppUsageInfoToJson(AppUsageInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'packageName': instance.packageName,
      'usage': instance.usage.inMicroseconds,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'lastForeground': instance.lastForeground.toIso8601String(),
    };
