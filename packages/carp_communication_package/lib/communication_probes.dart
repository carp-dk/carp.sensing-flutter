/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'communication.dart';

/// A probe that collects the phone log from this device.
///
/// Only works on Android.
class PhoneLogProbe extends MeasurementProbe {
  @override
  Future<Measurement> getMeasurement() async {
    final m = (samplingConfiguration as HistoricSamplingConfiguration);
    int from = (m.lastTime != null)
        ? m.lastTime!.millisecondsSinceEpoch
        : DateTime.now().subtract(m.past).millisecondsSinceEpoch;
    int now = DateTime.now().millisecondsSinceEpoch;
    Iterable<CallLogEntry> entries = await CallLog.query(
      dateFrom: from,
      dateTo: now,
    );
    return Measurement.fromData(
      PhoneLog(
        m.lastTime!,
        DateTime.now(),
        entries.map((call) => PhoneCall.fromCallLogEntry(call)).toList(),
      ),
    );
  }
}

/// A probe that collects a complete list of all text (SMS) messages from
/// this device. Combines both send and received messages.
///
/// Only works on Android.
class TextMessageLogProbe extends MeasurementProbe {
  SmsColumn? col;
  static const List<SmsColumn> ALL_SMS_COLUMNS = [
    SmsColumn.ADDRESS,
    SmsColumn.BODY,
    SmsColumn.DATE,
    SmsColumn.DATE_SENT,
    SmsColumn.ID,
    SmsColumn.READ,
    SmsColumn.SEEN,
    SmsColumn.STATUS,
    SmsColumn.SUBJECT,
    SmsColumn.SUBSCRIPTION_ID,
    SmsColumn.TYPE,
  ];

  @override
  Future<Measurement> getMeasurement() async {
    List<SmsMessage> allSms = [];
    allSms
      ..addAll(await _telephony.getInboxSms(columns: ALL_SMS_COLUMNS))
      ..addAll(await _telephony.getSentSms(columns: ALL_SMS_COLUMNS));
    return Measurement.fromData(
      TextMessageLog(
        allSms.map((sms) => TextMessage.fromSmsMessage(sms)).toList(),
      ),
    );
  }
}

// The singleton instance of the [Telephony] class to be used in
// background execution context.
Telephony get _telephony => Telephony.backgroundInstance;

// A private stream controller to be used in the call-back from the SMS probe.
StreamController<Measurement> _textMessageProbeController =
    StreamController.broadcast();

/// The top-level call-back method for handling in-coming SMS messages when
/// the app is in the background.
void backgroundMessageHandler(SmsMessage message) async {
  _textMessageProbeController.add(
    Measurement.fromData(TextMessage.fromSmsMessage(message)),
  );
}

/// The [TextMessageProbe] listens to SMS messages and collects a
/// [TextMessage] every time a new SMS message is received.
///
/// Only works on Android.
class TextMessageProbe extends StreamProbe {
  @override
  Stream<Measurement> get stream => _textMessageProbeController.stream;

  // @override
  // bool onInitialize() {
  //   if (!Platform.isAndroid) {
  //     warning('$runtimeType only available on Android.');
  //     return false;
  //   }

  //   _telephony.listenIncomingSms(
  //     onNewMessage: (SmsMessage message) {
  //       _textMessageProbeController.add(
  //         Measurement.fromData(TextMessage.fromSmsMessage(message)),
  //       );
  //     },
  //     onBackgroundMessage: backgroundMessageHandler,
  //   );
  //   return true;
  // }

  @override
  Future<bool> onStart() async {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _textMessageProbeController.add(
          Measurement.fromData(TextMessage.fromSmsMessage(message)),
        );
      },
      onBackgroundMessage: backgroundMessageHandler,
    );

    return await super.onStart();
  }
}

/// A probe collecting calendar entries from the calendar on the phone.
///
/// See [CalendarMeasure] for how to configure this probe's measure.
class CalendarProbe extends MeasurementProbe {
  final _deviceCalendar = cal.DeviceCalendarPlugin();
  List<cal.Calendar>? _calendars;
  late Iterator<cal.Calendar> _calendarIterator;
  List<CalendarEvent> _events = [];
  DateTime? startDate, endDate;

  @override
  bool onInitialize() {
    _retrieveCalendars();
    return true;
  }

  Future<bool> _retrieveCalendars() async {
    // try to get permission to access calendar
    var permissionsGranted = await _deviceCalendar.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendar.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        return false;
      }
    }

    final calendarsResult = await _deviceCalendar.retrieveCalendars();
    _calendars = calendarsResult.data;
    return true;
  }

  @override
  HistoricSamplingConfiguration get samplingConfiguration =>
      super.samplingConfiguration as HistoricSamplingConfiguration;

  // Collects events from a calendar.
  Future<bool> _retrieveEvents(cal.Calendar calendar) async {
    startDate = DateTime.now().subtract(samplingConfiguration.past);
    endDate = DateTime.now().add(samplingConfiguration.future);

    var calendarEventsResult = await _deviceCalendar.retrieveEvents(
      calendar.id,
      cal.RetrieveEventsParams(startDate: startDate, endDate: endDate),
    );
    List<cal.Event>? calendarEvents = calendarEventsResult.data;
    if (calendarEvents != null) {
      for (var event in calendarEvents) {
        _events.add(CalendarEvent.fromEvent(event));
      }
    } else {
      return false;
    }

    // recursively collect events from the next calendar in the iterator
    if (_calendarIterator.moveNext()) {
      return await _retrieveEvents(_calendarIterator.current);
    }

    return true;
  }

  /// Get the [Calendar] measurement.
  @override
  Future<Measurement> getMeasurement() async {
    if (_calendars == null) await _retrieveCalendars();

    if (_calendars != null) {
      _events = [];
      _calendarIterator = _calendars!.iterator;

      if (_calendarIterator.moveNext()) {
        await _retrieveEvents(_calendarIterator.current);
      }

      return Measurement(
        sensorStartTime: startDate!.microsecondsSinceEpoch,
        sensorEndTime: endDate?.microsecondsSinceEpoch,
        data: Calendar(startDate!, endDate!)..calendarEvents = _events,
      );
    } else {
      return Measurement.fromData(
        Error(message: 'Permission to collect calendar entries not granted.'),
      );
    }
  }
}
