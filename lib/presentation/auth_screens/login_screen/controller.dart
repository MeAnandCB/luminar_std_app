import 'dart:convert';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/material.dart';
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

  // Get full name directly with better fallback
  String get fullName {
    // Safe navigation with null checks
    final studentProfile = _loginResponse?.student?.profile;
    if (studentProfile?.fullName != null &&
        studentProfile!.fullName.isNotEmpty) {
      return studentProfile.fullName;
    }
    return 'Student';
  }

  Future<bool> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoggerUtils.info('🚀 Starting login process...', tag: 'Auth');

      final response = await _apiService.login(
        body: {'email': email, 'password': password},
      );

      if (response.success == true) {
        LoginResponseModel loginResponseModel = response.data;
        // Get the full name from response
        final String fullName = loginResponseModel.student.profile.fullName;

        // Save tokens with full name
        await SharedPrefService.saveTokens(
          loginResponseModel.tokens.access,
          loginResponseModel.tokens.refresh,
          fullName, // Save the name here
        );

        // Convert the entire response to JSON and save
        final responseJson = response.data.toJson();
        await SharedPrefService.saveUserData(responseJson);

        _loginResponse = response.data;
        _isLoading = false;
        notifyListeners();

        // Print confirmation
        LoggerUtils.info('✅ LOGIN SUCCESSFUL | 👤 Student: $fullName', tag: 'Auth');

        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        LoggerUtils.warning('❌ Login failed - ${response.message}', tag: 'Auth');
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      LoggerUtils.error('🔥 Error during login - $e', tag: 'Auth');
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
      LoggerUtils.info('🔍 CheckLoginStatus: isLoggedIn = $isLoggedIn', tag: 'Auth');

      if (isLoggedIn) {
        // Try to get full user data from SharedPrefs
        final userData = await SharedPrefService.getUserData();
        final savedName = await SharedPrefService.getFullName();

        LoggerUtils.debug('🔍 CheckLoginStatus: saved name = $savedName', tag: 'Auth');
        LoggerUtils.debug('🔍 CheckLoginStatus: userData exists = ${userData != null}', tag: 'Auth');

        // If we have user data, reconstruct the login response
        if (userData != null) {
          try {
            // Reconstruct LoginResponseModel from saved data
            _loginResponse = LoginResponseModel.fromJson(userData);
            LoggerUtils.info('✅ Successfully reconstructed user data', tag: 'Auth');
            LoggerUtils.debug(
              '👤 Reconstructed name: ${_loginResponse?.student.profile.fullName}',
              tag: 'Auth',
            );
            notifyListeners();
            return true;
          } catch (e) {
            LoggerUtils.error('❌ Error reconstructing user data: $e', tag: 'Auth');

            // If reconstruction fails but we have the name, create minimal profile
            if (savedName != null && savedName.isNotEmpty) {
              // Create a minimal response with just the name
              // This is a fallback - you might want to handle this differently
              LoggerUtils.warning('⚠️ Using minimal profile with name: $savedName', tag: 'Auth');
            }
            return true;
          }
        } else {
          // If no user data but isLoggedIn is true, something is wrong
          LoggerUtils.warning('⚠️ Inconsistent state: isLoggedIn true but no user data', tag: 'Auth');
          return true; // Still return true since they are logged in
        }
      }
      return false;
    } catch (e) {
      LoggerUtils.error('❌ CheckLoginStatus error: $e', tag: 'Auth');
      return false;
    }
  }

  // Add a method to refresh user data if needed
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
}
