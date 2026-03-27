import 'dart:developer';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/razorpay/model/emi_res_model.dart';
import 'package:luminar_std/repository/razorpay/model/razorpay_model.dart';

class RazorpayScreenService {
  Future<ApiResponse> getPaymentDetails({required String id}) async {
    final response = await ApiService().post(
      endpoint: '${AppEndpoints.razorpayFull}$id/',
      token: await AppUtils.getAccessKey(),
      body: {},
    );
    log(response.data.toString());
    log(response.statusCode.toString());
    if (response.success) {
      log(response.data.toString());
      PaymentResModel resModel = PaymentResModel.fromJson(response.data);
      return ApiResponse(success: true, data: resModel, message: response.message, statusCode: response.statusCode);
    } else {
      return ApiResponse(success: false, data: '', message: response.message, statusCode: response.statusCode);
    }
  }

  Future<ApiResponse> getEmiPaymentDetails({required String id}) async {
    log("${AppEndpoints.razorpayEmi}$id/");
    final response = await ApiService().post(
      endpoint: '${AppEndpoints.razorpayEmi}$id/',
      token: await AppUtils.getAccessKey(),
      body: {},
    );
    log(response.data.toString());
    log(response.data.toString());
    log(response.statusCode.toString());
    if (response.success) {
      log(response.data.toString());
      EmiPaymentResModel resModel = EmiPaymentResModel.fromJson(response.data);
      return ApiResponse(success: true, data: resModel, message: response.message, statusCode: response.statusCode);
    } else {
      return ApiResponse(success: false, data: '', message: response.message, statusCode: response.statusCode);
    }
  }
}
