/*
 * Copyright 2024 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// The infrastructure library provide on-phone implementations of CAMS services
/// like the [SmartphoneDeploymentService] deployment service and the
/// [SQLiteDataManager] data manager.
///
/// This library also holds the two built-in sampling packages:
///
///  * [device] - a sampling package for collecting information from the device hardware.
///  * [sensors] - a sampling package for collecting data from the basic phone sensors:
///
/// In terms of Domain-Driven Design (DDD), "the infrastructure layer is responsible
/// for providing technical services and resources to support the other layers.
/// It can include databases, message brokers, web servers, cloud platforms,
/// 3rd-party APIs, or any other external components that are required by the system.
/// The infrastructure layer should be generic and adaptable, implementing the
/// interfaces or abstractions that are defined by the domain layer."
/// From [Domain-Driven Design (DDD): A Guide to Building Scalable, High-Performance Systems](https://romanglushach.medium.com/domain-driven-design-ddd-a-guide-to-building-scalable-high-performance-systems-5314a7fe053c) by Roman Glushach.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'infrastructure/data_managers/console_data_manager.dart';
part 'infrastructure/data_managers/file_data_manager.dart';
part 'infrastructure/data_managers/sqlite_data_manager.dart';

part 'infrastructure/file_study_manager.dart';
part 'infrastructure/local_notification_controller.dart';
part 'infrastructure/deployment_service.dart';
part 'infrastructure/persistence.dart';
