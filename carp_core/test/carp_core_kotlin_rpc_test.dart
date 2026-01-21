import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_serializable/carp_serializable.dart';

void main() {
  const String apiVersion = '1.1.1';
  const String path = 'test/json/carp.core-kotlin/$apiVersion';
  const testDeploymentId = 'c9cc5317-48da-45f2-958e-58bc07f34681';

  setUp(() {
    Core();
  });

  group('Protocol Service', () {
    test('Add - Request', () async {
      String rpcString = File(
        '$path/protocols/ProtocolService/add.json',
      ).readAsStringSync();

      var expected = Add.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      String plainJson = File(
        '$path/protocols/study_protocol.json',
      ).readAsStringSync();
      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      var request = Add(protocol, 'Version 1');

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('Add - Response', () async {
      String plainJson = File(
        '$path/protocols/ProtocolService/add-response.json',
      ).readAsStringSync();
      // the response is empty
      print(toJsonString(plainJson));
    });

    test('AddVersion - Request', () async {
      String rpcString = File(
        '$path/protocols/ProtocolService/addVersion.json',
      ).readAsStringSync();

      var expected = AddVersion.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      String plainJson = File(
        '$path/protocols/study_protocol.json',
      ).readAsStringSync();
      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      // the name and the version number is updated
      protocol.name = 'Walking/biking study';
      var request = AddVersion(protocol, 'Version 2: new name');

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('AddVersion - Response', () async {
      String plainJson = File(
        '$path/protocols/ProtocolService/addVersion-response.json',
      ).readAsStringSync();
      // the response is empty
      print(toJsonString(plainJson));
    });

    test('UpdateParticipantDataConfiguration - Request', () async {
      String rpcString = File(
        '$path/protocols/ProtocolService/updateParticipantDataConfiguration.json',
      ).readAsStringSync();

      var expected = UpdateParticipantDataConfiguration.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = UpdateParticipantDataConfiguration(
        '25fe92a5-0d52-4e37-8d05-31f347d72d3d',
        'Version 3: ask participant data',
        [
          ExpectedParticipantData(
            attribute: ParticipantAttribute(
              inputDataType: 'dk.cachet.carp.input.sex',
            ),
            assignedTo: AssignedTo(roleNames: {'Participant'}),
          ),
        ],
      );

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('UpdateParticipantDataConfiguration - Response', () async {
      String plainJson = File(
        '$path/protocols/ProtocolService/updateParticipantDataConfiguration-response.json',
      ).readAsStringSync();

      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      print(toJsonString(protocol));
      expect(protocol.id, '25fe92a5-0d52-4e37-8d05-31f347d72d3d');
      expect(protocol.name, 'Nonmotorized transport study');
    });

    test('GetBy - Request', () async {
      String rpcString = File(
        '$path/protocols/ProtocolService/getBy.json',
      ).readAsStringSync();

      var expected = GetBy.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = GetBy('25fe92a5-0d52-4e37-8d05-31f347d72d3d', 'Version 1');

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('GetBy - Response', () async {
      String plainJson = File(
        '$path/protocols/ProtocolService/getBy-response.json',
      ).readAsStringSync();

      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      print(toJsonString(protocol));
      expect(protocol.id, '25fe92a5-0d52-4e37-8d05-31f347d72d3d');
      expect(protocol.name, 'Nonmotorized transport study');
    });

    test('GetAllForOwner - Request', () async {
      String rpcString = File(
        '$path/protocols/ProtocolService/getAllForOwner.json',
      ).readAsStringSync();

      var expected = GetAllForOwner.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = GetAllForOwner('491f03fc-964b-4783-86a6-a528bbfe4e94');

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('GetAllForOwner - Response', () async {
      String plainJson = File(
        '$path/protocols/ProtocolService/getAllForOwner-response.json',
      ).readAsStringSync();

      var list = json.decode(plainJson) as List<dynamic>;
      var protocol = StudyProtocol.fromJson(list[0] as Map<String, dynamic>);

      print(toJsonString(protocol));
      expect(protocol.id, '25fe92a5-0d52-4e37-8d05-31f347d72d3d');
      expect(protocol.name, 'Nonmotorized transport study');
    });

    test('GetVersionHistoryFor - Request', () async {
      String rpcString = File(
        '$path/protocols/ProtocolService/getVersionHistoryFor.json',
      ).readAsStringSync();

      var expected = GetVersionHistoryFor.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = GetVersionHistoryFor(
        '25fe92a5-0d52-4e37-8d05-31f347d72d3d',
      );

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('GetVersionHistoryFor - Response', () async {
      String plainJson = File(
        '$path/protocols/ProtocolService/getVersionHistoryFor-response.json',
      ).readAsStringSync();

      var list = json.decode(plainJson) as List<dynamic>;
      print(toJsonString(list));

      var version = ProtocolVersion.fromJson(list[0] as Map<String, dynamic>);
      expect(version.tag, 'Version 1');
      expect(version.date, DateTime.tryParse('2022-01-18T10:56:59Z'));
    });
  });

  group('ProtocolFactory Service', () {
    test('CreateCustomProtocol - Request', () async {
      String rpcString = File(
        '$path/protocols/ProtocolFactoryService/createCustomProtocol.json',
      ).readAsStringSync();

      var expected = CreateCustomProtocol.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = CreateCustomProtocol(
        '491f03fc-964b-4783-86a6-a528bbfe4e94',
        'Fictional Company study',
        "Collect heartrate and GPS using Fictional Company's software.",
        '{"collect-data": "heartrate, gps"}',
      );

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('CreateCustomProtocol - Response', () async {
      String plainJson = File(
        '$path/protocols/ProtocolFactoryService/createCustomProtocol-response.json',
      ).readAsStringSync();

      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      print(toJsonString(protocol));
      expect(protocol.id, '4d8c75c7-9604-48fa-8f9b-5ed3e4bd5df8');
      expect(protocol.name, 'Fictional Company study');
    });
  });
  group('DataStream Service', () {
    test('OpenDataStreams - Request', () async {
      String rpcString = File(
        '$path/data/DataStreamService/openDataStreams.json',
      ).readAsStringSync();

      var expected = OpenDataStreams.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = OpenDataStreams(
        DataStreamsConfiguration(
          studyDeploymentId: 'c9cc5317-48da-45f2-958e-58bc07f34681',
          expectedDataStreams: {
            ExpectedDataStream(
              dataType: 'dk.cachet.carp.geolocation',
              deviceRoleName: "Participant's phone",
            ),
            ExpectedDataStream(
              dataType: 'dk.cachet.carp.stepcount',
              deviceRoleName: "Participant's phone",
            ),
          },
        ),
      );

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('OpenDataStreams - Response', () async {
      String plainJson = File(
        '$path/data/DataStreamService/openDataStreams-response.json',
      ).readAsStringSync();

      // the response is empty
      print(toJsonString(plainJson));
    });

    test('AppendToDataStreams - Request', () async {
      String rpcString = File(
        '$path/data/DataStreamService/appendToDataStreams.json',
      ).readAsStringSync();

      var expected = AppendToDataStreams.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );
      print(toJsonString(expected));

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

      var request = AppendToDataStreams(
        'c9cc5317-48da-45f2-958e-58bc07f34681',
        [
          DataStreamBatch(
            dataStream: DataStreamId(
              studyDeploymentId: 'c9cc5317-48da-45f2-958e-58bc07f34681',
              deviceRoleName: "Participant's phone",
              dataType: "dk.cachet.carp.geolocation",
            ),
            firstSequenceId: 0,
            measurements: [m1, m2],
            triggerIds: {0},
          ),
          DataStreamBatch(
            dataStream: DataStreamId(
              studyDeploymentId: 'c9cc5317-48da-45f2-958e-58bc07f34681',
              deviceRoleName: "Participant's phone",
              dataType: "dk.cachet.carp.stepcount",
            ),
            firstSequenceId: 0,
            measurements: [m3, m4],
            triggerIds: {0},
          ),
        ],
      );

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('AppendToDataStreams - Response', () async {
      String plainJson = File(
        '$path/data/DataStreamService/appendToDataStreams-response.json',
      ).readAsStringSync();

      // the response is empty
      print(toJsonString(plainJson));
    });

    test('GetDataStream - Request', () async {
      String rpcString = File(
        '$path/data/DataStreamService/getDataStream.json',
      ).readAsStringSync();

      var expected = GetDataStream.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = GetDataStream(
        DataStreamId(
          studyDeploymentId: 'c9cc5317-48da-45f2-958e-58bc07f34681',
          deviceRoleName: "Participant's phone",
          dataType: 'dk.cachet.carp.geolocation',
        ),
        0,
        100,
      );

      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('GetDataStream - Response', () async {
      String plainJson = File(
        '$path/data/DataStreamService/getDataStream-response.json',
      ).readAsStringSync();

      var list = json.decode(plainJson) as List<dynamic>;
      var data = DataStreamBatch.fromJson(list[0] as Map<String, dynamic>);

      print(toJsonString(data));
      expect(
        data.dataStream.studyDeploymentId,
        'c9cc5317-48da-45f2-958e-58bc07f34681',
      );
      expect(data.measurements.length, 2);
    });

    test('CloseDataStreams - Request', () async {
      String rpcString = File(
        '$path/data/DataStreamService/closeDataStreams.json',
      ).readAsStringSync();

      var expected = CloseDataStreams.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = CloseDataStreams([
        "c9cc5317-48da-45f2-958e-58bc07f34681",
        "d4a9bba4-860e-4c58-a356-8a91605dc1ee",
      ]);
      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('CloseDataStreams - Response', () async {
      String plainJson = File(
        '$path/data/DataStreamService/closeDataStreams-response.json',
      ).readAsStringSync();

      // the response is empty
      print(toJsonString(plainJson));
    });

    test('RemoveDataStreams - Request', () async {
      String rpcString = File(
        '$path/data/DataStreamService/removeDataStreams.json',
      ).readAsStringSync();

      var expected = RemoveDataStreams.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = RemoveDataStreams([
        "c9cc5317-48da-45f2-958e-58bc07f34681",
        "d4a9bba4-860e-4c58-a356-8a91605dc1ee",
      ]);
      print(toJsonString(request));
      expect(toJsonString(expected), toJsonString(request));
    });

    test('RemoveDataStreams - Response', () async {
      String plainJson = File(
        '$path/data/DataStreamService/removeDataStreams-response.json',
      ).readAsStringSync();

      var list = json.decode(plainJson) as List<dynamic>;

      print(toJsonString(list));
      expect(list[0], 'c9cc5317-48da-45f2-958e-58bc07f34681');
      expect(list[1], 'd4a9bba4-860e-4c58-a356-8a91605dc1ee');
    });
  });

  group('Participation Service', () {
    test('GetActiveParticipationInvitations - Request', () async {
      String rpcString = File(
        '$path/deployments/ParticipationService/getActiveParticipationInvitations.json',
      ).readAsStringSync();

      var expected = GetActiveParticipationInvitations.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );
      var request = GetActiveParticipationInvitations(
        'ca60cb7f-de18-44b6-baf9-3c8e6a73005a',
      );

      expect(expected.toJson(), request.toJson());
      print(toJsonString(request));
    });

    test('GetActiveParticipationInvitations - Response', () async {
      String plainJson = File(
        '$path/deployments/ParticipationService/getActiveParticipationInvitations-response.json',
      ).readAsStringSync();

      // expecting a list of invitations
      final invitations = json.decode(plainJson) as List<dynamic>;

      // checking the first one
      ActiveParticipationInvitation invitation =
          ActiveParticipationInvitation.fromJson(
            invitations.first as Map<String, dynamic>,
          );
      expect(
        invitation.participation.participantId,
        '32880e82-01c9-40cf-a6ed-17ff3348f251',
      );
      print(toJsonString(invitation));
    });

    test('GetParticipantData - Request', () async {
      String rpc = File(
        '$path/deployments/ParticipationService/getParticipantData.json',
      ).readAsStringSync();

      var expected = GetParticipantData.fromJson(
        json.decode(rpc) as Map<String, dynamic>,
      );
      var request = GetParticipantData('c9cc5317-48da-45f2-958e-58bc07f34681');

      expect(expected.toJson(), request.toJson());
      print(toJsonString(request));
    });

    test('GetParticipantData - Response', () async {
      String response = File(
        '$path/deployments/ParticipationService/getParticipantData-response.json',
      ).readAsStringSync();

      ParticipantData data = ParticipantData.fromJson(
        json.decode(response) as Map<String, dynamic>,
      );
      expect(data.roles.first.roleName, "Participant");
      print(toJsonString(data));
    });

    test('GetParticipantDataList - Request', () async {
      String rpc = File(
        '$path/deployments/ParticipationService/getParticipantDataList.json',
      ).readAsStringSync();

      var expected = GetParticipantDataList.fromJson(
        json.decode(rpc) as Map<String, dynamic>,
      );
      var request = GetParticipantDataList([
        'c9cc5317-48da-45f2-958e-58bc07f34681',
      ]);

      expect(expected.toJson(), request.toJson());
      print(toJsonString(request));
    });

    test('GetParticipantDataList - Response', () async {
      String response = File(
        '$path/deployments/ParticipationService/getParticipantDataList-response.json',
      ).readAsStringSync();
      var list = json.decode(response) as List<dynamic>;

      expect(list.length, 1);
      print(toJsonString(list));
    });

    test('SetParticipantData - Request', () async {
      String rpcString = File(
        '$path/deployments/ParticipationService/setParticipantData.json',
      ).readAsStringSync();

      var data = SexInput(value: Sex.Male);

      var request = SetParticipantData('c9cc5317-48da-45f2-958e-58bc07f34681', {
        data.type: data,
      }, 'Participant');

      var expected = SetParticipantData.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );
      print(toJsonString(expected));

      // for some strange reason, this doesn't work here?????
      // expect(expected.toJson(), request.toJson());
      expect(toJsonString(expected), toJsonString(request));
    });

    test('SetParticipantData - Response', () async {
      String response = File(
        '$path/deployments/ParticipationService/setParticipantData-response.json',
      ).readAsStringSync();

      ParticipantData data = ParticipantData.fromJson(
        json.decode(response) as Map<String, dynamic>,
      );
      expect(data.roles.first.roleName, "Participant");
      print(toJsonString(data));
    });
  });

  group('Deployment Service', () {
    test('CreateStudyDeployment - Request', () async {
      String rpcString = File(
        '$path/deployments/DeploymentService/createStudyDeployment.json',
      ).readAsStringSync();

      final expected = CreateStudyDeployment.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      String protocolJson = File(
        '$path/protocols/study_protocol.json',
      ).readAsStringSync();
      StudyProtocol protocol = StudyProtocol.fromJson(
        json.decode(protocolJson) as Map<String, dynamic>,
      );
      final request = CreateStudyDeployment(
        protocol,
        [
          ParticipantInvitation(
            participantId: '32880e82-01c9-40cf-a6ed-17ff3348f251',
            assignedRoles: AssignedTo(roleNames: {'Participant'}),
            identity: EmailAccountIdentity('boaty@mcboatface.com'),
            invitation: StudyInvitation(
              'Copenhagen transportation study',
              'Participate in this study, which keeps track of how much you walk and bike!',
              '{"trialGroup", "A"}',
            ),
          ),
        ],
        {
          "Participant's bike": AltBeaconDeviceRegistration(
            registrationCreatedOn: DateTime.tryParse("2022-01-18T11:06:40Z"),
            manufacturerId: 280,
            organizationId: "4e990957-0838-414c-bf25-2d391e2990b5",
            majorId: 42,
            minorId: 42,
            referenceRssi: 0,
            deviceDisplayName: null,
            deviceId: "280:4e990957-0838-414c-bf25-2d391e2990b5:42:42",
          ),
        },
      );

      // expect(expected.toJson(), request.toJson());
      expect(toJsonString(request), toJsonString(expected));
      print(toJsonString(request));
    });

    test('CreateStudyDeployment - Response', () async {
      String plainJson = File(
        '$path/deployments/DeploymentService/createStudyDeployment-response.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      expect(status.studyDeploymentId, testDeploymentId);
      expect(status.status, StudyDeploymentStatusTypes.Invited);
      print(toJsonString(status));
    });

    test('GetStudyDeploymentStatus - Request', () async {
      String rpcString = File(
        '$path/deployments/DeploymentService/getStudyDeploymentStatus.json',
      ).readAsStringSync();

      final expected = GetStudyDeploymentStatus.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );
      final request = GetStudyDeploymentStatus(testDeploymentId);

      // expect(expected.toJson(), request.toJson());
      expect(toJsonString(request), toJsonString(expected));
      print(toJsonString(request));
    });

    test('GetStudyDeploymentStatus - Response', () async {
      String plainJson = File(
        '$path/deployments/DeploymentService/getStudyDeploymentStatus-response.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      expect(status.studyDeploymentId, testDeploymentId);
      expect(status.status, StudyDeploymentStatusTypes.Invited);
      print(toJsonString(status));
    });

    test('RegisterDevice - Request', () async {
      String rpcString = File(
        '$path/deployments/DeploymentService/registerDevice.json',
      ).readAsStringSync();

      var expected = RegisterDevice.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = RegisterDevice(
        testDeploymentId,
        "Participant's phone",
        DefaultDeviceRegistration(
          deviceId: 'fc7b41b0-e9e2-4b5d-8c3d-5119b556a3f0',
          registrationCreatedOn: DateTime.tryParse('2022-01-18T13:55:10Z'),
        ),
      );
      print(toJsonString(request));

      // expect(expected.toJson(), request.toJson());
      expect(toJsonString(expected), toJsonString(request));
    });

    test('RegisterDevice - Response', () async {
      String plainJson = File(
        '$path/deployments/DeploymentService/registerDevice-response.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      expect(status.studyDeploymentId, testDeploymentId);
      expect(status.status, StudyDeploymentStatusTypes.DeployingDevices);
      print(toJsonString(status));
    });

    test('UnregisterDevice - Request', () async {
      String rpcString = File(
        '$path/deployments/DeploymentService/unregisterDevice.json',
      ).readAsStringSync();

      var expected = UnregisterDevice.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = UnregisterDevice(testDeploymentId, "Participant's phone");
      print(toJsonString(request));

      // expect(expected.toJson(), request.toJson());
      expect(toJsonString(expected), toJsonString(request));
    });

    test('UnregisterDevice - Response', () async {
      String plainJson = File(
        '$path/deployments/DeploymentService/unregisterDevice-response.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      expect(status.studyDeploymentId, testDeploymentId);
      expect(status.status, StudyDeploymentStatusTypes.Invited);
      print(toJsonString(status));
    });

    test('GetDeviceDeploymentFor - Request', () async {
      String rpcString = File(
        '$path/deployments/DeploymentService/getDeviceDeploymentFor.json',
      ).readAsStringSync();

      var expected = GetDeviceDeploymentFor.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = GetDeviceDeploymentFor(
        testDeploymentId,
        "Participant's phone",
      );
      print(toJsonString(request));

      // expect(expected.toJson(), request.toJson());
      expect(toJsonString(expected), toJsonString(request));
    });

    test('GetDeviceDeploymentFor - Response', () async {
      String plainJson = File(
        '$path/deployments/DeploymentService/getDeviceDeploymentFor-response.json',
      ).readAsStringSync();

      PrimaryDeviceDeployment deployment = PrimaryDeviceDeployment.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );

      expect(deployment.deviceConfiguration.isPrimaryDevice, true);
      expect(deployment.deviceConfiguration.roleName, "Participant's phone");
      print(toJsonString(deployment));
    });

    test('DeviceDeployed - Request', () async {
      String rpcString = File(
        '$path/deployments/DeploymentService/deviceDeployed.json',
      ).readAsStringSync();

      var expected = DeviceDeployed.fromJson(
        json.decode(rpcString) as Map<String, dynamic>,
      );

      var request = DeviceDeployed(
        testDeploymentId,
        "Participant's phone",
        DateTime.tryParse('2022-01-18T13:55:10Z')!,
      );
      print(toJsonString(request));

      expect(toJsonString(expected), toJsonString(request));
    });

    test('DeviceDeployed - Response', () async {
      String plainJson = File(
        '$path/deployments/DeploymentService/deviceDeployed-response.json',
      ).readAsStringSync();

      StudyDeploymentStatus status = StudyDeploymentStatus.fromJson(
        json.decode(plainJson) as Map<String, dynamic>,
      );
      expect(status.studyDeploymentId, testDeploymentId);
      expect(status.status, StudyDeploymentStatusTypes.Running);
      print(toJsonString(status));
    });
  });
}
