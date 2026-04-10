import 'package:flutter/foundation.dart';
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

      debugPrint('══════════════════════════════════════════');
      debugPrint('📤 FETCH EXAM SESSIONS');
      debugPrint('   GET $endpoint');

      final response = await ApiService().get(
        endpoint: endpoint,
        token: token,
      );

      debugPrint('📥 FETCH EXAM SESSIONS — response:');
      debugPrint('   success : ${response.success}');
      debugPrint('   status  : ${response.statusCode}');
      debugPrint('   data    : ${response.data}');
      debugPrint('   message : ${response.message}');
      debugPrint('══════════════════════════════════════════');

      if (response.success) {
        return ApiResponse.success(
          ExamSessionsResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      } else {
        return response.cast<ExamSessionsResponse>();
      }
    } catch (e) {
      debugPrint('❌ FETCH EXAM SESSIONS — exception: $e');
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

      debugPrint('══════════════════════════════════════════');
      debugPrint('📤 MARK VISIBILITY');
      debugPrint('   POST $endpoint');
      debugPrint('   Payload: $body');

      final response = await ApiService().post(
        endpoint: endpoint,
        token: token,
        body: body,
      );

      debugPrint('📥 MARK VISIBILITY — response:');
      debugPrint('   success : ${response.success}');
      debugPrint('   status  : ${response.statusCode}');
      debugPrint('   data    : ${response.data}');
      debugPrint('   message : ${response.message}');
      debugPrint('══════════════════════════════════════════');

      return response;
    } catch (e) {
      debugPrint('❌ MARK VISIBILITY — exception: $e');
      return ApiResponse.error(e.toString(), null);
    }
  }
}
