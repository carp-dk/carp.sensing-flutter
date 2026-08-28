import 'package:carp_core/carp_core.dart' hide Smartphone, BLEHeartRateDevice;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:test/test.dart';

/// Tests that protocols and deployments created with CAMS 1.x
/// (protocol API level < 2.0) - where devices used the carp_core device
/// namespace - still can be deserialized into the CAMS 2.x domain classes.
void main() {
  setUp(() {
    CarpMobileSensing.ensureInitialized();
  });

  group('API Level 1.x Backwards Compatibility', () {
    test(' - 1.x smartphone configuration', () {
      final device = PrimaryDeviceConfiguration.fromJson({
        '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.Smartphone',
        'roleName': 'Primary Phone',
        'isOptional': false,
        'defaultSamplingConfiguration': <String, dynamic>{},
        'isPrimaryDevice': true,
      });

      expect(device, isA<Smartphone>());
      expect(device.roleName, 'Primary Phone');
      expect(device.type, Smartphone.DEVICE_TYPE);
    });

    test(' - 1.x smartphone device registration', () {
      final registration = DeviceRegistration.fromJson({
        '__type':
            '${DeviceConfiguration.DEVICE_NAMESPACE}.SmartphoneDeviceRegistration',
        'deviceId': '123',
        'registrationCreatedOn': '2025-10-23T07:46:11.643113Z',
        'platform': 'Android',
        'deviceModel': 'Pixel 7',
        'sdk': '34',
      });

      expect(registration, isA<SmartphoneRegistration>());
      expect((registration as SmartphoneRegistration).platform, 'Android');
      expect(registration.deviceId, '123');
    });

    test(' - 1.x BLE heart rate device w/o scan configuration', () {
      final device = DeviceConfiguration.fromJson({
        '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.BLEHeartRateDevice',
        'roleName': 'HR Monitor',
        'isOptional': true,
        'defaultSamplingConfiguration': <String, dynamic>{},
      });

      expect(device, isA<BLEHeartRateDevice>());
      expect((device as BLEHeartRateDevice).serviceUuids, isEmpty);
      expect(device.allowDuplicates, true);
    });

    test(' - 1.x study protocol w. old device namespace and measure types',
        () {
      final protocol = SmartphoneStudyProtocol.fromJson({
        'applicationData': {
          'studyDescription': {
            '__type': 'StudyDescription',
            'title': 'study.description.title',
            'description': 'study.description.description',
            'purpose': 'study.description.purpose',
          },
        },
        'id': '71b71133-ebbf-436c-851f-73cac1df3d36',
        'createdOn': '2025-10-23T07:46:11.643113Z',
        'version': 0,
        'description': 'study.description.description',
        'ownerId': '979b408d-784e-4b1b-bb1e-ff9204e072f3',
        'name': 'CARP Demo Protocol',
        'participantRoles': [
          {'role': 'Participant', 'isOptional': false},
        ],
        'primaryDevices': [
          {
            '__type': '${DeviceConfiguration.DEVICE_NAMESPACE}.Smartphone',
            'roleName': 'Primary Phone',
            'isOptional': false,
            'defaultSamplingConfiguration': <String, dynamic>{},
            'isPrimaryDevice': true,
          },
        ],
        'connectedDevices': <Map<String, dynamic>>[],
        'connections': <Map<String, dynamic>>[],
        'assignedDevices': <String, dynamic>{},
        'tasks': [
          {
            '__type': 'dk.cachet.carp.common.application.tasks.BackgroundTask',
            'name': 'Task #11',
            'measures': [
              {
                '__type':
                    'dk.cachet.carp.common.application.tasks.Measure.DataStream',
                'type': 'dk.cachet.carp.stepcount',
              },
              {
                '__type':
                    'dk.cachet.carp.common.application.tasks.Measure.DataStream',
                'type': 'dk.cachet.carp.heartbeat',
              },
            ],
          },
        ],
        'triggers': {
          '0': {
            '__type':
                'dk.cachet.carp.common.application.triggers.ImmediateTrigger',
            'sourceDeviceRoleName': 'Primary Phone',
          },
        },
        'taskControls': [
          {
            'triggerId': 0,
            'taskName': 'Task #11',
            'destinationDeviceRoleName': 'Primary Phone',
            'control': 'Start',
          },
        ],
        'expectedParticipantData': <Map<String, dynamic>>[],
      });

      expect(protocol.primaryDevice, isA<Smartphone>());
      expect(protocol.primaryDevice.type, Smartphone.DEVICE_TYPE);

      // a 1.x protocol has no API level specified
      expect(protocol.protocolApiLevel, isNull);
    });

    test(' - 1.x step count measure type is still supported', () {
      // Step count moved to the ActivitySamplingPackage in API level 3.0 -
      // activity recognition is a permission of its own. A 1.x protocol asking
      // for it by name must still resolve to a probe.
      final packages = SamplingPackageRegistry().lookup(
        SensorSamplingPackage.STEP_COUNT,
      );

      expect(packages, isNotEmpty);
      expect(
        packages.first.create(SensorSamplingPackage.STEP_COUNT),
        isA<StepCountProbe>(),
      );
    });

    test(' - 1.x protocol gets the service devices its measures need', () {
      // A 1.x protocol declares only the phone, and collects step count on it.
      // Step count now samples through the ActivityService, which such a
      // protocol cannot know to declare - so CAMS adds it, or the probe would
      // never get a connected device to sample through.
      final protocol = SmartphoneStudyProtocol(
        ownerId: 'test',
        name: '1.x protocol',
      )..addPrimaryDevice(Smartphone());

      protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(
          measures: [Measure(type: SensorSamplingPackage.STEP_COUNT)],
        ),
        protocol.primaryDevice,
        Control.Start,
      );

      final deployment = SmartphoneDeployment.fromSmartphoneStudyProtocol(
        studyDeploymentId: 'test',
        primaryDeviceRoleName: protocol.primaryDevice.roleName,
        protocol: protocol,
      );

      expect(
        deployment.devices.map((device) => device.type),
        isNot(contains(ActivityService.DEVICE_TYPE)),
      );

      addMissingServiceDevices(deployment);

      expect(
        deployment.devices.map((device) => device.type),
        contains(ActivityService.DEVICE_TYPE),
      );
    });
  });
}
