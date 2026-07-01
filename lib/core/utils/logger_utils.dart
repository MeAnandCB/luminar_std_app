import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class LoggerUtils {
  static const int _levelDebug   = 500;
  static const int _levelInfo    = 800;
  static const int _levelWarning = 900;
  static const int _levelError   = 1000;

  // dev.log() only streams to the Dart VM Service (IDE Debug Console /
  // DevTools) — it never reaches plain stdout, so terminal/CI/`flutter run`
  // log captures never see it. Mirror through debugPrint so these lines show
  // up in any console too.
  static void _console(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint('[$tag] $message');
  }

  static void debug(String message, {String? tag}) {
    if (!kDebugMode) return;
    dev.log(message, name: tag ?? 'APP', level: _levelDebug);
    _console(tag ?? 'APP', message);
  }

  static void info(String message, {String? tag}) {
    if (!kDebugMode) return;
    dev.log(message, name: tag ?? 'APP', level: _levelInfo);
    _console(tag ?? 'APP', message);
  }

  static void warning(String message, {String? tag}) {
    dev.log('⚠️  $message', name: tag ?? 'APP', level: _levelWarning);
    _console(tag ?? 'APP', '⚠️  $message');
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
    _console(tag ?? 'APP', '🔴 $message');
  }
}
