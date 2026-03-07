import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/presentation/login_screen/login_screen.dart';
import 'package:luminar_std/repository/global/helper.dart';

import 'package:luminar_std/repository/profile_screen/model/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreenService {
  final ApiHelper _apiHelper = ApiHelper();

  Future<ProfileModel> GetProfileData({required BuildContext context}) async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      // Check if accessKey exists
      if (accessKey == null || accessKey.isEmpty) {
        _navigateToLogin(context);
        throw ApiException('Session expired. Please login again.', null);
      }

      final response = await _apiHelper.get(
        headers: {'Authorization': 'Bearer $accessKey'},
        context,
        '/api/student_portal/profile/',
      );

      if (response['status'] == 'success' || response['statusCode'] == 200) {
        return ProfileModel.fromJson(response);
      } else if (response['status'] == 'error' ||
          response['statusCode'] >= 400) {
        // Handle 401 Unauthorized specifically
        if (response['statusCode'] == 401) {
          await _clearUserSession();
          _navigateToLogin(context);
          throw ApiException('Session expired. Please login again.', response);
        }

        throw ApiException(response['message'] ?? 'Request failed', response);
      } else {
        throw ApiException('Unexpected response status', response);
      }
    } on ApiException catch (e) {
      // Check if it's an auth error in the exception message
      if (e.message.contains('expired') ||
          e.message.contains('Unauthorized') ||
          e.message.contains('Invalid token')) {
        await _clearUserSession();
        _navigateToLogin(context);
      }

      // Re-throw with clean message
      throw ApiException(_getCleanErrorMessage(e.message));
    } catch (e) {
      // Handle unexpected errors
      throw ApiException('Unexpected error: ${e.toString()}', null);
    }
  }

  String _getCleanErrorMessage(String message) {
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

  Future<void> _clearUserSession() async {
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

  void _navigateToLogin(BuildContext context) {
    // Use WidgetsBinding to ensure navigation happens after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    });
  }
}
