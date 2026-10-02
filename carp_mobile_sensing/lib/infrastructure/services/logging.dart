/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// Logs an information [message] to the console.
/// Only logged if [Settings.debugLevel] is [DebugLevel.info] or higher.
void info(String message) =>
    (Settings().debugLevel.index >= DebugLevel.info.index)
    ? debugPrint('\x1B[32m[CAMS INFO]\x1B[0m $message')
    : 0;

/// Logs a warning [message] to the console.
/// Only logged if [Settings.debugLevel] is [DebugLevel.warning] or higher.
void warning(String message) =>
    (Settings().debugLevel.index >= DebugLevel.warning.index)
    ? debugPrint('\x1B[31m[CAMS WARNING]\x1B[0m $message')
    : 0;

/// Logs a debug [message] to the console.
/// Only logged if [Settings.debugLevel] is [DebugLevel.debug] and the
/// Flutter app runs in debug mode (`kDebugMode`).
void debug(String message) =>
    (kDebugMode && Settings().debugLevel.index >= DebugLevel.debug.index)
    ? debugPrint('\x1B[35m[CAMS DEBUG]\x1B[0m $message')
    : 0;
