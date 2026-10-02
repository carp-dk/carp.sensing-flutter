/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// A [StudyProtocolManager] that loads and saves [SmartphoneStudyProtocol]s
/// as JSON files on the phone.
///
/// The path and filename format is given by [filename].
class FileStudyProtocolManager implements StudyProtocolManager {
  /// Logs the protocol file path. No other setup is needed.
  @override
  Future<void> initialize() async {
    info('Initializing FileDeploymentService...');
    info('Study file path : ${Settings().localApplicationPath}/protocols');
  }

  @override
  Future<SmartphoneStudyProtocol?> getStudyProtocol(String studyId) async {
    info("Loading study '$studyId'.");
    SmartphoneStudyProtocol? study;

    try {
      String jsonString = File(filename(studyId)).readAsStringSync();
      study = SmartphoneStudyProtocol.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
    } catch (exception) {
      warning("Failed to load study '$studyId' - $exception");
    }

    return study;
  }

  /// Saves [study] as JSON to [filename].
  /// Returns `true` if successful.
  @override
  Future<bool> saveStudyProtocol(
    String studyId,
    SmartphoneStudyProtocol study,
  ) async {
    bool success = true;
    info("Saving study protocol - id: '$studyId'.");
    try {
      final json = jsonEncode(study);
      File(filename(studyId)).writeAsStringSync(json);
    } catch (exception) {
      success = false;
      warning("Failed to save study protocol '$studyId' - $exception");
    }

    return success;
  }

  /// The path and filename of the protocol with [studyId], on the format
  ///
  ///   `<localApplicationPath>/protocols/protocol-<study_id>.json`
  ///
  /// See [Settings.localApplicationPath].
  String filename(String studyId) =>
      '${Settings().localApplicationPath}/protocols/protocol-$studyId.json';
}
