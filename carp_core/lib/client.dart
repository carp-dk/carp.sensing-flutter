/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

/// The client runtime that runs a study on a device, such as a smartphone.
///
/// The client subsystem holds reusable components which understand the
/// runtime configuration ([PrimaryDeviceDeployment]) derived from a protocol
/// by the deployment subsystem. Sensor integrations are plugged in through
/// [DeviceDataCollector]s, so sensing itself is not part of core.
///
/// [ClientManager] is the main entry point into this subsystem.
/// Concrete clients extend it; e.g., `SmartPhoneClientManager` in
/// [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing)
/// manages data collection on a smartphone.
///
/// Main types: [ClientManager], [Study], [StudyDeploymentProxy],
/// [ClientRepository], [DeviceDataCollectorFactory] and [DeviceDataCollector].
///
/// See the [`carp.clients`](https://github.com/carp-dk/carp.core-kotlin/blob/develop/docs/carp-clients.md)
/// definition in Kotlin.
library;

import 'dart:async';

import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:meta/meta.dart';
import 'package:carp_core/common.dart';
import 'package:carp_core/deployment.dart';

part 'client/client_manager.dart';
part 'client/study.dart';
part 'client/device_data_collector.dart';
part 'client/client_repository.dart';
part 'client/study_deployment_proxy.dart';
