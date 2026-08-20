// ignore_for_file: unused_local_variable, definitely_unassigned_late_local_variable

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_transportation_package/transportation.dart';

/// This is a very simple example of how this sampling package is used with
/// CARP Mobile Sensing (CAMS).
/// NOTE, however, that the code below will not run.
/// See the documentation on how to use CAMS:
/// https://docs.carp.dk/carp-mobile-sensing/
void main() async {
  // Register this sampling package before using its measures
  SamplingPackageRegistry().register(TransportationSamplingPackage());

  // Create a study protocol
  StudyProtocol protocol = StudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Transportation Sensing Example',
  );

  // Define which devices are used for data collection - only this smartphone
  Smartphone phone = Smartphone();
  protocol.addPrimaryDevice(phone);

  // Add a task that makes the transportation data types available for
  // collection. Data itself is added by app code below, not sensed
  // automatically.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: TransportationSamplingPackage.ROUTE),
        Measure(type: TransportationSamplingPackage.MODE),
        Measure(type: TransportationSamplingPackage.USER_FEEDBACK),
      ],
    ),
    phone,
  );

  // --- Later, at runtime, once the study is running ---

  // Assume `transportationProbe` is the running TransportationProbe looked
  // up from the deployment executor, e.g.:
  //
  //   var transportationProbe = Sensing()
  //       .controller!
  //       .executor
  //       .lookupProbe(TransportationSamplingPackage.ROUTE)
  //       .first as TransportationProbe;
  late TransportationProbe transportationProbe;

  // 1) The app collected a GPS trace (e.g. via carp_context_package's
  //    location probe) and finished a route - send it for classification.
  var route = Route(
    startTime: DateTime.now().subtract(const Duration(minutes: 20)),
    endTime: DateTime.now(),
    points: [
      RoutePoint(
        latitude: 55.6761,
        longitude: 12.5683,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      RoutePoint(
        latitude: 55.6765,
        longitude: 12.5690,
        timestamp: DateTime.now(),
      ),
    ],
  );
  transportationProbe.addMeasurement(Measurement.fromData(route));

  // 2) The server responded with a mode classification for that route.
  var mode = Mode(
    routeId: route.id,
    segments: [
      RouteSegment(
        startTime: route.startTime,
        endTime: route.endTime!,
        mode: TransportationModeType.cycling,
        confidence: 0.87,
      ),
    ],
  );
  transportationProbe.addMeasurement(Measurement.fromData(mode));

  // 3a) The user approved the detected mode of that segment.
  var approval = UserFeedback(
    routeId: route.id,
    segmentStartTime: mode.segments.first.startTime,
    segmentEndTime: mode.segments.first.endTime,
    feedbackType: FeedbackType.approved,
  );
  transportationProbe.addMeasurement(Measurement.fromData(approval));

  // 3b) ...or the user corrected it instead.
  var correction = UserFeedback(
    routeId: route.id,
    segmentStartTime: mode.segments.first.startTime,
    segmentEndTime: mode.segments.first.endTime,
    feedbackType: FeedbackType.corrected,
    correctedMode: TransportationModeType.bus,
  );
  transportationProbe.addMeasurement(Measurement.fromData(correction));

  // 3c) ...or the user labeled a cluster of locations as a known place.
  var placeLabel = UserFeedback(
    routeId: route.id,
    feedbackType: FeedbackType.labeled,
    placeLabel: PlaceLabel.home,
    locationCluster: [route.points.first],
  );
  transportationProbe.addMeasurement(Measurement.fromData(placeLabel));
}
