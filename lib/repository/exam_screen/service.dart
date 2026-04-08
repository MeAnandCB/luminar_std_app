import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/exam_screen/model.dart';

class ExamService {
  Future<ApiResponse<ExamSessionsResponse>> fetchExamSessions() async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await ApiService().get(
        endpoint: AppEndpoints.examSessions,
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
}
