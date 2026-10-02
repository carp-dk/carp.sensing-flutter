/*
 * Copyright 2018-2025 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// A sampling package that collects data about the apps installed on the phone.
///
/// Register [AppsSamplingPackage] in the `SamplingPackageRegistry` to use
/// these measure types in a protocol:
///  * `dk.cachet.carp.apps` - the list of installed apps ([Apps]).
///  * `dk.cachet.carp.appusage` - app usage over a time period ([AppUsage]).
///
/// Android only. Both measures run on the [Smartphone] primary device and need
/// the `QUERY_ALL_PACKAGES` and `PACKAGE_USAGE_STATS` permissions in the app's
/// Android manifest.
library;

import 'dart:io';
import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:app_usage/app_usage.dart' as app_usage;

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'apps_data.dart';
part 'app_probes.dart';
part 'apps_package.dart';
part 'apps.g.dart';
