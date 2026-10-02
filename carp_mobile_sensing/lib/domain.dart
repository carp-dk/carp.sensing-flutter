/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// The CAMS domain model: what a study runs, on which devices, and where data goes.
///
/// Extends the [carp_core](https://pub.dev/packages/carp_core) domain model with
/// smartphone-specific classes, like the protocol ([SmartphoneStudyProtocol]),
/// devices ([Smartphone], [BLEHeartRateDevice]), triggers ([PeriodicTrigger],
/// [RecurrentScheduledTrigger]), tasks ([AppTask], [FunctionTask]), and
/// data endpoints ([SQLiteDataEndPoint]). It also defines the service interfaces
/// that the runtime and infrastructure layers implement: [DataManager],
/// [NotificationManager], [StudyProtocolManager], and [SamplingPackage].
/// All domain classes can be serialized to and from JSON.
library;

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart' show AppLifecycleState;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain/core/smartphone_protocol.dart';
part 'domain/core/study_description.dart';
part 'domain/core/data_endpoint.dart';
part 'domain/core/sampling_configurations.dart';
part 'domain/core/device_configurations.dart';
part 'domain/core/device_registrations.dart';
part 'domain/core/smartphone_study.dart';
part 'domain/core/smartphone_deployment.dart';
part 'domain/core/app_task.dart';
part 'domain/core/tasks.dart';
part 'domain/core/triggers.dart';
part 'domain/core/data.dart';
part 'domain/core/data_types.dart';
part 'domain/core/transformers.dart';
part 'infrastructure/services/device_info_service.dart';
part 'domain/services/data_manager.dart';
part 'domain/services/notification_manager.dart';
part 'domain/services/protocol_manager.dart';
part 'domain/services/sampling_package.dart';

part 'domain.g.dart';
