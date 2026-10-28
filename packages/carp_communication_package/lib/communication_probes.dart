/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'communication.dart';

/// Collects the phone call log from this device as [PhoneLog] data.
///
/// Used for the [CommunicationSamplingPackage.PHONE_LOG] measure. The period
/// starts at the last time this probe collected data or, the first time, at
/// [HistoricSamplingConfiguration.past] before now. The period ends now.
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
    Iterable<CallLogEntry> entries = await CallLog.query(dateFrom: from, dateTo: now);
    return Measurement.fromData(
      PhoneLog(
        DateTime.fromMillisecondsSinceEpoch(from).toUtc(),
        DateTime.now().toUtc(),
        entries.map((call) => PhoneCall.fromCallLogEntry(call)).toList(),
      ),
    );
  }
}

/// Collects all text (SMS) messages on this device as [TextMessageLog] data.
///
/// Used for the [CommunicationSamplingPackage.TEXT_MESSAGE_LOG] measure.
/// Combines the inbox and sent messages. It does not filter on the
/// [HistoricSamplingConfiguration] period, so each run returns the full log.
///
/// Only works on Android.
class TextMessageLogProbe extends MeasurementProbe {
  /// Not used.
  SmsColumn? col;

  /// The SMS columns read from the inbox and sent messages.
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
    return Measurement.fromData(TextMessageLog(allSms.map((sms) => TextMessage.fromSmsMessage(sms)).toList()));
  }
}

// The singleton instance of the [Telephony] class to be used in
// background execution context.
Telephony get _telephony => Telephony.backgroundInstance;

// A private stream controller to be used in the call-back from the SMS probe.
StreamController<Measurement> _textMessageProbeController = StreamController.broadcast();

/// Handles incoming SMS messages while the app is in the background.
///
/// Must be a top-level function so the telephony plugin can call it from a
/// background isolate. Passed to `listenIncomingSms` by [TextMessageProbe].
void backgroundMessageHandler(SmsMessage message) async {
  _textMessageProbeController.add(Measurement.fromData(TextMessage.fromSmsMessage(message)));
}

/// Collects a [TextMessage] every time this device receives an SMS message.
///
/// Used for the [CommunicationSamplingPackage.TEXT_MESSAGE] measure. Starts
/// listening on [onResume], both in the foreground and in the background
/// (via [backgroundMessageHandler]).
///
/// Only works on Android.
class TextMessageProbe extends StreamProbe {
  @override
  Stream<Measurement> get stream => _textMessageProbeController.stream;

  @override
  Future<bool> onResume() async {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _textMessageProbeController.add(Measurement.fromData(TextMessage.fromSmsMessage(message)));
      },
      onBackgroundMessage: backgroundMessageHandler,
    );

    return await super.onResume();
  }
}

/// Collects the events in all calendars on the phone as [Calendar] data.
///
/// Used for the [CommunicationSamplingPackage.CALENDAR] measure. Asks for
/// calendar permission the first time, if the user has not been asked yet.
/// If the calendars cannot be read, the measurement holds an [Error].
class CalendarProbe extends MeasurementProbe {
  final cal.DeviceCalendar _deviceCalendar = cal.DeviceCalendar();
  List<cal.Calendar>? _calendars;

  /// Get the entire list of calendars from the device.
  /// This only needs to be done once, and the list of calendars is then cached.
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

  /// Gets a [Calendar] measurement for all events in all calendars.
  ///
  /// The period starts at the last time this probe collected data or, the
  /// first time, at [HistoricSamplingConfiguration.past] before now. The
  /// period ends now.
  @override
  Future<Measurement> getMeasurement() async {
    if (_calendars == null) await _retrieveCalendars();

    // Fast out if calendars could not be retrieved, e.g. due to missing permissions.
    if (_calendars == null) {
      return Measurement.fromData(Error(message: 'The list of calendars could not be retrieved.'));
    }

    DateTime startDate = samplingConfiguration.lastTime ?? DateTime.now().subtract(samplingConfiguration.past);
    DateTime endDate = DateTime.now();

    // Get all events from all calendars.
    var events = await _deviceCalendar.listEvents(startDate, endDate);

    return Measurement(
      sensorStartTime: startDate.microsecondsSinceEpoch,
      sensorEndTime: endDate.microsecondsSinceEpoch,
      data: Calendar(startDate, endDate)
        ..calendarEvents = events.map((event) => CalendarEvent.fromEvent(event)).toList(),
    );
  }
}
