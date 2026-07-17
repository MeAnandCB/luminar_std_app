import 'dart:io';

import 'package:flutter/services.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';

/// Checks the device's "Set time automatically" setting — attendance QR
/// validation compares the QR's start/end timestamps against
/// `DateTime.now()`, so a manually-set (wrong) device clock causes valid
/// QR codes to read as "not yet valid" or "expired". Android exposes this
/// via Settings.Global.AUTO_TIME; iOS has no public API for it, so this
/// always reports enabled on iOS (fail-open) rather than blocking a
/// platform we can't actually check.
class DeviceTimeUtils {
  static const _channel = MethodChannel('luminar/device_time');

  static Future<bool> isAutoTimeEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('isAutoTimeEnabled');
      return result ?? true;
    } catch (e) {
      LoggerUtils.error('isAutoTimeEnabled failed: $e', tag: 'DeviceTime');
      return true;
    }
  }

  /// Returns true if the settings screen was actually launched. Callers
  /// should surface a fallback message on false instead of failing silently
  /// — e.g. if this MethodChannel isn't registered because native code
  /// changed but the app was only hot-reloaded/hot-restarted rather than
  /// fully rebuilt.
  static Future<bool> openDateSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      await _channel.invokeMethod('openDateSettings');
      return true;
    } catch (e) {
      LoggerUtils.error('openDateSettings failed: $e', tag: 'DeviceTime');
      return false;
    }
  }
}
