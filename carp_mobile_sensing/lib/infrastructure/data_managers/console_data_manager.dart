/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// A data manager that prints each [Measurement] as JSON to the console.
///
/// Used for testing and debugging. Selected when the protocol's data endpoint
/// has type [DataEndPointTypes.PRINT]. Nothing is stored, so all data is lost
/// when the app stops.
class ConsoleDataManager extends AbstractDataManager {
  @override
  String get type => DataEndPointTypes.PRINT;

  @override
  Future<void> onMeasurement(Measurement measurement) async => debugPrint(jsonEncode(measurement));
}

/// Creates a [ConsoleDataManager] for data endpoints of type
/// [DataEndPointTypes.PRINT].
///
/// Registered in the [DataManagerRegistry] by
/// [SmartPhoneClientManager.configure].
class ConsoleDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.PRINT;

  @override
  DataManager create() => ConsoleDataManager();
}
