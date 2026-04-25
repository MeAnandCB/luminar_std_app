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
        '\n'
        '╔══════════════════════════════════════════════════════════╗\n'
        '║           📤  NACTET REGISTRATION PAYLOAD               ║\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  endpoint : ${AppEndpoints.certificatesCreate}\n'
        '║  method   : POST (multipart)\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  TEXT FIELDS (${fields.length})\n'
        '${fields.entries.map((e) => '║    ${e.key.padRight(50)}: ${e.value}').join('\n')}\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  FILES (${files.length})${files.isEmpty ? ' — none' : ''}\n'
        '${files.isEmpty ? '║    (none)' : files.map((f) => '║    ${f.field.padRight(42)} → ${f.filename}').join('\n')}\n'
        '╚══════════════════════════════════════════════════════════╝',
        name: '📤 NACTET.Payload',
      );

      final response = await _apiService.multipart(
        endpoint: AppEndpoints.certificatesCreate,
        method: 'POST',
        fields: fields,
        files: files,
        token: token,
      );

      developer.log(
        '\n'
        '╔══════════════════════════════════════════════════════════╗\n'
        '║           📥  NACTET REGISTRATION RESPONSE              ║\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  status_code : ${response.statusCode}\n'
        '║  success     : ${response.success}\n'
        '║  message     : ${response.message ?? '—'}\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '║  data :\n'
        '${(() {
          final d = response.data;
          if (d == null) return '║    (null)';
          if (d is Map) {
            return d.entries.map((e) => '║    ${e.key.toString().padRight(28)}: ${e.value}').join('\n');
          }
          return '║    $d';
        })()}\n'
        '╚══════════════════════════════════════════════════════════╝',
        name: '📥 NACTET.Response',
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
