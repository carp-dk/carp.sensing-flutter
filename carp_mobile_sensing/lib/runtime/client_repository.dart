/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../runtime.dart';

/// Stores the studies of the [SmartPhoneClientManager] on the phone.
///
/// A singleton [ClientRepository] that keeps studies in memory and saves them
/// with the [PersistenceService], so they survive app restarts.
class SmartphoneClientRepository implements ClientRepository<SmartphoneStudy> {
  static final SmartphoneClientRepository _instance =
      SmartphoneClientRepository._();
  final StreamGroup<StudyStatusEvent<SmartphoneStudy>> _studyStatusEventGroup =
      StreamGroup.broadcast();

  /// Creates the singleton instance. Studies are loaded later, in [init].
  SmartphoneClientRepository._();

  /// Returns the singleton [SmartphoneClientRepository].
  factory SmartphoneClientRepository() => _instance;

  /// The in-memory cache of this repository.
  Set<SmartphoneStudy> _repository = {};

  /// The [StudyStatusEvent]s of all studies in this repository.
  Stream<StudyStatusEvent<SmartphoneStudy>> get studyStatusEvents =>
      _studyStatusEventGroup.stream;

  @override
  DeviceRegistration? deviceRegistration;

  /// Loads all studies from the [PersistenceService].
  ///
  /// Called by [SmartPhoneClientManager.configure] after the persistence
  /// service is initialized.
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
