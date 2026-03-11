/*
 * Copyright 2018-2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// The runtime layer is the main entry point to CAMS and holds the [SmartPhoneClientManager],
/// [SmartphoneStudyController]s with a [SmartphoneDeploymentExecutor] for each
/// running study, [DeviceController] with [DeviceManager]s for each connected
/// device, and a [SamplingPackageRegistry] for registering sampling packages
/// and their supported devices and probes.
library;

import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cron/cron.dart' as cron;
import 'package:battery_plus/battery_plus.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
part 'runtime/device_manager/device_controller.dart';
part 'runtime/device_manager/device_manager.dart';
part 'runtime/device_manager/device_managers.dart';
part 'runtime/sampling_package_registry.dart';
part 'runtime/user_tasks.dart';

part 'runtime.g.dart';
