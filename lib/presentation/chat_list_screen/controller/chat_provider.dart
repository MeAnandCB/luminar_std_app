import 'dart:async';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/chat_list_screen/models/chat.dart';
import 'package:luminar_std/repository/chat_list_screen/models/message.dart';
import 'package:luminar_std/repository/chat_list_screen/models/user.dart';
import 'package:luminar_std/repository/chat_list_screen/service/api_service.dart';
import 'package:luminar_std/repository/chat_list_screen/service/websocket_service.dart';
import 'package:luminar_std/main.dart';
import 'package:luminar_std/presentation/chat_screen/chat_screen.dart';
import 'package:luminar_std/repository/shared_pref.dart';

class ChatProvider extends ChangeNotifier with WidgetsBindingObserver {
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

  // Badge count fetched on app open (before chat tab is ever opened)
  int _apiUnreadCount = 0;

  // Getters
  List<Chat> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  ChatApiService? get apiService => _apiService;
  WebSocketService? get webSocketService => _webSocketService;

  /// Badge count: uses live chat-list sum when loaded, API count otherwise.
  int get totalUnreadCount =>
      _chats.isNotEmpty ? _chats.fold(0, (sum, c) => sum + c.unreadCount) : _apiUnreadCount;

  /// Lightweight call — only fetches badge count, no WebSocket or chat list.
  Future<void> fetchUnreadCountOnly() async {
    try {
      final token = await AppUtils.getAccessKey();
      if (token == null || token.isEmpty) return;
      final service = ChatApiService(token: token);
      final response = await service.fetchUnreadCount();
      if (response.success && response.data != null) {
        _apiUnreadCount = response.data!;
        notifyListeners();
      }
    } catch (_) {}
  }

  ChatProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (AppUtils.isDeepLinking) {
        debugPrint('[ChatProvider] Skipping auto-refresh on resume: Deep-link in progress');
        return;
      }
      debugPrint('[ChatProvider] App resumed — ensuring WebSocket connectivity');
      _ensureConnectivity();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('[ChatProvider] App paused — user going offline');
      _webSocketService?.updateUserStatus(false);
    }
  }

  void _ensureConnectivity() {
    if (_webSocketService == null) return;
    if (!_webSocketService!.isConnected) {
      debugPrint('[ChatProvider] WebSocket disconnected — reconnecting...');
      _webSocketService!.connect();
    } else {
      // Already connected — just refresh our status
      _webSocketService!.updateUserStatus(true);
    }
  }

  /// Call when entering a chat screen so unread is not incremented
  /// for the chat the user is currently reading.
  void setActiveChat(String? chatUid) {
    _activeChatUid = chatUid;
  }

  /// Navigates to a specific chat by its UID.
  /// Handles refreshing the chat list if the chat is not found locally.
  Future<void> navigateToChat(String chatUid) async {
    if (_activeChatUid == chatUid) {
      debugPrint('[ChatProvider] Already in chat: $chatUid. Skipping navigation.');
      return;
    }

    if (_apiService == null || _currentUser == null) await init();

    Chat? chat;
    try {
      chat = _chats.firstWhere((c) => c.uid == chatUid);
    } catch (_) {
      // If not found in current list, refresh first
      await loadChats(showLoading: false);
      try {
        chat = _chats.firstWhere((c) => c.uid == chatUid);
      } catch (_) {
        debugPrint('[ChatProvider] Chat not found after refresh: $chatUid');
      }
    }

    if (chat != null && navigatorKey.currentState != null) {
      // Ensure we are initialized
      if (_currentUser == null || _webSocketService == null || _apiService == null) {
        debugPrint('[ChatProvider] Cannot navigate: dependecies missing');
        return;
      }

      // Zero badge locally — ChatScreen handles actual server mark-read
      zeroChatBadge(chat);
      setActiveChat(chat.uid);

      navigatorKey.currentState!
          .push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chat: chat!,
                currentUser: _currentUser!,
                websocketUrl: _webSocketService!.url,
                apiService: _apiService!,
                webSocketService: _webSocketService,
              ),
            ),
          )
          .then((_) {
            setActiveChat(null);
            AppUtils.isDeepLinking = false; // Reset global flag
          });
    } else {
      AppUtils.isDeepLinking = false; // Reset if navigation couldn't happen
    }
  }

  Future<void> init() async {
    final token = await AppUtils.getAccessKey();
    if (token == null || token.isEmpty) {
      _error = 'No access token found';
      notifyListeners();
      return;
    }

    // If we are already initialized with the SAME token, skip full reset
    if (_apiService != null && _apiService!.token == token) {
      _ensureConnectivity();
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
        // Robust ID resolution from login response
        int studentId = 0;
        final student = userData['student'];
        if (student is Map) {
          final profile = student['profile'];
          if (profile is Map) {
            // Check for numeric 'id' first, then 'student_id' if numeric
            studentId =
                int.tryParse(profile['id']?.toString() ?? '') ??
                int.tryParse(profile['student_id']?.toString() ?? '') ??
                0;

            _currentUser = User(
              id: studentId,
              fullName: profile['full_name'] ?? 'Student',
              profilePic: AppUtils.getAbsoluteUrl(profile['profile_picture']),
              email: profile['email'],
            );
          }
        }
      }

      if (_currentUser == null) {
        _currentUser = User(id: 0, fullName: 'Student');
      }

      // Initial chat load
      await loadChats(showLoading: false);

      // Fallback: Resolve real user ID from chat participants if still 0
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
      final websocketUrl = "${GlobalLinks.websocketUrl}chat/?token=$token";
      _webSocketService = WebSocketService(url: websocketUrl, currentUser: _currentUser!, apiService: _apiService!);

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
    _localMessageSubscription = _webSocketService!.localMessageStream.listen((message) {
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
            lastMessagePreview: {...preview, 'content': 'Message deleted', 'is_deleted': true},
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
    final chatUid = message.chatId;
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
      final shouldIncrementUnread = !fromSelf && !isViewing && !_locallyReadChats.contains(chatUid);

      _chats[chatIndex] = chat.copyWith(
        lastMessageAt: message.createdAt,
        lastMessagePreview: {
          'content': preview,
          'sender': message.sender.fullName,
          'sender_id': message.sender.id,
          'message_uid': message.uid,
          'message_type': message.messageType,
        },
        unreadCount: shouldIncrementUnread ? chat.unreadCount + 1 : chat.unreadCount,
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


  Future<void> refresh() async {
    await loadChats(showLoading: true);
    _ensureConnectivity();
  }

  Future<void> loadChats({bool showLoading = true}) async {
    if (_apiService == null) return;

    try {
      if (showLoading) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final response = await _apiService!.fetchChats();

      if (response.success && response.data != null) {
        final chats = response.data!;
        // Apply local read overrides so badge doesn't flash back.
        // If server now confirms 0, lift the guard naturally.
        _chats = chats.map((chat) {
          if (chat.unreadCount == 0) {
            _locallyReadChats.remove(chat.uid);
            return chat;
          }
          if (_locallyReadChats.contains(chat.uid)) {
            return chat.copyWith(unreadCount: 0);
          }
          return chat;
        }).toList();

        _sortChats();
      } else {
        _error = response.message;
      }
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

  /// Zeroes the unread badge locally — call this when opening a chat.
  /// No API call. The actual server mark-read happens in ChatScreen once messages load.
  void zeroChatBadge(Chat chat) {
    _locallyReadChats.add(chat.uid);
    final chatIndex = _chats.indexWhere((c) => c.uid == chat.uid);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

  /// Marks messages as read on the server using already-loaded message list.
  /// Call this from ChatScreen after _loadMessages() completes.
  Future<void> markMessagesRead(String chatUid, List<String> messageUids) async {
    if (_apiService == null || _markingReadInProgress.contains(chatUid)) return;
    if (messageUids.isEmpty) return;

    _markingReadInProgress.add(chatUid);
    try {
      await _apiService!.markMessagesAsRead(chatUid, messageUids);
    } catch (e) {
      debugPrint('[ChatProvider] MarkRead Error: $e');
    } finally {
      _markingReadInProgress.remove(chatUid);
    }
  }

  void reset() {
    _resetInternal();
    notifyListeners();
  }

  void _resetInternal() {
    _statusSubscription?.cancel();
    _messageSubscription?.cancel();
    _localMessageSubscription?.cancel();
    _deleteSubscription?.cancel();
    _webSocketService?.disconnect();

    _chats = [];
    _isLoading = false;
    _error = null;
    _currentUser = null;
    _apiUnreadCount = 0;
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
    WidgetsBinding.instance.removeObserver(this);
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
