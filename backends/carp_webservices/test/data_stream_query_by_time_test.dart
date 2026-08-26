// Self-check for CarpDataStreamService.getDataStreamBatchesByTime's request
// shape, without hitting the network: endpoint path, DataStreamId JSON body,
// and the ISO-8601 `from`/`to` query params (must be UTC + parseable by the
// Kotlin `Instant` converter on the CAWS backend).
import 'dart:convert';

import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // registers the data types (StepCount, ...) used in the JSON below.
    CarpMobileSensing.ensureInitialized();
  });

  test('query-by-time endpoint path and request shape', () {
    expect(
      CarpDataStreamService.DATA_STREAM_QUERY_BY_TIME_ENDPOINT_NAME,
      'data-stream-service/query-by-time',
    );

    final dataStream = DataStreamId(
      studyDeploymentId: '00000000-0000-0000-0000-000000000000',
      deviceRoleName: 'Primary Phone',
      dataType: 'dk.cachet.carp.heartbeat',
    );

    // Body must be the plain DataStreamId JSON (mirrors what the Spring
    // controller decodes via WS_JSON.decodeFromString(DataStreamId.serializer())).
    final body = dataStream.toJson();
    expect(body['studyDeploymentId'], dataStream.studyDeploymentId);
    expect(body['deviceRoleName'], dataStream.deviceRoleName);
    expect(DataStreamId.fromJson(body).toJson(), body);

    // from/to must be UTC ISO-8601 instants ending in 'Z' so the Kotlin
    // backend's Instant converter accepts them as query params.
    final from = DateTime.utc(2026, 8, 1);
    final to = DateTime.utc(2026, 8, 5);
    expect(from.toUtc().toIso8601String(), '2026-08-01T00:00:00.000Z');
    expect(to.toUtc().toIso8601String(), '2026-08-05T00:00:00.000Z');
  });

  test('response is a JSON list of batches, one per contiguous run', () {
    // The endpoint returns an array - a new batch starts wherever the
    // sequence was interrupted - not a single DataStreamBatch object.
    final responseJson = json.decode('''
      [{"dataStream":{"studyDeploymentId":"4f282ef1-35a5-4e20-8ad7-744ac3c8a8bb",
        "deviceRoleName":"Primary Phone","dataType":"dk.cachet.carp.stepcount"},
        "firstSequenceId":1,"triggerIds":[4],
        "measurements":[{"sensorStartTime":1786965175523786,
          "data":{"__type":"dk.cachet.carp.stepcount","steps":187718}}]},
       {"dataStream":{"studyDeploymentId":"4f282ef1-35a5-4e20-8ad7-744ac3c8a8bb",
        "deviceRoleName":"Primary Phone","dataType":"dk.cachet.carp.stepcount"},
        "firstSequenceId":14,"triggerIds":[4],
        "measurements":[{"sensorStartTime":1787142486778844,
          "data":{"__type":"dk.cachet.carp.stepcount","steps":192862}}]}]
    ''');

    final batches = (responseJson as List<dynamic>)
        .map((batch) => DataStreamBatch.fromJson(batch as Map<String, dynamic>))
        .toList();

    expect(batches.length, 2);
    expect(batches.map((b) => b.firstSequenceId), [1, 14]);
    expect(batches.expand((b) => b.measurements).length, 2);
  });
}
