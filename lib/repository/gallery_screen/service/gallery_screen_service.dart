// repository/gallery_screen/gallery_screen_service.dart
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/gallery_screen/models/gellery_res_model.dart';

class GalleryScreenService {
  Future<ApiResponse> getGalleries({required String batchId, int page = 1, int pageSize = 10}) async {
    try {
      final response = await ApiService().get(
        endpoint: '/api/galleries/?batch_uid=$batchId&page=$page&page_size=$pageSize',
      );

      if (response.success) {
        GalleryResModel resModel = GalleryResModel.fromJson(response.data);
        return ApiResponse(success: true, data: resModel, message: response.message, statusCode: response.statusCode);
      } else {
        return ApiResponse(success: false, data: null, message: response.message, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(success: false, data: null, message: 'Error: $e', statusCode: 500);
    }
  }
}
