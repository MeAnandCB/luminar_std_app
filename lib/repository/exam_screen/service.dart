import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/exam_screen/model.dart';

class ExamService {
  Future<ApiResponse<ExamSessionsResponse>> fetchExamSessions() async {
    try {
      final token = await AppUtils.getAccessKey();
      final endpoint = AppEndpoints.examSessions;

      final response = await ApiService().get(
        endpoint: endpoint,
        token: token,
      );

      if (response.success) {
        return ApiResponse.success(
          ExamSessionsResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      } else {
        return response.cast<ExamSessionsResponse>();
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  /// Marks an exam session's attempt as visible (or hidden) to the student.
  /// Endpoint: POST /api/student_portal/exam-sessions/{session_uid}/visibility/
  Future<ApiResponse<dynamic>> markVisibility({
    required String sessionUid,
    required String attemptUid,
    bool isVisibleToStudent = true,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final endpoint =
          '${AppEndpoints.examSessionVisibility}$sessionUid/visibility/';
      final body = {
        'records': [
          {
            'attempt_uid': attemptUid,
            'is_visible_to_student': isVisibleToStudent,
          },
        ],
      };

      final response = await ApiService().post(
        endpoint: endpoint,
        token: token,
        body: body,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  /// Fetches an exam session's result using attemptUid.
  /// Endpoint: GET /api/student_portal/exams/results/{attemptUid}/
  Future<ApiResponse<ExamResultResponse>> fetchExamResult({
    required String attemptUid,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final endpoint = '${AppEndpoints.examResult}$attemptUid/';

      final response = await ApiService().get(
        endpoint: endpoint,
        token: token,
      );

      if (response.success) {
        return ApiResponse.success(
          ExamResultResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      } else {
        return response.cast<ExamResultResponse>();
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
