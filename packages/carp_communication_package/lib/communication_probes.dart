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
        DateTime.fromMillisecondsSinceEpoch(from).toUtc(),
        DateTime.now().toUtc(),
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
  Future<bool> onResume() async {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _textMessageProbeController.add(
          Measurement.fromData(TextMessage.fromSmsMessage(message)),
        );
      },
      onBackgroundMessage: backgroundMessageHandler,
    );

    return await super.onResume();
  }
}

/// A probe collecting calendar entries from the calendar on the phone.
///
/// See [CalendarMeasure] for how to configure this probe's measure.
class CalendarProbe extends MeasurementProbe {
  final _deviceCalendar = cal.DeviceCalendar.instance;
  List<cal.Calendar>? _calendars;
  late Iterator<cal.Calendar> _calendarIterator;
  DateTime? startDate, endDate;

  @override
  bool onInitialize() {
    _retrieveCalendars();
    return true;
  }

  Future<bool> _retrieveCalendars() async {
    // try to get permission to access calendar
    var permissionsGranted = await _deviceCalendar.hasPermissions();

    if (permissionsGranted != cal.CalendarPermissionStatus.granted &&
        permissionsGranted == cal.CalendarPermissionStatus.notDetermined) {
      // User hasn't been asked yet - now we can prompt
      permissionsGranted = await _deviceCalendar.requestPermissions();
      // If permissions are still not granted, we cannot proceed.
      if (permissionsGranted != cal.CalendarPermissionStatus.granted) {
        return false;
      }
    }

    _calendars = await _deviceCalendar.listCalendars();
    return true;
  }

  @override
  HistoricSamplingConfiguration get samplingConfiguration =>
      super.samplingConfiguration as HistoricSamplingConfiguration;

  /// Get the [Calendar] measurement for all events in the calendar between
  /// [startDate] and [endDate].
  @override
  Future<Measurement> getMeasurement() async {
    if (_calendars == null) await _retrieveCalendars();

    if (_calendars != null) {
      // Get all events from all calendars.
      var events = await _deviceCalendar.listEvents(startDate!, endDate!);

      return Measurement(
        sensorStartTime: startDate!.microsecondsSinceEpoch,
        sensorEndTime: endDate?.microsecondsSinceEpoch,
        data: Calendar(startDate!, endDate!)
          ..calendarEvents = events
              .map((event) => CalendarEvent.fromEvent(event))
              .toList(),
      );
    } else {
      return Measurement.fromData(
        Error(message: 'Permission to collect calendar entries not granted.'),
      );
    }
  }
}
