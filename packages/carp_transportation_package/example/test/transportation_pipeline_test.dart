/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

import 'package:carp_context_package/carp_context_package.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_transportation_package/transportation.dart';
import 'package:carp_transportation_package_example/transportation_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    CarpMobileSensing.ensureInitialized();
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(TransportationSamplingPackage());
  });

  test('emits one transportation sample per buffered location', () {
    final emitted = <Data>[];
    final pipeline = TransportationPipeline(emit: emitted.add);

    final locations = List.generate(
      TransportationPipeline.batchSize,
      (i) => Location(latitude: 55.6 + i / 10000, longitude: 12.5)
        ..speed = i.toDouble()
        ..accuracy = 5
        ..time = DateTime(2026, 1, 1).add(Duration(seconds: i)),
    );

    for (var i = 0; i < locations.length; i++) {
      final isReady = pipeline.isBatchReady(
        Measurement.fromData(locations[i]),
      );
      expect(isReady, i == locations.length - 1, reason: 'batch of $i');
    }

    pipeline.runInference();

    // one model configuration + one sample per location, matching 1:1.
    final samples = emitted.whereType<TransportationSample>().toList();
    expect(emitted.whereType<TransportationModelConfiguration>(), hasLength(1));
    expect(samples, hasLength(locations.length));
    for (var i = 0; i < samples.length; i++) {
      expect(samples[i].latitude, locations[i].latitude);
      expect(samples[i].speed, locations[i].speed);
      expect(samples[i].timestamp, locations[i].time);
      expect(samples[i].sampleId, i);
    }

    // stationary at 0 m/s, walking at 1 m/s, driving at 14 m/s.
    expect(samples[0].mode, TransportationMode.stationary);
    expect(samples[1].mode, TransportationMode.walk);
    expect(samples[14].mode, TransportationMode.car);

    // the buffer is drained, so the next batch starts over.
    expect(pipeline.buffered, 0);
  });
}
