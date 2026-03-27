import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/academic_info/model.dart';

class AcademicInfoService {
  Future<ApiResponse<QualificationResponse>> getQualifications() async {
    final response = await ApiService().get(
      endpoint: AppEndpoints.qualifications,
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(
        QualificationResponse.fromJson(response.data),
        response.statusCode ?? 200,
      );
    } else {
      return ApiResponse.error(
        response.message ?? 'Failed to fetch qualifications',
        response.statusCode,
      );
    }
  }

  Future<ApiResponse<SpecializationResponse>> getSpecializations() async {
    final response = await ApiService().get(
      endpoint: AppEndpoints.specializations,
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(
        SpecializationResponse.fromJson(response.data),
        response.statusCode ?? 200,
      );
    } else {
      return ApiResponse.error(
        response.message ?? 'Failed to fetch specializations',
        response.statusCode,
      );
    }
  }
}
