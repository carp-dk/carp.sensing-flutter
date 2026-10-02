/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'communication.dart';

/// The sampling package for collecting phone calls, text messages and calendar entries.
///
/// Register it before you deploy a protocol that uses its measure types:
///
/// ```dart
/// SamplingPackageRegistry().register(CommunicationSamplingPackage());
/// ```
///
/// Key points:
///  * [PHONE_LOG], [TEXT_MESSAGE_LOG] and [TEXT_MESSAGE] only work on Android.
///    On other platforms [create] returns `null`, so no probe runs.
///  * [CALENDAR] works on Android and iOS.
///  * On registration, adds anonymizers for all four measure types to the
///    default [PrivacySchema] (see [textMessageAnonymizer], [textMessageLogAnonymizer],
///    [phoneLogAnonymizer] and [calendarAnonymizer]).
class CommunicationSamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for collection of the phone log for a specific time period.
  ///  * Collected as [PhoneLog] data. Android only.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * Use a [HistoricSamplingConfiguration] for configuration.
  static const String PHONE_LOG = "${NameSpace.CARP}.phonelog";

  /// Measure type for collection of the text message (SMS) log for a specific
  /// time period.
  ///  * Collected as [TextMessageLog] data. Android only.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * Use a [HistoricSamplingConfiguration] for configuration.
  static const String TEXT_MESSAGE_LOG = "${NameSpace.CARP}.textmessagelog";

  /// Measure type for collection of text messages (SMS) as they are received.
  ///  * Collected as [TextMessage] data. Android only.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * No sampling configuration needed.
  static const String TEXT_MESSAGE = "${NameSpace.CARP}.textmessage";

  /// Measure type for collection of calendar entries from the calendar on the
  /// phone for a specific time period.
  ///  * Collected as [Calendar] data.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * Use a [HistoricSamplingConfiguration] for configuration.
  static const String CALENDAR = "${NameSpace.CARP}.calendar";

  /// Default sampling schemes. [PHONE_LOG], [TEXT_MESSAGE_LOG] and [CALENDAR]
  /// use a [HistoricSamplingConfiguration] of one day back and one day forward
  /// in time.
  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: PHONE_LOG,
            displayName: "Phone Log",
            timeType: DataTimeType.TIME_SPAN,
            dataEventType: DataEventType.ONE_TIME,
            permissions: [Permission.phone],
          ),
          HistoricSamplingConfiguration(
            past: const Duration(days: 1),
            future: const Duration(days: 1),
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: TEXT_MESSAGE_LOG,
            displayName: "Text Message Log",
            timeType: DataTimeType.TIME_SPAN,
            dataEventType: DataEventType.ONE_TIME,
            permissions: [Permission.sms],
          ),
          HistoricSamplingConfiguration(
            past: const Duration(days: 1),
            future: const Duration(days: 1),
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: TEXT_MESSAGE,
            displayName: "Text Messages",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.EVENT,
            permissions: [Permission.phone],
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: CALENDAR,
            displayName: "Calendar Entries",
            timeType: DataTimeType.TIME_SPAN,
            dataEventType: DataEventType.ONE_TIME,
            permissions: [Permission.calendarFullAccess],
          ),
          HistoricSamplingConfiguration(
            past: const Duration(days: 1),
            future: const Duration(days: 1),
          ),
        ),
      ]);

  @override
  Probe? create(String type) {
    switch (type) {
      case PHONE_LOG:
        return (Platform.isAndroid) ? PhoneLogProbe() : null;
      case TEXT_MESSAGE_LOG:
        return (Platform.isAndroid) ? TextMessageLogProbe() : null;
      case TEXT_MESSAGE:
        return (Platform.isAndroid) ? TextMessageProbe() : null;
      case CALENDAR:
        return CalendarProbe();
      default:
        return null;
    }
  }

  @override
  void onRegister() {
    // register all data types
    FromJsonFactory().registerAll([
      TextMessageLog(),
      TextMessage(),
      PhoneLog(DateTime.now(), DateTime.now()),
      Calendar(DateTime.now(), DateTime.now()),
    ]);

    // register the default privacy transformers
    DataTransformerSchemaRegistry()
        .lookup(PrivacySchema.DEFAULT)!
        .add(TEXT_MESSAGE, textMessageAnonymizer);
    DataTransformerSchemaRegistry()
        .lookup(PrivacySchema.DEFAULT)!
        .add(TEXT_MESSAGE_LOG, textMessageLogAnonymizer);
    DataTransformerSchemaRegistry()
        .lookup(PrivacySchema.DEFAULT)!
        .add(PHONE_LOG, phoneLogAnonymizer);
    DataTransformerSchemaRegistry()
        .lookup(PrivacySchema.DEFAULT)!
        .add(CALENDAR, calendarAnonymizer);
  }
}
