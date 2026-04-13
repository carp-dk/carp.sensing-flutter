/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'communication.dart';

/// This is the base class for this communication sampling package.
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry.register(CommunicationSamplingPackage());
/// ```
class CommunicationSamplingPackage extends SmartphoneSamplingPackage {
  /// Measure type for collection of the phone log for a specific time period.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * Use the [HistoricSamplingConfiguration] for configuration.
  static const String PHONE_LOG = "${NameSpace.CARP}.phonelog";

  // static const String TELEPHONY = "dk.cachet.carp.telephony";

  /// Measure type for collection of the text message (SMS) log for a specific
  /// time period.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * Use the [HistoricSamplingConfiguration] for configuration.
  static const String TEXT_MESSAGE_LOG = "${NameSpace.CARP}.textmessagelog";

  /// Measure type for collection of text message (SMS) as they are received.
  ///  * Event-based measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * No sampling configuration needed.
  static const String TEXT_MESSAGE = "${NameSpace.CARP}.textmessage";

  /// Measure type for collection of calendar entries from the calendar on the
  /// phone for a specific time period.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * Use the [HistoricSamplingConfiguration] for configuration.
  static const String CALENDAR = "${NameSpace.CARP}.calendar";

  /// Default samplings schema for:
  ///  * [PHONE_LOG] - a period one day back in time and one day into the future
  ///  * [TEXT_MESSAGE_LOG] - a period one day back in time and one day into the future
  ///  * [CALENDAR] - a period one day back in time and one day into the future
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
      // case TELEPHONY:
      //   throw "Not implemented yet";
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
