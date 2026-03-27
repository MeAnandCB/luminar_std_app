import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/payment_screen/model.dart';

class PaymentScreenService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<EnrollmentDetailResponse>> fetchEnrollmentDetails(
    String enrollmentUid,
    String accessKey,
  ) async {
    try {
      final response = await _apiService.get(
        endpoint: '${AppEndpoints.enrollmentDetail}$enrollmentUid/',
        token: accessKey,
      );

      if (response.success) {
        return ApiResponse.success(
          EnrollmentDetailResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }
      
      return response.cast<EnrollmentDetailResponse>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }
}
