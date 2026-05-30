import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/jobs/model/job_notification_model.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class JobsService {
  final ApiService _api = ApiService();

  Future<ApiResponse<JobDetailResponse>> getJobDetail(String jobUid) async {
    try {
      final token = await SharedPrefService.getAccessToken();
      final response = await _api.get(
        endpoint: '${AppEndpoints.jobDetail}$jobUid/',
        token: token,
      );
      if (response.success && response.data != null) {
        final model = JobDetailResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return ApiResponse(
          success: true,
          data: model,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(
        success: false,
        data: null,
        message: response.message ?? 'Failed to load job details',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Error: $e',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<JobApplicationDetailResponse>> getApplicationDetail(
    String applicationUid,
  ) async {
    try {
      final token = await SharedPrefService.getAccessToken();
      final response = await _api.get(
        endpoint: '${AppEndpoints.jobApplicationDetail}$applicationUid/',
        token: token,
      );
      if (response.success && response.data != null) {
        final model = JobApplicationDetailResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return ApiResponse(
          success: true,
          data: model,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(
        success: false,
        data: null,
        message: response.message ?? 'Failed to load application',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Error: $e',
        statusCode: 500,
      );
    }
  }

  Future<void> markJobAsViewed(String jobUid) async {
    try {
      final token = await SharedPrefService.getAccessToken();
      await _api.patch(
        endpoint: '${AppEndpoints.jobDetail}$jobUid/',
        body: {'is_viewed': true},
        token: token,
      );
    } catch (_) {}
  }

  Future<ApiResponse<dynamic>> applyForJob(
    String jobUid, {
    required String email,
    required String phone,
    String? fullName,
    String? resumeUrl,
    String? resumeBase64,
    String? resumeFilename,
    List<Map<String, dynamic>> answers = const [],
  }) async {
    try {
      final token = await SharedPrefService.getAccessToken();
      final body = <String, dynamic>{'email': email, 'phone': phone};
      if (fullName != null && fullName.isNotEmpty) body['full_name'] = fullName;
      if (resumeUrl != null) body['resume_url'] = resumeUrl;
      if (resumeBase64 != null) body['resume_base64'] = resumeBase64;
      if (resumeFilename != null) body['resume_filename'] = resumeFilename;
      if (answers.isNotEmpty) body['answers'] = answers;

      final response = await _api.post(
        endpoint: '${AppEndpoints.jobApply}$jobUid/apply/',
        body: body,
        token: token,
      );
      return response;
    } catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Error: $e',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<JobNotificationResponse>> getJobNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await SharedPrefService.getAccessToken();
      final response = await _api.get(
        endpoint:
            '${AppEndpoints.jobNotifications}?page=$page&page_size=$pageSize',
        token: token,
      );

      if (response.success && response.data != null) {
        final model = JobNotificationResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return ApiResponse(
          success: true,
          data: model,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(
        success: false,
        data: null,
        message: response.message ?? 'Failed to load jobs',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        data: null,
        message: 'Error: $e',
        statusCode: 500,
      );
    }
  }
}
