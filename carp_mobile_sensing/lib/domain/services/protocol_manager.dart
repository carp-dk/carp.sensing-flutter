/*
 * Copyright 2020 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Gets and saves [SmartphoneStudyProtocol]s, e.g. from local files or a server.
///
/// Apps implement it to load the protocol they run. See
/// [FileStudyProtocolManager] for an example.
abstract class StudyProtocolManager {
  /// Initializes this manager. Call it before any other method.
  void initialize();

  /// Gets a [SmartphoneStudyProtocol] based on its [id].
  /// Returns `null` if no protocol exists.
  Future<SmartphoneStudyProtocol?> getStudyProtocol(String id);

  /// Saves [protocol] with the ID [id].
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> saveStudyProtocol(String id, SmartphoneStudyProtocol protocol);
}
