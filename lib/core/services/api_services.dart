import 'dart:convert';
import 'dart:developer';
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

  // GET
  Future<ApiResponse<dynamic>> get({
    required String endpoint,
    String? token,
  }) async {
    log("$baseUrl$endpoint");
    try {
      final response = await http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers(token),
      );

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
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers(token),
        body: jsonEncode(body),
      );

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
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl$endpoint"),
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
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers(token),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(e.toString(), null);
    }
  }

  ApiResponse<dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    try {
      final jsonData = jsonDecode(response.body);

      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success(jsonData, statusCode);
      } else {
        return ApiResponse.error(
          jsonData["message"] ?? "Unknown error",
          statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error("Invalid response format", statusCode);
    }
  }
}
