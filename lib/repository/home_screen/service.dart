import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/global/helper.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';

class DashboardService {
  final ApiHelper apiHelper = ApiHelper();

  Future<DashBoardModel> GetDashboardData({
    required BuildContext context,
  }) async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      // Check if accessKey exists
      if (accessKey == null || accessKey.isEmpty) {
        AppUtils.navigateToLogin(context);
        throw ApiException('Session expired. Please login again.', null);
      }

      final response = await apiHelper.get(
        headers: {'Authorization': 'Bearer $accessKey'},
        context,
        '/api/student_portal/dashboard/',
      );

      // PRINT THE FULL RESPONSE
      print('========== DASHBOARD API RESPONSE ==========');
      print('Response status: ${response['status']}');
      print('Response statusCode: ${response['statusCode']}');
      print('Full response data:');
      print(response); // This will print the entire response object

      // For more readable JSON format, you can use:
      // const JsonEncoder.withIndent('  ').convert(response)

      print('============================================');

      if (response['status'] == 'success' || response['statusCode'] == 200) {
        return DashBoardModel.fromJson(response);
      } else if (response['status'] == 'error' ||
          response['statusCode'] >= 400) {
        // Handle 401 Unauthorized specifically
        if (response['statusCode'] == 401) {
          await AppUtils.clearUserSession();
          AppUtils.navigateToLogin(context);
          throw ApiException('Session expired. Please login again.', response);
        }

        throw ApiException(response['message'] ?? 'Request failed', response);
      } else {
        throw ApiException('Unexpected response status', response);
      }
    } on ApiException catch (e) {
      // PRINT ERROR
      print('========== DASHBOARD API ERROR ==========');
      print('Error message: ${e.message}');
      print('Error data: ${e.responseData}');
      print('=========================================');

      // Check if it's an auth error in the exception message
      if (e.message.contains('expired') ||
          e.message.contains('Unauthorized') ||
          e.message.contains('Invalid token')) {
        await AppUtils.clearUserSession();
        AppUtils.navigateToLogin(context);
      }

      // Re-throw with clean message
      throw ApiException(AppUtils.getCleanErrorMessage(e.message));
    } catch (e) {
      // PRINT UNEXPECTED ERROR
      print('========== DASHBOARD UNEXPECTED ERROR ==========');
      print('Error: $e');
      print('===============================================');

      // Handle unexpected errors
      throw ApiException('Unexpected error: ${e.toString()}', null);
    }
  }
}
