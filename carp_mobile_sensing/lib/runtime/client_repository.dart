/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../runtime.dart';

/// A [ClientRepository] that runs on a smartphone. Works as a singleton.
/// Uses the [PersistenceService] infrastructure to store study information persistently
/// across app restarts.
class SmartphoneClientRepository implements ClientRepository<SmartphoneStudy> {
  static final SmartphoneClientRepository _instance =
      SmartphoneClientRepository._();
  final StreamGroup<StudyStatusEvent<SmartphoneStudy>> _studyStatusEventGroup =
      StreamGroup.broadcast();

  /// Create the singleton instance and load all studies from persistence storage.
  SmartphoneClientRepository._();

  /// Get the singleton [SmartphoneClientRepository].
  factory SmartphoneClientRepository() => _instance;

  /// The in-memory cache of this repository.
  Set<SmartphoneStudy> _repository = {};

  /// A stream of [StudyStatusEvent] events generate whenever a study change state.
  Stream<StudyStatusEvent<SmartphoneStudy>> get studyStatusEvents =>
      _studyStatusEventGroup.stream;

  @override
  DeviceRegistration? deviceRegistration;

  Future<void> init() async {
    // Load all studies from persistent storage.
    _repository = (await PersistenceService().getAllStudies()).toSet();
    for (var study in _repository) {
      _studyStatusEventGroup.add(study.events);
    }
  }

  @override
  void addStudy(SmartphoneStudy study) {
    if (_repository.add(study)) {
      _studyStatusEventGroup.add(study.events);
      PersistenceService().saveStudy(study);
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
  bool hasStudy(SmartphoneStudy study) => _repository.contains(study);

  @override
  List<SmartphoneStudy> getStudyList() => _repository.toList();

  @override
  void removeStudy(SmartphoneStudy study) {
    _studyStatusEventGroup.remove(study.events);
    _repository.remove(study);
    PersistenceService().removeStudy(study);
  }

  @override
  void updateStudy(SmartphoneStudy study) =>
      PersistenceService().updateStudy(study);

  @override
  String toString() => '$runtimeType [${_repository.length}]';
}
