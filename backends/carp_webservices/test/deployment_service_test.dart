import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_credentials.dart';
import '_carp_properties.dart';

/// This test suite tests the [CarpDeploymentService].
void main() {
  CarpUser? user;

  Settings().debugLevel = DebugLevel.debug;
  SharedPreferences.setMockInitialValues({});
  WidgetsFlutterBinding.ensureInitialized();
  CarpMobileSensing.ensureInitialized();

  /// Configure CARP and authenticate.
  setUpAll(() async {
    await CarpAuthService().configure(CarpProperties().authProperties);
    CarpService().configure(CarpProperties().app, CarpProperties().study);

    user = await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );
    CarpDeploymentService().configureFrom(CarpService());
  });

  tearDownAll(() {});

  group("Base services", () {
    test('- authentication', () async {
      debugPrint('CarpService : ${CarpService().app}');
      debugPrint(" - signed in as: $user");

      // debugPrint('${CarpAuthService().manager?.discoveryDocument}');
    }, skip: false);

    test('- device ID', () async {
      String id = CarpDeploymentService().deployment().registeredDeviceId;
      debugPrint('Registered Device ID : $id');
    }, skip: false);
  });

  group("Deployment - using DeploymentReference", () {
    test('- get status', () async {
      final status = await CarpDeploymentService().deployment().getStatus();
      debugPrint(toJsonString(status));
      expect(status.studyDeploymentId, testDeploymentId);
    });

    test('- register device', () async {
      final reference = CarpDeploymentService().deployment();
      var status = await reference.getStatus();
      debugPrint('$status');

      expect(status.deviceStatusList.length, isNot(0));

      try {
        var newStatus = await reference.registerDevice();
        debugPrint('$newStatus');
        expect(newStatus.studyDeploymentId, testDeploymentId);
      } catch (error) {
        debugPrint('Error registering device: $error');

        // if device is already registered, CAWS returns a 400 Bad Request
        expect(error, isA<CarpBadRequestException>());
        expect(
          (error as CarpBadRequestException).message,
          startsWith('The passed device is already registered'),
        );
      }
    }, skip: false);

    test('- get primary device deployment', () async {
      final reference = CarpDeploymentService().deployment();
      final status = await reference.getStatus();
      debugPrint('$status');

      expect(status.deviceStatusList.length, isNot(0));

      PrimaryDeviceDeployment deployment = await reference.get();
      debugPrint(toJsonString(deployment));
      expect(deployment.registration.deviceId, isNotNull);
    }, skip: false);

    test('- deployed', () async {
      final reference = CarpDeploymentService().deployment();
      final status_1 = await reference.getStatus();
      debugPrint(toJsonString(status_1));

      final deployment = await reference.get();
      final status_2 = await reference.deployed();
      debugPrint(toJsonString(deployment));
      debugPrint(toJsonString(status_2));
      expect(status_1.studyDeploymentId, status_2.studyDeploymentId);
      expect(status_2.studyDeploymentId, testDeploymentId);
    }, skip: false);

    test('- unregister device', () async {
      final reference = CarpDeploymentService().deployment();
      var status = await reference.getStatus();
      debugPrint('$status');

      expect(status.deviceStatusList.length, isNot(0));
      status = await reference.unRegisterDevice();
      debugPrint('$status');

      expect(status.studyDeploymentId, testDeploymentId);
    }, skip: false);
  }, skip: true);

  group("Deployment - using CarpDeploymentService", () {
    test('- get status', () async {
      StudyDeploymentStatus status = await CarpDeploymentService()
          .getStudyDeploymentStatus(testDeploymentId);
      debugPrint(toJsonString(status.toJson()));
      debugPrint('$status');
      debugPrint('{status.primaryDeviceStatus?.device}');
      debugPrint(toJsonString(status));
      expect(status.studyDeploymentId, testDeploymentId);
    }, skip: false);

    test('- register device', () async {
      try {
        var status = await CarpDeploymentService().registerDevice(
          testDeploymentId,
          testPhoneRoleName,
          DefaultDeviceRegistration(deviceDisplayName: 'Samsung A10'),
        );
        debugPrint('$status');
        expect(status.studyDeploymentId, testDeploymentId);
      } catch (error) {
        debugPrint('Error registering device: $error');

        // if device is already registered, CAWS returns a 400 Bad Request
        expect(error, isA<CarpBadRequestException>());
        expect(
          (error as CarpBadRequestException).message,
          startsWith('The passed device is already registered'),
        );
      }
    }, skip: false);

    test('- register WRONG device', () async {
      try {
        await CarpDeploymentService().registerDevice(
          testDeploymentId,
          "WRONG Phone",
          DefaultDeviceRegistration(deviceDisplayName: 'Samsung A10'),
        );
      } catch (error) {
        // if a wrong device role name is used, CAWS returns a 400 Bad Request
        expect(error, isA<CarpBadRequestException>());
        expect(
          (error as CarpBadRequestException).message,
          startsWith(
            "A device with the role name 'WRONG Phone' could not be found in the study deployment",
          ),
        );
      }
    }, skip: false);

    test('- get primary device deployment', () async {
      StudyDeploymentStatus status = await CarpDeploymentService()
          .getStudyDeploymentStatus(testDeploymentId);
      debugPrint('$status');
      expect(status.deviceStatusList.length, isNot(0));
      debugPrint('${status.deviceStatusList.first.device}');

      PrimaryDeviceDeployment deployment = await CarpDeploymentService()
          .getDeviceDeploymentFor(
            testDeploymentId,
            status.deviceStatusList.first.device.roleName,
          );
      debugPrint('$deployment');
      for (var task in deployment.tasks) {
        debugPrint('$task');
        task.measures?.forEach((measure) => debugPrint('$measure'));
      }
      expect(deployment.registration.deviceId, isNotNull);
    }, skip: false);

    test('- deployed', () async {
      StudyDeploymentStatus status_1 = await CarpDeploymentService()
          .getStudyDeploymentStatus(testDeploymentId);
      debugPrint('$status_1');
      expect(status_1.deviceStatusList.length, isNot(0));
      debugPrint('${status_1.deviceStatusList.first.device}');
      PrimaryDeviceDeployment deployment = await CarpDeploymentService()
          .getDeviceDeploymentFor(
            testDeploymentId,
            status_1.deviceStatusList.first.device.roleName,
          );
      debugPrint('$deployment');

      StudyDeploymentStatus status_2 = await CarpDeploymentService()
          .deviceDeployed(
            testDeploymentId,
            status_1.deviceStatusList.first.device.roleName,
            deployment.lastUpdatedOn,
          );
      debugPrint('$status_2');
      expect(status_1.studyDeploymentId, status_2.studyDeploymentId);
      expect(status_2.studyDeploymentId, testDeploymentId);
    });

    test('- unregister device', () async {
      StudyDeploymentStatus status = await CarpDeploymentService()
          .getStudyDeploymentStatus(testDeploymentId);
      debugPrint('$status');
      expect(status.deviceStatusList.length, isNot(0));
      debugPrint('{$status.deviceStatusList.first.device}');
      status = await CarpDeploymentService().unregisterDevice(
        testDeploymentId,
        status.deviceStatusList.first.device.roleName,
      );
      debugPrint('$status');
      expect(status.studyDeploymentId, testDeploymentId);
    }, skip: false);
  }, skip: true);
}
