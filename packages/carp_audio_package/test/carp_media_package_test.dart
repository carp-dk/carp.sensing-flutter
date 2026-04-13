import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_audio_package/media.dart';

void main() {
  late StudyProtocol protocol;
  Smartphone phone;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUpAll(() {
    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();

    // register the context sampling package
    SamplingPackageRegistry().register(MediaSamplingPackage());

    // Create a new study protocol.
    protocol = StudyProtocol(
      ownerId: 'alex@uni.dk',
      name: 'Audio package test',
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
  test('Audio Data Point', () async {
    MediaData media = AudioMedia(
      filename: "filename.mp3",
      startRecordingTime: DateTime.now().subtract(const Duration(days: 1)),
      endRecordingTime: DateTime.now(),
    );

    final measurement = Measurement.fromData(media);

    print(measurement);
    print(toJsonString(measurement));
    expect(measurement.data, isA<MediaData>());
  });

  test('Video Data Point', () async {
    MediaData media = VideoMedia(
      filename: "filename.mp3",
      startRecordingTime: DateTime.now().subtract(const Duration(days: 1)),
      endRecordingTime: DateTime.now(),
    );

    final measurement = Measurement.fromData(media);

    print(measurement);
    print(toJsonString(measurement));
    expect(measurement.data, isA<MediaData>());
  });
}
