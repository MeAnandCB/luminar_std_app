import 'dart:convert';
import 'dart:io';

import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/repository/FCM/fcm_service.dart';
import 'package:luminar_std/repository/loginscreen/model.dart';
import 'package:luminar_std/repository/loginscreen/service.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class AuthProvider extends ChangeNotifier {
  final LoginService _apiService = LoginService();

  bool _isLoading = false;
  String? _errorMessage;
  LoginResponseModel? _loginResponse;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LoginResponseModel? get loginResponse => _loginResponse;
  StudentData? get studentData => _loginResponse?.student;

  String get fullName {
    final studentProfile = _loginResponse?.student?.profile;
    if (studentProfile?.fullName != null &&
        studentProfile!.fullName.isNotEmpty) {
      return studentProfile.fullName;
    }
    return 'Student';
  }

  Future<bool> login({
    required BuildContext context,
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoggerUtils.info('🚀 Starting login process...', tag: 'Auth');

      // ─── Get FCM Token before login ───────────────────────────
      String? fcmToken;
      try {
        fcmToken = await FCMService().getToken();
        LoggerUtils.info('📲 FCM Token fetched: $fcmToken', tag: 'Auth');
      } catch (e) {
        LoggerUtils.error('⚠️ FCM token fetch failed: $e', tag: 'Auth');
      }
      // ──────────────────────────────────────────────────────────

      // Always trim and lowercase before sending
      final cleanIdentifier = identifier.toLowerCase().trim();

      // Detect email vs phone: if it contains '@' treat as email, else phone
      final bool isEmail = cleanIdentifier.contains('@');

      // Build login body with FCM token
      final Map<String, dynamic> loginBody = {
        if (isEmail) 'email': cleanIdentifier else 'phone': cleanIdentifier,
        'password': password,
        'fcm_token': fcmToken ?? '',
        'platform': Platform.isIOS ? 'ios' : 'android',
      };

      // Print to console
      LoggerUtils.info(
        '📤 Login payload: ${jsonEncode(loginBody)}',
        tag: 'Auth',
      );

      final response = await _apiService.login(body: loginBody);

      if (response.success == true) {
        LoginResponseModel loginResponseModel = response.data;
        final String fullName = loginResponseModel.student.profile.fullName;

        await SharedPrefService.saveTokens(
          loginResponseModel.tokens.access,
          loginResponseModel.tokens.refresh,
          fullName,
        );

        final responseJson = response.data.toJson();
        await SharedPrefService.saveUserData(responseJson);

        _loginResponse = response.data;
        _isLoading = false;
        notifyListeners();

        LoggerUtils.info(
          '✅ LOGIN SUCCESSFUL | 👤 Student: $fullName',
          tag: 'Auth',
        );

        return true;
      } else {
        _errorMessage = _cleanError(response.message);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _cleanError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      LoggerUtils.info('🚪 Logging out...', tag: 'Auth');
      await SharedPrefService.clearAllData();
      _loginResponse = null;
      notifyListeners();
      LoggerUtils.info('✅ Logout successful', tag: 'Auth');
    } catch (e) {
      LoggerUtils.error('❌ Logout error: $e', tag: 'Auth');
    }
  }

  Future<bool> checkLoginStatus() async {
    try {
      final isLoggedIn = await SharedPrefService.isLoggedIn();
      LoggerUtils.info(
        '🔍 CheckLoginStatus: isLoggedIn = $isLoggedIn',
        tag: 'Auth',
      );

      if (isLoggedIn) {
        final userData = await SharedPrefService.getUserData();
        final savedName = await SharedPrefService.getFullName();

        LoggerUtils.debug(
          '🔍 CheckLoginStatus: saved name = $savedName',
          tag: 'Auth',
        );
        LoggerUtils.debug(
          '🔍 CheckLoginStatus: userData exists = ${userData != null}',
          tag: 'Auth',
        );

        if (userData != null) {
          try {
            _loginResponse = LoginResponseModel.fromJson(userData);
            LoggerUtils.info(
              '✅ Successfully reconstructed user data',
              tag: 'Auth',
            );
            LoggerUtils.debug(
              '👤 Reconstructed name: ${_loginResponse?.student.profile.fullName}',
              tag: 'Auth',
            );
            notifyListeners();
            return true;
          } catch (e) {
            LoggerUtils.error(
              '❌ Error reconstructing user data: $e',
              tag: 'Auth',
            );
            if (savedName != null && savedName.isNotEmpty) {
              LoggerUtils.warning(
                '⚠️ Using minimal profile with name: $savedName',
                tag: 'Auth',
              );
            }
            return true;
          }
        } else {
          LoggerUtils.warning(
            '⚠️ Inconsistent state: isLoggedIn true but no user data found. Force clearing.',
            tag: 'Auth',
          );
          await SharedPrefService.clearAllData();
          _loginResponse = null;
          notifyListeners();
          return false;
        }
      }
      return false;
    } catch (e) {
      LoggerUtils.error('❌ CheckLoginStatus error: $e', tag: 'Auth');
      return false;
    }
  }

  Future<void> refreshUserData() async {
    try {
      final userData = await SharedPrefService.getUserData();
      if (userData != null) {
        _loginResponse = LoginResponseModel.fromJson(userData);
        notifyListeners();
        LoggerUtils.info(
          '🔄 User data refreshed: ${_loginResponse?.student.profile.fullName}',
          tag: 'Auth',
        );
      }
    } catch (e) {
      LoggerUtils.error('❌ Error refreshing user data: $e', tag: 'Auth');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanError(String? raw) {
    if (raw == null || raw.isEmpty) return 'Something went wrong. Please try again.';
    final r = raw.toLowerCase();
    if (r.contains('socketexception') ||
        r.contains('failed host lookup') ||
        r.contains('network is unreachable') ||
        r.contains('connection refused') ||
        r.contains('clientexception')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (r.contains('timeout') || r.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }
    if (r.contains('invalid credentials') ||
        r.contains('no active account') ||
        r.contains('unable to log in')) {
      return 'Incorrect email/phone or password.';
    }
    return raw;
  }
}
