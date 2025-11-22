/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../client.dart';

/// A repository which handles persisting the state of studies.
/// Used by a [ClientManager] to store and retrieve information about
/// the client device and the studies it is handling.
abstract interface class ClientRepository<TStudy extends Study> {
  /// The [DeviceRegistration] used to register the client in deployments.
  DeviceRegistration? deviceRegistration;

  /// Adds [study] to the repository.
  ///
  /// If study with the same study deployment id and device role name as [study]
  /// already exists in this repository, nothing happens.
  /// If a study needs to be updated, use the [updateStudy] method.
  void addStudy(TStudy study);

  /// Return the study with [studyDeploymentId] and [deviceRoleName],
  /// or null when no such study is found.
  TStudy? getStudy(String studyDeploymentId, String deviceRoleName);

  /// Is [study] in this repository?
  bool hasStudy(TStudy study);

  /// Return all studies in this repository. May be an empty list if no
  /// studies have been added.
  List<TStudy> getStudyList();

  /// Update a [study] which is already stored in the repository.
  /// In case [study] is not stored in this repository, nothing happens.
  void updateStudy(TStudy study);

  /// Remove [study] which is already stored in the repository.
  /// In case [study] is not stored in this repository, nothing happens.
  void removeStudy(TStudy study);
}
