/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../infrastructure.dart';

/// A [ClientRepository] that runs on a smartphone.
/// Uses the [Persistence] infrastructure to store study information persistently
/// in a SQLite DB on the phone.
class SmartphoneClientRepository implements ClientRepository {
  static final SmartphoneClientRepository _instance =
      SmartphoneClientRepository._();
  SmartphoneClientRepository._();
  StreamSubscription<StudyStatusEvent>? _subscription;

  /// Get the singleton [SmartphoneClientRepository].
  factory SmartphoneClientRepository() => _instance;

  /// The in-memory cache of this repository.
  final Set<Study> _repository = {};

  @override
  DeviceRegistration? deviceRegistration;

  @override
  void addStudy(Study study) {
    _repository.add(study);

    // Listen for updates to this study and save it (if no error).
    _subscription = study.events.listen((event) {
      if (event.event != StudyStatusEventTypes.DeploymentError) {
        Persistence().saveStudy(study);
      }
    });
  }

  @override
  Study? getStudy(String studyDeploymentId, String deviceRoleName) {
    try {
      return _repository.firstWhere(
        (study) =>
            study.studyDeploymentId == studyDeploymentId &&
            study.deviceRoleName == deviceRoleName,
      );
    } catch (error) {
      return null;
    }
  }

  @override
  List<Study> getStudyList() => _repository.toList();

  @override
  void removeStudy(Study study) {
    _subscription?.cancel();
    _repository.remove(study);
    Persistence().removeStudy(study);
  }

  @override
  void updateStudy(Study study) {
    Persistence().saveStudy(study);
  }
}
