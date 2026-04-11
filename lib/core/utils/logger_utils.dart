import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class LoggerUtils {
  // log levels matching dart:developer convention
  static const int _levelDebug   = 500;
  static const int _levelInfo    = 800;
  static const int _levelWarning = 900;
  static const int _levelError   = 1000;

  static void debug(String message, {String? tag}) {
    if (!kDebugMode) return;
    dev.log(message, name: tag ?? 'APP', level: _levelDebug);
  }

  static void info(String message, {String? tag}) {
    if (!kDebugMode) return;
    dev.log(message, name: tag ?? 'APP', level: _levelInfo);
  }

  static void warning(String message, {String? tag}) {
    dev.log('⚠️  $message', name: tag ?? 'APP', level: _levelWarning);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '🔴 $message',
      name: tag ?? 'APP',
      level: _levelError,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
