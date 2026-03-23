import 'dart:async';
import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/bottom_nav_screens/message_screen/controller/controller/controller.dart';
import 'package:luminar_std/repository/message_screen/model/message_screen_models.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatListScreen — unchanged, kept here for completeness
// ─────────────────────────────────────────────────────────────────────────────
class ChatListScreen extends StatefulWidget {
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late ChatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<ChatProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.loadChats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.deepPurple,
        actions: [
          StreamBuilder<bool>(
            stream: _provider.webSocketService.connectionStatusStream,
            initialData: _provider.isWebSocketConnected,
            builder: (_, snap) {
              final live = snap.data ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: live ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      live ? 'Live' : 'Offline',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _provider.chatsStream,
        initialData: _provider.chats,
        builder: (context, snapshot) {
          final chats = snapshot.data ?? [];

          if (_provider.isLoading && chats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.error != null && chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${_provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _provider.loadChats(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No chats yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _provider.loadChats(),
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) =>
                  _ChatTile(chat: chats[index], provider: _provider),
            ),
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final ChatProvider provider;
  const _ChatTile({required this.chat, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.shade100,
            radius: 24,
            child: Text(
              chat.otherParticipant.fullName[0].toUpperCase(),
              style: const TextStyle(color: Colors.deepPurple, fontSize: 18),
            ),
          ),
          if (provider.isUserOnline(chat.otherParticipant.id))
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat.otherParticipant.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.lastMessagePreview?.content ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
          fontWeight: chat.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageAt != null)
            Text(
              _formatTime(chat.lastMessageAt!),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        provider.setCurrentChat(chat);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(chatUid: chat.uid)),
        ).then((_) => provider.loadChats());
      },
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatScreen
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String chatUid;
  const ChatScreen({Key? key, required this.chatUid}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late ChatProvider _provider;
  StreamSubscription? _scrollSub;
  StreamSubscription? _typingSub;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<ChatProvider>(context, listen: false);

    // THE KEY FIX: Register this screen's chatUid with the provider
    // immediately on mount. This is what makes _onIncomingMessage route
    // incoming WS messages to this screen's message list. Without this,
    // _activeChatUid stays null inside the provider and all messages are
    // silently dropped for bottom-nav ChatScreens.
    _provider.registerActiveChatUid(widget.chatUid);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _provider.loadMessages(widget.chatUid);
    });

    // Subscribe only to scrollStream (void events), not messagesStream.
    // This avoids spurious scroll jumps when chat-list badges update.
    _scrollSub = _provider.scrollStream.listen((_) => _scrollToBottom());

    _typingSub = _provider.webSocketService.typingStream.listen((data) {
      final userId = data['user_id'] as int?;
      final isTyping = data['is_typing'] as bool? ?? false;
      if (_provider.currentChat?.otherParticipant.id == userId) {
        _provider.updateTypingStatus(isTyping);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent > 0) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    if (_isTyping) {
      _provider.sendTypingIndicator(false);
      setState(() => _isTyping = false);
    }
    // Pass chatUid explicitly so sendMessage works even if _currentChat
    // was never set (bottom-nav pattern).
    await _provider.sendMessage(text, chatUid: widget.chatUid);
  }

  void _onTypingChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _provider.sendTypingIndicator(true);
      setState(() => _isTyping = true);
    } else if (text.isEmpty && _isTyping) {
      _provider.sendTypingIndicator(false);
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: ListenableBuilder(
          listenable: _provider,
          builder: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _provider.currentChat?.otherParticipant.fullName ?? 'Chat',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              StreamBuilder<bool>(
                stream: _provider.webSocketService.connectionStatusStream,
                initialData: _provider.isWebSocketConnected,
                builder: (_, snap) => Text(
                  (snap.data ?? false) ? 'Online' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 12,
                    color: (snap.data ?? false)
                        ? Colors.greenAccent
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _provider.messagesStream,
              initialData: _provider.messages,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                if (_provider.isLoadingMessages && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Say hello!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = _provider.isCurrentUser(msg.sender.id);
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Typing indicator — driven by notifyListeners, lightweight.
          ListenableBuilder(
            listenable: _provider,
            builder: (_, __) {
              if (!_provider.isOtherUserTyping) return const SizedBox.shrink();
              return _TypingIndicator(
                name:
                    _provider.currentChat?.otherParticipant.fullName ?? 'User',
              );
            },
          ),

          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              onChanged: _onTypingChanged,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollSub?.cancel();
    _typingSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    // Unregister so the provider stops routing messages to this screen.
    _provider.unregisterActiveChatUid();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MessageBubble
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64 : 12,
        right: isMe ? 12 : 64,
        top: 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                message.sender.fullName,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.deepPurple : Colors.grey.shade200,
              borderRadius: isMe
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white60 : Colors.grey.shade500,
                      ),
                    ),
                    if (isMe) ...[const SizedBox(width: 4), _statusIcon()],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(Colors.white60),
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.white60);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.white60);
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.lightBlueAccent,
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: Colors.redAccent,
        );
    }
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(t.year, t.month, t.day);
    if (msgDay == today) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    } else if (msgDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(t).inDays < 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];
    }
    return '${t.day}/${t.month}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypingIndicator
// ─────────────────────────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  final String name;
  const _TypingIndicator({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            '$name is typing',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 6),
          const _DotsAnimation(),
        ],
      ),
    );
  }
}

class _DotsAnimation extends StatefulWidget {
  const _DotsAnimation();
  @override
  State<_DotsAnimation> createState() => _DotsAnimationState();
}

class _DotsAnimationState extends State<_DotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
    _anims = List.generate(3, (i) {
      final s = i * 0.2;
      final e = (s + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(s, e, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      3,
      (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Opacity(
          opacity: _anims[i].value,
          child: Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
