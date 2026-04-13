// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'communication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextMessageLog _$TextMessageLogFromJson(Map<String, dynamic> json) =>
    TextMessageLog(
      (json['textMessageLog'] as List<dynamic>?)
              ?.map((e) => TextMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$TextMessageLogToJson(TextMessageLog instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'textMessageLog': instance.textMessageLog.map((e) => e.toJson()).toList(),
    };

TextMessage _$TextMessageFromJson(Map<String, dynamic> json) => TextMessage(
  id: (json['id'] as num?)?.toInt(),
  address: json['address'] as String?,
  body: json['body'] as String?,
  size: (json['size'] as num?)?.toInt(),
  read: json['read'] as bool?,
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  dateSent: json['dateSent'] == null
      ? null
      : DateTime.parse(json['dateSent'] as String),
  type: $enumDecodeNullable(_$SmsTypeEnumMap, json['type']),
  status: $enumDecodeNullable(_$SmsStatusEnumMap, json['status']),
)..$type = json['__type'] as String?;

Map<String, dynamic> _$TextMessageToJson(TextMessage instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'id': ?instance.id,
      'address': ?instance.address,
      'body': ?instance.body,
      'size': ?instance.size,
      'read': ?instance.read,
      'date': ?instance.date?.toIso8601String(),
      'dateSent': ?instance.dateSent?.toIso8601String(),
      'type': ?_$SmsTypeEnumMap[instance.type],
      'status': ?_$SmsStatusEnumMap[instance.status],
    };

const _$SmsTypeEnumMap = {
  SmsType.MESSAGE_TYPE_ALL: 'MESSAGE_TYPE_ALL',
  SmsType.MESSAGE_TYPE_INBOX: 'MESSAGE_TYPE_INBOX',
  SmsType.MESSAGE_TYPE_SENT: 'MESSAGE_TYPE_SENT',
  SmsType.MESSAGE_TYPE_DRAFT: 'MESSAGE_TYPE_DRAFT',
  SmsType.MESSAGE_TYPE_OUTBOX: 'MESSAGE_TYPE_OUTBOX',
  SmsType.MESSAGE_TYPE_FAILED: 'MESSAGE_TYPE_FAILED',
  SmsType.MESSAGE_TYPE_QUEUED: 'MESSAGE_TYPE_QUEUED',
};

const _$SmsStatusEnumMap = {
  SmsStatus.STATUS_COMPLETE: 'STATUS_COMPLETE',
  SmsStatus.STATUS_FAILED: 'STATUS_FAILED',
  SmsStatus.STATUS_NONE: 'STATUS_NONE',
  SmsStatus.STATUS_PENDING: 'STATUS_PENDING',
};

PhoneLog _$PhoneLogFromJson(Map<String, dynamic> json) => PhoneLog(
  DateTime.parse(json['start'] as String),
  DateTime.parse(json['end'] as String),
  (json['phoneLog'] as List<dynamic>?)
          ?.map((e) => PhoneCall.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
)..$type = json['__type'] as String?;

Map<String, dynamic> _$PhoneLogToJson(PhoneLog instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'start': instance.start.toIso8601String(),
  'end': instance.end.toIso8601String(),
  'phoneLog': instance.phoneLog.map((e) => e.toJson()).toList(),
};

PhoneCall _$PhoneCallFromJson(Map<String, dynamic> json) => PhoneCall(
  json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  json['callType'] as String?,
  (json['duration'] as num?)?.toInt(),
  json['formattedNumber'] as String?,
  json['number'] as String?,
  json['name'] as String?,
);

Map<String, dynamic> _$PhoneCallToJson(PhoneCall instance) => <String, dynamic>{
  'timestamp': ?instance.timestamp?.toIso8601String(),
  'callType': ?instance.callType,
  'duration': ?instance.duration,
  'formattedNumber': ?instance.formattedNumber,
  'number': ?instance.number,
  'name': ?instance.name,
};

Calendar _$CalendarFromJson(Map<String, dynamic> json) => Calendar(
  DateTime.parse(json['start'] as String),
  DateTime.parse(json['end'] as String),
  (json['calendarEvents'] as List<dynamic>?)
          ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
)..$type = json['__type'] as String?;

Map<String, dynamic> _$CalendarToJson(Calendar instance) => <String, dynamic>{
  '__type': ?instance.$type,
  'calendarEvents': instance.calendarEvents.map((e) => e.toJson()).toList(),
  'start': instance.start.toIso8601String(),
  'end': instance.end.toIso8601String(),
};

CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    CalendarEvent(
      json['eventId'] as String?,
      json['calendarId'] as String?,
      json['title'] as String?,
      json['description'] as String?,
      json['start'] == null ? null : DateTime.parse(json['start'] as String),
      json['end'] == null ? null : DateTime.parse(json['end'] as String),
      json['allDay'] as bool?,
      json['location'] as String?,
      json['status'] as String?,
      json['timeZone'] as String?,
      json['isRecurring'] as bool? ?? false,
    );

Map<String, dynamic> _$CalendarEventToJson(CalendarEvent instance) =>
    <String, dynamic>{
      'eventId': ?instance.eventId,
      'calendarId': ?instance.calendarId,
      'title': ?instance.title,
      'description': ?instance.description,
      'start': ?instance.start?.toIso8601String(),
      'end': ?instance.end?.toIso8601String(),
      'allDay': ?instance.allDay,
      'location': ?instance.location,
      'status': ?instance.status,
      'timeZone': ?instance.timeZone,
      'isRecurring': instance.isRecurring,
    };
