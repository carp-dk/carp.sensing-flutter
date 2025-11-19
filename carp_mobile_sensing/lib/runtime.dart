/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// Contains classes for running the sensing framework incl.
/// the [SmartphoneDeploymentExecutor], [TaskExecutor] and different types of
/// [Probe]s.
library;

import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import 'package:async/async.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cron/cron.dart' as cron;
import 'package:battery_plus/battery_plus.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// import 'dart:async';
// import 'dart:io';
// import 'dart:developer' as log;

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';

// import 'package:carp_serializable/carp_serializable.dart';
// import 'package:carp_core/carp_core.dart';
// import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

// import 'package:path_provider/path_provider.dart';
// import 'package:async/async.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

part 'runtime/executors/deployment_executor.dart';
part 'runtime/executors/executor_factory.dart';
part 'runtime/executors/executors.dart';
part 'runtime/executors/trigger_executors.dart';
part 'runtime/executors/task_executors.dart';
part 'runtime/executors/task_control_executors.dart';
part 'runtime/executors/probes.dart';
part 'runtime/util/cron_parser.dart';

part 'runtime/app_task_controller.dart';
part 'runtime/client_manager.dart';
part 'runtime/client_repository.dart';
part 'runtime/study_controller.dart';
part 'runtime/device_controller.dart';
part 'runtime/device_manager.dart';
part 'runtime/sampling_package.dart';
part 'runtime/user_tasks.dart';

part 'runtime.g.dart';
