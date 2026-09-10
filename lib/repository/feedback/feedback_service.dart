import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/feedback/feedback_model.dart';

class FeedbackService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<FeedbackOptions>> getOptions() async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: AppEndpoints.feedbackOptions,
        token: token,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          FeedbackOptions.fromJson(response.data as Map<String, dynamic>),
          response.statusCode ?? 200,
        );
      }
      return response.cast<FeedbackOptions>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<MyBatchFeedbackResponse>> getMyBatches() async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: AppEndpoints.feedbackMyBatches,
        token: token,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          MyBatchFeedbackResponse.fromJson(response.data as Map<String, dynamic>),
          response.statusCode ?? 200,
        );
      }
      return response.cast<MyBatchFeedbackResponse>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<BatchFeedbackEntry>> submitFeedback({
    required String batchUid,
    required int rating,
    required String concernType,
    required String message,
    String? concernDetail,
  }) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.post(
        endpoint: '${AppEndpoints.feedbackSubmit}$batchUid/submit/',
        token: token,
        body: {
          'rating': rating,
          'concern_type': concernType,
          'message': message,
          if (concernDetail != null && concernDetail.trim().isNotEmpty)
            'concern_detail': concernDetail.trim(),
        },
      );

      if (response.success && response.data != null) {
        final root = response.data as Map<String, dynamic>;
        final feedbackJson = root['feedback'] as Map<String, dynamic>?;
        if (feedbackJson != null) {
          return ApiResponse.success(
            BatchFeedbackEntry.fromJson(feedbackJson),
            response.statusCode ?? 201,
          );
        }
      }

      return ApiResponse.error(
        response.message ?? 'Failed to submit feedback',
        response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
