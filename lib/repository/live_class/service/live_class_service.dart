import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/live_class/model/live_class_model.dart';

class LiveClassService {
  Future<ApiResponse> getLiveClassDetails() async {
    final response = await ApiService().get(
      endpoint: AppEndpoints.liveClassEnrollments,
      token: await AppUtils.getAccessKey(),
    );

    if (response.success) {
      LiveClassResModel resModel = LiveClassResModel.fromJson(response.data);
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

  Future<ApiResponse> getLivelink({required String id}) async {
    final response = await ApiService().get(
      endpoint: '${AppEndpoints.liveClassUrl}$id/',
      token: await AppUtils.getAccessKey(),
    );

    if (response.success) {
      ClasslinkResModel resModel = ClasslinkResModel.fromJson(response.data);
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
