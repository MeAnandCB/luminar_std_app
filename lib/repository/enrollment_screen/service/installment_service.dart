import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/repository/enrollment_screen/model/emiplans_model.dart';

class PaymentDetailsApiService {
  final ApiService _apiService = ApiService();

  // Store enrollment ID to use in requests
  String? _enrollmentId;

  // Method to set enrollment ID
  void setEnrollmentId(String enrollmentId) {
    _enrollmentId = enrollmentId;
  }

  Future<ApiResponse<List<EmiPlan>>> fetchEmiPlans() async {
    try {
      final accessKey = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: AppEndpoints.emiPlans,
        token: accessKey,
      );

      if (response.success) {
        final jsonData = response.data;
        List<dynamic> plansJson = [];
        
        if (jsonData is List) {
          plansJson = jsonData;
        } else if (jsonData is Map) {
          if (jsonData.containsKey('results')) {
            plansJson = jsonData['results'] as List<dynamic>;
          } else if (jsonData.containsKey('emi_plans')) {
            plansJson = jsonData['emi_plans'] as List<dynamic>;
          } else if (jsonData.containsKey('data')) {
            plansJson = jsonData['data'] as List<dynamic>;
          }
        }

        final plans = plansJson.map((json) => EmiPlan.fromJson(json)).toList();
        return ApiResponse.success(plans, response.statusCode ?? 200);
      } else {
        return response.cast<List<EmiPlan>>();
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<dynamic>> confirmEmiPlan({
    required String emiPlanId,
    required String enrollmentId,
    required List<num> emiAmounts,
    String? firstEmiDate,
  }) async {
    if (emiPlanId.isEmpty) {
      return ApiResponse.error('emi_plan_id cannot be empty', null);
    }
    if (enrollmentId.isEmpty) {
      return ApiResponse.error('enrollment_id cannot be empty', null);
    }
    if (emiAmounts.isEmpty) {
      return ApiResponse.error('emi_amounts cannot be empty', null);
    }
    try {
      final accessKey = await AppUtils.getAccessKey();
      final Map<String, dynamic> body = {
        'enrollment_id': enrollmentId,
        'emi_plan_id': emiPlanId,
        'emi_amounts': emiAmounts,
        'confirmation': true,
      };
      if (firstEmiDate != null && firstEmiDate.isNotEmpty) {
        body['first_emi_date'] = firstEmiDate;
      }

      LoggerUtils.info('=== EMI Confirm REQUEST ===', tag: 'EmiConfirm');
      LoggerUtils.info('POST ${AppEndpoints.emiConfirm}', tag: 'EmiConfirm');
      LoggerUtils.info('  enrollment_id  : $enrollmentId', tag: 'EmiConfirm');
      LoggerUtils.info('  emi_plan_id    : $emiPlanId', tag: 'EmiConfirm');
      LoggerUtils.info('  emi_amounts    : $emiAmounts', tag: 'EmiConfirm');
      LoggerUtils.info('  confirmation   : true', tag: 'EmiConfirm');
      LoggerUtils.info('  first_emi_date : ${firstEmiDate ?? "(not sent)"}', tag: 'EmiConfirm');
      LoggerUtils.info('===========================', tag: 'EmiConfirm');

      final response = await _apiService.post(
        endpoint: AppEndpoints.emiConfirm,
        token: accessKey,
        body: body,
      );

      LoggerUtils.info('=== EMI Confirm RESPONSE ===', tag: 'EmiConfirm');
      LoggerUtils.info('  status  : ${response.statusCode}', tag: 'EmiConfirm');
      LoggerUtils.info('  success : ${response.success}', tag: 'EmiConfirm');
      LoggerUtils.info('  message : ${response.message}', tag: 'EmiConfirm');
      LoggerUtils.info('  data    : ${response.data}', tag: 'EmiConfirm');
      LoggerUtils.info('============================', tag: 'EmiConfirm');

      return response;
    } catch (e) {
      LoggerUtils.error('EMI Confirm exception: $e', tag: 'EmiConfirm', error: e);
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<EmiPreviewResponse>> fetchEmiPreview(String emiPlanId) async {
    // Validate emiPlanId
    if (emiPlanId.isEmpty) {
      return ApiResponse.error('emi_plan_id cannot be empty', null);
    }

    // Check if enrollment ID is set
    if (_enrollmentId == null || _enrollmentId!.isEmpty) {
      return ApiResponse.error('Enrollment ID is required but not set', null);
    }

    final Map<String, dynamic> payload = {
      'emi_plan_id': emiPlanId,
      'enrollment_id': _enrollmentId,
    };

    try {
      final accessKey = await AppUtils.getAccessKey();
      final response = await _apiService.post(
        endpoint: AppEndpoints.emiPreview,
        token: accessKey,
        body: payload,
      );

      if (response.success) {
        return ApiResponse.success(
          EmiPreviewResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      } else {
        return response.cast<EmiPreviewResponse>();
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
