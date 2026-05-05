import 'package:flutter/foundation.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/repository/referral_status/model/referred_students_model.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class ReferralStatusService {
  final ApiService _apiService = ApiService();

  Future<ReferredStudentsModel?> getReferredStudentsHistory() async {
    try {
      final endpoint = AppEndpoints.referredStudentsHistory;
      
      final token = await SharedPrefService.getAccessToken();
      
      final response = await _apiService.get(
        endpoint: endpoint,
        token: token,
      );

      if (response.success && response.data != null) {
        return ReferredStudentsModel.fromJson(response.data);
      } else {
        debugPrint('Failed to fetch referred history: ${response.message}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('Error in ReferralStatusService History: $e\n$stack');
      return null;
    }
  }

  Future<ReferredStudentsModel?> getReferredStudentsEnrolled(String studentId) async {
    try {
      final endpoint = '${AppEndpoints.referredStudentsEnrolled}$studentId/referred-students/';
      
      final token = await SharedPrefService.getAccessToken();
      
      final response = await _apiService.get(
        endpoint: endpoint,
        token: token,
      );

      if (response.success && response.data != null) {
        return ReferredStudentsModel.fromJson(response.data);
      } else {
        debugPrint('Failed to fetch enrolled students: ${response.message}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('Error in ReferralStatusService Enrolled: $e\n$stack');
      return null;
    }
  }
}
