import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/presentation/chat_screen/chat_screen.dart';
import 'package:luminar_std/repository/chat_list_screen/models/chat.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().init();
    });
  }

  // ── Time formatting ────────────────────────────────────────────────────────
  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final local = time.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) {
      final h = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final m = local.minute.toString().padLeft(2, '0');
      final p = local.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[local.weekday - 1];
    } else {
      final dd = local.day.toString().padLeft(2, '0');
      final mm = local.month.toString().padLeft(2, '0');
      final yy = local.year.toString().substring(2);
      return '$dd/$mm/$yy';
    }
  }

  // ── Chat tile tap handler ──────────────────────────────────────────────────
  void _onChatTap(Chat chat) {
    final provider = context.read<ChatProvider>();

    if (chat.unreadCount > 0) {
      provider.markChatAsRead(chat);
    }

    // Tell the provider which chat is open so incoming messages
    // for THIS chat don't increment the unread badge while viewing
    provider.setActiveChat(chat.uid);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chat: chat,
          currentUser: provider.currentUser!,
          websocketUrl: "${provider.webSocketService!.url}",
          apiService: provider.apiService!,
          webSocketService: provider.webSocketService,
        ),
      ),
    ).then((_) {
      // User left the chat screen — clear active chat so unread
      // resumes incrementing for that chat normally
      provider.setActiveChat(null);
    });
  }

  // ── WebSocket connection indicator ───────────────────────────────────────────
  Widget _buildWsIndicator(bool isConnected) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isConnected
          ? Tooltip(
              key: const ValueKey('online'),
              message: 'Connected',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            )
          : Tooltip(
              key: const ValueKey('offline'),
              message: 'Connecting…',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Connecting…',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(Chat chat, Map<int, bool> onlineStatus) {
    if (chat.chatType != ChatType.individual) {
      return _buildStackedAvatar(chat);
    }

    final isOnline =
        chat.otherParticipant != null &&
        onlineStatus[chat.otherParticipant!.id] == true;

    final bgColor = const Color(0xFF7B9FD4);
    final bgImage = chat.otherParticipant?.profilePic != null
        ? NetworkImage(chat.otherParticipant!.profilePic!)
        : null;
    final child = Text(
      chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: bgColor,
          backgroundImage: bgImage,
          child: bgImage == null ? child : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF4F6FB), width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ── Stacked Avatar for Groups/Batches ──────────────────────────────────────
  Widget _buildStackedAvatar(Chat chat) {
    final isBatch = chat.chatType == ChatType.batch;
    final color = isBatch ? Colors.orange : Colors.purple;
    final icon = isBatch ? Icons.school : Icons.group;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
          // Background circle (offset to bottom-right)
          Positioned(
            right: 2,
            bottom: 6,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                Icons.person_outline_rounded,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ),
          ),
          // Foreground circle (offset to top-left)
          Positioned(
            left: 0,
            top: 2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF4F6FB), width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                backgroundImage:
                    chat.groupIcon != null
                        ? NetworkImage(chat.groupIcon!)
                        : null,
                child:
                    chat.groupIcon == null
                        ? Icon(
                          Icons.person_rounded,
                          color: color.withOpacity(0.8),
                          size: 22,
                        )
                        : null,
              ),
            ),
          ),
          // Group/Batch icon badge (bottom-right corner)
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF4F6FB), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat type badge ────────────────────────────────────────────────────────
  Widget _buildTypeBadge(Chat chat) {
    if (chat.chatType == ChatType.individual) return const SizedBox.shrink();

    final isBatch = chat.chatType == ChatType.batch;
    final color = isBatch ? Colors.orange : Colors.purple;
    final icon = isBatch ? Icons.school_outlined : Icons.group_outlined;
    final label = isBatch
        ? (chat.batchName ?? 'Batch')
        : (chat.groupName ?? 'Group');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.shade700),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Last message preview text ──────────────────────────────────────────────
  String _buildPreviewText(Chat chat) {
    final preview = chat.lastMessagePreview;
    if (preview == null) return '';

    final content = preview['content'] as String? ?? '';
    final sender = preview['sender'] as String? ?? '';
    final isGroupOrBatch =
        chat.chatType == ChatType.group || chat.chatType == ChatType.batch;

    if (isGroupOrBatch && sender.isNotEmpty && content.isNotEmpty) {
      return '$sender: $content';
    }
    return content;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              'Chats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 8),
            _buildWsIndicator(provider.isWsConnected),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => provider.refresh(),
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(ChatProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B9FD4)),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load chats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => provider.loadChats(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B9FD4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7B9FD4),
      onRefresh: () => provider.loadChats(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.chats.length,
        itemBuilder: (context, index) =>
            _buildChatTile(provider.chats[index], provider),
      ),
    );
  }

  Widget _buildChatTile(Chat chat, ChatProvider provider) {
    final hasUnread = chat.unreadCount > 0;
    final previewText = _buildPreviewText(chat);
    final isIndividual = chat.chatType == ChatType.individual;
    final isOnline =
        isIndividual &&
        chat.otherParticipant != null &&
        provider.userOnlineStatus[chat.otherParticipant!.id] == true;

    return InkWell(
      onTap: () => _onChatTap(chat),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar ─────────────────────────────────────────────────
            _buildAvatar(chat, provider.userOnlineStatus),
            const SizedBox(width: 12),

            // ── Name + preview / online status ──────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      if (chat.chatType != ChatType.individual) ...[
                        const SizedBox(width: 6),
                        _buildTypeBadge(chat),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Show "Online" when active, otherwise show last message preview
                  if (isOnline)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else if (previewText.isNotEmpty)
                    Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread
                            ? const Color(0xFF1A1A2E)
                            : Colors.grey.shade500,
                        fontWeight: hasUnread
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    )
                  else
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Time + unread badge ─────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMessageTime(chat.lastMessageAt ?? chat.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread
                        ? const Color(0xFF7B9FD4)
                        : Colors.grey.shade400,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 5),
                if (hasUnread)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B9FD4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      chat.unreadCount > 99
                          ? '99+'
                          : chat.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
