import 'dart:async';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/chat_list_screen/models/chat.dart';
import 'package:luminar_std/repository/chat_list_screen/models/message.dart';
import 'package:luminar_std/repository/chat_list_screen/models/user.dart';
import 'package:luminar_std/repository/chat_list_screen/service/api_service.dart';
import 'package:luminar_std/repository/chat_list_screen/service/websocket_service.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  bool _isLoading = false;
  String? _error;
  User? _currentUser;
  ChatApiService? _apiService;
  WebSocketService? _webSocketService;
  Map<int, bool> userOnlineStatus = {};

  // Tracks chats the user has tapped — prevents stale server data
  // from restoring the unread badge before the API call completes
  final Set<String> _locallyReadChats = {};

  // Prevents duplicate concurrent mark-read calls for the same chat
  final Set<String> _markingReadInProgress = {};

  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Message>? _localMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;

  // Getters
  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  ChatApiService? get apiService => _apiService;
  WebSocketService? get webSocketService => _webSocketService;

  Future<void> init() async {
    if (_apiService != null) return; // Already initialized

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await AppUtils.getAccessKey();
      if (token == null || token.isEmpty) {
        throw Exception('No access token found');
      }

      _apiService = ChatApiService(token: token);

      // Load current user profile
      final userData = await SharedPrefService.getUserData();
      if (userData != null) {
        // Try to map existing profile data to chat User model
        // Note: The integer ID might need to be retrieved from the chat API
        // if it's not in the student profile.
        final profile = userData['student']?['profile'];
        if (profile != null) {
          // Fallback: If no integer ID is found, we might need a better way to get it
          // or use a placeholder until first chat loads
          _currentUser = User(
            id: 0, // Placeholder ID
            fullName: profile['full_name'] ?? 'Student',
            profilePic: profile['profile_picture'],
            email: profile['email'],
          );
        }
      }

      if (_currentUser == null) {
        _currentUser = User(id: 0, fullName: 'Student');
      }

      // Initial chat load to possibly find our real ID
      await loadChats(showLoading: false);

      // If we still have ID 0, try to find it from chat participants
      if (_currentUser?.id == 0 && _chats.isNotEmpty) {
        for (var chat in _chats) {
          if (chat.otherParticipant != null) {
            final myId = (chat.participant1 == chat.otherParticipant!.id) ? chat.participant2 : chat.participant1;
            if (myId != null && myId != 0) {
              _currentUser = User(
                id: myId,
                fullName: _currentUser!.fullName,
                profilePic: _currentUser!.profilePic,
                email: _currentUser!.email,
              );
              break;
            }
          }
        }
      }

      // Initialize WebSocket
      final websocketUrl = "${GlobalLinks.websocketUrl}chat//?token=$token";
      _webSocketService = WebSocketService(url: websocketUrl, currentUser: _currentUser!, apiService: _apiService!);

      _setupListeners();
      _webSocketService!.connect();
    } catch (e) {
      _error = e.toString();
      debugPrint('[ChatProvider] Init Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupListeners() {
    _statusSubscription?.cancel();
    _messageSubscription?.cancel();
    _localMessageSubscription?.cancel();

    _statusSubscription = _webSocketService!.statusStream.listen((status) {
      final userId = status['user_id'];
      final isOnline = status['online'];
      if (userId is int && isOnline is bool) {
        userOnlineStatus[userId] = isOnline;
        notifyListeners();
      }
    });

    _messageSubscription = _webSocketService!.messageStream.listen((message) {
      _updateChatForMessage(message);
    });

    _localMessageSubscription = _webSocketService!.localMessageStream.listen((message) {
      _updateChatForMessage(message);
    });
  }

  Future<void> loadChats({bool showLoading = true}) async {
    if (_apiService == null) return;

    try {
      if (showLoading) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final chats = await _apiService!.fetchChats();

      // Apply local read overrides
      _chats = chats.map((chat) {
        if (_locallyReadChats.contains(chat.uid)) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();

      _sortChats();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _sortChats() {
    _chats.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    notifyListeners();
  }

  void _updateChatForMessage(Message message) {
    final chatIndex = _chats.indexWhere((c) => c.uid == message.chatId.toString());
    if (chatIndex != -1) {
      final chat = _chats[chatIndex];
      _chats[chatIndex] = chat.copyWith(
        lastMessageAt: message.createdAt,
        lastMessagePreview: {'content': message.content},
        unreadCount: message.sender.id == _currentUser?.id ? chat.unreadCount : chat.unreadCount + 1,
      );
      _sortChats();
    } else {
      loadChats(showLoading: false);
    }
  }

  Future<void> markChatAsRead(Chat chat) async {
    if (_apiService == null || _markingReadInProgress.contains(chat.uid)) return;

    _markingReadInProgress.add(chat.uid);
    _locallyReadChats.add(chat.uid);

    // Optimistically update
    final chatIndex = _chats.indexWhere((c) => c.uid == chat.uid);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
      notifyListeners();
    }

    try {
      if (chat.chatType == ChatType.group || chat.chatType == ChatType.batch) {
        final messages = await _apiService!.fetchMessages(chat.uid, page: 1, pageSize: chat.unreadCount);

        final unreadUids = messages.where((m) => m.sender.id != _currentUser?.id).map((m) => m.uid).toList();

        if (unreadUids.isNotEmpty) {
          await _apiService!.markMessagesAsRead(chat.uid, unreadUids);
          _locallyReadChats.remove(chat.uid);
        }
      } else {
        final pageSize = chat.unreadCount.clamp(1, 50);
        final messages = await _apiService!.fetchMessages(chat.uid, page: 1, pageSize: pageSize);

        final unreadUids = messages.where((m) => m.sender.id != _currentUser?.id).map((m) => m.uid).toList();

        if (unreadUids.isNotEmpty) {
          await _apiService!.markMessagesAsRead(chat.uid, unreadUids);
        }
        _locallyReadChats.remove(chat.uid);
      }
    } catch (e) {
      debugPrint('[ChatProvider] MarkRead Error: $e');
    } finally {
      _markingReadInProgress.remove(chat.uid);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _messageSubscription?.cancel();
    _localMessageSubscription?.cancel();
    _webSocketService?.disconnect();
    super.dispose();
  }
}

extension ChatCopyWith on Chat {
  Chat copyWith({
    String? uid,
    ChatType? chatType,
    int? participant1,
    int? participant2,
    String? batch,
    String? batchName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    Map<String, dynamic>? lastMessagePreview,
    int? unreadCount,
    User? otherParticipant,
    bool? isActive,
    bool? isArchived,
    String? groupName,
    String? groupDescription,
    String? groupIcon,
  }) {
    return Chat(
      uid: uid ?? this.uid,
      chatType: chatType ?? this.chatType,
      participant1: participant1 ?? this.participant1,
      participant2: participant2 ?? this.participant2,
      batch: batch ?? this.batch,
      batchName: batchName ?? this.batchName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      otherParticipant: otherParticipant ?? this.otherParticipant,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupIcon: groupIcon ?? this.groupIcon,
    );
  }
}
