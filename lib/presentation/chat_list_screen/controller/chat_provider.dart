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
  bool _isWsConnected = false;
  bool get isWsConnected => _isWsConnected;

  // Tracks which chat screen is currently open so we never
  // increment unread for the chat the user is actively viewing
  String? _activeChatUid;

  // Tracks chats the user has tapped — prevents stale server data
  // from restoring the unread badge before the API call completes
  final Set<String> _locallyReadChats = {};

  // Prevents duplicate concurrent mark-read calls for the same chat
  final Set<String> _markingReadInProgress = {};

  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Message>? _localMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _deleteSubscription;

  // Polling timer as a fallback when WebSocket misses events
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 8);

  // Getters
  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  ChatApiService? get apiService => _apiService;
  WebSocketService? get webSocketService => _webSocketService;

  /// Call when entering a chat screen so unread is not incremented
  /// for the chat the user is currently reading.
  void setActiveChat(String? chatUid) {
    _activeChatUid = chatUid;
  }

  Future<void> init() async {
    final token = await AppUtils.getAccessKey();
    if (token == null || token.isEmpty) {
      _error = 'No access token found';
      notifyListeners();
      return;
    }

    // If we are already initialized with the SAME token, skip
    if (_apiService != null && _apiService!.token == token) {
      return;
    }

    // Otherwise, re-initialize (switching users)
    _resetInternal();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _apiService = ChatApiService(token: token);

      // Load current user profile
      final userData = await SharedPrefService.getUserData();
      if (userData != null) {
        final profile = userData['student']?['profile'];
        if (profile != null) {
          _currentUser = User(
            id: 0, // Placeholder — resolved below from chat participants
            fullName: profile['full_name'] ?? 'Student',
            profilePic: profile['profile_picture'],
            email: profile['email'],
          );
        }
      }

      if (_currentUser == null) {
        _currentUser = User(id: 0, fullName: 'Student');
      }

      // Initial chat load
      await loadChats(showLoading: false);

      // Resolve real user ID from chat participants
      if (_currentUser?.id == 0 && _chats.isNotEmpty) {
        for (var chat in _chats) {
          if (chat.otherParticipant != null) {
            final myId = (chat.participant1 == chat.otherParticipant!.id)
                ? chat.participant2
                : chat.participant1;
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
      _webSocketService = WebSocketService(
        url: websocketUrl,
        currentUser: _currentUser!,
        apiService: _apiService!,
      );

      _setupListeners();

      _webSocketService!.onConnected = () {
        _isWsConnected = true;
        // Broadcast that WE are online so other users see our status,
        // and trigger presence replies from the server for others
        _webSocketService!.updateUserStatus(true);
        notifyListeners();
      };
      _webSocketService!.onDisconnected = () {
        _isWsConnected = false;
        notifyListeners();
      };

      _webSocketService!.connect();
      _startPolling();
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
    _deleteSubscription?.cancel();

    // ── Online/offline presence ──────────────────────────────────────────────
    _statusSubscription = _webSocketService!.statusStream.listen((status) {
      final userId = status['user_id'];
      final isOnline = status['online'];
      if (userId is int && isOnline is bool) {
        userOnlineStatus[userId] = isOnline;
        notifyListeners();
      }
    });

    // ── Incoming messages from other users via WebSocket ────────────────────
    _messageSubscription = _webSocketService!.messageStream.listen((message) {
      _handleIncomingMessage(message, fromSelf: false);
    });

    // ── Messages we sent ourselves (broadcast back from ChatScreen) ─────────
    // These should update lastMessage preview but NEVER increment unread
    _localMessageSubscription = _webSocketService!.localMessageStream.listen((
      message,
    ) {
      _handleIncomingMessage(message, fromSelf: true);
    });

    // ── Deleted messages — update preview if it was the last message ────────
    _deleteSubscription = _webSocketService!.deleteStream.listen((data) {
      final chatUid = data['chat_uid']?.toString();
      if (chatUid == null) return;
      final chatIndex = _chats.indexWhere((c) => c.uid == chatUid);
      if (chatIndex != -1) {
        final chat = _chats[chatIndex];
        final preview = chat.lastMessagePreview ?? {};
        // If deleted message was the last one shown, update preview text
        if (preview['message_uid'] == data['message_uid']) {
          _chats[chatIndex] = chat.copyWith(
            lastMessagePreview: {
              ...preview,
              'content': 'Message deleted',
              'is_deleted': true,
            },
          );
          notifyListeners();
        }
      }
    });
  }

  /// Central handler for all incoming messages (WebSocket + local broadcast).
  /// [fromSelf] = true  → sent by current user, never increment unread
  /// [fromSelf] = false → sent by someone else, increment unread unless
  ///                      the user is actively viewing that chat
  void _handleIncomingMessage(Message message, {required bool fromSelf}) {
    final chatUid = message.chatId.toString();
    final chatIndex = _chats.indexWhere((c) => c.uid == chatUid);

    // Build a human-readable preview string
    final preview = _buildPreview(message);

    if (chatIndex != -1) {
      final chat = _chats[chatIndex];

      // Determine whether to increment unread:
      //   • Never if WE sent it
      //   • Never if the user is currently inside that chat screen
      //   • Never if the chat is locally marked as read (tap in progress)
      final isViewing = _activeChatUid == chatUid;
      final shouldIncrementUnread =
          !fromSelf && !isViewing && !_locallyReadChats.contains(chatUid);

      _chats[chatIndex] = chat.copyWith(
        lastMessageAt: message.createdAt,
        lastMessagePreview: {
          'content': preview,
          'sender': message.sender.fullName,
          'sender_id': message.sender.id,
          'message_uid': message.uid,
          'message_type': message.messageType,
        },
        unreadCount: shouldIncrementUnread
            ? chat.unreadCount + 1
            : chat.unreadCount,
      );

      _sortChats();
    } else {
      // Unknown chat — fetch fresh list from server
      loadChats(showLoading: false);
    }
  }

  /// Returns a user-friendly one-line preview for any message type.
  String _buildPreview(Message message) {
    if (message.isDeleted) return 'Message deleted';
    switch (message.messageType) {
      case 'image':
        return '📷 Photo';
      case 'audio':
        return '🎤 Voice message';
      case 'video':
        return '🎬 Video';
      case 'file':
        final name = message.fileName;
        return name != null && name.isNotEmpty ? '📎 $name' : '📎 File';
      default:
        return message.content;
    }
  }

  /// Polling fallback — silently refreshes chats every 8 seconds.
  /// Catches any messages the WebSocket may have missed (reconnects, gaps).
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_apiService == null) return;
      try {
        final fresh = await _apiService!.fetchChats();
        if (fresh.isEmpty) return;

        bool changed = false;

        for (final freshChat in fresh) {
          final idx = _chats.indexWhere((c) => c.uid == freshChat.uid);

          if (idx == -1) {
            // Brand new chat appeared
            _chats.add(freshChat);
            changed = true;
            continue;
          }

          final existing = _chats[idx];
          final freshTime = freshChat.lastMessageAt;
          final existingTime = existing.lastMessageAt;

          // Only update if the server reports a newer message
          final serverIsNewer =
              freshTime != null &&
              (existingTime == null || freshTime.isAfter(existingTime));

          if (serverIsNewer) {
            // Preserve locally-zeroed unread counts
            final unread = _locallyReadChats.contains(freshChat.uid)
                ? 0
                : freshChat.unreadCount;
            _chats[idx] = freshChat.copyWith(unreadCount: unread);
            changed = true;
          }
        }

        if (changed) _sortChats();
      } catch (e) {
        debugPrint('[ChatProvider] Poll error: $e');
      }
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

      // Apply local read overrides so badge doesn't flash back
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

  Future<void> markChatAsRead(Chat chat) async {
    if (_apiService == null || _markingReadInProgress.contains(chat.uid))
      return;

    _markingReadInProgress.add(chat.uid);
    _locallyReadChats.add(chat.uid);

    // Optimistically zero the badge immediately
    final chatIndex = _chats.indexWhere((c) => c.uid == chat.uid);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
      notifyListeners();
    }

    try {
      final pageSize = chat.unreadCount.clamp(1, 50);
      final messages = await _apiService!.fetchMessages(
        chat.uid,
        page: 1,
        pageSize: pageSize,
      );

      final unreadUids = messages
          .where((m) => m.sender.id != _currentUser?.id)
          .map((m) => m.uid)
          .toList();

      if (unreadUids.isNotEmpty) {
        await _apiService!.markMessagesAsRead(chat.uid, unreadUids);
      }

      _locallyReadChats.remove(chat.uid);
    } catch (e) {
      debugPrint('[ChatProvider] MarkRead Error: $e');
    } finally {
      _markingReadInProgress.remove(chat.uid);
      notifyListeners();
    }
  }

  void reset() {
    _resetInternal();
    notifyListeners();
  }

  void _resetInternal() {
    _pollTimer?.cancel();
    _statusSubscription?.cancel();
    _messageSubscription?.cancel();
    _localMessageSubscription?.cancel();
    _deleteSubscription?.cancel();
    _webSocketService?.disconnect();

    _chats = [];
    _isLoading = false;
    _error = null;
    _currentUser = null;
    _apiService = null;
    _webSocketService = null;
    userOnlineStatus = {};
    _locallyReadChats.clear();
    _markingReadInProgress.clear();
    _activeChatUid = null;
    _isWsConnected = false;
  }

  @override
  void dispose() {
    _resetInternal();
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
