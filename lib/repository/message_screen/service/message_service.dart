import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/message_screen/model/message_screen_models.dart';

class MessageApiService {
  static const String baseUrl = 'https://api.crm.dev.luminartechnohub.com/api';

  String? _accessToken;

  Future<String> _getToken() async {
    _accessToken = await AppUtils.getAccessKey();
    return _accessToken!;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<ChatModel>> getChats({int page = 1, int pageSize = 100}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/?page=$page&page_size=$pageSize'),
        headers: headers,
      );

      print('Chats API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((json) => ChatModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading chats: $e');
    }
  }

  Future<Map<String, dynamic>> getMessages(
    String chatUid, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/chats/$chatUid/messages/?page=$page&page_size=$pageSize',
        ),
        headers: headers,
      );

      print('Messages API: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  /// POST /api/chats/{chatUid}/messages/send/
  /// Body: { "content": "...", "message_type": "text" }
  /// Returns the created MessageModel from the server
  Future<MessageModel> sendMessage({
    required String chatUid,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = <String, dynamic>{
        'content': content,
        'message_type': messageType,
      };
      if (replyTo != null) body['reply_to'] = replyTo;

      print(
        '📤 Sending message via REST: $baseUrl/chats/$chatUid/messages/send/',
      );
      print('📝 Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatUid/messages/send/'),
        headers: headers,
        body: json.encode(body),
      );

      print('Send message API: ${response.statusCode}');
      print('Send message response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Some APIs wrap in { "message": {...} }, others return flat
        final messageJson = data is Map && data.containsKey('message')
            ? data['message']
            : data;
        return MessageModel.fromJson(messageJson);
      } else {
        throw Exception(
          'Failed to send message: ${response.statusCode} — ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }

  Future<void> markAsRead(String chatUid) async {
    // Try both common endpoint patterns — 404 means wrong path, we try the other.
    // Non-critical: failure here only means unread badge may not update server-side.
    final endpoints = [
      '$baseUrl/chats/$chatUid/mark-read/',
      '$baseUrl/chats/$chatUid/mark_as_read/',
      '$baseUrl/chats/$chatUid/read/',
    ];
    try {
      final headers = await _getHeaders();
      for (final url in endpoints) {
        final response = await http.post(Uri.parse(url), headers: headers);
        print('Mark as read [$url]: ${response.statusCode}');
        if (response.statusCode == 200 || response.statusCode == 201) return;
        if (response.statusCode != 404) break; // unexpected error, stop trying
      }
    } catch (e) {
      print('Error marking as read (non-critical): $e');
    }
  }
}
