part of '../carp_services/carp_services.dart';

/// How much `carp_webservices` logs. A level also logs the levels before it.
enum CarpLogLevel { none, info, warning, debug }

/// The log of `carp_webservices`. Set [level] to log more or less.
class CarpLog {
  static CarpLogLevel level = CarpLogLevel.warning;

  static void info(String message) => _log(CarpLogLevel.info, message);
  static void warning(String message) => _log(CarpLogLevel.warning, message);

  /// Requests and responses in full. Never logged in a release build.
  static void debug(String message) => kDebugMode ? _log(CarpLogLevel.debug, message) : null;

  static void _log(CarpLogLevel at, String message) =>
      level.index >= at.index ? debugPrint('[CAWS ${at.name.toUpperCase()}] $message') : null;
}
