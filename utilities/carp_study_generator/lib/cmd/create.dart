part of '../carp_study_generator.dart';

class CreateStudyProtocolCommand extends AbstractCommand {
  String? _protocolJson;
  SmartphoneStudyProtocol? _protocol;
  // StudyProtocol? _customProtocol;

  CreateStudyProtocolCommand() : super();

  String get protocolJson {
    if (_protocolJson == null) {
      print('Reading the study protocol from file: $protocolPath');
      _protocolJson = File(protocolPath).readAsStringSync();
    }
    return _protocolJson!;
  }

  SmartphoneStudyProtocol get protocol {
    if (_protocol == null) {
      print('Checking that this is a valid Smartphone Study Protocol');
      _protocol = SmartphoneStudyProtocol.fromJson(
        json.decode(protocolJson) as Map<String, dynamic>,
      );

      // set the ownerId of the protocol to the authenticated user
      _protocol?.ownerId = ownerId;
    }
    return _protocol!;
  }

  // StudyProtocol get customProtocol {
  //   if (_customProtocol == null) {
  //     // This doesn't work -- see issue #44 (https://github.com/cph-cachet/carp.webservices-docker/issues/44)
  //     //
  //     // print('Getting custom protocol template from CARP Server');
  //     // StudyProtocol customProtocol =
  //     //     await CANSProtocolService().createCustomProtocol(
  //     //   ownerId,
  //     //   protocol.name,
  //     //   protocol.description,
  //     //   protocolJson,
  //     // );

  //     // therefore, we create a custom protocol "by hand"
  //     var customDevice = CustomProtocolDevice(roleName: 'Custom device');

  //     _customProtocol = StudyProtocol(
  //         ownerId: ownerId,
  //         name: protocol.name,
  //         description: protocol.description);

  //     // make sure that the smartphone protocol also have the right owner id
  //     protocol.ownerId = ownerId;
  //     _customProtocol!.addPrimaryDevice(customDevice);
  //     _customProtocol!.addTaskControl(
  //         ElapsedTimeTrigger(
  //             sourceDeviceRoleName: customDevice.roleName,
  //             elapsedTime: IsoDuration(seconds: 0)),
  //         CustomProtocolTask(
  //             name: 'Custom device task',
  //             studyProtocol: toJsonString(protocol)),
  //         customDevice);
  //   }

  //   return _customProtocol!;
  // }

  @override
  Future<void> execute() async {
    await authenticate();

    print("Uploading protocol: $protocol");
    await CarpProtocolService().add(protocol);
    print('Upload successful!');
  }
}
