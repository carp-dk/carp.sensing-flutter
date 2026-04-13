import 'dart:io';

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import '../lib/main.dart';

/// Generates a protocol JSON file used for upload to CAWS server in integration tests.
/// Run this test file separately to generate the protocol.json file in
/// "test/resources/protocol.json".
/// Once generated, the file can be uploaded as a protocol in the CAWS portal and
/// used in a study deployment.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();

  Future<void> writeToFile(String json, String fileName) async {
    File file = File('test/resources/$fileName');
    await file.writeAsString(json);
    debugPrint("Done writing '$fileName'");
  }

  setUpAll(() async {
    // Set deployment mode matching the mode used in main.dart when testing.
    // This ensures that the data endpoint in the generated protocol matches
    // the deployment mode used in the app.
    //
    // Note, however, that it is possible to create a protocol with a local
    // endpoint and then use it in a dev, test, or prod deployment. Then data is
    // stored locally on the device, but the protocol is managed via CAWS.
    bloc.deploymentMode = DeploymentMode.dev;
  });

  /// Generates and save the study protocol as json file
  test(
    'protocol.json',
    () async => await writeToFile(
      toJsonString(await LocalStudyProtocolManager().getStudyProtocol('1234')),
      'protocol.json',
    ),
  );
}
