/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'communication.dart';

/// The text (SMS) messages on the device.
///
/// Collected by [TextMessageLogProbe] for the
/// [CommunicationSamplingPackage.TEXT_MESSAGE_LOG] measure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TextMessageLog extends Data {
  /// The inbox and sent messages.
  List<TextMessage> textMessageLog = [];

  TextMessageLog([this.textMessageLog = const []]) : super();

  @override
  Function get fromJsonFunction => _$TextMessageLogFromJson;
  factory TextMessageLog.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<TextMessageLog>(json);
  @override
  Map<String, dynamic> toJson() => _$TextMessageLogToJson(this);
}

/// A text message (SMS).
///
/// Collected by [TextMessageProbe] for the [CommunicationSamplingPackage.TEXT_MESSAGE]
/// measure, and listed in a [TextMessageLog].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TextMessage extends Data {
  /// The id of this message on the device.
  int? id;

  /// The address (phone number) of the other party of this message.
  String? address;

  /// The text body of this message.
  String? body;

  /// The size in bytes of the body of the message.
  int? size;

  /// Whether the message has been read.
  bool? read;

  /// The date this message was created.
  DateTime? date;

  /// The date this message was sent.
  DateTime? dateSent;

  /// The type of message, e.g. inbox or sent.
  SmsType? type;

  /// The delivery status of the message.
  SmsStatus? status;

  TextMessage({
    this.id,
    this.address,
    this.body,
    this.size,
    this.read,
    this.date,
    this.dateSent,
    this.type,
    this.status,
  }) : super();

  /// Creates a [TextMessage] from an [SmsMessage] from the telephony plugin.
  factory TextMessage.fromSmsMessage(SmsMessage sms) => TextMessage(
    id: sms.id,
    address: sms.address,
    body: sms.body,
    size: (sms.body != null) ? sms.body!.length : null,
    read: sms.read,
    date: DateTime.fromMicrosecondsSinceEpoch(sms.date!, isUtc: true),
    dateSent: DateTime.fromMicrosecondsSinceEpoch(sms.dateSent!, isUtc: true),
    type: sms.type,
    status: sms.status,
  );

  @override
  Function get fromJsonFunction => _$TextMessageFromJson;
  factory TextMessage.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<TextMessage>(json);

  @override
  Map<String, dynamic> toJson() => _$TextMessageToJson(this);
}

/// The phone log, i.e. the list of phone calls made on the device in a period.
///
/// Collected by [PhoneLogProbe] for the [CommunicationSamplingPackage.PHONE_LOG]
/// measure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PhoneLog extends Data {
  /// The start and end (UTC) of the period this log covers.
  DateTime start, end;

  /// The phone calls in the period.
  List<PhoneCall> phoneLog = [];

  PhoneLog(this.start, this.end, [this.phoneLog = const []]) : super();

  @override
  Function get fromJsonFunction => _$PhoneLogFromJson;
  factory PhoneLog.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<PhoneLog>(json);

  @override
  Map<String, dynamic> toJson() => _$PhoneLogToJson(this);
}

/// A phone call, as listed in a [PhoneLog].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PhoneCall {
  /// Date and time of the call.
  DateTime? timestamp;

  /// Type of call. One of:
  ///  * answered_externally
  ///  * incoming
  ///  * blocked
  ///  * missed
  ///  * outgoing
  ///  * rejected
  ///  * voice_mail
  ///  * unknown
  String? callType;

  /// Duration of the call in seconds, as reported by the Android call log.
  int? duration;

  /// The formatted version of the phone number (if available).
  String? formattedNumber;

  /// The phone number.
  String? number;

  /// The name of the caller (if available).
  String? name;

  PhoneCall([this.timestamp, this.callType, this.duration, this.formattedNumber, this.number, this.name]);

  /// Creates a [PhoneCall] from a [CallLogEntry] from the call log plugin.
  factory PhoneCall.fromCallLogEntry(CallLogEntry call) {
    DateTime timestamp = DateTime.fromMicrosecondsSinceEpoch(call.timestamp!);
    String type = "unknown";

    switch (call.callType) {
      case CallType.answeredExternally:
        type = 'answered_externally';
        break;
      case CallType.blocked:
        type = 'blocked';
        break;
      case CallType.incoming:
        type = 'incoming';
        break;
      case CallType.missed:
        type = 'missed';
        break;
      case CallType.outgoing:
        type = 'outgoing';
        break;
      case CallType.rejected:
        type = 'rejected';
        break;
      case CallType.voiceMail:
        type = 'voice_mail';
        break;
      default:
        type = "unknown";
        break;
    }

    return PhoneCall(timestamp, type, call.duration, call.formattedNumber, call.number, call.name);
  }

  factory PhoneCall.fromJson(Map<String, dynamic> json) => _$PhoneCallFromJson(json);
  Map<String, dynamic> toJson() => _$PhoneCallToJson(this);
}

/// The calendar events on the device in a period.
///
/// Collected by [CalendarProbe] for the [CommunicationSamplingPackage.CALENDAR]
/// measure.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Calendar extends Data {
  /// The list of calendar entries collected.
  List<CalendarEvent> calendarEvents = [];

  /// The start and end of the period this calendar data covers.
  DateTime start, end;

  Calendar(this.start, this.end, [this.calendarEvents = const []]) : super();

  @override
  Function get fromJsonFunction => _$CalendarFromJson;
  factory Calendar.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<Calendar>(json);
  @override
  Map<String, dynamic> toJson() => _$CalendarToJson(this);
}

/// A calendar event, as listed in a [Calendar].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CalendarEvent {
  /// The unique identifier for this event.
  String? eventId;

  /// The identifier of the calendar that this event is associated with.
  String? calendarId;

  /// The title of this event.
  String? title;

  /// The description for this event.
  String? description;

  /// When the event starts (UTC).
  DateTime? start;

  /// When the event ends (UTC).
  DateTime? end;

  /// Whether this is an all-day event.
  bool? allDay;

  /// The location of this event.
  String? location;

  /// Status of the event, e.g. `confirmed`, `tentative` or `canceled`.
  final String? status;

  /// Timezone identifier for the event (e.g., "America/New_York").
  /// Null for all-day events (floating dates).
  final String? timeZone;

  /// Whether this is a recurring event.
  /// True for recurring events, false for one-time events.
  final bool isRecurring;

  CalendarEvent([
    this.eventId,
    this.calendarId,
    this.title,
    this.description,
    this.start,
    this.end,
    this.allDay,
    this.location,
    this.status,
    this.timeZone,
    this.isRecurring = false,
  ]);

  /// Creates a [CalendarEvent] from an event from the device calendar plugin.
  factory CalendarEvent.fromEvent(cal.Event event) {
    return CalendarEvent(
      event.eventId,
      event.calendarId,
      event.title,
      event.description,
      event.startDate.toUtc(),
      event.endDate.toUtc(),
      event.isAllDay,
      event.location,
      event.status.name,
      event.timeZone,
      event.isRecurring,
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);
}
