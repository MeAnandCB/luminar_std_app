// ==================== API SERVICE ====================

import 'dart:convert';

import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/enrollment_screen/model/emiplans_model.dart';
import 'package:http/http.dart' as http;

class PaymentDetailsApiService {
  static const String baseUrl = '${GlobalLinks.baseUrl}/api';

  // Store enrollment ID to use in requests
  String? _enrollmentId;

  // Method to set enrollment ID
  void setEnrollmentId(String enrollmentId) {
    print('🔑 Setting enrollment ID: $enrollmentId');
    _enrollmentId = enrollmentId;
  }

  Future<List<EmiPlan>> fetchEmiPlans() async {
    print('📡 Fetching EMI plans...');
    try {
      final accessKey = await AppUtils.getAccessKey();
      print('🔑 Access key retrieved');

      final url = Uri.parse('$baseUrl/emi-plans/');
      print('🌐 URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessKey',
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ JSON parsed successfully');

        // Handle different response structures
        List<dynamic> plansJson = [];
        if (jsonData is List) {
          plansJson = jsonData;
        } else if (jsonData is Map) {
          if (jsonData.containsKey('results')) {
            plansJson = jsonData['results'] as List<dynamic>;
          } else if (jsonData.containsKey('emi_plans')) {
            plansJson = jsonData['emi_plans'] as List<dynamic>;
          } else if (jsonData.containsKey('data')) {
            plansJson = jsonData['data'] as List<dynamic>;
          }
        }

        print('📊 Number of plans found: ${plansJson.length}');
        return plansJson.map((json) => EmiPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load EMI plans: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchEmiPlans: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<EmiPreviewResponse> fetchEmiPreview(String emiPlanId) async {
    print('📡 Fetching EMI preview for plan: "$emiPlanId"');

    // Validate emiPlanId
    if (emiPlanId.isEmpty) {
      throw Exception('emi_plan_id cannot be empty');
    }

    // Check if enrollment ID is set
    if (_enrollmentId == null || _enrollmentId!.isEmpty) {
      throw Exception('Enrollment ID is required but not set');
    }

    final Map<String, dynamic> payload = {
      'emi_plan_id': "fc383b4e-5e24-4563-96c6-8f79a1ac5310",
      'enrollment_id': "137f329b-d002-4042-b30a-088de2058736",
    };

    try {
      final accessKey = await AppUtils.getAccessKey();
      print('🔑 Access key retrieved');

      final url = Uri.parse('$baseUrl/student-enrollment/emi-preview/');
      print('🌐 URL: $url');

      print('📤 Payload: $payload');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessKey',
        },
        body: json.encode(payload),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ JSON parsed successfully');
        return EmiPreviewResponse.fromJson(jsonData);
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to load EMI preview: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchEmiPreview: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }
}
