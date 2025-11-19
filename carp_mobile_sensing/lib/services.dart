/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// This library holds the definition of all CAMS services used for sensing.
library;

import 'dart:async';
import 'dart:io';
import 'dart:developer' as log;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

part 'domain/services/data_manager.dart';
part 'runtime/device_controller.dart';
part 'domain/services/notification_controller.dart';
part 'infrastructure/settings.dart';
part 'infrastructure/study_manager.dart';
part 'infrastructure/phone/logging.dart';
