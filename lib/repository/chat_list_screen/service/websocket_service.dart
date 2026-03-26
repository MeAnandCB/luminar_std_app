import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/message.dart';
import '../models/user.dart';
import 'api_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String url;
  final User currentUser;
  final ChatApiService apiService;

  final Map<int, bool> userOnlineStatus = {};

  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  final StreamController<Message> _localMessageController =
      StreamController<Message>.broadcast();
  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _deleteController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _reactionController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Message> get localMessageStream => _localMessageController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Map<String, dynamic>> get deleteStream => _deleteController.stream;
  Stream<Map<String, dynamic>> get reactionStream => _reactionController.stream;

  Function(Message)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;
  Function(int userId, bool isOnline)? onUserStatusUpdate;
  Function(String chatUid, String messageUid)? onMessageDeleted;
  Function(String chatUid, String messageUid, String emoji, int userId)?
  onReaction;

  WebSocketService({
    required this.url,
    required this.currentUser,
    required this.apiService,
  });

  bool _isDisposed = false;

  void connect() {
    if (_isDisposed) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          if (!_isDisposed) {
            onDisconnected?.call();
          }
        },
        onError: (error) {
          if (!_isDisposed) {
            _errorController.add(error.toString());
            onError?.call(error.toString());
          }
        },
      );

      onConnected?.call();
    } catch (e) {
      if (!_isDisposed) {
        _errorController.add(e.toString());
        onError?.call(e.toString());
      }
    }
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _messageController.close();
    _localMessageController.close();
    _statusController.close();
    _errorController.close();
    _deleteController.close();
    _reactionController.close();
  }

  Future<Message> sendMessage(
    String content, {
    String? replyTo,
    String? chatUid,
  }) async {
    if (content.trim().isEmpty) throw Exception('Content is empty');
    final targetUid = chatUid ?? '';
    if (targetUid.isEmpty) throw Exception('No chat UID');

    try {
      final message = await apiService.sendMessage(
        chatUid: targetUid,
        content: content,
        replyTo: replyTo,
      );
      return message;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(String chatUid, String messageUid) async {
    try {
      await apiService.deleteMessage(chatUid, messageUid);

      if (_channel != null) {
        final deleteEvent = {
          'type': 'message_deleted',
          'chat_uid': chatUid,
          'message_uid': messageUid,
          'deleted_at': DateTime.now().toIso8601String(),
        };
        _channel!.sink.add(json.encode(deleteEvent));
      }

      _deleteController.add({'chat_uid': chatUid, 'message_uid': messageUid});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendReaction(
    String chatUid,
    String messageUid,
    String emoji,
  ) async {
    try {
      await apiService.sendReaction(chatUid, messageUid, emoji);

      if (_channel != null) {
        final reactionEvent = {
          'type': 'message_reaction',
          'chat_uid': chatUid,
          'message_uid': messageUid,
          'emoji': emoji,
          'user_id': currentUser.id,
          'user_name': currentUser.fullName,
          'created_at': DateTime.now().toIso8601String(),
        };
        _channel!.sink.add(json.encode(reactionEvent));
      }

      _reactionController.add({
        'chat_uid': chatUid,
        'message_uid': messageUid,
        'emoji': emoji,
        'user_id': currentUser.id,
        'user_name': currentUser.fullName,
      });
    } catch (e) {
      rethrow;
    }
  }

  void broadcastLocalMessage(Message message) {
    _localMessageController.add(message);
  }

  void _handleMessage(String message) {
    try {
      debugPrint('[WS] Raw message: $message');
      final data = jsonDecode(message);

      if (data is Map<String, dynamic> && data['type'] == 'message_deleted') {
        final chatUid = data['chat_uid']?.toString();
        final messageUid = data['message_uid']?.toString();
        if (chatUid != null && messageUid != null) {
          _deleteController.add({
            'chat_uid': chatUid,
            'message_uid': messageUid,
          });
          onMessageDeleted?.call(chatUid, messageUid);
        }
        return;
      }

      if (data is Map<String, dynamic> && data['type'] == 'message_reaction') {
        _reactionController.add({
          'chat_uid': data['chat_uid'],
          'message_uid': data['message_uid'],
          'emoji': data['emoji'],
          'user_id': data['user_id'],
          'user_name': data['user_name'],
          'created_at': data['created_at'],
        });
        onReaction?.call(
          data['chat_uid'],
          data['message_uid'],
          data['emoji'],
          data['user_id'],
        );
        return;
      }

      if (data is Map<String, dynamic> && data.containsKey('uid')) {
        try {
          final receivedMessage = Message.fromJson(data);
          _messageController.add(receivedMessage);
          onMessageReceived?.call(receivedMessage);
          return;
        } catch (e) {}
      }

      if (data is Map<String, dynamic>) {
        final type = data['type'];
        switch (type) {
          case 'message':
          case 'new_message':
            final messageData = data['data'] ?? data;
            if (messageData is Map<String, dynamic>) {
              try {
                if (!messageData.containsKey('chat') &&
                    messageData.containsKey('chat_uid')) {
                  messageData['chat'] = messageData['chat_uid'];
                }
                final receivedMessage = Message.fromJson(messageData);
                _messageController.add(receivedMessage);
                onMessageReceived?.call(receivedMessage);
              } catch (e) {
                _errorController.add('Failed to parse message: $e');
              }
            }
            break;

          case 'presence':
          case 'user_status':
          case 'online_status':
            final dynamic rawData = data['data'] ?? data;

            void processItem(Map<String, dynamic> statusData) {
              dynamic userIdRaw = statusData['user_id'] ?? statusData['id'];
              if (userIdRaw == null &&
                  statusData.containsKey('user') &&
                  statusData['user'] is Map) {
                userIdRaw = statusData['user']['id'];
              }

              final isOnlineRaw = statusData['online'] ??
                  statusData['is_online'] ??
                  statusData['status'];

              int? userId;
              if (userIdRaw is int)
                userId = userIdRaw;
              else if (userIdRaw is String)
                userId = int.tryParse(userIdRaw);

              bool? isOnline;
              if (isOnlineRaw is bool)
                isOnline = isOnlineRaw;
              else if (isOnlineRaw is String) {
                final lower = isOnlineRaw.toLowerCase();
                isOnline = lower == 'true' || lower == 'online';
              } else if (isOnlineRaw is num) {
                isOnline = isOnlineRaw != 0;
              }

              if (userId != null && isOnline != null) {
                userOnlineStatus[userId] = isOnline;
                _statusController.add({'user_id': userId, 'online': isOnline});
                onUserStatusUpdate?.call(userId, isOnline);
              }
            }

            if (rawData is List) {
              for (var item in rawData) {
                if (item is Map<String, dynamic>) processItem(item);
              }
            } else if (rawData is Map<String, dynamic>) {
              processItem(rawData);
            }
            break;
        }
      }
    } catch (e) {
      _errorController.add('Failed to parse WebSocket message: $e');
      onError?.call('Failed to parse WebSocket message: $e');
    }
  }

  void updateUserStatus(bool isOnline) {
    if (_channel != null && currentUser.id != 0) {
      final statusMessage = jsonEncode({
        'action': 'presence',
        'user_id': currentUser.id,
        'online': isOnline,
      });
      _channel!.sink.add(statusMessage);
    }
  }

  bool get isConnected => _channel != null;
}
