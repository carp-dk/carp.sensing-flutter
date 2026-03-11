/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// A very simple data manager that just "uploads" the data to the
/// console (i.e., prints it). Used mainly for testing and debugging purposes.
class ConsoleDataManager extends AbstractDataManager {
  @override
  String get type => DataEndPointTypes.PRINT;

  @override
  Future<void> onMeasurement(Measurement measurement) async =>
      debugPrint(jsonEncode(measurement));
}

class ConsoleDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.PRINT;

  @override
  DataManager create() => ConsoleDataManager();
}
