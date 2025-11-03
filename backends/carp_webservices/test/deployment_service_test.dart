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

      debugPrint('${CarpAuthService().manager?.discoveryDocument}');
    }, skip: false);

    test('- device ID', () async {
      String id = CarpDeploymentService().deployment().registeredDeviceId;
      debugPrint('Registered Device ID : $id');
    }, skip: false);
  });

  group("Deployment - using DeploymentReference", () {
    test('- get deployment status', () async {
      final status = await CarpDeploymentService().deployment().getStatus();
      debugPrint(toJsonString(status));
      expect(status.studyDeploymentId, testDeploymentId);
    });

    test('- register device', () async {
      final reference = CarpDeploymentService().deployment();
      var status = await reference.getStatus();
      debugPrint('$status');

      expect(status.primaryDeviceStatus!.device, isNotNull);
      debugPrint('${status.primaryDeviceStatus!.device}');
      var newStatus = await reference.registerPrimaryDevice();
      debugPrint('$newStatus');
      expect(newStatus.studyDeploymentId, testDeploymentId);
    }, skip: false);

    test('- get primary device deployment', () async {
      final reference = CarpDeploymentService().deployment();
      final status = await reference.getStatus();
      debugPrint('$status');
      expect(status.primaryDeviceStatus!.device, isNotNull);
      debugPrint('${status.primaryDeviceStatus!.device}');

      PrimaryDeviceDeployment deployment = await reference.get();
      debugPrint(toJsonString(deployment));
      expect(deployment.registration.deviceId, isNotNull);
    }, skip: false);

    test('- deployment success', () async {
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
      expect(status.primaryDeviceStatus!.device, isNotNull);
      debugPrint('${status.primaryDeviceStatus!.device}');
      status = await reference.unRegisterDevice(
          deviceRoleName: status.primaryDeviceStatus!.device.roleName);
      debugPrint('$status');
      expect(status.studyDeploymentId, testDeploymentId);
    }, skip: false);
  }, skip: true);

  group("Deployment - using CarpDeploymentService", () {
    test('- get deployment status', () async {
      StudyDeploymentStatus status = await CarpDeploymentService()
          .getStudyDeploymentStatus(testDeploymentId);
      debugPrint(toJsonString(status.toJson()));
      debugPrint('$status');
      debugPrint('{status.primaryDeviceStatus?.device}');
      debugPrint(toJsonString(status));
      expect(status.studyDeploymentId, testDeploymentId);
    }, skip: false);

    test('- register device', () async {
      // StudyDeploymentStatus status = await CarpDeploymentService()
      //     .getStudyDeploymentStatus(testDeploymentId);
      // debugPrint('$status');
      // expect(status.primaryDeviceStatus!.device, isNotNull);
      // debugPrint('{$status.primaryDeviceStatus?.device}');
      var status = await CarpDeploymentService().registerDevice(
          testDeploymentId,
          "Father's Phone",
          // status.primaryDeviceStatus!.device.roleName,
          DefaultDeviceRegistration(deviceDisplayName: 'Samsung A10'));
      debugPrint('$status');
      expect(status.studyDeploymentId, testDeploymentId);
    }, skip: false);

    test('- get primary device deployment', () async {
      StudyDeploymentStatus status = await CarpDeploymentService()
          .getStudyDeploymentStatus(testDeploymentId);
      debugPrint('$status');
      expect(status.primaryDeviceStatus!.device, isNotNull);
      debugPrint('${status.primaryDeviceStatus!.device}');
      PrimaryDeviceDeployment deployment =
          await CarpDeploymentService().getDeviceDeploymentFor(
        testDeploymentId,
        status.primaryDeviceStatus!.device.roleName,
      );
      debugPrint('$deployment');
      for (var task in deployment.tasks) {
        debugPrint('$task');
        task.measures?.forEach((measure) => debugPrint('$measure'));
      }
      expect(deployment.registration.deviceId, isNotNull);
    }, skip: false);

    test('- device deployed', () async {
      StudyDeploymentStatus status_1 = await CarpDeploymentService()
          .getStudyDeploymentStatus(testDeploymentId);
      debugPrint('$status_1');
      expect(status_1.primaryDeviceStatus!.device, isNotNull);
      debugPrint('${status_1.primaryDeviceStatus!.device}');
      PrimaryDeviceDeployment deployment =
          await CarpDeploymentService().getDeviceDeploymentFor(
        testDeploymentId,
        status_1.primaryDeviceStatus!.device.roleName,
      );
      debugPrint('$deployment');

      StudyDeploymentStatus status_2 =
          await CarpDeploymentService().deviceDeployed(
        testDeploymentId,
        status_1.primaryDeviceStatus!.device.roleName,
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
      expect(status.primaryDeviceStatus!.device, isNotNull);
      debugPrint('{$status.primaryDeviceStatus?.device}');
      status = await CarpDeploymentService().unregisterDevice(
          testDeploymentId, status.primaryDeviceStatus!.device.roleName);
      debugPrint('$status');
      expect(status.studyDeploymentId, testDeploymentId);
    }, skip: false);
  }, skip: true);
}
