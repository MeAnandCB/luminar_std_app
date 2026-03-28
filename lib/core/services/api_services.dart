import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/main.dart';
import 'package:luminar_std/repository/shared_pref.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';

class ApiService {
  final String baseUrl = GlobalLinks.baseUrl;

  // Track the last time we redirected to Login due to session expiry
  // to avoid infinite loops from multiple concurrent requests.
  static DateTime? _lastRedirectTime;

  Map<String, String> _headers(String? bearerToken) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (bearerToken != null) "Authorization": "Bearer $bearerToken",
    };
  }

  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      return Uri.parse("$baseUrl$endpoint?$queryString");
    }
    return Uri.parse("$baseUrl$endpoint");
  }

  // GET
  Future<ApiResponse<dynamic>> get({required String endpoint, String? token, Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    LoggerUtils.debug("GET: $uri", tag: 'API');
    try {
      final response = await http.get(uri, headers: _headers(token));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  // POST
  Future<ApiResponse<dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    LoggerUtils.debug("POST: $uri", tag: 'API');
    try {
      final response = await http.post(uri, headers: _headers(token), body: jsonEncode(body));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  // PUT
  Future<ApiResponse<dynamic>> put({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    LoggerUtils.debug("PUT: $uri", tag: 'API');
    try {
      final response = await http.put(uri, headers: _headers(token), body: jsonEncode(body));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  // PATCH
  Future<ApiResponse<dynamic>> patch({
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    LoggerUtils.debug("PATCH: $uri", tag: 'API');
    try {
      final response = await http.patch(uri, headers: _headers(token), body: jsonEncode(body));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  // DELETE
  Future<ApiResponse<dynamic>> delete({
    required String endpoint,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    LoggerUtils.debug("DELETE: $uri", tag: 'API');
    try {
      final response = await http.delete(uri, headers: _headers(token));
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  // MULTIPART (for file uploads)
  Future<ApiResponse<dynamic>> multipart({
    required String endpoint,
    required String method,
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    String? token,
  }) async {
    final uri = _buildUri(endpoint, null);
    LoggerUtils.debug("$method (Multipart): $uri", tag: 'API');
    try {
      var request = http.MultipartRequest(method, uri);
      request.headers.addAll(_headers(token));
      request.fields.addAll(fields);
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  ApiResponse<dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Log response in debug mode
    LoggerUtils.debug("Response [Status $statusCode]: ${response.body}", tag: 'API');

    try {
      // Handle empty body (like 204 No Content or 201 Created with no body)
      if (response.body.isEmpty) {
        if (statusCode >= 200 && statusCode < 300) {
          return ApiResponse.success({}, statusCode);
        } else {
          return ApiResponse.error("Empty error response", statusCode);
        }
      }

      final jsonData = jsonDecode(response.body);

      // Check for session conflict/expiry in body (status: "expired")
      // The server might return 401 or 403 with this body
      if (jsonData is Map && jsonData["status"] == "expired") {
        final now = DateTime.now();
        if (_lastRedirectTime == null || now.difference(_lastRedirectTime!) > const Duration(seconds: 3)) {
          _lastRedirectTime = now;
          LoggerUtils.warning("🚨 Session expired/conflict detected. Redirecting to login.", tag: 'API');
          
          // Clear all local data
          SharedPrefService.clearAllData();

          // Redirect to LoginScreen globally
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } else {
          LoggerUtils.debug("⏳ Redundant session expiry detected - suppressing duplicate redirect", tag: 'API');
        }
        
        return ApiResponse.error(jsonData["error"] ?? "Session expired. Please login again.", statusCode);
      }

      // Check for status 223 specifically as requested before (as a fallback)
      if (statusCode == 223) {
        final now = DateTime.now();
        if (_lastRedirectTime == null || now.difference(_lastRedirectTime!) > const Duration(seconds: 3)) {
          _lastRedirectTime = now;
          SharedPrefService.clearAllData();
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
        return ApiResponse.error("Account logged in on another device.", 223);
      }

      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success(jsonData, statusCode);
      } else {
        return ApiResponse.error(jsonData["message"] ?? jsonData["error"] ?? "Unknown error", statusCode);
      }
    } catch (e) {
      // If parsing fails but status code is success, return empty success Map
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success({}, statusCode);
      }
      return ApiResponse.error("Invalid response format", statusCode);
    }
  }
}
