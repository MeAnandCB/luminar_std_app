import 'package:http/http.dart' as http;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/class_task/class_task_model.dart';

class ClassTaskService {
  final ApiService _apiService = ApiService();

  /// Fetch tasks assigned to the logged-in student.
  /// Optional filters: [batchUid], [taskUid]
  Future<ApiResponse<StudentTasksResponse>> getMyTasks({
    String? batchUid,
    String? taskUid,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final Map<String, String> queryParams = {};
      if (batchUid != null && batchUid.isNotEmpty) {
        queryParams['batch_uid'] = batchUid;
      }
      if (taskUid != null && taskUid.isNotEmpty) {
        queryParams['task_uid'] = taskUid;
      }

      final response = await _apiService.get(
        endpoint: AppEndpoints.studentTasksMy,
        token: token,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          StudentTasksResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      } else {
        return response.cast<StudentTasksResponse>();
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  /// Submit work for an assignment with multiple files (max 10) plus optional message.
  /// POST /api/student-tasks/assignments/<assignment_uid>/submissions/create/
  Future<ApiResponse<SubmissionCreateResponse>> submitTask({
    required String assignmentUid,
    required List<http.MultipartFile> files,
    String? message,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final endpoint =
          '${AppEndpoints.studentTaskSubmit}$assignmentUid/submissions/create/';

      final Map<String, String> fields = {};
      if (message != null && message.trim().isNotEmpty) {
        fields['message'] = message.trim();
      }

      final response = await _apiService.multipart(
        endpoint: endpoint,
        method: 'POST',
        fields: fields,
        files: files,
        token: token,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          SubmissionCreateResponse.fromJson(response.data),
          response.statusCode ?? 201,
        );
      } else {
        return ApiResponse.error(
          response.message ?? 'Submission failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
