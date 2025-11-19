/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// Retrieve and store [StudyProtocol] json definitions on the device's local
/// file system.
///
/// The path and filename format is
///
///   `~/carp/study/study-<study_id>.json`
///
class FileStudyProtocolManager implements StudyProtocolManager {
  /// Initializing the the local FileDeploymentService
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

  /// Save a study on the local file system.
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

  /// Current path and filename according to this format:
  ///
  ///   `carp/protocols/protocol-<study_id>.json`
  ///
  String filename(String studyId) =>
      '${Settings().localApplicationPath}/protocols/protocol-$studyId.json';
}
