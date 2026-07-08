/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// Add an information messages to the system log.
void info(String message) =>
    (Settings().debugLevel.index >= DebugLevel.info.index)
    ? debugPrint('[CAMS INFO] $message')
    : 0;

/// Add a warning messages to the system log.
void warning(String message) =>
    (Settings().debugLevel.index >= DebugLevel.warning.index)
    ? debugPrint('[CAMS WARNING] $message')
    : 0;

/// Add a debug messages to the system log.
/// Only logged if the Flutter app is in debug mode (kDebugMode).
void debug(String message) =>
    (kDebugMode && Settings().debugLevel.index >= DebugLevel.debug.index)
    ? debugPrint('[CAMS DEBUG] $message')
    : 0;
