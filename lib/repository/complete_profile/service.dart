import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class CompleteProfileService {
  Future<Map<String, dynamic>> submitProfile({
    required Map<String, dynamic> fields,
    String? idFrontPath,
    String? idBackPath,
    String? profilePicPath,
    String? resumePath,
    required String? student_id,
  }) async {
    final token = await SharedPrefService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }

    // Removing trailing slash as it can sometimes cause issues with PATCH multipart in some Django configurations
    final uri = Uri.parse('${GlobalLinks.baseUrl}/api/student/profile/$student_id/update/');

    var request = http.MultipartRequest('PATCH', uri);

    // Add headers
    request.headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'});

    // Convert dynamic fields to String and add to request
    final Map<String, String> stringFields = {};
    fields.forEach((key, value) {
      if (value != null) {
        stringFields[key] = value.toString();
      }
    });
    request.fields.addAll(stringFields);

    // Add files if they exist
    if (idFrontPath != null) {
      final ext = idFrontPath.split('.').last.toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'id_proof',
        idFrontPath,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }
    if (idBackPath != null) {
      final ext = idBackPath.split('.').last.toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'id_proof_2',
        idBackPath,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }
    if (profilePicPath != null) {
      final ext = profilePicPath.split('.').last.toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'profile_pic',
        profilePicPath,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
    }
    if (resumePath != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'resume',
        resumePath,
        contentType: MediaType('application', 'pdf'),
      ));
    }

    // Logging the full data
    developer.log('--- Profile Update Request Data ---', name: 'ProfileUpdate');
    developer.log('URL: $uri', name: 'ProfileUpdate');
    developer.log('Method: PATCH', name: 'ProfileUpdate');
    developer.log('Fields: ${json.encode(stringFields)}', name: 'ProfileUpdate');
    developer.log('Files: ', name: 'ProfileUpdate');
    if (idFrontPath != null) developer.log('- id_proof (Front ID)', name: 'ProfileUpdate');
    if (idBackPath != null) developer.log('- id_proof_2 (Back ID)', name: 'ProfileUpdate');
    if (profilePicPath != null) developer.log('- profile_pic', name: 'ProfileUpdate');
    if (resumePath != null) developer.log('- resume', name: 'ProfileUpdate');
    developer.log('-----------------------------------', name: 'ProfileUpdate');

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      developer.log('=== Profile Update Response ===', name: 'ProfileUpdate');
      developer.log('Status Code: ${response.statusCode}', name: 'ProfileUpdate');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        developer.log('=== Profile Update Success ===', name: 'ProfileUpdate');
        return responseBody;
      } else {
        developer.log('=== Profile Update Failure ===', name: 'ProfileUpdate');
        developer.log('Response Body: ${response.body}', name: 'ProfileUpdate');

        // Try to parse error message if it's JSON
        try {
          final responseBody = json.decode(response.body);
          throw Exception(responseBody['message'] ?? 'Failed to update profile (Status: ${response.statusCode})');
        } catch (_) {
          throw Exception('Server error (${response.statusCode}). Please check your connection or try again later.');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      developer.log('=== Profile Update Exception ===', name: 'ProfileUpdate');
      developer.log('Error: $e', name: 'ProfileUpdate');
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
