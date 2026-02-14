/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../client.dart';

/// Provides a [localDataCollector] to collect data locally on the primary device
/// and supports creating [ConnectedDeviceDataCollector] instances for connected
/// devices.
abstract class DeviceDataCollectorFactory {
  /// The data collector for the primary device.
  DeviceDataCollector? localDataCollector;

  DeviceDataCollectorFactory([this.localDataCollector]);

  /// Create a [ConnectedDeviceDataCollector] for a connected [deviceType]
  /// using connection options specified in [deviceRegistration].
  ///
  /// Returns null in case the [ConnectedDeviceDataCollector] cannot be created.
  ConnectedDeviceDataCollector? createConnectedDataCollector(
    String deviceType,
    DeviceRegistration deviceRegistration,
  );
}

/// Collects [Data] for a single device.
abstract interface class DeviceDataCollector {
  /// The set of data types defining which data can be collected on this device.
  Set<DataType> get supportedDataTypes;
}

/// Collects [Data] for a single connected device.
abstract interface class ConnectedDeviceDataCollector<
  TDeviceConfiguration extends DeviceConfiguration<TRegistration>,
  TRegistration extends DeviceRegistration
>
    extends DeviceDataCollector {
  /// Determines whether a connection can be made at this point in time to the device.
  bool get canConnect;
}
