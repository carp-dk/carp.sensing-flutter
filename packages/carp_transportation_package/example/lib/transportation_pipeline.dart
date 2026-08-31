/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

import 'dart:math';

import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_transportation_package/transportation.dart';

/// The mobility processing pipeline of the example app.
///
/// It buffers the [Location] measurements sampled by the location service
/// (which is configured with `distance: 0`, so every location update is
/// collected) and, once [batchSize] of them are buffered, "runs inference"
/// over the batch and emits one [TransportationSample] per buffered location -
/// a 1:1 match, carrying the same coordinates, speed and heading.
///
/// In a real deployment [_infer] would be an ML model over a window of raw
/// samples. Here the model output (mode, probabilities, embedding) is mocked
/// from the observed speed - everything else comes from the actual GPS fix.
class TransportationPipeline {
  /// The number of location samples inference runs over at a time.
  static const int batchSize = 15;

  /// Called with every [Data] object the pipeline produces.
  final void Function(Data data) emit;

  TransportationPipeline({required this.emit});

  final List<Location> _buffer = [];
  final Random _random = Random();
  int _sampleId = 0;
  bool _isConfigurationEmitted = false;

  /// The number of locations buffered so far, out of [batchSize].
  int get buffered => _buffer.length;

  /// The number of transportation samples emitted so far.
  int get numSamplesEmitted => _sampleId;

  /// Buffers the location of [measurement] and reports whether a full batch is
  /// ready for inference. Used as the trigger condition of the study protocol.
  bool isBatchReady(Measurement measurement) {
    if (measurement.data is Location) _buffer.add(measurement.data as Location);
    return _buffer.length >= batchSize;
  }

  /// Runs inference over the buffered batch, emitting one
  /// [TransportationSample] per buffered [Location]. Called by the protocol's
  /// function task whenever [isBatchReady] triggered.
  void runInference() {
    if (!_isConfigurationEmitted) {
      emit(
        TransportationModelConfiguration(
          embeddingModel: 'TransformerEncoder',
          modeLabels: {0: 'walk', 1: 'bike', 2: 'car', 3: 'bus', 4: 'train'},
          mainMethod: 'Transformer',
          decodeMethod: 'argmax',
        ),
      );
      _isConfigurationEmitted = true;
    }

    for (var location in _buffer) {
      emit(_infer(location));
    }
    _buffer.clear();
  }

  /// One transportation sample for one location fix - the mocked model output.
  TransportationSample _infer(Location location) {
    final speed = location.speed ?? 0;
    final mode = _modeFor(speed);

    return TransportationSample(
      sampleId: _sampleId++,
      timestamp: location.time ?? DateTime.now(),
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: location.altitude ?? 0,
      gpsAccuracy: location.accuracy ?? 0,
      speed: speed,
      heading: location.heading ?? 0,
      embedding: List.generate(8, (_) => _random.nextDouble() * 2 - 1),
      mode: mode,
      probabilities: _probabilitiesFor(mode),
    );
  }

  /// Mocked mode prediction - the model is a speed threshold.
  TransportationMode _modeFor(double speed) => switch (speed) {
    < 0.3 => TransportationMode.stationary,
    < 2.5 => TransportationMode.walk,
    < 7 => TransportationMode.bike,
    < 20 => TransportationMode.car,
    _ => TransportationMode.train,
  };

  /// A distribution peaking at [mode], so the sample's confidence is derived
  /// from a realistic probability distribution.
  Map<String, double> _probabilitiesFor(TransportationMode mode) {
    const candidates = ['walk', 'bike', 'car', 'bus', 'train'];
    final peak = mode == TransportationMode.stationary ? 'walk' : mode.name;
    final peakProbability = 0.6 + _random.nextDouble() * 0.35;
    final rest = (1 - peakProbability) / (candidates.length - 1);
    return {for (var c in candidates) c: c == peak ? peakProbability : rest};
  }
}
