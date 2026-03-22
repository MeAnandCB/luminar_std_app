import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/message_screen/model/message_screen_models.dart';
import 'package:luminar_std/repository/message_screen/service/message_service.dart';
import 'package:luminar_std/repository/message_screen/websocket/web_socket_data.dart';

class ChatProvider extends ChangeNotifier {
  final MessageApiService apiService;
  final WebSocketService webSocketService;

  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  ChatModel? _currentChat;

  // THE ROOT FIX:
  // When ChatScreen lives in a bottom nav, it is mounted immediately with
  // a chatUid prop. But setCurrentChat() is only called from the chat list
  // tap handler — which never fires in a bottom-nav setup. So _currentChat
  // stays null and _onIncomingMessage always dropped incoming messages.
  //
  // _activeChatUid is set by ChatScreen.initState() via
  // registerActiveChatUid(chatUid) and cleared in ChatScreen.dispose() via
  // unregisterActiveChatUid(). It represents "which chat room is the user
  // actually looking at right now" and is the source of truth for routing
  // incoming WS messages to the visible list.
  String? _activeChatUid;

  bool _isLoading = false;
  bool _isLoadingMessages = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreMessages = true;
  int _currentUserId = 0;

  final Map<String, int> _uidToIntId = {};
  final Map<int, String> _intIdToUid = {};
  final Map<int, bool> _onlineStatus = {};
  bool _isOtherUserTyping = false;

  final _chatsStreamCtrl = StreamController<List<ChatModel>>.broadcast();
  final _messagesStreamCtrl = StreamController<List<MessageModel>>.broadcast();
  final _scrollStreamCtrl = StreamController<void>.broadcast();

  Stream<List<ChatModel>> get chatsStream => _chatsStreamCtrl.stream;
  Stream<List<MessageModel>> get messagesStream => _messagesStreamCtrl.stream;
  Stream<void> get scrollStream => _scrollStreamCtrl.stream;

  ChatProvider({required this.apiService, required this.webSocketService}) {
    _setupCallbacks();
    _loadCurrentUser();
  }

  List<ChatModel> get chats => List.from(_chats);
  List<MessageModel> get messages => List.from(_messages);
  ChatModel? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  bool get isWebSocketConnected => webSocketService.isConnected;
  bool get isOtherUserTyping => _isOtherUserTyping;
  bool isUserOnline(int userId) => _onlineStatus[userId] ?? false;
  bool isCurrentUser(int userId) => userId == _currentUserId;

  // ─── Active screen registration ────────────────────────────────────────────
  // Called by ChatScreen.initState — tells provider which uid is on screen.
  void registerActiveChatUid(String chatUid) {
    _activeChatUid = chatUid;
    print('🟢 Active chat registered: $chatUid');
  }

  // Called by ChatScreen.dispose — clears so background chats aren't wrongly
  // treated as open when the user navigates away.
  void unregisterActiveChatUid() {
    print('🔴 Active chat unregistered: $_activeChatUid');
    _activeChatUid = null;
  }

  void _emitChats() {
    if (!_chatsStreamCtrl.isClosed) _chatsStreamCtrl.add(List.from(_chats));
    notifyListeners();
  }

  void _emitMessages() {
    if (!_messagesStreamCtrl.isClosed)
      _messagesStreamCtrl.add(List.from(_messages));
    notifyListeners();
  }

  void _emitAll() {
    if (!_chatsStreamCtrl.isClosed) _chatsStreamCtrl.add(List.from(_chats));
    if (!_messagesStreamCtrl.isClosed)
      _messagesStreamCtrl.add(List.from(_messages));
    notifyListeners();
  }

  void _emitScroll() {
    if (!_scrollStreamCtrl.isClosed) _scrollStreamCtrl.add(null);
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = 665; // TODO: replace with real auth
  }

  void _setupCallbacks() {
    webSocketService.onMessageReceived = _onIncomingMessage;
    webSocketService.onConnected = () {
      print('✅ WS connected');
      notifyListeners();
    };
    webSocketService.onDisconnected = () {
      print('🔌 WS disconnected');
      notifyListeners();
    };
    webSocketService.onPresenceUpdate = (userId, isOnline) {
      _onlineStatus[userId] = isOnline;
      _emitChats();
    };
    webSocketService.onTypingIndicator = (isTyping, userId) {
      _isOtherUserTyping = isTyping;
      notifyListeners();
    };
  }

