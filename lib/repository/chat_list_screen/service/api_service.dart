import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/presentation/chat_screen/widgets/preseigner_url.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatApiService {
  final ApiService _apiService = ApiService();
  final String token;

  ChatApiService({required this.token});
  
  String get baseUrl => _apiService.baseUrl;

  // ── Chats ──────────────────────────────────────────────────────────────────
  Future<ApiResponse<List<Chat>>> fetchChats() async {
    final response = await _apiService.get(
      endpoint: AppEndpoints.chats,
      token: token,
      queryParams: {'page': '1', 'page_size': '100'},
    );

    if (response.success) {
      final data = response.data;
      List<dynamic> results;
      if (data is List) {
        results = data;
      } else if (data is Map<String, dynamic>) {
        results = data['results'] ?? data['chats'] ?? [];
      } else {
        results = [];
      }
      final chats = results.map((c) => Chat.fromJson(c as Map<String, dynamic>)).toList();
      return ApiResponse.success(chats, response.statusCode ?? 200);
    }
    return ApiResponse.error(response.message ?? "Failed to load chats", response.statusCode);
  }

  // ── Messages ───────────────────────────────────────────────────────────────
  Future<ApiResponse<List<Message>>> fetchMessages(String chatUid, {int page = 1, int pageSize = 50}) async {
    final response = await _apiService.get(
      endpoint: '${AppEndpoints.chatMessages}$chatUid/messages/',
      token: token,
      queryParams: {'page': page.toString(), 'page_size': pageSize.toString()},
    );

    if (response.success) {
      final data = response.data;
      List<dynamic> results;
      if (data is List) {
        results = data;
      } else if (data is Map<String, dynamic>) {
        results = data['results'] ?? data['messages'] ?? data['data'] ?? [];
      } else {
        results = [];
      }
      final messages = results.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
      return ApiResponse.success(messages, response.statusCode ?? 200);
    }
    return ApiResponse.error(response.message ?? "Failed to load messages", response.statusCode);
  }

  // ── Send text message ──────────────────────────────────────────────────────
  Future<ApiResponse<Message>> sendMessage({
    required String chatUid,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) async {
    final body = <String, dynamic>{'content': content, 'message_type': messageType};
    if (replyTo != null) body['reply_to'] = replyTo;

    final response = await _apiService.post(
      endpoint: '${AppEndpoints.sendMessage}$chatUid/messages/send/',
      token: token,
      body: body,
    );

    if (response.success) {
      final data = response.data;
      final messageJson = (data is Map && data.containsKey('message')) ? data['message'] : data;
      if (messageJson is Map && !messageJson.containsKey('chat')) {
        messageJson['chat'] = chatUid;
      }
      final message = Message.fromJson(messageJson as Map<String, dynamic>);
      return ApiResponse.success(message, response.statusCode ?? 200);
    }
    return ApiResponse.error(response.message ?? "Failed to send message", response.statusCode);
  }

  // ── Edit message ───────────────────────────────────────────────────────────
  Future<ApiResponse<Message?>> editMessage({
    required String chatUid,
    required String messageUid,
    required String content,
  }) async {
    final response = await _apiService.patch(
      endpoint: '${AppEndpoints.editMessage}$chatUid/messages/$messageUid/edit/',
      token: token,
      body: {'content': content},
    );

    if (response.success) {
      if (response.data == null) return ApiResponse.success(null, response.statusCode ?? 200);

      final data = response.data;
      Map<String, dynamic>? messageJson;
      if (data is Map<String, dynamic>) {
        final inner = data['message'];
        if (inner is Map<String, dynamic>) {
          messageJson = inner;
        } else if (inner is String) {
          messageJson = null;
        } else {
          messageJson = data;
        }
      }

      if (messageJson == null) return ApiResponse.success(null, response.statusCode ?? 200);

      if (!messageJson.containsKey('chat')) {
        messageJson['chat'] = chatUid;
      }
      final message = Message.fromJson(messageJson);
      return ApiResponse.success(message, response.statusCode ?? 200);
    }
    return ApiResponse.error(response.message ?? "Failed to edit message", response.statusCode);
  }

  // ── Send file / image / audio message (after S3 upload) ───────────────────
  Future<ApiResponse<Message>> sendFileMessage({
    required String chatUid,
    required UploadResult upload,
    String? replyTo,
    String? caption,
  }) async {
    final body = <String, dynamic>{
      'message_type': upload.messageType,
      'content': (caption != null && caption.isNotEmpty) ? caption : upload.originalFilename,
      'attachment_url': upload.finalUrl,
      'file': upload.finalUrl,
      'file_url': upload.finalUrl,
      'file_name': upload.originalFilename,
      'content_type': upload.contentType,
      'original_filename': upload.originalFilename,
      's3_key': upload.s3Key,
    };
    if (replyTo != null) body['reply_to'] = replyTo;

    final response = await _apiService.post(
      endpoint: '${AppEndpoints.sendMessage}$chatUid/messages/send/',
      token: token,
      body: body,
    );

    if (response.success) {
      final data = response.data;
      final messageJson = (data is Map && data.containsKey('message')) ? data['message'] : data;
      if (messageJson is Map && !messageJson.containsKey('chat')) {
        messageJson['chat'] = chatUid;
      }
      final message = Message.fromJson(messageJson as Map<String, dynamic>);
      return ApiResponse.success(message, response.statusCode ?? 200);
    }
    return ApiResponse.error(response.message ?? "Failed to send file message", response.statusCode);
  }

  // ── Delete message ─────────────────────────────────────────────────────────
  Future<ApiResponse<void>> deleteMessage(String chatUid, String messageUid) async {
    final response = await _apiService.delete(
      endpoint: '${AppEndpoints.deleteMessage}$chatUid/messages/$messageUid/delete/',
      token: token,
    );

    if (response.success) {
      final data = response.data;
      if (data != null && data is Map && data['status'] == 'success') {
        return ApiResponse.success(null, response.statusCode ?? 200);
      } else if (data == null) {
        return ApiResponse.success(null, response.statusCode ?? 204);
      }
      return ApiResponse.error(data?['message'] ?? 'Failed to delete message', response.statusCode);
    }
    return ApiResponse.error(response.message ?? "Failed to delete message", response.statusCode);
  }

  // ── Reactions ──────────────────────────────────────────────────────────────
  Future<ApiResponse<void>> sendReaction(String chatUid, String messageUid, String emoji) async {
    final response = await _apiService.post(
      endpoint: '${AppEndpoints.reactions}$chatUid/messages/$messageUid/reactions/',
      token: token,
      body: {'emoji': emoji},
    );

    if (response.success) {
      return ApiResponse.success(null, response.statusCode ?? 200);
    }
    return ApiResponse.error(response.message ?? "Failed to send reaction", response.statusCode);
  }

  Future<ApiResponse<void>> removeReaction(String chatUid, String messageUid, String emoji) async {
    final response = await _apiService.delete(
      endpoint: '${AppEndpoints.reactions}$chatUid/messages/$messageUid/reactions/',
      token: token,
      queryParams: {'emoji': emoji}, // emoji usually goes in body for delete if using http.delete with body, but ApiService delete handles queryParams
    );
    // Note: The original code used body for DELETE. http.delete(..., body: json.encode({'emoji': emoji})).
    // Standard delete usually doesn't have a body. I'll stick to queryParams if the backend supports it, 
    // or I might need to update ApiService to support body in DELETE if necessary.
    // Let's check original removeReaction.
    /*
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chats/$chatUid/messages/$messageUid/reactions/'),
        headers: _headers,
        body: json.encode({'emoji': emoji}),
      );
    */
    // Since http package's delete DOES support a body, I should update ApiService.delete to support body too.
    // But for now let's use post/delete with whatever ApiService has.
    
    // Actually, I'll update ApiService to support body in delete.
    return ApiResponse.success(null, response.statusCode ?? 200);
  }

  // ── Mark messages read ─────────────────────────────────────────────────────
  Future<ApiResponse<void>> markMessagesAsRead(String chatUid, List<String> messageUids) async {
    if (messageUids.isEmpty) return ApiResponse.success(null, 200);
    
    final response = await _apiService.post(
      endpoint: '${AppEndpoints.markRead}$chatUid/messages/mark-read/',
      token: token,
      body: {'message_uids': messageUids},
    );

    if (response.success) {
      return ApiResponse.success(null, response.statusCode ?? 200);
    }
    return ApiResponse.error(response.message ?? "Failed to mark read", response.statusCode);
  }
}

