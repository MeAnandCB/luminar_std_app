import 'dart:developer' as developer;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<DashBoardModel>> getDashboardData() async {
    try {
      final accessKey = await AppUtils.getAccessKey();

      if (accessKey == null || accessKey.isEmpty) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }

      final response = await _apiService.get(
        endpoint: AppEndpoints.dashboard,
        token: accessKey,
      );

      developer.log(
        '─── Dashboard API Response ───\n'
        '  status  : ${response.statusCode}\n'
        '  success : ${response.success}\n'
        '  message : ${response.message}\n'
        '  data    : ${response.data}',
        name: 'DashboardService',
        error: response.success ? null : 'HTTP ${response.statusCode}',
      );

      if (response.success) {
        return ApiResponse.success(
          DashBoardModel.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }

      return response.cast<DashBoardModel>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }
}
