import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/nactet_registration/model/nactet_registration_model.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class NactetRegistrationService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<dynamic>> submitRegistration(
      NactetRegistrationModel registrationModel) async {
    final token = await SharedPrefService.getAccessToken();
    if (token == null || token.isEmpty) {
      return ApiResponse.error(
        'Authentication token not found. Please login again.',
        401,
      );
    }

    try {
      final fields = registrationModel.toFields();
      final files = await registrationModel.toFiles();

      developer.log(
        '─── NACTET Registration Payload ───\n'
        '  endpoint : ${AppEndpoints.certificatesCreate}\n'
        '  fields   :\n${fields.entries.map((e) => '    ${e.key}: ${e.value}').join('\n')}\n'
        '  files    : ${files.isEmpty ? '(none)' : files.map((f) => '${f.field} → ${f.filename}').join(', ')}',
        name: 'NactetRegistration.payload',
      );

      final response = await _apiService.multipart(
        endpoint: AppEndpoints.certificatesCreate,
        method: 'POST',
        fields: fields,
        files: files,
        token: token,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  Future<ApiResponse<dynamic>> fetchCheckDisplayStatus({String? enrollmentUid}) async {
    final token = await SharedPrefService.getAccessToken();
    debugPrint('token: $token');
    if (token == null || token.isEmpty) {
      return ApiResponse.error('Authentication token not found.', 401);
    }

    try {
      String endpoint = AppEndpoints.certificatesCheckDisplay;
      if (enrollmentUid != null) {
        endpoint += '?enrollment_uid=$enrollmentUid';
      }

      final response = await _apiService.get(
        endpoint: endpoint,
        token: token,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
