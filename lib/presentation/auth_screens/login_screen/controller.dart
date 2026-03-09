import 'dart:convert';
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
    // First try from login response
    if (_loginResponse?.student.profile.fullName != null && _loginResponse!.student.profile.fullName.isNotEmpty) {
      return _loginResponse!.student.profile.fullName;
    }
    return 'Student';
  }

  Future<bool> login({required BuildContext context, required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🚀 AuthProvider: Starting login process...');

      final response = await _apiService.login(body: {'email': email, 'password': password});

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
        print('=' * 50);
        print('✅ LOGIN SUCCESSFUL');
        print('=' * 50);
        print('👤 Student Name: $fullName');
        print('🆔 Student ID: ${loginResponseModel.student.profile.studentId}');
        print('📧 Email: ${loginResponseModel.student.profile.email}');
        print('=' * 50);

        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        print('❌ AuthProvider: Login failed - ${response.message}');
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('🔥 AuthProvider: Error during login - $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print('🚪 Logging out...');
      await SharedPrefService.clearAllData();
      _loginResponse = null;
      notifyListeners();
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
    }
  }

  Future<bool> checkLoginStatus() async {
    try {
      final isLoggedIn = await SharedPrefService.isLoggedIn();
      print('🔍 CheckLoginStatus: isLoggedIn = $isLoggedIn');

      if (isLoggedIn) {
        // Try to get full user data from SharedPrefs
        final userData = await SharedPrefService.getUserData();
        final savedName = await SharedPrefService.getFullName();

        print('🔍 CheckLoginStatus: saved name = $savedName');
        print('🔍 CheckLoginStatus: userData exists = ${userData != null}');

        // If we have user data, reconstruct the login response
        if (userData != null) {
          try {
            // Reconstruct LoginResponseModel from saved data
            _loginResponse = LoginResponseModel.fromJson(userData);
            print('✅ Successfully reconstructed user data');
            print('👤 Reconstructed name: ${_loginResponse?.student.profile.fullName}');
            notifyListeners();
            return true;
          } catch (e) {
            print('❌ Error reconstructing user data: $e');

            // If reconstruction fails but we have the name, create minimal profile
            if (savedName != null && savedName.isNotEmpty) {
              // Create a minimal response with just the name
              // This is a fallback - you might want to handle this differently
              print('⚠️ Using minimal profile with name: $savedName');
            }
            return true;
          }
        } else {
          // If no user data but isLoggedIn is true, something is wrong
          print('⚠️ Inconsistent state: isLoggedIn true but no user data');
          return true; // Still return true since they are logged in
        }
      }
      return false;
    } catch (e) {
      print('❌ CheckLoginStatus error: $e');
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
        print('🔄 User data refreshed: ${_loginResponse?.student.profile.fullName}');
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
