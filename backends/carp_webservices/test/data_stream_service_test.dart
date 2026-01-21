// import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import '_carp_properties.dart';
import '_credentials.dart';

void main() {
  CarpUser? user;

  /// Runs once before all tests.
  setUpAll(() async {
    Settings().debugLevel = DebugLevel.debug;
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    CarpMobileSensing.ensureInitialized();

    await CarpAuthService().configure(CarpProperties().authProperties);
    CarpService().configure(CarpProperties().app, CarpProperties().study);

    user = await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );

    CarpDataStreamService().configureFrom(CarpService());
  });

  /// Runs once after all tests.
  tearDownAll(() {});

  group("Base services", () {
    test('- authentication', () async {
      debugPrint('CarpService : ${CarpService().app}');
      debugPrint(" - signed in as: $user");
    }, skip: false);
  });

  group("Data Stream Service", () {
    test('- append - KNOWN measurements to carp-core.kotlin', () async {
      var m1 = Measurement(
        sensorStartTime: 1642505045000000,
        data: Geolocation(
          latitude: 55.68061908805645,
          longitude: 12.582050313435703,
        )..sensorSpecificData = SignalStrength(rssi: 0),
      );
      var m2 = Measurement(
        sensorStartTime: 1642505144000000,
        data: Geolocation(
          latitude: 55.680802203873114,
          longitude: 12.581802212861367,
        ),
      );
      var m3 = Measurement(
        sensorStartTime: 1642505045000000,
        data: StepCount(steps: 0),
      );
      var m4 = Measurement(
        sensorStartTime: 1642505144000000,
        data: StepCount(steps: 30),
      );

      var batch = [
        DataStreamBatch(
          dataStream: DataStreamId(
            studyDeploymentId: testDeploymentId,
            deviceRoleName: testPhoneRoleName,
            dataType: CarpDataTypes.GEOLOCATION,
          ),
          firstSequenceId: 0,
          measurements: [m1, m2],
          triggerIds: {0},
        ),
        DataStreamBatch(
          dataStream: DataStreamId(
            studyDeploymentId: testDeploymentId,
            deviceRoleName: testPhoneRoleName,
            dataType: CarpDataTypes.STEP_COUNT,
          ),
          firstSequenceId: 0,
          measurements: [m3, m4],
          triggerIds: {0},
        ),
      ];

      int length = 0;
      for (var item in batch) {
        length += item.measurements.length;
      }

      await CarpDataStreamService().appendToDataStreams(
        testDeploymentId,
        batch,
        compress: false, // no compression
      );
      debugPrint('Uploaded N=$length measurements.');
    });

    test('- append - UNKNOWN measurements to carp-core.kotlin', () async {
      var m1 = Measurement(
        sensorStartTime: 1642505045000000,
        data: BatteryState(100),
      );
      var m2 = Measurement(
        sensorStartTime: 1642505045000000,
        data: BatteryState(100),
      );

      var batch = [
        DataStreamBatch(
          dataStream: DataStreamId(
            studyDeploymentId: testDeploymentId,
            deviceRoleName: testPhoneRoleName,
            dataType: DeviceSamplingPackage.BATTERY_STATE,
          ),
          firstSequenceId: 0,
          measurements: [m1, m2],
          triggerIds: {0},
        ),
      ];

      int length = 0;
      for (var item in batch) {
        length += item.measurements.length;
      }

      // debugPrint(toJsonString(batch));
      await CarpDataStreamService().appendToDataStreams(
        testDeploymentId,
        batch,
        compress: false,
      );
      debugPrint('Uploaded N=$length measurements.');
    });

    test('- append - STOPPED deployment', () async {
      var m1 = Measurement(
        sensorStartTime: 1642505045000000,
        data: BatteryState(100),
      );
      var m2 = Measurement(
        sensorStartTime: 1642505045000000,
        data: BatteryState(100),
      );

      var batch = [
        DataStreamBatch(
          dataStream: DataStreamId(
            studyDeploymentId: stoppedDeploymentId,
            deviceRoleName: stoppedPhoneRoleName,
            dataType: DeviceSamplingPackage.BATTERY_STATE,
          ),
          firstSequenceId: 0,
          measurements: [m1, m2],
          triggerIds: {0},
        ),
      ];

      expect(
        () async => await CarpDataStreamService().appendToDataStreams(
          stoppedDeploymentId,
          batch,
          compress: false,
        ),
        throwsA(isA<CarpInternalServerException>()),
      );
    });

    test('- append - compressed (default)', () async {
      List<Measurement> upload = [];

      // Creating a batch of battery measurements, with "STATE_CONNECTED_NOT_CHARGING"
      // as the battery state. Easy to find later when downloading the data.
      for (var i = 0; i < 10; i++) {
        upload.add(
          Measurement(
            sensorStartTime: 1642505045000000 + 1000 * i,
            data: BatteryState(
              100 - i,
              BatteryState.STATE_CONNECTED_NOT_CHARGING,
            ),
          ),
        );
      }

      var batch = [
        DataStreamBatch(
          dataStream: DataStreamId(
            studyDeploymentId: testDeploymentId,
            deviceRoleName: testPhoneRoleName,
            dataType: DeviceSamplingPackage.BATTERY_STATE,
          ),
          firstSequenceId: 0,
          measurements: upload,
          triggerIds: {0},
        ),
      ];

      int length = 0;
      for (var item in batch) {
        length += item.measurements.length;
      }

      await CarpDataStreamService().appendToDataStreams(
        testDeploymentId,
        batch,
        compress: true, // default, so really not needed
      );
      debugPrint('Uploaded N=$length measurements.');
    });

    test('- append - compressed, STOPPED deployment', () async {
      List<Measurement> upload = [];

      for (var i = 0; i < 10; i++) {
        upload.add(
          Measurement(
            sensorStartTime: 1642505045000000 + 1000 * i,
            data: BatteryState(
              100 - i,
              BatteryState.STATE_CONNECTED_NOT_CHARGING,
            ),
          ),
        );
      }

      var batch = [
        DataStreamBatch(
          dataStream: DataStreamId(
            studyDeploymentId: stoppedDeploymentId,
            deviceRoleName: stoppedPhoneRoleName,
            dataType: DeviceSamplingPackage.BATTERY_STATE,
          ),
          firstSequenceId: 0,
          measurements: upload,
          triggerIds: {0},
        ),
      ];

      expect(
        () async => await CarpDataStreamService().appendToDataStreams(
          stoppedDeploymentId,
          batch,
        ),
        throwsA(isA<CarpInternalServerException>()),
      );
    });

    test('- get - Battery (up to 100)', () async {
      var list = await CarpDataStreamService().getDataStream(
        DataStreamId(
          studyDeploymentId: testDeploymentId,
          deviceRoleName: testPhoneRoleName,
          dataType: DeviceSamplingPackage.BATTERY_STATE,
        ),
        0,
        10,
      );
      debugPrint('No. Batches = ${list.length}');
      List<Measurement> measurements = [];

      for (var batch in list) {
        measurements.addAll(batch.measurements);
      }
      debugPrint('No. Measurements = ${measurements.length}');
      // debugPrint(toJsonString(measurements));
    });

    test('- get - BatteryState.STATE_CONNECTED_NOT_CHARGING', () async {
      var list = await CarpDataStreamService().getDataStream(
        DataStreamId(
          studyDeploymentId: testDeploymentId,
          deviceRoleName: testPhoneRoleName,
          dataType: DeviceSamplingPackage.BATTERY_STATE,
        ),
        0,
      );
      debugPrint('No. Batches = ${list.length}');

      List<Measurement> measurements = [];

      for (var batch in list) {
        measurements.addAll(batch.measurements);
      }
      debugPrint('No. Measurements = ${measurements.length}');
      // debugPrint(toJsonString(measurements));

      var selected = measurements
          .where(
            (item) =>
                (item.data as BatteryState).batteryStatus ==
                BatteryState.STATE_CONNECTED_NOT_CHARGING,
          )
          .toList();

      debugPrint(
        'No. BatteryState.STATE_CONNECTED_NOT_CHARGING = ${selected.length}',
      );
    });

    test('- get - Device Information - should throw', () async {
      // expect to throw an exception from CAWS from CARP Core, since
      // device information is not part of this protocol
      expect(
        () async => await CarpDataStreamService().getDataStream(
          DataStreamId(
            studyDeploymentId: testDeploymentId,
            deviceRoleName: testPhoneRoleName,
            dataType: DeviceSamplingPackage.DEVICE_INFORMATION,
          ),
          0,
          100,
        ),
        throwsException,
      );
    });

    // Some test data
    List<DataStreamBatch> geoLocationBatch = [
      DataStreamBatch(
        dataStream: DataStreamId(
          studyDeploymentId: testDeploymentId,
          deviceRoleName: testPhoneRoleName,
          dataType: CarpDataTypes.GEOLOCATION,
        ),
        firstSequenceId: 0,
        measurements: [
          Measurement(
            sensorStartTime: 1642505045000000,
            data: Geolocation(
              latitude: 55.68061908805645,
              longitude: 12.582050313435703,
            )..sensorSpecificData = SignalStrength(rssi: 0),
          ),
          Measurement(
            sensorStartTime: 1642505144000000,
            data: Geolocation(
              latitude: 55.680802203873114,
              longitude: 12.581802212861367,
            ),
          ),
        ],
        triggerIds: {0},
      ),
    ];

    Future<List<DataStreamBatch>> getGeoLocationBatches() async =>
        await CarpDataStreamService().getDataStream(
          DataStreamId(
            studyDeploymentId: testDeploymentId,
            deviceRoleName: testPhoneRoleName,
            dataType: CarpDataTypes.GEOLOCATION,
          ),
          0,
          100,
        );

    // This test tests for data upload/download consistency as reported in Issue #16
    // - https://github.com/cph-cachet/carp-webservices-spring/issues/16
    test('- upload & get - checking consistency (Issue #16)', () async {
      debugPrint('Getting Geolocation measurements ...');
      var list = await getGeoLocationBatches();
      debugPrint('N = ${list.length}');

      debugPrint('Uploading another batch of Geolocation measurements...');
      await CarpDataStreamService().appendToDataStreams(
        testDeploymentId,
        geoLocationBatch,
      );

      var list2 = await getGeoLocationBatches();
      debugPrint('N = ${list2.length}');

      expect(list2.length, list.length + 1);
    });
  });
}
