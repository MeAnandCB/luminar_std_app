import 'dart:convert';
import 'package:luminar_std/core/constants/app_endpoints.dart';

import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AppUtils {
  /// Set to true once the splash screen finishes navigating away.
  /// The internet dialog is suppressed until this is true.
  static bool appReady = false;

  static Future<String?> getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static navigateToLogin(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    });
  }

  static Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_key');
      await prefs.remove('user_data');
      // Clear any other stored data
      // await AppUtils.clearAccessKey(); // If you have this method
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  static String getCleanErrorMessage(String message) {
    if (message.contains('Invalid credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('expired') || message.contains('Unauthorized')) {
      return 'Your session has expired. Please login again.';
    }
    return message;
  }

  /// Converts raw exception strings into user-friendly messages.
  /// Short, already-readable messages (e.g. "Invalid OTP") are returned as-is.
  static String friendlyError(String raw) {
    if (raw.isEmpty) return 'Something went wrong. Please try again.';
    final lower = raw.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no address associated') ||
        lower.contains('network is unreachable') ||
        lower.contains('clientexception')) {
      return 'No internet connection.\nPlease check your network and try again.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'Access denied. You don\'t have permission.';
    }
    if (lower.contains('404')) {
      return 'Data not found. Please try again.';
    }
    if (lower.contains('500') || lower.contains('server error')) {
      return 'Server error. Please try again later.';
    }
    // Long or technical strings → generic message
    if (raw.length > 80 ||
        lower.contains('exception') ||
        lower.contains('uri=') ||
        lower.contains('errno') ||
        lower.contains('stacktrace')) {
      return 'Something went wrong. Please try again.';
    }
    // Short readable messages (e.g. "Invalid OTP") → show as-is
    return raw;
  }

  static String? getAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    final cleanUrl = url.startsWith('/') ? url : '/$url';
    return '${GlobalLinks.baseUrl}$cleanUrl';
  }
}
