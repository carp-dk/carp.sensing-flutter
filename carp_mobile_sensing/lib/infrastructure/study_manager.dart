/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../services.dart';

/// An interface defining a manger of [SmartphoneStudyProtocol]s.
///
/// Is mainly used to get and save [SmartphoneStudyProtocol]s.
/// See [FileStudyProtocolManager] for an example.
abstract class StudyProtocolManager {
  /// Initialize the study manager.
  void initialize();

  /// Get a [SmartphoneStudyProtocol] based on its [id].
  /// Returns `null` if no protocol exists.
  Future<SmartphoneStudyProtocol?> getStudyProtocol(String id);

  /// Save a [SmartphoneStudyProtocol] with the ID [id].
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> saveStudyProtocol(
    String id,
    SmartphoneStudyProtocol protocol,
  );
}
