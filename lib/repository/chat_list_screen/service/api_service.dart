import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:luminar_std/presentation/chat_screen/widgets/preseigner_url.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatApiService {
  final String baseUrl = 'https://api.crm.dev.luminartechnohub.com';
  final String token;

  ChatApiService({required this.token});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // ── Chats ──────────────────────────────────────────────────────────────────
  Future<List<Chat>> fetchChats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chats/?page=1&page_size=100'),
        headers: _headers,
      );
      debugPrint('[API] fetchChats status : ${response.statusCode}');
      debugPrint('[API] fetchChats body   : ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data is Map<String, dynamic>) {
          results = data['results'] ?? data['chats'] ?? [];
        } else {
          results = [];
        }
        return results
            .map((c) => Chat.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load chats: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching chats: $e');
    }
  }

  // ── Messages ───────────────────────────────────────────────────────────────
  Future<List<Message>> fetchMessages(
    String chatUid, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/chats/$chatUid/messages/?page=$page&page_size=$pageSize',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data is Map<String, dynamic>) {
          results = data['results'] ?? data['messages'] ?? data['data'] ?? [];
        } else {
          results = [];
        }
        return results
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load messages: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  // ── Send text message ──────────────────────────────────────────────────────
  Future<Message> sendMessage({
    required String chatUid,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) async {
    try {
      final body = <String, dynamic>{
        'content': content,
        'message_type': messageType,
      };
      if (replyTo != null) body['reply_to'] = replyTo;

      final response = await http.post(
        Uri.parse('$baseUrl/api/chats/$chatUid/messages/send/'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final messageJson = (data is Map && data.containsKey('message'))
            ? data['message']
            : data;
        if (messageJson is Map && !messageJson.containsKey('chat')) {
          messageJson['chat'] = chatUid;
        }
        return Message.fromJson(messageJson as Map<String, dynamic>);
      }
      throw Exception(
        'Failed to send message: ${response.statusCode} — ${response.body}',
      );
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // ── Edit message ───────────────────────────────────────────────────────────
  // PATCH /api/chats/{chat_uid}/messages/{message_uid}/edit/
  // Body : { "content": "new text" }
  Future<Message?> editMessage({
    required String chatUid,
    required String messageUid,
    required String content,
  }) async {
    final url = '$baseUrl/api/chats/$chatUid/messages/$messageUid/edit/';
    final payload = json.encode({'content': content});

    debugPrint('[API] PATCH $url');
    debugPrint('[API] body: $payload');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: payload,
      );

      debugPrint('[API] editMessage status: ${response.statusCode}');
      debugPrint('[API] editMessage body  : ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        // Try to parse a full message object from the response.
        // The backend may return:
        //   (a) { "message": { ...message fields... } }  ← full object
        //   (b) { "message": "Message updated successfully" } ← success string
        //   (c) the message object directly at the root
        //   (d) 204 No Content
        if (response.body.isEmpty) return null; // 204 — use optimistic value

        try {
          final data = json.decode(response.body);

          // Unwrap nested "message" key only when its value is a Map
          Map<String, dynamic>? messageJson;
          if (data is Map<String, dynamic>) {
            final inner = data['message'];
            if (inner is Map<String, dynamic>) {
              // Case (a): full message object nested under "message"
              messageJson = inner;
            } else if (inner is String) {
              // Case (b): "message" is a success string — no object to parse
              messageJson = null;
            } else {
              // Case (c): root IS the message object
              messageJson = data;
            }
          }

          if (messageJson == null) {
            // Backend didn't return a parseable message — caller uses optimistic
            return null;
          }

          if (!messageJson.containsKey('chat')) {
            messageJson['chat'] = chatUid;
          }
          return Message.fromJson(messageJson);
        } catch (_) {
          // JSON parse error — treat as success with no returned object
          return null;
        }
      }

      throw Exception(
        'Failed to edit message: ${response.statusCode} — ${response.body}',
      );
    } catch (e) {
      throw Exception('Error editing message: $e');
    }
  }

  // ── Send file / image / audio message (after S3 upload) ───────────────────
  Future<Message> sendFileMessage({
    required String chatUid,
    required UploadResult upload,
    String? replyTo,
    String? caption,
  }) async {
    try {
      final body = <String, dynamic>{
        'message_type': upload.messageType,
        'content': (caption != null && caption.isNotEmpty)
            ? caption
            : upload.originalFilename,
        'attachment_url': upload.finalUrl,
        'file': upload.finalUrl,
        'file_url': upload.finalUrl,
        'file_name': upload.originalFilename,
        'content_type': upload.contentType,
        'original_filename': upload.originalFilename,
        's3_key': upload.s3Key,
      };
      if (replyTo != null) body['reply_to'] = replyTo;

      debugPrint(
        '[API] sendFileMessage → $baseUrl/api/chats/$chatUid/messages/send/',
      );
      debugPrint('[API] body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/chats/$chatUid/messages/send/'),
        headers: _headers,
        body: json.encode(body),
      );

      debugPrint('[API] sendFileMessage status: ${response.statusCode}');
      debugPrint('[API] sendFileMessage body  : ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final messageJson = (data is Map && data.containsKey('message'))
            ? data['message']
            : data;
        if (messageJson is Map && !messageJson.containsKey('chat')) {
          messageJson['chat'] = chatUid;
        }
        return Message.fromJson(messageJson as Map<String, dynamic>);
      }
      throw Exception(
        'Failed to send file message: ${response.statusCode} — ${response.body}',
      );
    } catch (e) {
      throw Exception('Error sending file message: $e');
    }
  }

  // ── Delete message ─────────────────────────────────────────────────────────
  Future<void> deleteMessage(String chatUid, String messageUid) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chats/$chatUid/messages/$messageUid/delete/'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final data = json.decode(response.body);
        if (data['status'] != 'success') {
          throw Exception(data['message'] ?? 'Failed to delete message');
        }
      } else {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  // ── Reactions ──────────────────────────────────────────────────────────────
  Future<void> sendReaction(
    String chatUid,
    String messageUid,
    String emoji,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/chats/$chatUid/messages/$messageUid/reactions/',
        ),
        headers: _headers,
        body: json.encode({'emoji': emoji}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send reaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending reaction: $e');
    }
  }

  Future<void> removeReaction(
    String chatUid,
    String messageUid,
    String emoji,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$baseUrl/api/chats/$chatUid/messages/$messageUid/reactions/',
        ),
        headers: _headers,
        body: json.encode({'emoji': emoji}),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove reaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing reaction: $e');
    }
  }

  // ── Mark messages read ─────────────────────────────────────────────────────
  Future<void> markMessagesAsRead(
    String chatUid,
    List<String> messageUids,
  ) async {
    if (messageUids.isEmpty) return;
    final url = '$baseUrl/api/chats/$chatUid/messages/mark-read/';
    final payload = json.encode({'message_uids': messageUids});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: payload,
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to mark read: ${response.statusCode} — ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }
}
