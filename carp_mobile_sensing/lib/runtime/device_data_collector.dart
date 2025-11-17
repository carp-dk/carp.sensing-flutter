/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of 'carp_core_client.dart';

// /// Collects [Data] for a single device.
// abstract class DeviceDataCollector<
//   TDeviceConfiguration extends DeviceConfiguration
// > {
//   /// The type of this device
//   String type;

//   /// The configuration for this device.
//   TDeviceConfiguration? configuration;

//   /// The set of data types defining which data can be collected on this device.
//   Set<String> get supportedDataTypes;

//   /// Get a unique id for this device.
//   String get id;

//   // Get a printer-friendly display name for this device.
//   String? get displayName;

//   /// Determines whether a connection can be made at this point in time to
//   /// the device.
//   Future<bool> canConnect();

//   DeviceDataCollector(this.type, [this.configuration]);
// }

// /// Supports creating and holding a registry of [DeviceDataCollector]s for devices.
// abstract class DeviceDataCollectorFactory {
//   /// The devices available in this [DeviceDataCollectorFactory] mapped to their
//   /// device type.
//   Map<String, DeviceDataCollector> get devices;

//   /// Returns the [DeviceDataCollector] of the given [deviceType].
//   /// Returns `null` if no device is found.
//   DeviceDataCollector? getDevice(String deviceType);

//   /// Returns true if this factory supports a device of the given [deviceType].
//   /// Note that even though a certain type of device is supported, its device
//   /// [DeviceDataCollector] is not loaded until [registerDevice] is called.
//   bool supportsDevice(String deviceType);

//   /// Returns true if this factory contain a device manager of the given [deviceType].
//   bool hasDevice(String deviceType);

//   /// Register and initialize a [DeviceDataCollector] for a [deviceType].
//   void registerDevice(String deviceType, DeviceDataCollector collector);

//   /// Create and register a [DeviceDataCollector] based on a [deviceType].
//   /// Returns `null` if a device cannot be created.
//   Future<DeviceDataCollector?> createDevice(String deviceType);

//   // Remove the device of [deviceType] from this registry.
//   void unregisterDevice(String deviceType);
// }
