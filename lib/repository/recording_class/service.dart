// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:luminar_std/repository/recording_class/model.dart';

class ApiService {
  static const String baseUrl = 'https://api.crm.dev.luminartechnohub.com/api';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Get galleries with pagination
  Future<EnrollmentResponse> getGalleries({
    required String batchUid,
    int page = 1,
  }) async {
    try {
      final url = '$baseUrl/galleries/?batch_uid=$batchUid&page=$page';
      print('Fetching galleries from: $url'); // For debugging

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // For debugging
      print('Response body: ${response.body}'); // For debugging

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return EnrollmentResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load galleries: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error fetching galleries: $e'); // For debugging
      throw Exception('Network error: $e');
    }
  }

  // Get folders in a gallery
  Future<dynamic> getFolders(String galleryUid) async {
    try {
      final url = '$baseUrl/galleries/$galleryUid/folders/';
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load folders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
