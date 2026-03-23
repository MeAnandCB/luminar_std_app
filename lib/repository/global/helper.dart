import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class ApiHelper {
  static final ApiHelper _instance = ApiHelper._internal();
  factory ApiHelper() => _instance;
  ApiHelper._internal();

  // Get headers with optional auth token
  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add auth token if required
    if (requiresAuth) {
      final token = await SharedPrefService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // Add custom headers
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  // Generic request method
  Future<Map<String, dynamic>> request({
    required BuildContext context,
    required String endpoint,
    required HttpMethod method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? customHeaders,
    bool showErrorSnackbar = true,
  }) async {
    try {
      // Build URL with query parameters
      Uri uri = Uri.parse('${GlobalLinks.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Get headers
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        customHeaders: customHeaders,
      );

      // Prepare body
      String? jsonBody = body != null ? json.encode(body) : null;

      // Make request
      late http.Response response;

      switch (method) {
        case HttpMethod.get:
          response = await http
              .get(uri, headers: headers)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Request timeout'),
              );
          break;
        case HttpMethod.post:
          response = await http
              .post(uri, headers: headers, body: jsonBody)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Request timeout'),
              );
          break;
        case HttpMethod.put:
          response = await http
              .put(uri, headers: headers, body: jsonBody)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Request timeout'),
              );
          break;
        case HttpMethod.patch:
          response = await http
              .patch(uri, headers: headers, body: jsonBody)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Request timeout'),
              );
          break;
        case HttpMethod.delete:
          response = await http
              .delete(uri, headers: headers)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Request timeout'),
              );
          break;
      }

      // Decode response with UTF-8
      final String decodedBody = utf8.decode(response.bodyBytes);

      // Parse response
      final Map<String, dynamic> responseData = json.decode(decodedBody);

      // Handle response
      return _handleResponse(
        context,
        response.statusCode,
        responseData,
        showErrorSnackbar,
      );
    } catch (e) {
      if (showErrorSnackbar) {
        // _showErrorSnackbar(context, _getUserFriendlyErrorMessage(e));
      }

      if (e is ApiException) {
        rethrow;
      } else if (e is TimeoutException) {
        throw ApiException('Request timeout. Please try again.');
      } else if (e is http.ClientException) {
        throw ApiException('Network error. Check your internet connection.');
      } else {
        throw ApiException('An unexpected error occurred.');
      }
    }
  }

  // Convenience methods
  Future<Map<String, dynamic>> get(
    BuildContext context,
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? headers,
    bool showErrorSnackbar = true,
  }) {
    return request(
      context: context,
      endpoint: endpoint,
      method: HttpMethod.get,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      customHeaders: headers,
      showErrorSnackbar: showErrorSnackbar,
    );
  }

  Future<Map<String, dynamic>> post(
    BuildContext context,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? headers,
    bool showErrorSnackbar = true,
  }) {
    return request(
      context: context,
      endpoint: endpoint,
      method: HttpMethod.post,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      customHeaders: headers,
      showErrorSnackbar: showErrorSnackbar,
    );
  }

  Future<Map<String, dynamic>> put(
    BuildContext context,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? headers,
    bool showErrorSnackbar = true,
  }) {
    return request(
      context: context,
      endpoint: endpoint,
      method: HttpMethod.put,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      customHeaders: headers,
      showErrorSnackbar: showErrorSnackbar,
    );
  }

  Future<Map<String, dynamic>> patch(
    BuildContext context,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? headers,
    bool showErrorSnackbar = true,
  }) {
    return request(
      context: context,
      endpoint: endpoint,
      method: HttpMethod.patch,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      customHeaders: headers,
      showErrorSnackbar: showErrorSnackbar,
    );
  }

  Future<Map<String, dynamic>> delete(
    BuildContext context,
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
    Map<String, String>? headers,
    bool showErrorSnackbar = true,
  }) {
    return request(
      context: context,
      endpoint: endpoint,
      method: HttpMethod.delete,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      customHeaders: headers,
      showErrorSnackbar: showErrorSnackbar,
    );
  }

  // Response handler
  Map<String, dynamic> _handleResponse(
    BuildContext context,
    int statusCode,
    Map<String, dynamic> responseData,
    bool showErrorSnackbar,
  ) {
    // Success codes
    if (statusCode >= 200 && statusCode < 300) {
      return responseData;
    }

    // Handle specific status codes
    switch (statusCode) {
      case 400:
        throw ApiException(
          responseData['message'] ?? 'Bad request',
          responseData,
        );
      case 401:
        // Handle unauthorized - maybe logout
        _handleUnauthorized(context);
        throw ApiException(
          responseData['message'] ?? 'Session expired. Please login again.',
          responseData,
        );
      case 403:
        throw ApiException(
          responseData['message'] ?? 'Access forbidden',
          responseData,
        );
      case 404:
        throw ApiException(
          responseData['message'] ?? 'Resource not found',
          responseData,
        );
      case 422:
        throw ApiException(
          responseData['message'] ?? 'Validation error',
          responseData,
        );
      case 500:
        throw ApiException(
          responseData['message'] ?? 'Internal server error',
          responseData,
        );
      default:
        throw ApiException(
          responseData['message'] ?? 'Server error: $statusCode',
          responseData,
        );
    }
  }

  // Handle unauthorized access
  void _handleUnauthorized(BuildContext context) async {
    await SharedPrefService.clearAllData();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Error message formatting
  String _getUserFriendlyErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.message.contains('Invalid credentials')) {
        return 'Invalid email or password';
      } else if (error.message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      } else if (error.message.contains('Network')) {
        return 'Network error. Check your connection.';
      }
      return error.message;
    }
    return 'An error occurred. Please try again.';
  }

  // // Show error snackbar
  // void _showErrorSnackbar(BuildContext context, String message) {
  //   if (context.mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Row(
  //           children: [
  //             const Icon(Icons.error_outline, color: Colors.white, size: 20),
  //             const SizedBox(width: 10),
  //             Expanded(child: Text(message)),
  //           ],
  //         ),
  //         backgroundColor: Colors.red.shade700,
  //         behavior: SnackBarBehavior.floating,
  //         duration: const Duration(seconds: 4),
  //         action: SnackBarAction(
  //           label: 'Dismiss',
  //           textColor: Colors.white,
  //           onPressed: () {},
  //         ),
  //       ),
  //     );
  //   }
  // }
}

enum HttpMethod { get, post, put, patch, delete }

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? responseData;

  ApiException(this.message, [this.responseData]);

  get statusCode => null;

  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
