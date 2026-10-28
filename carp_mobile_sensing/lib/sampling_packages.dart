/*
 * Copyright 2025 Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// The built-in CAMS sampling packages, which collect data from the phone itself.
///
///  * [DeviceSamplingPackage] - information about the phone and the app.
///    Measure types: `dk.cachet.carp.deviceinformation`,
///    `dk.cachet.carp.applicationinformation`, `dk.cachet.carp.freememory`,
///    `dk.cachet.carp.batterystate`, `dk.cachet.carp.screenevent`
///    (Android only), `dk.cachet.carp.applifecycleevent`,
///    `dk.cachet.carp.timezone`, and `dk.cachet.carp.heartbeat`.
///  * [SensorSamplingPackage] - the basic phone sensors.
///    Measure types: `dk.cachet.carp.acceleration`,
///    `dk.cachet.carp.nongravitationalacceleration`,
///    `dk.cachet.carp.accelerationfeatures`, `dk.cachet.carp.rotation`,
///    `dk.cachet.carp.magneticfield`, `dk.cachet.carp.ambientlight`
///    (Android only), `dk.cachet.carp.stepevent`, and `dk.cachet.carp.stepcount`.
///
/// Both run on Android and iOS (except where noted) and need no extra device:
/// they use the [Smartphone]. The monitoring package
/// ([MonitoringSamplingPackage]) is part of the [domain] library.
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:light/light.dart';
import 'package:pedometer/pedometer.dart' as pedometer;
import 'package:statistics/statistics.dart';
import 'package:sample_statistics/sample_statistics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart' as battery;
import 'package:screen_state/screen_state.dart';
import 'package:system_info2/system_info2.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'infrastructure/sampling_packages/sensors/sensor_probes.dart';
part 'infrastructure/sampling_packages/sensors/light_probe.dart';
part 'infrastructure/sampling_packages/sensors/pedometer_probe.dart';
part 'infrastructure/sampling_packages/sensors/sensor_data.dart';
part 'infrastructure/sampling_packages/sensors/sensor_package.dart';

part 'infrastructure/sampling_packages/device/device_data.dart';
part 'infrastructure/sampling_packages/device/device_package.dart';
part 'infrastructure/sampling_packages/device/device_probes.dart';

part 'sampling_packages.g.dart';
