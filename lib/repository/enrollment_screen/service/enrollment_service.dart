import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';

class EnrollmentService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<EnrollmentResponse>> getEnrollmentData() async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }

      final response = await _apiService.get(
        endpoint: AppEndpoints.studentPortalEnrollments,
        token: accessKey,
      );

      if (response.success) {
        // ── RAW JSON DEBUG — debug-only: includes payment/financial PII ────
        if (kDebugMode) {
          developer.log(
            '── Enrollment raw JSON ──\n'
            '${const JsonEncoder.withIndent('  ').convert(response.data)}',
            name: 'EnrollmentService',
          );

          // Log payment_info fields for each enrollment so we can verify
          // that the key names match what PaymentInfo.fromJson expects.
          final enrollments =
              (response.data['enrollments'] as List<dynamic>? ?? []);
          for (var i = 0; i < enrollments.length; i++) {
            final pi = enrollments[i]['payment_info'] as Map<String, dynamic>?;
            developer.log(
              '── Enrollment[$i] payment_info ──\n'
              '  gross_amount                : ${pi?['gross_amount']}\n'
              '  total_discount              : ${pi?['total_discount']}\n'
              '  net_amount                  : ${pi?['net_amount']}\n'
              '  amount_paid                 : ${pi?['amount_paid']}\n'
              '  pending_amount              : ${pi?['pending_amount']}\n'
              '  payment_completion_percentage: ${pi?['payment_completion_percentage']}\n'
              '  is_fully_paid               : ${pi?['is_fully_paid']}\n'
              '  has_overpayment             : ${pi?['has_overpayment']}\n'
              '  (full map keys: ${pi?.keys.toList()})',
              name: 'EnrollmentService',
            );
          }
        }
        // ─────────────────────────────────────────────────────────────────

        return ApiResponse.success(
          EnrollmentResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }
      
      return response.cast<EnrollmentResponse>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }
}
