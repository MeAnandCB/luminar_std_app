import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefService {
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyFullName = 'fullname';

  // Auth tokens live in platform secure storage (Keychain / Keystore), not
  // plaintext SharedPreferences. Tokens saved by older app versions are moved
  // over on first read, so existing users stay logged in.
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<void> _writeToken(SharedPreferences prefs, String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
      await prefs.remove(key);
    } catch (e) {
      // Secure storage unavailable on this device: keep the old behaviour
      LoggerUtils.error('Secure storage write failed, using SharedPreferences: $e', tag: 'SharedPref');
      await prefs.setString(key, value);
    }
  }

  static Future<String?> _readToken(String key) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = await _secure.read(key: key);
      if (value != null && value.isNotEmpty) return value;
    } catch (e) {
      LoggerUtils.error('Secure storage read failed: $e', tag: 'SharedPref');
      return prefs.getString(key);
    }
    final legacy = prefs.getString(key);
    if (legacy != null && legacy.isNotEmpty) {
      await _writeToken(prefs, key, legacy);
    }
    return legacy;
  }

  /// Debug-only session injection (see main.dart).
  static Future<void> saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeToken(prefs, keyAccessToken, accessToken);
  }

  // Save tokens
  static Future<void> saveTokens(String accessToken, String refreshToken, String fullname) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeToken(prefs, keyAccessToken, accessToken);
    await _writeToken(prefs, keyRefreshToken, refreshToken);
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
  static Future<String?> getAccessToken() => _readToken(keyAccessToken);

  // Get refresh token
  static Future<String?> getRefreshToken() => _readToken(keyRefreshToken);

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

  // Clear auth data on logout — only the keys this class owns.
  // Must NOT use prefs.clear(): that wipes every key in SharedPreferences
  // app-wide, including unrelated one-time flags like
  // TermsAgreementScreen.prefsKey, which then incorrectly re-prompts the
  // Terms of Use screen after every logout.
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAccessToken);
    await prefs.remove(keyRefreshToken);
    await prefs.remove(keyFullName);
    await prefs.remove(keyUserData);
    await prefs.remove(keyIsLoggedIn);
    try {
      await _secure.delete(key: keyAccessToken);
      await _secure.delete(key: keyRefreshToken);
    } catch (e) {
      LoggerUtils.error('Secure storage delete failed: $e', tag: 'SharedPref');
    }
    LoggerUtils.info('🚪 User logged out, auth data cleared', tag: 'SharedPref');
  }
}
