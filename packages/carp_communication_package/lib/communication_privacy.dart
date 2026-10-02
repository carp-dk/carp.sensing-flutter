/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'communication.dart';

/// Anonymizes a [TextMessage] by replacing its address and body with SHA-1 hashes.
///
/// Registered in the default [PrivacySchema] for the
/// [CommunicationSamplingPackage.TEXT_MESSAGE] measure.
TextMessage textMessageAnonymizer(Data data) {
  assert(data is TextMessage);
  var msg = data as TextMessage;
  if (msg.address != null) {
    msg.address = sha1.convert(utf8.encode(msg.address!)).toString();
  }
  if (msg.body != null) {
    msg.body = sha1.convert(utf8.encode(msg.body!)).toString();
  }

  return msg;
}

/// Anonymizes each [TextMessage] in a [TextMessageLog] using [textMessageAnonymizer].
///
/// Registered in the default [PrivacySchema] for the
/// [CommunicationSamplingPackage.TEXT_MESSAGE_LOG] measure.
Data textMessageLogAnonymizer(Data data) {
  assert(data is TextMessageLog);
  TextMessageLog log = data as TextMessageLog;
  for (var msg in log.textMessageLog) {
    textMessageAnonymizer(msg);
  }
  return log;
}

/// Anonymizes each [PhoneCall] in a [PhoneLog] using [phoneCallAnonymizer].
///
/// Registered in the default [PrivacySchema] for the
/// [CommunicationSamplingPackage.PHONE_LOG] measure.
Data phoneLogAnonymizer(Data data) {
  assert(data is PhoneLog);
  PhoneLog log = data as PhoneLog;
  for (var call in log.phoneLog) {
    phoneCallAnonymizer(call);
  }
  return log;
}

/// Anonymizes a [PhoneCall] by replacing its formatted number, number and
/// name with SHA-1 hashes.
PhoneCall phoneCallAnonymizer(PhoneCall call) {
  if (call.formattedNumber != null) {
    call.formattedNumber = sha1.convert(utf8.encode(call.formattedNumber!)).toString();
  }
  if (call.number != null) {
    call.number = sha1.convert(utf8.encode(call.number!)).toString();
  }
  if (call.name != null) {
    call.name = sha1.convert(utf8.encode(call.name!)).toString();
  }

  return call;
}

/// Anonymizes each [CalendarEvent] in a [Calendar] using [calendarEventAnonymizer].
///
/// Registered in the default [PrivacySchema] for the
/// [CommunicationSamplingPackage.CALENDAR] measure.
Data calendarAnonymizer(Data data) {
  assert(data is Calendar);
  Calendar calendar = data as Calendar;
  for (var event in calendar.calendarEvents) {
    calendarEventAnonymizer(event);
  }
  return calendar;
}

/// Anonymizes a [CalendarEvent] by replacing its title and description with
/// SHA-1 hashes.
CalendarEvent calendarEventAnonymizer(CalendarEvent event) {
  if (event.title != null) {
    event.title = sha1.convert(utf8.encode(event.title!)).toString();
  }
  if (event.description != null) {
    event.description = sha1.convert(utf8.encode(event.description!)).toString();
  }

  return event;
}
