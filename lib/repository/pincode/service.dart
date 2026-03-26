import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/pincode/model.dart';

class PincodeService {
  Future<ApiResponse<PincodeModel>> getPincodeData(String pincode) async {
    final response = await ApiService().get(endpoint: '/api/postal-pincode/$pincode/');

    if (response.success && response.data != null) {
      return ApiResponse.success(PincodeModel.fromJson(response.data), response.statusCode ?? 200);
    } else {
      return ApiResponse.error(response.message ?? 'Failed to fetch pincode data', response.statusCode);
    }
  }
}
