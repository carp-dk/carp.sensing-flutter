/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'communication.dart';

/// A [TextMessage] anonymizer function. Anonymizes:
///  - address
///  - body
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

/// A [TextMessageLog] anonymizer function. Anonymizes each [TextMessage]
/// entry in the log using the [textMessageAnonymizer] function.
Data textMessageLogAnonymizer(Data data) {
  assert(data is TextMessageLog);
  TextMessageLog log = data as TextMessageLog;
  for (var msg in log.textMessageLog) {
    textMessageAnonymizer(msg);
  }
  return log;
}

/// A [PhoneLog] anonymizer function. Anonymizes each [PhoneCall]
/// entry in the log using the [phoneCallAnonymizer] function.
Data phoneLogAnonymizer(Data data) {
  assert(data is PhoneLog);
  PhoneLog log = data as PhoneLog;
  for (var call in log.phoneLog) {
    phoneCallAnonymizer(call);
  }
  return log;
}

/// A [PhoneCall] anonymizer function. Anonymizes:
///  - formattedNumber
///  - number
///  - name
PhoneCall phoneCallAnonymizer(PhoneCall call) {
  if (call.formattedNumber != null) {
    call.formattedNumber = sha1
        .convert(utf8.encode(call.formattedNumber!))
        .toString();
  }
  if (call.number != null) {
    call.number = sha1.convert(utf8.encode(call.number!)).toString();
  }
  if (call.name != null) {
    call.name = sha1.convert(utf8.encode(call.name!)).toString();
  }

  return call;
}

/// A [Calendar] anonymizer function. Anonymizes each [CalendarEvent]
/// entry in the calendar using the [calendarEventAnonymizer] function.
Data calendarAnonymizer(Data data) {
  assert(data is Calendar);
  Calendar calendar = data as Calendar;
  for (var event in calendar.calendarEvents) {
    calendarEventAnonymizer(event);
  }
  return calendar;
}

/// A [CalendarEvent] anonymizer function. Anonymizes:
///  - title
///  - description
///  - names of all attendees
CalendarEvent calendarEventAnonymizer(CalendarEvent event) {
  if (event.title != null) {
    event.title = sha1.convert(utf8.encode(event.title!)).toString();
  }
  if (event.description != null) {
    event.description = sha1
        .convert(utf8.encode(event.description!))
        .toString();
  }

  return event;
}
