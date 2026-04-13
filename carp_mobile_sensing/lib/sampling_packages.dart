/*
 * Copyright 2025 Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// The sampling package library holds the built-in sampling packages:
///
///  * [DeviceSamplingPackage] - a sampling package for collecting information from the device hardware.
///  * [SensorSamplingPackage] - a sampling package for collecting data from the basic phone sensors:
///  * [MonitoringSamplingPackage] - a sampling package for monitoring data sampling (e.g, errors, completed tasks,etc.)
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
