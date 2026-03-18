import 'dart:developer';

import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/razorpay/model/razorpay_model.dart';

class RazorpayScreenService {
  Future<ApiResponse> getPaymentDetails({required String id}) async {
    final response = await ApiService().post(
      endpoint: '/api/student-payments/full/$id/',
      token: await AppUtils.getAccessKey(),
      body: {},
    );
    log(response.data.toString());
    log(response.statusCode.toString());
    if (response.success) {
      log(response.data.toString());
      PaymentResModel resModel = PaymentResModel.fromJson(response.data);
      return ApiResponse(
        success: true,
        data: resModel,
        message: response.message,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse(
        success: false,
        data: '',
        message: response.message,
        statusCode: response.statusCode,
      );
    }
  }
}
