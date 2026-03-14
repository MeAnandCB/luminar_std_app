// lib/repository/attandance_screen/attendance_service.dart

import 'package:flutter/material.dart';
import 'package:luminar_std/repository/attandance_screen/model.dart';
import 'package:luminar_std/repository/global/helper.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'dart:convert';

class AttendanceService {
  final ApiHelper apiHelper = ApiHelper();

  void _prettyPrintJson(String label, dynamic data) {
    print('📦 $label:');
    const encoder = JsonEncoder.withIndent('  ');
    String prettyJson = encoder.convert(data);
    print(prettyJson);
    print('════════════════════════════════════════');
  }

  Future<AttendanceResponse> getBatchAttendance({
    required BuildContext context,
    required String batchId,
    String? sessionId,
    String? startDate,
    String? endDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        print('❌ No access key found');
        AppUtils.navigateToLogin(context);
        throw ApiException('Session expired. Please login again.', null);
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (sessionId != null) queryParams['session_id'] = sessionId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      // Build endpoint with query parameters
      final endpoint = '/api/attendance/my-batch-attendance/$batchId';
      final uri = Uri(path: endpoint, queryParameters: queryParams);
      final fullEndpoint = uri.toString();

      print('📍 Fetching attendance from: $fullEndpoint (Page $page)');

      final response = await apiHelper.get(
        headers: {'Authorization': 'Bearer $accessKey'},
        context,
        fullEndpoint,
      );

      _prettyPrintJson('Attendance API Response', response);

      if (response['status'] == 'success' || response['statusCode'] == 200) {
        print('✅ Attendance data fetched successfully');
        print(
          '📊 Page $page of ${response['total_pages']} - Total records: ${response['count']}',
        );
        return AttendanceResponse.fromJson(response);
      } else if (response['statusCode'] == 401) {
        print('❌ Unauthorized - Session expired');
        await AppUtils.clearUserSession();
        AppUtils.navigateToLogin(context);
        throw ApiException('Session expired. Please login again.', response);
      } else if (response['statusCode'] == 404) {
        print('❌ Batch not found: $batchId');
        throw ApiException(
          'Batch not found. Please check the batch ID.',
          response,
        );
      } else if (response['status'] == 'error' ||
          response['statusCode'] >= 400) {
        final errorMsg = response['message'] ?? 'Failed to load attendance';
        print('❌ API Error: $errorMsg');
        throw ApiException(errorMsg, response);
      } else {
        print('❌ Unexpected response format');
        throw ApiException('Unexpected response from server', response);
      }
    } on ApiException catch (e) {
      print('❌ ApiException caught: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw ApiException('Network error. Please check your connection.', null);
    }
  }
}
