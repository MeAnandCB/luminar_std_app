import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class CompleteProfileService {
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
        if (key == 'cgpa') {
          final d = double.tryParse(value.toString());
          if (d != null) {
            final formatted = d.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
            stringFields[key] = formatted;
            return;
          }
        }
        stringFields[key] = value.toString();
      }
    });

    // Prepare files
    final List<http.MultipartFile> files = [];

    if (idFrontPath != null) {
      final ext = idFrontPath.split('.').last.toLowerCase();
      files.add(await http.MultipartFile.fromPath(
        'id_proof', idFrontPath,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }
    if (idBackPath != null) {
      final ext = idBackPath.split('.').last.toLowerCase();
      files.add(await http.MultipartFile.fromPath(
        'id_proof_2', idBackPath,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }
    if (profilePicPath != null) {
      final ext = profilePicPath.split('.').last.toLowerCase();
      files.add(await http.MultipartFile.fromPath(
        'profile_pic', profilePicPath,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }
    if (resumePath != null) {
      files.add(await http.MultipartFile.fromPath(
        'resume', resumePath,
        contentType: MediaType('application', 'pdf'),
      ));
    }

    final endpoint = '${AppEndpoints.profileUpdate}$student_id/update/';
    final uri = Uri.parse('${GlobalLinks.baseUrl}$endpoint');

    // ── Request log — debug-only: fields/files include ID docs, phone, etc. ──
    if (kDebugMode) {
      developer.log(
        '\n'
        '╔══════════════════════════════════════════════════════════╗\n'
        '║           📤  PROFILE UPDATE — REQUEST                  ║\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '  URL    : $uri\n'
        '  METHOD : PATCH (multipart/form-data)\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '  TEXT FIELDS (${stringFields.length})${stringFields.isEmpty ? " — none" : ""}\n'
        '${stringFields.entries.map((e) => "    ${e.key.padRight(28)}: ${e.value}").join("\n")}\n'
        '╠══════════════════════════════════════════════════════════╣\n'
        '  FILES (${files.length})${files.isEmpty ? " — none" : ""}\n'
        '${files.isEmpty ? "    (none)" : files.map((f) => "    ${f.field.padRight(16)} → ${f.filename}").join("\n")}\n'
        '╚══════════════════════════════════════════════════════════╝',
        name: 'ProfileUpdate.Request',
      );
    }
    // ─────────────────────────────────────────────────────────────────────────

    try {
      final request = http.MultipartRequest('PATCH', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(stringFields)
        ..files.addAll(files);

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      final statusCode = response.statusCode;
      final rawBody = response.body;

      // ── Raw response log — debug-only, body may include PII ─────────────
      if (kDebugMode) {
        developer.log(
          '\n'
          '╔══════════════════════════════════════════════════════════╗\n'
          '║           📥  PROFILE UPDATE — RESPONSE                 ║\n'
          '╠══════════════════════════════════════════════════════════╣\n'
          '  STATUS  : $statusCode\n'
          '  SUCCESS : ${statusCode >= 200 && statusCode < 300}\n'
          '╠══════════════════════════════════════════════════════════╣\n'
          '  RAW BODY:\n'
          '$rawBody\n'
          '╚══════════════════════════════════════════════════════════╝',
          name: 'ProfileUpdate.Response',
          level: 1000,
        );
      }
      // ─────────────────────────────────────────────────────────────────────

      if (statusCode >= 200 && statusCode < 300) {
        final data = rawBody.isNotEmpty
            ? (jsonDecode(rawBody) as Map<String, dynamic>)
            : <String, dynamic>{};
        return ApiResponse.success(data, statusCode);
      } else {
        String errorMsg = 'Server error ($statusCode)';
        if (rawBody.isNotEmpty) {
          try {
            final json = jsonDecode(rawBody);
            if (json is Map) {
              // Field-specific validation errors, e.g.
              // {"message":"User field validation failed","validation_errors":{"phone":"Phone too long (max 15 digits)"}}
              final validationErrors = json['validation_errors'];
              if (validationErrors is Map && validationErrors.isNotEmpty) {
                final fieldErrors = validationErrors.entries
                    .map((e) => e.value is List
                        ? '${e.key}: ${(e.value as List).join(", ")}'
                        : '${e.key}: ${e.value}')
                    .join(' | ');
                final base = json['message']?.toString() ?? json['detail']?.toString();
                errorMsg = base != null ? '$base — $fieldErrors' : fieldErrors;
              } else if (json['detail'] != null) {
                errorMsg = json['detail'].toString();
              } else if (json['message'] != null) {
                errorMsg = json['message'].toString();
              } else {
                // Collect all field-level errors
                final fieldErrors = <String>[];
                json.forEach((k, v) {
                  if (v is List) {
                    fieldErrors.add('$k: ${v.join(", ")}');
                  } else {
                    fieldErrors.add('$k: $v');
                  }
                });
                if (fieldErrors.isNotEmpty) errorMsg = fieldErrors.join(' | ');
              }
            }
          } catch (_) {
            errorMsg = rawBody;
          }
        }
        return ApiResponse.error(errorMsg, statusCode);
      }
    } catch (e, st) {
      developer.log(
        '❌ PATCH exception: $e',
        name: 'ProfileUpdate.Response',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      return ApiResponse.error(e.toString(), null);
    }
  }
}
