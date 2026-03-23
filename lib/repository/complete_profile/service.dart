import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class CompleteProfileService {
  Future<Map<String, dynamic>> submitProfile({
    required Map<String, String> fields,
    Uint8List? idFront,
    Uint8List? idBack,
    Uint8List? profilePic,
  }) async {
    final token = await SharedPrefService.getAccessToken();
    final uri = Uri.parse('${GlobalLinks.baseUrl}/api/student_portal/profile/update/');

    var request = http.MultipartRequest('POST', uri);
    
    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Add text fields
    request.fields.addAll(fields);

    // Add files
    if (idFront != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'id_proof',
          idFront,
          filename: 'id_front.jpg',
        ),
      );
    }
    if (idBack != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'id_proof_2',
          idBack,
          filename: 'id_back.jpg',
        ),
      );
    }
    if (profilePic != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_picture',
          profilePic,
          filename: 'profile_pic.jpg',
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final responseBody = json.decode(response.body);
    if (response.statusCode == 200 || responseBody['status'] == 'success') {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to update profile');
    }
  }
}
