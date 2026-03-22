import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:luminar_std/repository/message_screen/model/message_screen_models.dart';

/// A persistent WebSocket service that stays connected across screens.
/// - On ChatListScreen: connected to the most recent chat room
/// - On ChatScreen: switches to that chat's room
/// - Never fully disconnects unless the user logs out
class WebSocketService {
  static WebSocketService? _instance;

  WebSocket? _socket;
  String? _currentChatUid;
  String? _currentToken;
  bool _isConnecting = false;
  bool _isConnected = false;
  // FIX: _disposed must start false and only be set true in dispose().
  // Previously disconnect(intentional:true) set _disposed=false (wrong — that
  // resets it to the already-false default and never protects the singleton).
  bool _disposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  // Callbacks set by ChatProvider
  Function(MessageModel)? onMessageReceived;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(int, bool)? onPresenceUpdate;
  Function(bool, int)? onTypingIndicator;

  // Broadcast streams
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _typingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _presenceStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStreamController.stream;
  Stream<Map<String, dynamic>> get presenceStream =>
      _presenceStreamController.stream;

  bool get isConnected => _isConnected && _socket != null;
  String? get currentChatUid => _currentChatUid;

  factory WebSocketService() {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }
  WebSocketService._internal();

  /// Connect (or switch) to a chat room.
  /// Safe to call multiple times — re-uses existing connection if same room.
  Future<void> connect(String chatUid, String token) async {
    // FIX: Reset _disposed so a re-used singleton can reconnect after a
    // non-logout disconnect (e.g. switching screens).
    _disposed = false;

    if (_isConnecting) {
      // Queue this request to run after current connect finishes
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isConnected && _currentChatUid == chatUid) return;
    }

    // Already on this room and connected — nothing to do
    if (_isConnected && _socket != null && _currentChatUid == chatUid) {
      _connectionStatusController.add(true);
      onConnected?.call();
      return;
    }

    // Close existing socket silently before switching room
    if (_socket != null) {
      final old = _socket;
      _socket = null;
      _isConnected = false;
      try {
        await old!.close(WebSocketStatus.normalClosure);
      } catch (_) {}
    }

    _isConnecting = true;
    _currentChatUid = chatUid;
    _currentToken = token;
    _isConnected = false;
    // FIX: Always reset attempt counter when initiating a fresh connect so
    // the new room gets a full budget of retry attempts.
    _reconnectAttempts = 0;

    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed || _currentChatUid == null || _currentToken == null) return;
    _isConnecting = true;

    try {
      final url =
          'wss://api.crm.dev.luminartechnohub.com/ws/chat/$_currentChatUid/?token=$_currentToken';
      print('🔌 WS connecting to room ${_currentChatUid!.substring(0, 8)}...');

      _socket = await WebSocket.connect(
        url,
      ).timeout(const Duration(seconds: 10));

      if (_disposed) {
        await _socket!.close();
        _socket = null;
        return;
      }

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController.add(true);
      onConnected?.call();
      print('✅ WS connected to ${_currentChatUid!.substring(0, 8)}');

      _socket!.listen(
        _handleRawMessage,
        onError: (e) {
          print('❌ WS error: $e');
          _onSocketGone();
        },
        onDone: () {
          print('🔌 WS closed (code=${_socket?.closeCode})');
          _onSocketGone();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ WS connect failed: $e');
      _socket = null;
      _isConnected = false;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _onSocketGone() {
    if (_disposed) return;
    _socket = null;
    _isConnected = false;
    _connectionStatusController.add(false);
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _currentChatUid == null || _currentToken == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('⛔ WS giving up after $_maxReconnectAttempts attempts');
      return;
    }
    _reconnectAttempts++;
    // Exponential backoff: 2s, 4s, 6s ... capped at 30s
    final seconds = (_reconnectAttempts * 2).clamp(2, 30);
    print('🔄 WS reconnect #$_reconnectAttempts in ${seconds}s');
    Future.delayed(Duration(seconds: seconds), () {
      if (!_isConnected &&
          !_disposed &&
          _currentChatUid != null &&
          _currentToken != null) {
        _doConnect();
      }
    });
  }

  void _handleRawMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;
      print(
        '📨 WS received type=$type data=${raw.length > 200 ? raw.substring(0, 200) : raw}',
      );

      if (type == 'presence') {
        _presenceStreamController.add(data);
        final userId = data['user']?['id'] as int?;
        final isOnline = data['online'] as bool? ?? false;
        if (userId != null) onPresenceUpdate?.call(userId, isOnline);
      } else if (type == 'typing') {
        _typingStreamController.add(data);
        final userId = data['user_id'] as int? ?? 0;
        final isTyping = data['is_typing'] as bool? ?? false;
        onTypingIndicator?.call(isTyping, userId);
      } else if (data['content'] != null || data['message_type'] != null) {
        final msg = MessageModel.fromJson(data);
        onMessageReceived?.call(msg);
      } else {
        print('⚠️ WS unknown frame: $data');
      }
    } catch (e) {
      print('❌ WS parse error: $e');
    }
  }

  void sendTypingIndicator({required bool isTyping}) {
    _send({
      'type': 'typing',
      'is_typing': isTyping,
      'chat_uid': _currentChatUid,
    });
  }

  void sendReadReceipt(String messageUid) {
    _send({
      'type': 'read',
      'message_uid': messageUid,
      'chat_uid': _currentChatUid,
    });
  }

  void _send(Map<String, dynamic> payload) {
    if (!isConnected) return;
    try {
      _socket!.add(json.encode(payload));
    } catch (e) {
      print('❌ WS send error: $e');
    }
  }

  /// Soft disconnect — clears room/token so reconnect doesn't auto-restart.
  /// Call this when navigating away or temporarily pausing, NOT on logout.
  /// FIX: removed the old bug where intentional=true set _disposed=false.
  Future<void> disconnect({bool intentional = true}) async {
    _isConnected = false;
    _isConnecting = false;
    if (intentional) {
      _currentChatUid = null;
      _currentToken = null;
      _reconnectAttempts = 0;
    }
    if (_socket != null) {
      try {
        await _socket!.close(WebSocketStatus.normalClosure);
      } catch (_) {}
      _socket = null;
    }
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(false);
    }
  }

  /// Hard dispose — only call when the app is shutting down or user logs out.
  /// After this the singleton should be nulled out so a fresh one is created.
  void dispose() {
    // FIX: set _disposed BEFORE calling disconnect so _scheduleReconnect
    // guards correctly.
    _disposed = true;
    disconnect(intentional: true);
    if (!_connectionStatusController.isClosed)
      _connectionStatusController.close();
    if (!_typingStreamController.isClosed) _typingStreamController.close();
    if (!_presenceStreamController.isClosed) _presenceStreamController.close();
    // Reset the singleton so it can be re-created after logout.
    _instance = null;
  }
}
