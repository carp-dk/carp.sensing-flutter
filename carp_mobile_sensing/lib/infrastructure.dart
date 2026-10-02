/*
 * Copyright 2024 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// The CAMS infrastructure layer: on-phone implementations of the CAMS services.
///
/// Holds the local deployment service ([SmartphoneDeploymentService]), the
/// data managers that store measurements on the phone ([ConsoleDataManager],
/// [FileDataManager], [SQLiteDataManager]), the [FileStudyProtocolManager],
/// the [FlutterLocalNotificationManager], and the [PersistenceService] that
/// saves runtime state across app restarts.
/// These classes implement the interfaces defined in the [domain] layer and
/// are used by the [runtime] layer. The built-in sampling packages are in
/// the [sampling_packages] library.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:archive/archive_io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background/flutter_background.dart';

part 'infrastructure/data_managers/console_data_manager.dart';
part 'infrastructure/data_managers/file_data_manager.dart';
part 'infrastructure/data_managers/sqlite_data_manager.dart';

part 'infrastructure/services/file_protocol_manager.dart';
part 'infrastructure/services/local_notification_manager.dart';
part 'infrastructure/services/logging.dart';
part 'infrastructure/services/background_service.dart';

part 'infrastructure/services/deployment_service.dart';
part 'infrastructure/services/persistence_service.dart';
part 'infrastructure/settings.dart';