  // ─── Incoming WS message ───────────────────────────────────────────────────
  void _onIncomingMessage(MessageModel msg) {
    print('📨 WS msg: "${msg.content}" chatInt=${msg.chat}');

    // Always update chat list preview + badge.
    _refreshChatEntry(msg);

    // Determine if the incoming message belongs to the chat that is currently
    // visible on screen. We try three lookup paths so the check works even
    // before loadMessages() has returned (the UID<->int map may be empty):
    //
    //   Path A — uidToIntId[_activeChatUid] == msg.chat  (normal case)
    //   Path B — intIdToUid[msg.chat] == _activeChatUid  (reverse lookup)
    //   Path C — scan _chats list matching both uid & id  (cold start)
    final activeUid = _activeChatUid;
    bool belongsToActiveScreen = false;

    if (activeUid != null) {
      // Path A
      final mappedInt = _uidToIntId[activeUid];
      if (mappedInt != null && mappedInt == msg.chat) {
        belongsToActiveScreen = true;
      }
      // Path B
      if (!belongsToActiveScreen) {
        final mappedUid = _intIdToUid[msg.chat];
        if (mappedUid == activeUid) belongsToActiveScreen = true;
      }
      // Path C
      if (!belongsToActiveScreen) {
        belongsToActiveScreen = _chats.any(
          (c) => c.uid == activeUid && c.id == msg.chat,
        );
      }
    }

    print(
      '📨 belongs=$belongsToActiveScreen active=$activeUid msgInt=${msg.chat}',
    );

    if (belongsToActiveScreen) {
      final exists = _messages.any((m) => m.uid == msg.uid);
      if (!exists) {
        // Replace optimistic bubble if content + sender match
        final tempIdx = _messages.indexWhere(
          (m) =>
              m.isSending &&
              m.content == msg.content &&
              m.sender.id == msg.sender.id,
        );
        if (tempIdx != -1) {
          _messages[tempIdx] = msg;
        } else {
          _messages.add(msg);
        }
        // Only emit message stream when something actually changed.
        _emitMessages();
        _emitScroll();
      }
    }

    // Chat list always updates (badge / preview).
    _emitChats();
  }

  void _refreshChatEntry(MessageModel msg) {
    int idx = _chats.indexWhere((c) => _uidToIntId[c.uid] == msg.chat);
    if (idx == -1) idx = _chats.indexWhere((c) => c.id == msg.chat);
    if (idx == -1) {
      print('⚠️ Chat not found for intId=${msg.chat}');
      return;
    }
    final c = _chats[idx];

    // Opportunistically populate maps from WS message data.
    if (!_uidToIntId.containsKey(c.uid) && msg.chat != 0) {
      _uidToIntId[c.uid] = msg.chat;
      _intIdToUid[msg.chat] = c.uid;
      print('📌 Map filled via WS: ${c.uid} <-> ${msg.chat}');
    }

    final isOpen = _activeChatUid == c.uid;
    final updated = _rebuild(
      c,
      lastMessageAt: msg.createdAt,
      preview: LastMessagePreview(
        content: msg.content,
        sender: msg.sender.fullName,
        messageType: msg.messageType,
        isDeleted: false,
        createdAt: msg.createdAt,
      ),
      unreadCount: isOpen ? 0 : c.unreadCount + 1,
    );
    _chats
      ..removeAt(idx)
      ..insert(0, updated);
  }

  // ─── Load Chats ────────────────────────────────────────────────────────────
  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    _emitChats();

