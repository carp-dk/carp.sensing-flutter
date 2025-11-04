/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// A library containing a sampling package for collecting information from the
/// device hardware:
///
///  - device info
///  - battery status
///  - screen events
///  - app lifecycle events
///  - free memory
///  - time zone
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import 'package:battery_plus/battery_plus.dart' as battery;
import 'package:json_annotation/json_annotation.dart';
import 'package:screen_state/screen_state.dart';
import 'package:system_info2/system_info2.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

part 'device/device_data.dart';
part 'device/device_package.dart';
part 'device/device_probes.dart';
part 'device.g.dart';
