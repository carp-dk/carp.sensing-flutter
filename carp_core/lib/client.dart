/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

/// The runtime which performs the actual data collection on a device (e.g.,
/// desktop computer or smartphone). The client subsystem contains reusable components
/// which understand the runtime configuration derived from a study protocol by
/// the ‘deployment’ subsystem. Integrations with sensors are loaded through a
/// 'device data collector' plug-in system to decouple sensing — not part of core —
/// from sensing logic.
///
/// [ClientManager] is the main entry point into this subsystem.
/// Concrete devices extend on it, e.g., the SmartphoneClient manages data
/// collection on a smartphone and is implemented in
/// [CARP Mobile Sensing](https://pub.dev/packages/carp_mobile_sensing).
///
/// Contains the core client classes like [ClientManager], [DeviceDataCollectorFactory],
/// [DeviceDataCollector], and [ClientRepository].
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
