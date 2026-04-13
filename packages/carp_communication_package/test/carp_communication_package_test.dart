import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_communication_package/communication.dart';

void main() {
  late StudyProtocol protocol;
  Smartphone phone;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUpAll(() {
    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();

    // register the communication sampling package
    SamplingPackageRegistry().register(CommunicationSamplingPackage());

    // Create a new study protocol.
    protocol = StudyProtocol(
      ownerId: 'alex@uni.dk',
      name: 'Communication package test',
    );

    // Define which devices are used for data collection.
    phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // adding all available measures to one one trigger and one task
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..measures = SamplingPackageRegistry().dataTypes
            .map((type) => Measure(type: type.type))
            .toList(),
      phone,
    );
  });

  test('CAMSStudyProtocol -> JSON', () async {
    print(protocol);
    print(toJsonString(protocol));
    expect(protocol.ownerId, 'alex@uni.dk');

    // used in the test below
    await writeToFile(toJsonString(protocol), 'protocol.json');
  });

  test('StudyProtocol -> JSON -> StudyProtocol :: deep assert', () async {
    print('#1 : $protocol');
    final studyJson = toJsonString(protocol);

    StudyProtocol protocolFromJson = StudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), equals(studyJson));
    print('#2 : $protocolFromJson');
  });
  test('JSON File -> StudyProtocol', () async {
    // Read the study protocol from json file
    String plainJson = File('test/json/protocol.json').readAsStringSync();

    StudyProtocol protocol = StudyProtocol.fromJson(
      json.decode(plainJson) as Map<String, dynamic>,
    );

    expect(protocol.ownerId, 'alex@uni.dk');
    expect(protocol.primaryDevice.roleName, Smartphone.DEFAULT_ROLE_NAME);
    print(toJsonString(protocol));
  });

  test('Privacy - TextMessage', () {
    final msg = TextMessage(id: 123, address: '25550446', body: 'Hej Jakob');
    print(msg);

    print(toJsonString(msg));

    final pMsg =
        DataTransformerSchemaRegistry()
                .lookup(PrivacySchema.DEFAULT)!
                .transform(msg)
            as TextMessage;
    expect(pMsg.address, isNot('25550446'));
    expect(pMsg.body, isNot('Hej Jakob'));
    print(pMsg);
  });

  test('Privacy - TextMessageLog', () {
    TextMessageLog log = TextMessageLog([
      TextMessage(id: 123, address: '25550446', body: 'Hej Jakob'),
      TextMessage(id: 1232, address: '25550467', body: 'Hej Eva'),
    ]);

    print(toJsonString(log));

    log.textMessageLog.forEach(print);

    TextMessageLog pLog =
        DataTransformerSchemaRegistry()
                .lookup(PrivacySchema.DEFAULT)!
                .transform(log)
            as TextMessageLog;
    //expect(p_msg.textMessage.address, isNot('25550446'));
    //expect(p_msg.textMessage.body, isNot('Hej Jakob'));
    pLog.textMessageLog.forEach(print);
  });

  test('Privacy - PhoneLog', () {
    PhoneLog log = PhoneLog(DateTime.now(), DateTime.now(), [
      PhoneCall(
        DateTime.now(),
        'ingoing',
        23444,
        '2555 0446',
        '25550446',
        'Jakob',
      ),
      PhoneCall(
        DateTime.now(),
        'ingoing',
        2344444,
        '2555 0467',
        '25550457',
        'Eva',
      ),
    ]);

    print(toJsonString(log));

    log.phoneLog.forEach(print);

    PhoneLog pLog =
        DataTransformerSchemaRegistry()
                .lookup(PrivacySchema.DEFAULT)!
                .transform(log)
            as PhoneLog;
    pLog.phoneLog.forEach(print);
  });

  test('Privacy - Calendar', () {
    Calendar cal = Calendar(DateTime.now(), DateTime.now(), [
      CalendarEvent('122', 'wer', 'møde #1'),
      CalendarEvent('122', 'wer', 'møde #1'),
    ]);

    print(toJsonString(cal));

    Calendar pCal =
        DataTransformerSchemaRegistry()
                .lookup(PrivacySchema.DEFAULT)!
                .transform(cal)
            as Calendar;
    print(toJsonString(pCal));
  });
}
