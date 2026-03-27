import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/profile_screen/model/profile_model.dart';

class ProfileScreenService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<ProfileModel>> getProfileData() async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }

      final response = await _apiService.get(
        endpoint: AppEndpoints.profile,
        token: accessKey,
      );

      if (response.success) {
        return ApiResponse.success(
          ProfileModel.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }
      
      return response.cast<ProfileModel>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }
}
