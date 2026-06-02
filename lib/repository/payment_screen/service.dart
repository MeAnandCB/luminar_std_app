import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/repository/payment_screen/model.dart';

class PaymentGateway {
  final String id;
  final String label;
  final String? key;

  PaymentGateway({required this.id, required this.label, this.key});

  factory PaymentGateway.fromJson(Map<String, dynamic> json) => PaymentGateway(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        key: json['key']?.toString(),
      );
}

class PaymentScreenService {
  final ApiService _apiService = ApiService();

  Future<({String url, double amount, bool discountApplied, double discountAmount})?> getIciciSession(String enrollmentId) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.post(
        endpoint: '${AppEndpoints.iciciFull}$enrollmentId/',
        body: {},
        token: token,
      );

      LoggerUtils.info(
        '[ICICI] status=${response.statusCode} success=${response.success}\n'
        '[ICICI] response=${response.data}',
        tag: 'ICICI',
      );

      if (response.success && response.data != null) {
        final root = response.data as Map<String, dynamic>;
        final payload = root['data'] is Map<String, dynamic>
            ? root['data'] as Map<String, dynamic>
            : root;

        final url = payload['payment_url']?.toString() ??
            payload['redirect_url']?.toString() ??
            payload['url']?.toString() ?? '';

        final discountInfo = payload['discount_info'] as Map<String, dynamic>? ?? {};
        final amount = (payload['amount'] as num?)?.toDouble() ??
            (discountInfo['discounted_pending_amount'] as num?)?.toDouble() ?? 0;
        final discountApplied = discountInfo['discount_applied'] == true;
        final discountAmount = (discountInfo['course_fees_discount'] as num?)?.toDouble() ?? 0;

        LoggerUtils.info('[ICICI] url=$url  amount=$amount  discount=$discountApplied', tag: 'ICICI');

        if (url.isEmpty) return null;
        return (url: url, amount: amount, discountApplied: discountApplied, discountAmount: discountAmount);
      } else {
        LoggerUtils.error('[ICICI] failed: ${response.message}', tag: 'ICICI');
      }
    } catch (e, st) {
      LoggerUtils.error('[ICICI] exception', tag: 'ICICI', error: e, stackTrace: st);
    }
    return null;
  }

  Future<({String url, double amount, bool discountApplied, double discountAmount})?> getIciciEmiSession(String emiId) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.post(
        endpoint: '${AppEndpoints.iciciEmi}$emiId/',
        body: {},
        token: token,
      );

      if (response.success && response.data != null) {
        LoggerUtils.info(
          '[ICICI-EMI] SUCCESS status=${response.statusCode}\n'
          '[ICICI-EMI] response=${response.data}',
          tag: 'ICICI-EMI',
        );

        final root = response.data as Map<String, dynamic>;
        final payload = root['data'] is Map<String, dynamic>
            ? root['data'] as Map<String, dynamic>
            : root;

        final url = payload['payment_url']?.toString() ??
            payload['redirect_url']?.toString() ??
            payload['url']?.toString() ?? '';

        final discountInfo = payload['discount_info'] as Map<String, dynamic>? ?? {};
        final amount = (payload['amount'] as num?)?.toDouble() ??
            (discountInfo['discounted_pending_amount'] as num?)?.toDouble() ?? 0;
        final discountApplied = discountInfo['discount_applied'] == true;
        final discountAmount = (discountInfo['course_fees_discount'] as num?)?.toDouble() ?? 0;

        LoggerUtils.info('[ICICI-EMI] url=$url  amount=$amount  discount=$discountApplied', tag: 'ICICI-EMI');

        if (url.isEmpty) return null;
        return (url: url, amount: amount, discountApplied: discountApplied, discountAmount: discountAmount);
      } else {
        LoggerUtils.error(
          '[ICICI-EMI] FAILED status=${response.statusCode} message=${response.message}\n'
          '[ICICI-EMI] response=${response.data}',
          tag: 'ICICI-EMI',
        );
      }
    } catch (e, st) {
      LoggerUtils.error('[ICICI-EMI] exception', tag: 'ICICI-EMI', error: e, stackTrace: st);
    }
    return null;
  }

  Future<String?> getIciciPaymentUrl(String enrollmentId) async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.post(
        endpoint: '${AppEndpoints.iciciFull}$enrollmentId/',
        body: {},
        token: token,
      );

      LoggerUtils.info(
        '[ICICI] status=${response.statusCode} success=${response.success}\n'
        '[ICICI] response=${response.data}',
        tag: 'ICICI',
      );

      if (response.success && response.data != null) {
        final root = response.data as Map<String, dynamic>;
        // API returns { status, message, data: { payment_url, ... } }
        // Unwrap nested 'data' if present, otherwise fall back to root
        final payload = root['data'] is Map<String, dynamic>
            ? root['data'] as Map<String, dynamic>
            : root;

        LoggerUtils.info('[ICICI] payload=$payload', tag: 'ICICI');

        final url = payload['payment_url']?.toString() ??
            payload['redirect_url']?.toString() ??
            payload['url']?.toString();

        LoggerUtils.info('[ICICI] payment_url=$url', tag: 'ICICI');
        return url;
      } else {
        LoggerUtils.error(
          '[ICICI] failed: ${response.message}',
          tag: 'ICICI',
        );
      }
    } catch (e, st) {
      LoggerUtils.error('[ICICI] exception', tag: 'ICICI', error: e, stackTrace: st);
    }
    return null;
  }

  Future<List<PaymentGateway>> fetchPaymentGateways() async {
    try {
      final token = await AppUtils.getAccessKey();
      final response = await _apiService.get(
        endpoint: AppEndpoints.paymentGateways,
        token: token,
      );
      if (response.success && response.data != null) {
        final list = (response.data['payment_methods'] as List? ?? []);
        return list
            .whereType<Map<String, dynamic>>()
            .map(PaymentGateway.fromJson)
            .toList();
      }
    } catch (_) {}
    // Fallback: return Razorpay as the only option so the app never stalls
    return [PaymentGateway(id: 'razorpay', label: 'Razorpay')];
  }

  Future<ApiResponse<EnrollmentDetailResponse>> fetchEnrollmentDetails(
    String enrollmentUid,
    String accessKey,
  ) async {
    try {
      final response = await _apiService.get(
        endpoint: '${AppEndpoints.enrollmentDetail}$enrollmentUid/',
        token: accessKey,
      );

      if (response.success) {
        return ApiResponse.success(
          EnrollmentDetailResponse.fromJson(response.data),
          response.statusCode ?? 200,
        );
      }
      
      return response.cast<EnrollmentDetailResponse>();
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}', null);
    }
  }
}
