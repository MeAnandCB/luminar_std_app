import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/attandance_screen/new_model.dart';

class AttendanceService1 {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<AttendanceResponse>> getBatchAttendance({
    required String batchId,
    String? sessionId,
    String? startDate,
    String? endDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (sessionId != null) queryParams['session_id'] = sessionId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _apiService.get(
        endpoint: '${AppEndpoints.attendance}$batchId',
        token: accessKey,
        queryParams: queryParams,
      );

      if (response.success) {
        return ApiResponse.success(
          AttendanceResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }

      return response.cast<AttendanceResponse>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }
}

class AttendanceService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<AttendanceResponse>> getBatchAttendance({
    required String batchId,
    String? sessionId,
    String? startDate,
    String? endDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (sessionId != null) queryParams['session_id'] = sessionId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _apiService.get(
        endpoint: '${AppEndpoints.attendance}$batchId',
        token: accessKey,
        queryParams: queryParams,
      );

      if (response.success) {
        return ApiResponse.success(
          AttendanceResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }

      return response.cast<AttendanceResponse>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }

      final response = await _apiService.get(
        endpoint: AppEndpoints.dashboard,
        token: accessKey,
      );

      if (response.success) {
        return ApiResponse.success(
          response.data as Map<String, dynamic>,
          response.statusCode ?? 200,
        );
      }

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }
}
