import 'package:flutter/material.dart';

import 'package:luminar_std/repository/global/helper.dart';
import 'package:luminar_std/repository/loginscreen/model.dart';

class ApiService {
  final ApiHelper _apiHelper = ApiHelper();

  Future<LoginResponseModel> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiHelper.post(
        context,
        '/api/auth/student/login/',
        body: {'email': email, 'password': password},
        requiresAuth: false,
        showErrorSnackbar: false, // Handle error manually
      );

      if (response['status'] == 'success') {
        return LoginResponseModel.fromJson(response);
      } else {
        throw ApiException(response['message'] ?? 'Login failed', response);
      }
    } on ApiException catch (e) {
      // Re-throw with clean message
      throw ApiException(_getCleanErrorMessage(e.message));
    }
  }

  String _getCleanErrorMessage(String message) {
    if (message.contains('Invalid credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    } else if (message.contains('Network')) {
      return 'Network error. Check your internet connection.';
    }
    return message;
  }
}
