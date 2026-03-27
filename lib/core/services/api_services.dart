import 'dart:convert';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/response.dart';

class ApiService {
  final String baseUrl = GlobalLinks.baseUrl;

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
  Future<ApiResponse<dynamic>> get({
    required String endpoint,
    String? token,
    Map<String, String>? queryParams,
  }) async {
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
      final response = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode(body),
      );
      LoggerUtils.debug("Response: ${response.body}", tag: 'API');

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
      final response = await http.put(
        uri,
        headers: _headers(token),
        body: jsonEncode(body),
      );
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
      final response = await http.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(body),
      );
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

      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success(jsonData, statusCode);
      } else {
        return ApiResponse.error(jsonData["message"] ?? "Unknown error", statusCode);
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

