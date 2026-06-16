import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/presentation/chat_screen/chat_screen.dart';
import 'package:luminar_std/presentation/widgets/status_screens.dart';
import 'package:luminar_std/repository/chat_list_screen/models/chat.dart';
import 'package:luminar_std/repository/chat_list_screen/service/blocked_users_service.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // ── Search ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    // init() is called by BottomNavScreen on first chat tab tap
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Filter chats by search query ───────────────────────────────────────────
  List<Chat> _filteredChats(List<Chat> chats) {
    final blockedUsers = context.read<BlockedUsersService>();
    final visible = chats.where((chat) {
      if (chat.chatType != ChatType.individual) return true;
      return !blockedUsers.isBlocked(chat.otherParticipant?.id);
    });

    if (_searchQuery.isEmpty) return visible.toList();
    final q = _searchQuery.toLowerCase();
    return visible.where((chat) {
      if (chat.name.toLowerCase().contains(q)) return true;
      final preview = _buildPreviewText(chat).toLowerCase();
      return preview.contains(q);
    }).toList();
  }

  // ── Search bar widget ──────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      margin: EdgeInsets.fromLTRB(
          16, 8, 16, _isSearchFocused || _searchQuery.isNotEmpty ? 16 : 12),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF151E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark
                ? Colors.black.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.08),
            blurRadius: _isSearchFocused ? 12 : 8,
            offset: const Offset(0, 4),
          ),
          if (_isSearchFocused)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              spreadRadius: 2,
            )
        ],
        border: Border.all(
          color: _isSearchFocused
              ? AppColors.primary.withOpacity(0.5)
              : (AppColors.isDark ? AppColors.borderLight : Colors.transparent),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        style: TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search chats…',
          hintStyle: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isSearchFocused
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.7),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _searchFocusNode.unfocus();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
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
    if (chat.unreadCount > 0) provider.zeroChatBadge(chat);
    provider.setActiveChat(chat.uid);

    // Provide a subtle delay to ensure the ripple effect is visible
    Future.delayed(const Duration(milliseconds: 150), () {
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
        provider.setActiveChat(null);
        // Refresh chat list once when returning from chat screen
        provider.loadChats(showLoading: false);
      });
    });
  }

  // ── WebSocket connection indicator ─────────────────────────────────────────
  Widget _buildWsIndicator(bool isConnected) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isConnected
          ? Tooltip(
              key: const ValueKey('online'),
              message: 'Connected',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusActiveBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.statusActive.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.statusActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusActive,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Tooltip(
              key: const ValueKey('offline'),
              message: 'Connecting…',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connecting…',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
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
    final bgColor = AppColors.primary.withOpacity(0.15);
    final bgImage = chat.otherParticipant?.profilePic != null
        ? NetworkImage(chat.otherParticipant!.profilePic!)
        : null;
    final child = Text(
      chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            image: bgImage != null ? DecorationImage(image: bgImage, fit: BoxFit.cover) : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(
              color: AppColors.isDark ? AppColors.whiteWithOpacity10 : Colors.white,
              width: 2,
            )
          ),
          child: bgImage == null ? Center(child: child) : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.statusActive,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.isDark ? AppColors.scaffoldBackground : Colors.white,
                  width: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Stacked Avatar ─────────────────────────────────────────────────────────
  Widget _buildStackedAvatar(Chat chat) {
    final isBatch = chat.chatType == ChatType.batch;
    final color = isBatch ? const Color(0xFFF39C12) : const Color(0xFF8E44AD);
    final icon = isBatch ? Icons.school_rounded : Icons.group_rounded;
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(
                  color: AppColors.isDark ? AppColors.scaffoldBackground : Colors.white,
                  width: 2.5,
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: color.withOpacity(0.6),
                size: 20,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(
                  color: AppColors.isDark ? AppColors.scaffoldBackground : Colors.white,
                  width: 2.5,
                ),
                image: chat.groupIcon != null
                    ? DecorationImage(
                        image: NetworkImage(chat.groupIcon!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: chat.groupIcon == null
                  ? Icon(
                      Icons.groups_rounded,
                      color: color.withOpacity(0.9),
                      size: 24,
                    )
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.isDark ? AppColors.scaffoldBackground : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 10),
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

    if (isDeleted) return '🚫 This message was deleted';

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
          displayContent = '📎 Attachment';
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(provider),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChatProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        boxShadow: [
          if (_isSearchFocused || _searchQuery.isNotEmpty)
             BoxShadow(
              color: AppColors.isDark ? Colors.black12 : Colors.black.withOpacity(0.03),
              offset: const Offset(0, 4),
              blurRadius: 10,
            )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildWsIndicator(provider.isWsConnected),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.isDark
                        ? AppColors.whiteWithOpacity10
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => provider.refresh(),
                    icon: Icon(Icons.refresh_rounded, 
                      color: AppColors.primary, 
                      size: 22
                    ),
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),
          ),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildBody(ChatProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      );
    }

    if (provider.error != null) {
      return NoConnectionScreen(
        message: 'Could not load your chats.',
        onRetry: () => provider.loadChats(),
      );
    }

    final chats = _filteredChats(provider.chats);

    if (provider.chats.isEmpty) {
      return EmptyStateScreen(
        title: 'No Chats Yet',
        message: 'Start a conversation with your peers or mentors.',
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () => provider.loadChats(),
        buttonLabel: 'Refresh Chats',
      );
    }

    if (chats.isEmpty) {
      return EmptyStateScreen(
        title: 'No Matches',
        message: 'We couldn\'t find any chats matching "$_searchQuery".',
        icon: Icons.search_off_rounded,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      onRefresh: () => provider.loadChats(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        physics: const BouncingScrollPhysics(),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return _buildChatTile(chats[index], provider);
        },
      ),
    );
  }

  Widget _buildChatTile(Chat chat, ChatProvider provider) {
    final hasUnread = chat.unreadCount > 0;
    final previewText = _buildPreviewText(chat);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.isDark ? AppColors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark 
                ? Colors.black.withOpacity(0.2) 
                : const Color(0xFF5D6072).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: AppColors.isDark ? AppColors.borderLight.withOpacity(0.3) : Colors.transparent,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          onTap: () => _onChatTap(chat),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(chat, provider.userOnlineStatus),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (previewText.isNotEmpty)
                        Text(
                          previewText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            color: hasUnread
                                ? (AppColors.isDark ? Colors.white : Colors.black87)
                                : AppColors.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        )
                      else
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatMessageTime(chat.lastMessageAt ?? chat.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUnread
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.8),
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasUnread)
                      Container(
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          chat.unreadCount > 99
                              ? '99+'
                              : chat.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 24, width: 24), // Placeholder to maintain height
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
