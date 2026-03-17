// Service class for API calls
import 'dart:convert';

import 'package:flutter/rendering.dart';

import 'package:http/http.dart' as http;
import 'package:luminar_std/repository/payment_screen/model.dart';

class PaymentScreenService {
  static Future<EnrollmentDetailResponse?> fetchEnrollmentDetails(
    String enrollmentUid,
    String accessKey,
  ) async {
    try {
      final url =
          'https://api.crm.dev.luminartechnohub.com/api/enrollment/$enrollmentUid/';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessKey',
          'Content-Type': 'application/json',
        },
      );

      // Print the raw response
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Pretty print the JSON
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        final String prettyPrint = encoder.convert(jsonData);
        debugPrint('Response data: $prettyPrint');

        return EnrollmentDetailResponse.fromJson(jsonData);
      } else {
        debugPrint(
          'Failed to fetch enrollment details: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching enrollment details: $e');
      return null;
    }
  }
}
