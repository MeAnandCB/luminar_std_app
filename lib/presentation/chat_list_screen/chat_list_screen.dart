import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/presentation/chat_screen/chat_screen.dart';
import 'package:luminar_std/presentation/widgets/status_screens.dart';
import 'package:luminar_std/repository/chat_list_screen/models/chat.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // ── Search ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filter chats by search query ───────────────────────────────────────────
  List<Chat> _filteredChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) return chats;
    final q = _searchQuery.toLowerCase();
    return chats.where((chat) {
      if (chat.name.toLowerCase().contains(q)) return true;
      final preview = _buildPreviewText(chat).toLowerCase();
      return preview.contains(q);
    }).toList();
  }

  // ── Search bar widget ──────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search chats…',
          hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.scaffoldBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
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
    if (chat.unreadCount > 0) provider.markChatAsRead(chat);
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
    ).then((_) => provider.setActiveChat(null));
  }

  // ── WebSocket connection indicator ─────────────────────────────────────────
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
                      color: AppColors.statsGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.statsGreen,
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
                      color: AppColors.textSecondary.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Connecting…',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withOpacity(0.6),
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
    final bgColor = AppColors.primary.withOpacity(0.2);
    final bgImage = chat.otherParticipant?.profilePic != null
        ? NetworkImage(chat.otherParticipant!.profilePic!)
        : null;
    final child = Text(
      chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
      style: TextStyle(
        color: AppColors.primary,
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
                color: AppColors.statsGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBackground, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ── Stacked Avatar ─────────────────────────────────────────────────────────
  Widget _buildStackedAvatar(Chat chat) {
    final isBatch = chat.chatType == ChatType.batch;
    final color = isBatch ? Colors.orange : Colors.purple;
    final icon = isBatch ? Icons.school : Icons.group;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        children: [
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
          Positioned(
            left: 0,
            top: 2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBackground, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                backgroundImage: chat.groupIcon != null
                    ? NetworkImage(chat.groupIcon!)
                    : null,
                child: chat.groupIcon == null
                    ? Icon(
                        Icons.person_rounded,
                        color: color.withOpacity(0.8),
                        size: 22,
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBackground, width: 2),
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
        color: AppColors.isDark ? color.withOpacity(0.2) : color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.isDark ? color.withOpacity(0.4) : color.shade200,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: AppColors.isDark ? color.shade200 : color.shade700,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.isDark ? color.shade200 : color.shade700,
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

    final type = preview['message_type']?.toString() ?? 'text';
    final content = preview['content'] as String? ?? '';
    final sender = preview['sender'] as String? ?? '';
    final isDeleted = preview['is_deleted'] == true;

    if (isDeleted) return 'Message deleted';

    String displayContent = content;

    // Replace filenames with user-friendly descriptions for media
    if (type != 'text') {
      switch (type) {
        case 'image':
          displayContent = '📷 Photo';
          break;
        case 'audio':
          displayContent = '🎤 Voice message';
          break;
        case 'video':
          displayContent = '🎬 Video';
          break;
        case 'file':
          displayContent = '📎 File';
          break;
      }
    }

    final isGroupOrBatch =
        chat.chatType == ChatType.group || chat.chatType == ChatType.batch;
    if (isGroupOrBatch && sender.isNotEmpty) {
      return '$sender: $displayContent';
    }
    return displayContent;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        shadowColor: AppColors.shadowLight,
        titleSpacing: 16,
        title: Row(
          children: [
            Text(
              'Chats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            _buildWsIndicator(provider.isWsConnected),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => provider.refresh(),
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 4),
        ],
        // ── Search bar pinned below the title row ──────────────────────
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildSearchBar(),
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(ChatProvider provider) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.error != null) {
      return NoConnectionScreen(
        message: 'Could not load your chats.',
        onRetry: () => provider.loadChats(),
      );
    }

    final chats = _filteredChats(provider.chats); // ← apply search filter

    if (provider.chats.isEmpty) {
      return EmptyStateScreen(
        title: 'No Chats Yet',
        message: 'Start a conversation with your peers or mentors.',
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () => provider.loadChats(),
        buttonLabel: 'Refresh Chats',
      );
    }

    // Empty search results state
    if (chats.isEmpty) {
      return EmptyStateScreen(
        title: 'No Matches',
        message: 'We couldn\'t find any chats matching "$_searchQuery".',
        icon: Icons.search_off_rounded,
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7B9FD4),
      onRefresh: () => provider.loadChats(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        itemBuilder: (context, index) => _buildChatTile(chats[index], provider),
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          endIndent: 16,
          color: Color.fromARGB(255, 236, 236, 236),
        ),
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
            _buildAvatar(chat, provider.userOnlineStatus),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // if (chat.chatType != ChatType.individual) ...[
                      //   const SizedBox(width: 6),
                      //   _buildTypeBadge(chat),
                      // ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (isOnline)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.statsGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.statsGreen,
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
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
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
                      color: AppColors.primary,
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
