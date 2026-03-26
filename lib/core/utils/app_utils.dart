import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AppUtils {
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
    } else if (message.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    } else if (message.contains('Network')) {
      return 'Network error. Check your internet connection.';
    } else if (message.contains('expired') ||
        message.contains('Unauthorized')) {
      return 'Your session has expired. Please login again.';
    }
    return message;
  }
}
