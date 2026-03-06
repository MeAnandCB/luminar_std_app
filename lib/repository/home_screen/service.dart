import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';

import 'package:luminar_std/repository/global/helper.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';

class DashboardService {
  final ApiHelper _apiHelper = ApiHelper();

  Future<DashBoardModel> GetDashboardData({
    required BuildContext context,
  }) async {
    try {
      final accessKey = await AppUtils.getAccessKey();
      final response = await _apiHelper.get(
        headers: {'Authorization': 'Bearer $accessKey'},
        context,
        '/api/student_portal/dashboard/',
      );

      if (response['status'] == 'success') {
        return DashBoardModel.fromJson(response);
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
