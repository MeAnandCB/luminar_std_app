import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';
import 'package:path_provider/path_provider.dart';

class CertificateService {
  CertificateService({
    ApiService? apiService,
    Future<String?> Function()? tokenReader,
    Future<Directory> Function()? saveDirectory,
  }) : _apiService = apiService ?? ApiService(),
       _tokenReader = tokenReader ?? AppUtils.getAccessKey,
       _saveDirectory = saveDirectory ?? getTemporaryDirectory;

  final ApiService _apiService;
  final Future<String?> Function() _tokenReader;
  final Future<Directory> Function() _saveDirectory;

  /// Human-readable state of the token used by the last call (never the token
  /// itself) — logged so "was a proper token sent?" can be answered from the
  /// console.
  String lastTokenNote = 'not checked yet';

  /// Reads the stored access token. A missing token must be caught here: this
  /// endpoint answers a missing/invalid token with a misleading
  /// `403 "User account is inactive"` rather than a 401.
  Future<String?> _readToken() async {
    final token = await _tokenReader();
    if (token == null || token.isEmpty) {
      lastTokenNote = 'NO TOKEN stored — login again';
    } else {
      lastTokenNote = 'sent (${_describeToken(token)})';
    }
    LoggerUtils.debug('Access token: $lastTokenNote', tag: 'Certificate');
    return (token == null || token.isEmpty) ? null : token;
  }

  static String _describeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'opaque token, len ${token.length}';
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
              as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! num) return 'JWT without expiry';
      final left = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
          .difference(DateTime.now());
      return left.isNegative
          ? 'EXPIRED ${left.abs().inMinutes} min ago'
          : 'valid, expires in ${left.inMinutes} min';
    } catch (_) {
      return 'unreadable token';
    }
  }

  /// Completed batches + the certificate request (if any) for each.
  Future<ApiResponse<CertificateListResponse>> getRequests() async {
    try {
      final token = await _readToken();
      if (token == null) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }
      final response = await _apiService.get(
        endpoint: AppEndpoints.certificateRequests,
        token: token,
      );

      if (response.success && response.data is Map<String, dynamic>) {
        return ApiResponse.success(
          CertificateListResponse.fromJson(
            response.data as Map<String, dynamic>,
          ),
          response.statusCode ?? 200,
        );
      }
      return response.cast<CertificateListResponse>();
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  /// The POST body for one certificate request. `enrollment_number` is the
  /// identifier the API uses to find the student's enrollment — from it the
  /// server resolves the course and batch, and it rejects numbers that are
  /// unknown or belong to another student (404 "Enrollment not found").
  /// The certificate type is deliberately NOT sent: the server sets it from
  /// the batch.
  @visibleForTesting
  static Map<String, dynamic> requestBody({
    required String enrollmentNumber,
    String? studentNote,
  }) {
    final note = studentNote?.trim() ?? '';
    return {
      'enrollment_number': enrollmentNumber.trim(),
      if (note.isNotEmpty) 'student_note': note,
    };
  }

  Future<ApiResponse<CertificateRequestInfo>> requestCertificate({
    required String enrollmentNumber,
    String? studentNote,
  }) async {
    try {
      if (enrollmentNumber.trim().isEmpty) {
        return ApiResponse.error('Enrollment not found', null);
      }
      final token = await _readToken();
      if (token == null) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }
      final body = requestBody(
        enrollmentNumber: enrollmentNumber,
        studentNote: studentNote,
      );
      LoggerUtils.debug(
        'POST ${AppEndpoints.certificateRequests} body: $body',
        tag: 'Certificate',
      );
      final response = await _apiService.post(
        endpoint: AppEndpoints.certificateRequests,
        token: token,
        body: body,
      );

      if (response.success && response.data is Map<String, dynamic>) {
        final req = (response.data as Map<String, dynamic>)['request'];
        if (req is Map<String, dynamic>) {
          return ApiResponse.success(
            CertificateRequestInfo.fromJson(req),
            response.statusCode ?? 201,
          );
        }
      }

      return ApiResponse.error(
        response.message ?? 'Failed to request certificate',
        response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  /// `Certificate-<enrollment_number>.pdf`, safe to use as a file name.
  @visibleForTesting
  static String fileNameFor(String enrollmentNumber) {
    final safe = enrollmentNumber.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    return 'Certificate-${safe.isEmpty ? 'download' : safe}.pdf';
  }

  /// A real PDF always starts with `%PDF`. Anything else (an HTML error page
  /// behind a proxy, an empty body) must not be saved and opened as one.
  static bool _looksLikePdf(Uint8List bytes) =>
      bytes.length > 4 &&
      bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46; // F

  /// Downloads the issued certificate PDF and returns the saved file's path.
  /// The server renders it fresh on every call, so nothing is cached; the same
  /// file name is simply overwritten. Errors carry the server's own message
  /// (e.g. "Certificate not found", "Certificate template image is missing").
  Future<ApiResponse<String>> downloadCertificate({
    required String requestUid,
    required String enrollmentNumber,
  }) async {
    try {
      if (requestUid.trim().isEmpty) {
        return ApiResponse.error('Certificate not found', null);
      }
      final token = await _readToken();
      if (token == null) {
        return ApiResponse.error('Session expired. Please login again.', 401);
      }
      final response = await _apiService.getBytes(
        endpoint: AppEndpoints.certificateDownload(requestUid.trim()),
        token: token,
      );
      if (!response.success || response.data == null) {
        return ApiResponse.error(
          response.message ?? 'Could not download the certificate',
          response.statusCode,
        );
      }
      final bytes = response.data!;
      if (!_looksLikePdf(bytes)) {
        return ApiResponse.error(
          'The certificate could not be downloaded. Please try again.',
          response.statusCode,
        );
      }

      final dir = await _saveDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File('${dir.path}/${fileNameFor(enrollmentNumber)}');
      await file.writeAsBytes(bytes, flush: true);
      return ApiResponse.success(file.path, response.statusCode ?? 200);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }
}
