import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class LoggerUtils {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(message, name: tag ?? 'DEBUG');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(message, name: tag ?? 'INFO');
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      dev.log(
        message,
        name: tag ?? 'ERROR',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log(message, name: tag ?? 'WARNING');
    }
  }
}
