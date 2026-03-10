// Fix the typo in filename if needed

import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart';

class EnrollmentRepository {
  final ApiService _apiService = ApiService();

  // Method to fetch enrollments
  Future<ApiResponse<EntrolmentModel>> getEnrollments({String? token}) async {
    try {
      final response = await _apiService.get(
        endpoint: '/api/student_portal/enrollments/',
        token: token,
      );

      if (response.statusCode == 200) {
        // Parse the data into your model
        final enrollmentData = EntrolmentModel.fromJson(response.data);
        return ApiResponse.success(enrollmentData, response.data);
      } else {
        return ApiResponse.error(
          response.message ?? 'Failed to fetch enrollments',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
