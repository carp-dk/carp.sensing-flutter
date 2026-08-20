/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'transportation.dart';

/// A [SamplingPackage] for route/transportation-mode classification.
///
/// Unlike most sampling packages, this package does not sense continuously
/// from a phone sensor. Instead it defines three data types used to
/// exchange data between the phone and a route classification server:
///
///  * [ROUTE] - a GPS trace ([Route]) sent from the phone to the server.
///  * [MODE] - the route split into segments, each with a detected
///    transportation mode ([Mode]), sent from the server to the phone.
///  * [USER_FEEDBACK] - the user's approval, rejection, correction of a
///    segment's mode, or labeling of a location cluster (e.g. home, work,
///    restaurant) as [UserFeedback], sent from the phone to the server.
///
/// All three types are collected via the same no-op [TransportationProbe] -
/// app code calls `probe.addMeasurement(...)` once data is available (see
/// [TransportationProbe]).
///
/// An example of a study protocol configuration might be:
///
/// ```dart
///   protocol.addTaskControl(
///       ImmediateTrigger(),
///       BackgroundTask()
///         ..addMeasure(Measure(type: TransportationSamplingPackage.ROUTE))
///         ..addMeasure(Measure(type: TransportationSamplingPackage.MODE))
///         ..addMeasure(Measure(type: TransportationSamplingPackage.USER_FEEDBACK)),
///       phone);
/// ```
///
/// To use this package, register it using:
///
/// ```dart
///   SamplingPackageRegistry().register(TransportationSamplingPackage());
/// ```
class TransportationSamplingPackage extends SmartphoneSamplingPackage {
  static const String TRANSPORTATION_NAMESPACE =
      "${NameSpace.CARP}.transportation";

  /// Measure type for a GPS route trace sent to the classification server.
  ///  * One-time measure - collected and sent once per route.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * No sampling configuration needed - data is added by app code.
  static const String ROUTE = "$TRANSPORTATION_NAMESPACE.route";

  /// Measure type for the transportation mode classification of a route,
  /// as returned by the server.
  ///  * One-time measure - collected once per received classification.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * No sampling configuration needed - data is added by app code.
  static const String MODE = "$TRANSPORTATION_NAMESPACE.mode";

  /// Measure type for user feedback on a route's mode classification, or on
  /// labeling a cluster of locations.
  ///  * One-time measure - collected once per feedback submission.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * No sampling configuration needed - data is added by app code.
  static const String USER_FEEDBACK = "$TRANSPORTATION_NAMESPACE.userfeedback";

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ROUTE,
            displayName: "Transportation Route",
            timeType: DataTimeType.TIME_SPAN,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: MODE,
            displayName: "Transportation Mode Classification",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: USER_FEEDBACK,
            displayName: "Transportation User Feedback",
            timeType: DataTimeType.POINT,
            dataEventType: DataEventType.ONE_TIME,
          ),
        ),
      ]);

  @override
  Probe? create(String type) => switch (type) {
    ROUTE => TransportationProbe(),
    MODE => TransportationProbe(),
    USER_FEEDBACK => TransportationProbe(),
    _ => null,
  };

  @override
  void onRegister() {
    // register all data types for correct (de)serialization
    FromJsonFactory().registerAll([
      Route(startTime: DateTime.now()),
      Mode(routeId: ''),
      UserFeedback(routeId: '', feedbackType: FeedbackType.approved),
    ]);
  }
}
