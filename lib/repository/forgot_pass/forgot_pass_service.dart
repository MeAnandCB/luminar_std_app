import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/forgot_pass/forgotpass_model.dart';

class ForgotPassService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<ForgotPassModel>> sendOtp({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: AppEndpoints.forgotPasswordSendOtp,
        body: {'email': email},
      );

      if (response.success) {
        return ApiResponse.success(
          ForgotPassModel.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }
      
      return response.cast<ForgotPassModel>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: AppEndpoints.forgotPasswordVerifyOtp,
        body: {'email': email, 'otp': otp},
      );

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String comPass,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: AppEndpoints.forgotPasswordResetPassword,
        body: {
          "email": email,
          "otp": otp,
          "new_password": newPassword,
          "confirm_password": comPass,
        },
      );

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
