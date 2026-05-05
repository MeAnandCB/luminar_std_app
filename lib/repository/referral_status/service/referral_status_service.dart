import 'package:flutter/foundation.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/repository/referral_status/model/referred_students_model.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class ReferralStatusService {
  final ApiService _apiService = ApiService();

  Future<ReferredStudentsModel?> getReferredStudents(String studentId) async {
    try {
      final endpoint = '${AppEndpoints.referredStudents}$studentId/referred-students/';
      
      final token = await SharedPrefService.getAccessToken();
      
      final response = await _apiService.get(
        endpoint: endpoint,
        token: token,
      );

      if (response.success && response.data != null) {
        return ReferredStudentsModel.fromJson(response.data);
      } else {
        debugPrint('Failed to fetch referred students: ${response.message}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('Error in ReferralStatusService: $e\n$stack');
      return null;
    }
  }
}
