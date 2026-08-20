import 'dart:convert';
import 'dart:io';
import 'package:carp_transportation_package/transportation.dart';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

void main() {
  late StudyProtocol protocol;
  late Smartphone phone;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUpAll(() {
    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();

    // register the transportation sampling package
    SamplingPackageRegistry().register(TransportationSamplingPackage());

    // Create a new study protocol.
    protocol = StudyProtocol(
      ownerId: 'alex@uni.dk',
      name: 'Transportation package test',
    );

    // Define which devices are used for data collection.
    phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // add all data types of this package to one background task
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..measures = [
          Measure(type: TransportationSamplingPackage.ROUTE),
          Measure(type: TransportationSamplingPackage.MODE),
          Measure(type: TransportationSamplingPackage.USER_FEEDBACK),
        ],
      phone,
    );
  });

  test('StudyProtocol -> JSON -> StudyProtocol :: deep assert', () async {
    final studyJson = toJsonString(protocol);
    await writeToFile(studyJson, 'study_protocol.json');

    StudyProtocol protocolFromJson = StudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), equals(studyJson));
  });

  group('Route', () {
    test('serialization round-trip', () {
      final route = Route(
        startTime: DateTime.parse('2026-08-20T08:00:00Z'),
        endTime: DateTime.parse('2026-08-20T08:15:00Z'),
        points: [
          RoutePoint(
            latitude: 55.6761,
            longitude: 12.5683,
            timestamp: DateTime.parse('2026-08-20T08:00:00Z'),
            accuracy: 5,
          ),
          RoutePoint(
            latitude: 55.6765,
            longitude: 12.5690,
            timestamp: DateTime.parse('2026-08-20T08:05:00Z'),
          ),
        ],
      );

      final json = route.toJson();
      final restored = Route.fromJson(json);

      expect(restored.id, route.id);
      expect(restored.points.length, 2);
      expect(restored.points.first.latitude, 55.6761);
      expect(restored.toJson(), equals(json));
    });

    test('id is auto-generated when not provided', () {
      final a = Route(startTime: DateTime.now());
      final b = Route(startTime: DateTime.now());
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id)));
    });
  });

  group('Mode', () {
    test('serialization round-trip incl. segment mode enum', () {
      final mode = Mode(
        routeId: 'route-1',
        segments: [
          RouteSegment(
            startTime: DateTime.parse('2026-08-20T08:00:00Z'),
            endTime: DateTime.parse('2026-08-20T08:05:00Z'),
            mode: TransportationModeType.walking,
            confidence: 0.92,
          ),
          RouteSegment(
            startTime: DateTime.parse('2026-08-20T08:05:00Z'),
            endTime: DateTime.parse('2026-08-20T08:15:00Z'),
            mode: TransportationModeType.bus,
            confidence: 0.81,
          ),
        ],
      );

      final json = mode.toJson();
      final restored = Mode.fromJson(json);

      expect(restored.routeId, 'route-1');
      expect(restored.segments.length, 2);
      expect(restored.segments[0].mode, TransportationModeType.walking);
      expect(restored.segments[1].mode, TransportationModeType.bus);
    });

    test('unrecognized mode string from server falls back to other', () {
      // Simulates the server returning a mode value not yet known to this
      // client version - deserialization must not throw.
      final json = {
        '__type': TransportationSamplingPackage.MODE,
        'routeId': 'route-2',
        'segments': [
          {
            'startTime': '2026-08-20T08:00:00.000Z',
            'endTime': '2026-08-20T08:05:00.000Z',
            'mode': 'e-scooter',
          },
        ],
      };

      final restored = Mode.fromJson(json);
      expect(restored.segments.single.mode, TransportationModeType.other);
    });
  });

  group('UserFeedback', () {
    test('approve/reject/correct a segment', () {
      final approved = UserFeedback(
        routeId: 'route-1',
        segmentStartTime: DateTime.parse('2026-08-20T08:00:00Z'),
        segmentEndTime: DateTime.parse('2026-08-20T08:05:00Z'),
        feedbackType: FeedbackType.approved,
      );
      final corrected = UserFeedback(
        routeId: 'route-1',
        segmentStartTime: DateTime.parse('2026-08-20T08:05:00Z'),
        segmentEndTime: DateTime.parse('2026-08-20T08:15:00Z'),
        feedbackType: FeedbackType.corrected,
        correctedMode: TransportationModeType.cycling,
      );

      expect(
        UserFeedback.fromJson(approved.toJson()).feedbackType,
        FeedbackType.approved,
      );
      expect(
        UserFeedback.fromJson(corrected.toJson()).correctedMode,
        TransportationModeType.cycling,
      );
    });

    test('label a cluster of locations as a place', () {
      final feedback = UserFeedback(
        routeId: 'route-1',
        feedbackType: FeedbackType.labeled,
        placeLabel: PlaceLabel.home,
        locationCluster: [
          RoutePoint(
            latitude: 55.6761,
            longitude: 12.5683,
            timestamp: DateTime.parse('2026-08-20T08:00:00Z'),
          ),
        ],
      );

      final restored = UserFeedback.fromJson(feedback.toJson());
      expect(restored.feedbackType, FeedbackType.labeled);
      expect(restored.placeLabel, PlaceLabel.home);
      expect(restored.locationCluster, isNotNull);
      expect(restored.locationCluster!.single.latitude, 55.6761);
      expect(restored.segmentStartTime, isNull);
    });
  });

  test(
    'TransportationProbe.addMeasurement pushes data onto the measurements stream',
    () async {
      final probe = TransportationProbe();
      final route = Route(startTime: DateTime.now());

      final future = probe.measurements.first;
      probe.addMeasurement(Measurement.fromData(route));
      final measurement = await future;

      expect(measurement.data, isA<Route>());
      expect((measurement.data as Route).id, route.id);
    },
  );
}
