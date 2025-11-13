/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of 'carp_core_client.dart';

/// A repository which handles persisting the state of a client device.
/// Used by a [ClientManager] to store and retrieve information about
/// the client device and the studies it is handling.
abstract interface class ClientRepository {
  /// The [DeviceRegistration] used to register the client in deployments.
  DeviceRegistration? deviceRegistration;

  /// Adds [study] to the repository.
  ///
  /// Throws [IllegalArgumentException] if [study] has the same study deployment
  /// ID and device role name as an existing study.
  void addStudy(Study study);

  /// Return the [Study] with [studyDeploymentId] and [deviceRoleName],
  /// or null when no such study is found.
  Study? getStudy(String studyDeploymentId, String deviceRoleName);

  /// Return all [Study]s for the client.
  List<Study> getStudyList();

  /// Update a [study] which is already stored in the repository.
  ///
  /// Throws [IllegalArgumentException] if this study has not previously
  /// been added to this repository.
  void updateStudy(Study study);

  /// Remove [study] which is already stored in the repository.
  /// In case [study] is not stored in this repository, nothing happens.
  void removeStudy(Study study);
}
