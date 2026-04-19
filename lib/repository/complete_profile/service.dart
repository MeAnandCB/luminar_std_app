import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class CompleteProfileService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<Map<String, dynamic>>> submitProfile({
    required Map<String, dynamic> fields,
    String? idFrontPath,
    String? idBackPath,
    String? profilePicPath,
    String? resumePath,
    required String? student_id,
  }) async {
    final token = await SharedPrefService.getAccessToken();
    if (token == null || token.isEmpty) {
      return ApiResponse.error(
        'Authentication token not found. Please login again.',
        null,
      );
    }

    // Convert dynamic fields to String
    final Map<String, String> stringFields = {};
    fields.forEach((key, value) {
      if (value != null) {
        stringFields[key] = value.toString();
      }
    });

    // Prepare files
    final List<http.MultipartFile> files = [];

    if (idFrontPath != null) {
      final ext = idFrontPath.split('.').last.toLowerCase();
      files.add(
        await http.MultipartFile.fromPath(
          'id_proof',
          idFrontPath,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
        ),
      );
    }
    if (idBackPath != null) {
      final ext = idBackPath.split('.').last.toLowerCase();
      files.add(
        await http.MultipartFile.fromPath(
          'id_proof_2',
          idBackPath,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
        ),
      );
    }
    if (profilePicPath != null) {
      final ext = profilePicPath.split('.').last.toLowerCase();
      files.add(
        await http.MultipartFile.fromPath(
          'profile_pic',
          profilePicPath,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
        ),
      );
    }
    if (resumePath != null) {
      files.add(
        await http.MultipartFile.fromPath(
          'resume',
          resumePath,
          contentType: MediaType('application', 'pdf'),
        ),
      );
    }

    try {
      final response = await _apiService.multipart(
        endpoint: '${AppEndpoints.profileUpdate}$student_id/update/',
        method: 'PATCH',
        fields: stringFields,
        files: files,
        token: token,
      );

      if (response.success) {
        debugPrint('[CompleteProfile] PATCH success [${response.statusCode}]');
        return ApiResponse.success(response.data, response.statusCode ?? 200);
      } else {
        debugPrint('[CompleteProfile] PATCH FAILED [${response.statusCode}]: ${response.message}');
        return response.cast<Map<String, dynamic>>();
      }
    } catch (e, st) {
      debugPrint('[CompleteProfile] PATCH exception: $e\n$st');
      return ApiResponse.error(e.toString(), null);
    }
  }
}
