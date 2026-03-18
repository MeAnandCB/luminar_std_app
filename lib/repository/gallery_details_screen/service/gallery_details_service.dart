// services/folder_browser_service.dart
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/gallery_details_screen/models/gallery_detail_model.dart';

class FolderBrowserService {
  final ApiService _apiService = ApiService();

  // Get subfolders of a folder
  Future<ApiResponse> getSubfolders({
    required String batchId,
    required String galleryUid,
    String? parentFolderUid,
  }) async {
    try {
      String url = '/api/folders/?batch_uid=$batchId&gallery_uid=$galleryUid&is_active=true&without_subfolder=false';

      if (parentFolderUid != null) {
        url += '&parent_folder_uid=$parentFolderUid';
      }

      final response = await _apiService.get(endpoint: url);

      if (response.success) {
        FolderResponseModel resModel = FolderResponseModel.fromJson(response.data);
        return ApiResponse(success: true, data: resModel, message: response.message, statusCode: response.statusCode);
      } else {
        return ApiResponse(success: false, data: null, message: response.message, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(success: false, data: null, message: 'Error fetching subfolders: $e', statusCode: 500);
    }
  }

  // Get videos in a folder
  Future<ApiResponse> getFolderVideos({
    required String batchId,
    required String galleryUid,
    required String folderUid,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _apiService.get(
        endpoint:
            '/api/videos/?batch_uid=$batchId&gallery_uid=$galleryUid&is_active=true&without_folder=false&page=$page&page_size=$pageSize&folder_uid=$folderUid',
      );

      if (response.success) {
        VideoResponseModel resModel = VideoResponseModel.fromJson(response.data);
        return ApiResponse(success: true, data: resModel, message: response.message, statusCode: response.statusCode);
      } else {
        return ApiResponse(success: false, data: null, message: response.message, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse(success: false, data: null, message: 'Error fetching folder videos: $e', statusCode: 500);
    }
  }

  // Get both subfolders and videos for a folder
  Future<ApiResponse> getFolderContents({
    required String batchId,
    required String galleryUid,
    String? folderUid,
    String? folderName,
    int videoPage = 1,
    int videoPageSize = 10,
  }) async {
    try {
      final List<Future> futures = [
        getSubfolders(batchId: batchId, galleryUid: galleryUid, parentFolderUid: folderUid),
      ];

      // Only fetch videos if we have a folderUid (videos without folder are shown in root)
      if (folderUid != null) {
        futures.add(
          getFolderVideos(
            batchId: batchId,
            galleryUid: galleryUid,
            folderUid: folderUid,
            page: videoPage,
            pageSize: videoPageSize,
          ),
        );
      }

      final results = await Future.wait(futures);

      final foldersResponse = results[0];
      ApiResponse? videosResponse = results.length > 1 ? results[1] : null;

      if (foldersResponse.success && (videosResponse?.success ?? true)) {
        return ApiResponse(
          success: true,
          data: {
            'folders': foldersResponse.data,
            'videos': videosResponse?.data,
            'currentFolderUid': folderUid,
            'currentFolderName': folderName,
          },
          message: 'Success',
          statusCode: 200,
        );
      } else {
        return ApiResponse(success: false, data: null, message: 'Failed to load folder contents', statusCode: 500);
      }
    } catch (e) {
      return ApiResponse(success: false, data: null, message: 'Error: $e', statusCode: 500);
    }
  }
}
