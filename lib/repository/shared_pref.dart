import 'dart:convert';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyFullName = 'fullname';

  // Save tokens
  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    String fullname,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAccessToken, accessToken);
    await prefs.setString(keyRefreshToken, refreshToken);
    await prefs.setString(keyFullName, fullname);
    await prefs.setBool(keyIsLoggedIn, true);
    LoggerUtils.info('✅ Tokens and name saved successfully | 👤 Saved name: $fullname', tag: 'SharedPref');
  }

  // Get full name
  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyFullName);
  }

  // Save user data as JSON string
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(userData);
    await prefs.setString(keyUserData, jsonString);
    LoggerUtils.info('✅ User data saved successfully', tag: 'SharedPref');
    LoggerUtils.debug('📦 Saved JSON: $jsonString', tag: 'SharedPref');
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAccessToken);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyRefreshToken);
  }

  // Get user data as Map
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString(keyUserData);

    if (userDataString != null) {
      try {
        LoggerUtils.debug('📖 Retrieved user data string: $userDataString', tag: 'SharedPref');
        return Map<String, dynamic>.from(json.decode(userDataString));
      } catch (e) {
        LoggerUtils.error('❌ Error parsing user data: $e', tag: 'SharedPref');
        return null;
      }
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  // Clear all data (logout)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAccessToken);
    await prefs.remove(keyRefreshToken);
    await prefs.remove(keyFullName);
    await prefs.remove(keyUserData);
    await prefs.remove(keyIsLoggedIn);
    LoggerUtils.info('🚪 User logged out, all data cleared', tag: 'SharedPref');
  }
}