    try {
      _chats = await apiService.getChats();
      for (final c in _chats) {
        if (c.id != 0) {
          _uidToIntId[c.uid] = c.id;
          _intIdToUid[c.id] = c.uid;
        }
      }
      print('✅ ${_chats.length} chats, ${_uidToIntId.length} IDs mapped');
      if (_chats.isNotEmpty && !webSocketService.isConnected) {
        _connectWS(_chats.first.uid);
      }
    } catch (e) {
      _error = e.toString();
      print('❌ loadChats: $e');
    } finally {
      _isLoading = false;
      _emitChats();
    }
  }

  // ─── Load Messages ─────────────────────────────────────────────────────────
  Future<void> loadMessages(String chatUid, {bool refresh = false}) async {
    if (refresh) {
      _messages.clear();
      _currentPage = 1;
      _hasMoreMessages = true;
    }
    if (!_hasMoreMessages) return;

    _isLoadingMessages = true;
    _emitMessages();

    try {
      final res = await apiService.getMessages(chatUid, page: _currentPage);
      final raw = (res['messages'] as List?) ?? [];
      final fetched = raw.map((j) => MessageModel.fromJson(j)).toList();

      if (fetched.isNotEmpty && fetched.first.chat != 0) {
        final intId = fetched.first.chat;
        _uidToIntId[chatUid] = intId;
        _intIdToUid[intId] = chatUid;
        print('📌 $chatUid <-> $intId');
      }

      final ordered = fetched.reversed.toList();
      if (_currentPage == 1) {
        _messages = ordered;
      } else {
        _messages.insertAll(0, ordered);
      }

      _hasMoreMessages = res['has_next'] ?? false;
      if (_hasMoreMessages) _currentPage++;

      _connectWS(chatUid);
      if (_messages.isNotEmpty) _markAsRead(chatUid);
    } catch (e) {
      _error = e.toString();
      print('❌ loadMessages: $e');
    } finally {
      _isLoadingMessages = false;
      _emitMessages();
      _emitScroll();
    }
  }

  void _connectWS(String chatUid) {
    AppUtils.getAccessKey().then((token) {
      if (token != null && token.isNotEmpty) {
        webSocketService.connect(chatUid, token).catchError((e) {
          print('❌ WS connect error: $e');
        });
      }
    });
  }

  // ─── Send Message ──────────────────────────────────────────────────────────
  // chatUid param added so bottom-nav ChatScreen can pass its own uid
  // without relying on _currentChat being set.
  Future<void> sendMessage(
    String content, {
    String? replyTo,
    String? chatUid,
  }) async {
    if (content.trim().isEmpty) return;

    final targetUid = chatUid ?? _currentChat?.uid ?? _activeChatUid;
    if (targetUid == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final intId = _uidToIntId[targetUid] ?? 0;

    final temp = MessageModel(
      uid: tempId,
      chat: intId,
      sender: Sender(
        id: _currentUserId,
        fullName: 'You',
        email: '',
        profilePic: null,
      ),
      messageType: 'text',
      content: content,
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      readBy: [],
      isSending: true,
      status: MessageStatus.sending,
    );

    _messages.add(temp);
    _emitMessages();
    _emitScroll();

    try {
      final confirmed = await apiService.sendMessage(
        chatUid: targetUid,
        content: content,
        replyTo: replyTo,
      );

      final idx = _messages.indexWhere((m) => m.uid == tempId);
      if (idx != -1) {
        _messages[idx] = confirmed;
      } else if (!_messages.any((m) => m.uid == confirmed.uid)) {
        _messages.add(confirmed);
      }

      _refreshChatEntry(confirmed);
      _emitAll();
    } catch (e) {
      print('❌ sendMessage: $e');
      final idx = _messages.indexWhere((m) => m.uid == tempId);
      if (idx != -1) {
        _messages[idx].status = MessageStatus.failed;
        _messages[idx].isSending = false;
      }
      _error = 'Failed to send. Please try again.';
      _emitMessages();
    }
  }

  // ─── State ─────────────────────────────────────────────────────────────────
  void setCurrentChat(ChatModel chat) {
    _currentChat = chat;
    _messages.clear();
    _currentPage = 1;
    _hasMoreMessages = true;
    _isOtherUserTyping = false;
    _zeroBadge(chat.uid);
    _emitAll();
  }

  void onLeaveChat() {
    _currentChat = null;
    _messages.clear();
    _isOtherUserTyping = false;
    unregisterActiveChatUid();
    _emitAll();
    if (_chats.isNotEmpty) _connectWS(_chats.first.uid);
  }

  void updateTypingStatus(bool isTyping) {
    _isOtherUserTyping = isTyping;
    notifyListeners();
  }

  void sendTypingIndicator(bool isTyping) {
    if (webSocketService.isConnected) {
      webSocketService.sendTypingIndicator(isTyping: isTyping);
    }
  }

  Future<void> _markAsRead(String chatUid) async {
    try {
      await apiService.markAsRead(chatUid);
      _zeroBadge(chatUid);
      _emitChats();
    } catch (_) {}
  }

  void _zeroBadge(String chatUid) {
    final idx = _chats.indexWhere((c) => c.uid == chatUid);
    if (idx == -1 || _chats[idx].unreadCount == 0) return;
    _chats[idx] = _rebuild(_chats[idx], unreadCount: 0);
  }

  ChatModel _rebuild(
    ChatModel src, {
    DateTime? lastMessageAt,
    LastMessagePreview? preview,
    int? unreadCount,
  }) {
    return ChatModel(
      uid: src.uid,
      id: src.id,
      chatType: src.chatType,
      participant1: src.participant1,
      participant2: src.participant2,
      batch: src.batch,
      batchName: src.batchName,
      createdAt: src.createdAt,
      updatedAt: src.updatedAt,
      lastMessageAt: lastMessageAt ?? src.lastMessageAt,
      lastMessagePreview: preview ?? src.lastMessagePreview,
      unreadCount: unreadCount ?? src.unreadCount,
      otherParticipant: src.otherParticipant,
      isActive: src.isActive,
      isArchived: src.isArchived,
      groupName: src.groupName,
      groupDescription: src.groupDescription,
      groupIcon: src.groupIcon,
    );
  }

  @override
  void dispose() {
    _chatsStreamCtrl.close();
    _messagesStreamCtrl.close();
    _scrollStreamCtrl.close();
    webSocketService.dispose();
    super.dispose();
  }
}
