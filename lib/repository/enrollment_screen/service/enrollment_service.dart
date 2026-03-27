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
