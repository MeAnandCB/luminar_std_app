import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/loginscreen/model.dart';

class LoginService {
  Future<ApiResponse> login({required Map<String, dynamic> body}) async {
    final response = await ApiService().post(
      endpoint: '/api/auth/student/login/',
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
