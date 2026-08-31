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

  /// A sample at [sampleId] seconds past 8:00, at ([latitude], [longitude]).
  TransportationSample sample(
    int sampleId,
    double latitude,
    double longitude, {
    double speed = 0,
    TransportationMode mode = TransportationMode.unknown,
  }) => TransportationSample(
    sampleId: sampleId,
    timestamp: DateTime.parse(
      '2026-08-20T08:00:00Z',
    ).add(Duration(seconds: sampleId)),
    latitude: latitude,
    longitude: longitude,
    speed: speed,
    mode: mode,
  );

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
          Measure(type: TransportationSamplingPackage.MODEL_CONFIGURATION),
          Measure(type: TransportationSamplingPackage.STAGE_CONFIGURATION),
          Measure(type: TransportationSamplingPackage.TRANSPORTATION_SAMPLE),
          Measure(type: TransportationSamplingPackage.MOVE),
          Measure(type: TransportationSamplingPackage.STOP),
          Measure(type: TransportationSamplingPackage.ACTIVITY),
          Measure(type: TransportationSamplingPackage.STAGE_MODE_CORRECTION),
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

  group('Configuration', () {
    test('numModes is derived from the mode labels', () {
      final config = TransportationModelConfiguration(
        embeddingModel: 'TransformerEncoder',
        modeLabels: {0: 'walk', 1: 'bike', 2: 'car', 3: 'bus', 4: 'train'},
        mainMethod: 'Transformer',
        decodeMethod: 'HMM',
      );

      expect(config.numModes, 5);
      expect(config.toJson()['numModes'], 5);

      final restored = TransportationModelConfiguration.fromJson(
        config.toJson(),
      );
      expect(restored.modeLabels[3], 'bus');
      expect(restored.numModes, 5);
    });

    test('StageConfiguration round-trip', () {
      final config = StageConfiguration(
        userId: 'user_001',
        segmentMethod: 'HMM',
      );
      final restored = StageConfiguration.fromJson(config.toJson());
      expect(restored.userId, 'user_001');
      expect(restored.segmentMethod, 'HMM');
    });
  });

  group('TransportationSample', () {
    test('serialization round-trip', () {
      final original = TransportationSample(
        sampleId: 1,
        timestamp: DateTime.parse('2026-08-19T09:15:23Z'),
        latitude: 57.7060,
        longitude: 11.9670,
        altitude: 18.4,
        gpsAccuracy: 6.2,
        speed: 5.8,
        heading: 135,
        embedding: [0.12, -0.08, 0.31],
        mode: TransportationMode.bus,
        logits: {'walk': 1.2, 'bus': 3.5},
        probabilities: {'walk': 0.35, 'bus': 0.65},
      );

      final json = original.toJson();
      final restored = TransportationSample.fromJson(json);

      expect(json['embeddingDim'], 3);
      expect(restored.mode, TransportationMode.bus);
      expect(restored.embeddingDim, 3);
      expect(restored.probabilities!['bus'], 0.65);
      expect(restored.confidence, closeTo(original.confidence, 1e-12));
      expect(restored.toJson(), equals(json));
    });

    test('confidence is derived from the entropy of the probabilities', () {
      // A uniform distribution has maximum entropy -> zero confidence.
      expect(
        TransportationSample.confidenceFromProbabilities({
          'walk': 0.5,
          'bus': 0.5,
        }),
        closeTo(0, 1e-12),
      );
      // A one-hot distribution has zero entropy -> full confidence.
      expect(
        TransportationSample.confidenceFromProbabilities({
          'walk': 1.0,
          'bus': 0.0,
        }),
        closeTo(1, 1e-12),
      );
      // A skewed distribution lies in between.
      final confidence = TransportationSample.confidenceFromProbabilities({
        'walk': 0.07,
        'bike': 0.03,
        'car': 0.18,
        'bus': 0.65,
        'train': 0.07,
      });
      expect(confidence, greaterThan(0));
      expect(confidence, lessThan(1));

      // ...and is used as the sample's confidence when not given explicitly.
      expect(
        TransportationSample(
          sampleId: 0,
          timestamp: DateTime.now(),
          latitude: 0,
          longitude: 0,
          probabilities: {'walk': 1.0, 'bus': 0.0},
        ).confidence,
        closeTo(1, 1e-12),
      );
    });

    test('unrecognized mode from the classifier falls back to other', () {
      final json = {
        '__type': TransportationSamplingPackage.TRANSPORTATION_SAMPLE,
        'sampleId': 0,
        'timestamp': '2026-08-20T08:00:00.000Z',
        'latitude': 55.6761,
        'longitude': 12.5683,
        'mode': 'e-scooter',
        'confidence': 0.5,
      };

      expect(
        TransportationSample.fromJson(json).mode,
        TransportationMode.other,
      );
    });
  });

  group('MoveStage', () {
    // ~62 m apart along a longitude, ~1 m/s over the 60 s covered.
    final samples = [
      sample(0, 55.6761, 12.5683, speed: 0.8, mode: TransportationMode.walk),
      sample(30, 55.6761, 12.5688, speed: 1.0, mode: TransportationMode.walk),
      sample(60, 55.6761, 12.5693, speed: 1.2, mode: TransportationMode.walk),
    ];

    test('derives boundaries, distance and speed stats from its samples', () {
      final move = MoveStage.fromSamples(
        samples,
        stageId: 2,
        mode: TransportationMode.walk,
      );

      expect(move.startSampleId, 0);
      expect(move.endSampleId, 60);
      expect(move.numSamples, 61);
      expect(move.durationInMinutes, 1);
      expect(move.startLatitude, 55.6761);
      expect(move.endLongitude, 12.5693);
      expect(move.distance, closeTo(62.6, 1));
      expect(move.speedMean, closeTo(1.0, 1e-12));
      expect(move.speedMin, 0.8);
      expect(move.speedMax, 1.2);
      expect(move.speedStd, closeTo(0.163, 0.01));
    });

    test('serialization round-trip incl. derived attributes', () {
      final move = MoveStage.fromSamples(
        samples,
        stageId: 2,
        mode: TransportationMode.bus,
      )
        ..isPublicTransport = true
        ..transitLine = '150S'
        ..transitLineCandidates = {'150S': 0.72, '6A': 0.18};

      final json = move.toJson();
      final restored = MoveStage.fromJson(json);

      expect(json['numSamples'], 61);
      expect(json['durationInMinutes'], 1);
      expect(restored.mode, TransportationMode.bus);
      expect(restored.isPublicTransport, isTrue);
      expect(restored.transitLineCandidates!['150S'], 0.72);
      expect(restored.toJson(), equals(json));
    });

    test('a MoveStage must span at least one sample', () {
      expect(() => MoveStage.fromSamples([], stageId: 0), throwsArgumentError);
    });
  });

  group('StopStage', () {
    test('derives the centroid and max displacement from its samples', () {
      final stop = StopStage.fromSamples([
        sample(100, 55.6760, 12.5683),
        sample(160, 55.6762, 12.5683),
      ], stageId: 1);

      expect(stop.mode, TransportationMode.stationary);
      expect(stop.centroidLatitude, closeTo(55.6761, 1e-9));
      expect(stop.centroidLongitude, 12.5683);
      // Both samples are ~11 m from the centroid on the latitude axis.
      expect(stop.maxDisplacement, closeTo(11.1, 1));

      final restored = StopStage.fromJson(stop.toJson());
      expect(restored.numSamples, 61);
      expect(restored.centroidLatitude, stop.centroidLatitude);
    });
  });

  group('MobilityActivity', () {
    test('serialization round-trip incl. derived dwell time', () {
      final activity = MobilityActivity(
        activityId: 1,
        stopId: 1,
        activityType: MobilityActivityType.work,
        startTime: DateTime.parse('2026-08-20T08:30:00Z'),
        endTime: DateTime.parse('2026-08-20T16:30:00Z'),
        placeCategory: 'office',
        confidence: 0.91,
      );

      final json = activity.toJson();
      final restored = MobilityActivity.fromJson(json);

      expect(json['dwellTime'], 8 * 60);
      expect(restored.activityType, MobilityActivityType.work);
      expect(restored.stopId, 1);
      expect(restored.dwellTime, 8 * 60);
    });

    test('unrecognized activity type falls back to unknown', () {
      final json = {
        '__type': TransportationSamplingPackage.ACTIVITY,
        'activityId': 1,
        'activityType': 'volunteering',
        'startTime': '2026-08-20T08:30:00.000Z',
        'endTime': '2026-08-20T09:30:00.000Z',
      };

      expect(
        MobilityActivity.fromJson(json).activityType,
        MobilityActivityType.unknown,
      );
    });
  });

  group('StageModeCorrection', () {
    test('serialization round-trip', () {
      final correction = StageModeCorrection(
        userId: 'user_001',
        date: DateTime.parse('2026-08-20T00:00:00Z'),
        stageId: 2,
        originalMode: TransportationMode.bus,
        correctedMode: TransportationMode.car,
        originalConfidence: 0.65,
        feedbackTime: DateTime.parse('2026-08-20T18:00:00Z'),
        comment: 'I drove',
      );

      final restored = StageModeCorrection.fromJson(correction.toJson());

      expect(restored.correctionId, correction.correctionId);
      expect(restored.originalMode, TransportationMode.bus);
      expect(restored.correctedMode, TransportationMode.car);
      expect(restored.isLatest, isTrue);
      expect(restored.comment, 'I drove');
    });

    test('correctionId is auto-generated when not provided', () {
      StageModeCorrection correction() => StageModeCorrection(
        userId: 'user_001',
        date: DateTime.now(),
        stageId: 0,
        originalMode: TransportationMode.bus,
        correctedMode: TransportationMode.car,
        feedbackTime: DateTime.now(),
      );

      expect(correction().correctionId, isNotEmpty);
      expect(correction().correctionId, isNot(correction().correctionId));
    });
  });

  test(
    'TransportationProbe.addMeasurement pushes data onto the measurements stream',
    () async {
      final probe = TransportationProbe();
      final data = sample(0, 55.6761, 12.5683);

      final future = probe.measurements.first;
      probe.addMeasurement(Measurement.fromData(data));
      final measurement = await future;

      expect(measurement.data, isA<TransportationSample>());
      expect((measurement.data as TransportationSample).sampleId, 0);
    },
  );
}
