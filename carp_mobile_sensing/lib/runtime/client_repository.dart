/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../infrastructure.dart';

/// A [ClientRepository] that runs on a smartphone. Works as a singleton.
/// Uses the [Persistence] infrastructure to store study information persistently
/// across app restarts.
class SmartphoneClientRepository implements ClientRepository<SmartphoneStudy> {
  static final SmartphoneClientRepository _instance =
      SmartphoneClientRepository._();
  final StreamGroup<StudyStatusEvent<SmartphoneStudy>> _group =
      StreamGroup.broadcast();

  /// Create the singleton instance and load all studies from persistence storage.
  SmartphoneClientRepository._() {
    Persistence().getAllStudies().then(
      (studies) => _repository = studies.toSet(),
    );
  }

  /// Get the singleton [SmartphoneClientRepository].
  factory SmartphoneClientRepository() => _instance;

  /// The in-memory cache of this repository.
  Set<SmartphoneStudy> _repository = {};

  /// A stream of [StudyStatusEvent] events generate whenever a study change state.
  Stream<StudyStatusEvent<SmartphoneStudy>> get userTaskEvents => _group.stream;

  @override
  DeviceRegistration? deviceRegistration;

  @override
  void addStudy(SmartphoneStudy study) {
    if (_repository.add(study)) {
      _group.add(study.events);
      Persistence().saveStudy(study);
    }
  }

  @override
  SmartphoneStudy? getStudy(String studyDeploymentId, String deviceRoleName) {
    try {
      return _repository.firstWhere(
        (study) =>
            study.studyDeploymentId == studyDeploymentId &&
            study.deviceRoleName == deviceRoleName,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<SmartphoneStudy> getStudyList() => _repository.toList();

  @override
  void removeStudy(SmartphoneStudy study) {
    _group.remove(study.events);
    _repository.remove(study);
    Persistence().removeStudy(study);
  }

  @override
  void updateStudy(SmartphoneStudy study) => Persistence().updateStudy(study);
}
