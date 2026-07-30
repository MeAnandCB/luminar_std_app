import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/loginscreen/model.dart';

class LoginService {
  Future<ApiResponse> login({required Map<String, dynamic> body}) async {
    final response = await ApiService().post(
      endpoint: AppEndpoints.login,
      body: body, //,
    );

    if (response.success) {
      LoginResponseModel resModel = LoginResponseModel.fromJson(response.data);
      return ApiResponse(
        success: true,
        data: resModel,
        message: response.message,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse(
        success: false,
        data: '',
        message: response.message,
        statusCode: response.statusCode,
      );
    }
  }

  Future<ApiResponse> logout({
    required String accessToken,
    String? refreshToken,
    String? fcmToken,
  }) async {
    final response = await ApiService().post(
      endpoint: AppEndpoints.logout,
      body: {
        if (refreshToken != null && refreshToken.isNotEmpty) 'refresh': refreshToken,
        // Lets the backend unregister this device's push token so it stops
        // receiving notifications for the account that just logged out —
        // matters most on shared devices where a different student logs in
        // next.
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      },
      token: accessToken,
    );
    return response;
  }

  String getCleanErrorMessage(String message) {
    if (message.contains('Invalid credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    } else if (message.contains('Network')) {
      return 'Network error. Check your internet connection.';
    }
    return message;
  }
}
