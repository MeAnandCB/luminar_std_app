import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';

import 'package:luminar_std/repository/global/helper.dart';
import 'dart:convert';

class EnrollmentService {
  final ApiHelper apiHelper = ApiHelper();

  // Helper method to pretty print JSON
  void _prettyPrintJson(String label, dynamic data) {
    print('📦 $label:');
    const encoder = JsonEncoder.withIndent('  ');
    String prettyJson = encoder.convert(data);
    print(prettyJson);
    print('════════════════════════════════════════');
  }

  Future<EnrollmentResponse> getEnrollmentData({
    required BuildContext context,
  }) async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        AppUtils.navigateToLogin(context);
        throw ApiException('Session expired. Please login again.', null);
      }

      print('🔑 Access Key: $accessKey');
      print('🌐 Making API call to: /api/student_portal/enrollments/');

      final response = await apiHelper.get(
        headers: {'Authorization': 'Bearer $accessKey'},
        context,
        '/api/student_portal/enrollments/',
      );

      // Pretty print the entire response
      _prettyPrintJson('Full API Response', response);

      if (response['status'] == 'success' || response['statusCode'] == 200) {
        print('✅ API call successful');
        return EnrollmentResponse.fromJson(response);
      } else if (response['status'] == 'error' ||
          response['statusCode'] >= 400) {
        if (response['statusCode'] == 401) {
          print('❌ Unauthorized - Session expired');
          await AppUtils.clearUserSession();
          AppUtils.navigateToLogin(context);
          throw ApiException('Session expired. Please login again.', response);
        }

        print('❌ API Error: ${response['message']}');
        throw ApiException(response['message'] ?? 'Request failed', response);
      } else {
        print('❌ Unexpected response status');
        throw ApiException('Unexpected response status', response);
      }
    } on ApiException catch (e) {
      print('❌ ApiException caught: ${e.message}');
      if (e.message.contains('expired') ||
          e.message.contains('Unauthorized') ||
          e.message.contains('Invalid token')) {
        print('🔄 Auth error - clearing session');
        await AppUtils.clearUserSession();
        AppUtils.navigateToLogin(context);
      }
      throw ApiException(AppUtils.getCleanErrorMessage(e.message));
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw ApiException('Unexpected error: ${e.toString()}', null);
    }
  }
}
