import 'package:flutter/material.dart';
import 'package:luminar_std/core/constants/app_endpoints.dart';
import 'package:luminar_std/core/services/api_services.dart';
import 'package:luminar_std/repository/chat_list_screen/models/chat.dart';
import 'package:luminar_std/repository/chat_list_screen/models/message.dart';
import 'package:luminar_std/repository/chat_list_screen/service/api_service.dart';

// ── Forward result returned to the caller ─────────────────────────────────────
class ForwardResult {
  final bool success;
  final String? error;
  const ForwardResult({required this.success, this.error});
}

// ── Forward API service (bulk endpoint) ───────────────────────────────────────
class ForwardMessageService {
  final ChatApiService apiService;
  final ApiService _apiService = ApiService();

  ForwardMessageService({required this.apiService});

  Future<ForwardResult> forwardMessage({
    required Message message,
    required List<Chat> selectedChats,
  }) async {
    final chatUids = selectedChats.map((c) => c.uid).toList();
    final userIds = selectedChats
        .where(
          (c) =>
              c.chatType == ChatType.individual && c.otherParticipant != null,
        )
        .map((c) => c.otherParticipant!.id)
        .toSet()
        .toList();

    final body = <String, dynamic>{
      'chat_uids': chatUids,
      'batch_uids': <String>[],
      'user_ids': userIds,
      'content': _resolveForwardContent(message),
      'message_type': message.isImage
          ? 'image'
          : message.isAudio
          ? 'audio'
          : message.isFile
          ? 'file'
          : 'text',
    };

    if (message.mediaUrl != null) {
      body['attachment_url'] = message.mediaUrl;
      body['file'] = message.mediaUrl;
      body['file_url'] = message.mediaUrl;
      body['file_name'] = message.fileName ?? '';
    }

    final response = await _apiService.post(
      endpoint: AppEndpoints.bulkMessage,
      token: apiService.token,
      body: body,
    );

    if (response.success) {
      return const ForwardResult(success: true);
    }
    return ForwardResult(
      success: false,
      error: response.message ?? 'Unknown error',
    );
  }

  String _resolveForwardContent(Message message) {
    if (message.isImage) {
      return message.content.isNotEmpty ? message.content : '📷 Photo';
    }
    if (message.isAudio) return message.fileName ?? '🎤 Voice message';
    if (message.isFile) return message.fileName ?? '📎 File';
    return message.content;
  }
}


// ── Forward Sheet ─────────────────────────────────────────────────────────────
class ForwardMessageSheet extends StatefulWidget {
  final Message message;
  final List<Chat> allChats;
  final ChatApiService apiService;

  const ForwardMessageSheet({
    super.key,
    required this.message,
    required this.allChats,
    required this.apiService,
  });

  @override
  State<ForwardMessageSheet> createState() => _ForwardMessageSheetState();
}

class _ForwardMessageSheetState extends State<ForwardMessageSheet>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedUids = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSending = false;
  late ForwardMessageService _forwardService;

  @override
  void initState() {
    super.initState();
    _forwardService = ForwardMessageService(apiService: widget.apiService);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Chat> get _filteredChats {
    if (_searchQuery.isEmpty) return widget.allChats;
    return widget.allChats
        .where((c) => c.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _toggleChat(String uid) {
    setState(() {
      if (_selectedUids.contains(uid)) {
        _selectedUids.remove(uid);
      } else {
        _selectedUids.add(uid);
      }
    });
  }

  Future<void> _send() async {
    if (_selectedUids.isEmpty || _isSending) return;
    setState(() => _isSending = true);

    final selected = widget.allChats
        .where((c) => _selectedUids.contains(c.uid))
        .toList();

    final result = await _forwardService.forwardMessage(
      message: widget.message,
      selectedChats: selected,
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    Navigator.pop(context, result);
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(Chat chat) {
    Widget child;
    Color bgColor;
    ImageProvider? bgImage;

    if (chat.chatType == ChatType.individual) {
      bgColor = const Color(0xFF7B9FD4);
      bgImage = chat.otherParticipant?.profilePic != null
          ? NetworkImage(chat.otherParticipant!.profilePic!)
          : null;
      child = Text(
        chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (chat.chatType == ChatType.batch) {
      bgColor = Colors.orange.shade100;
      bgImage = null;
      child = Icon(Icons.school, color: Colors.orange.shade700, size: 20);
    } else {
      bgColor = Colors.purple.shade100;
      bgImage = chat.groupIcon != null ? NetworkImage(chat.groupIcon!) : null;
      child = Icon(Icons.group, color: Colors.purple.shade700, size: 20);
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: bgColor,
      backgroundImage: bgImage,
      child: bgImage == null ? child : null,
    );
  }

  String _subtitleFor(Chat chat) {
    if (chat.chatType == ChatType.individual) return 'Individual chat';
    if (chat.chatType == ChatType.batch)
      return 'Batch · ${chat.batchName ?? ""}';
    return 'Group · ${chat.groupName ?? ""}';
  }

  // ── Message preview card ───────────────────────────────────────────────────
  Widget _buildMessagePreview() {
    final msg = widget.message;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FD4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          if (msg.isImage && msg.mediaUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                msg.mediaUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      msg.isImage
                          ? Icons.image_outlined
                          : msg.isAudio
                          ? Icons.mic_outlined
                          : msg.isFile
                          ? Icons.attach_file_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: const Color(0xFF7B9FD4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      msg.isImage
                          ? 'Photo'
                          : msg.isAudio
                          ? 'Voice message'
                          : msg.isFile
                          ? 'File'
                          : 'Message',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7B9FD4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  msg.isImage
                      ? (msg.content.isNotEmpty ? msg.content : '📷 Photo')
                      : msg.isAudio
                      ? (msg.fileName ?? '🎤 Voice message')
                      : msg.isFile
                      ? (msg.fileName ?? '📎 File')
                      : msg.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredChats;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.forward_rounded,
                  color: Color(0xFF7B9FD4),
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Forward Message',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                if (_selectedUids.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B9FD4).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedUids.length} selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B9FD4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Message preview
          _buildMessagePreview(),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: 'Search chats…',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                ),
              ),
            ),
          ),

          // Chat list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.38,
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: Colors.grey.shade300,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No chats found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final chat = filtered[index];
                      final isSelected = _selectedUids.contains(chat.uid);

                      return InkWell(
                        onTap: () => _toggleChat(chat.uid),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7B9FD4).withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(
                                      0xFF7B9FD4,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Avatar with overlay when selected
                              Stack(
                                children: [
                                  _buildAvatar(chat),
                                  if (isSelected)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF7B9FD4,
                                          ).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _subtitleFor(chat),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Animated check circle
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: isSelected
                                    ? Container(
                                        key: const ValueKey('checked'),
                                        width: 26,
                                        height: 26,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF7B9FD4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      )
                                    : Container(
                                        key: const ValueKey('unchecked'),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Selected chips strip
          if (_selectedUids.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _selectedUids.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final uid = _selectedUids.elementAt(index);
                  final chat = widget.allChats.firstWhere((c) => c.uid == uid);
                  return GestureDetector(
                    onTap: () => _toggleChat(uid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B9FD4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF7B9FD4).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chat.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4A7FA5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF4A7FA5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Send button
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_selectedUids.isEmpty || _isSending) ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedUids.isEmpty
                      ? Colors.grey.shade200
                      : const Color(0xFF7B9FD4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedUids.isEmpty
                                ? 'Select a chat to forward'
                                : 'Forward to ${_selectedUids.length} chat${_selectedUids.length > 1 ? "s" : ""}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _selectedUids.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Convenience function ───────────────────────────────────────────────────────
Future<ForwardResult?> showForwardSheet({
  required BuildContext context,
  required Message message,
  required List<Chat> allChats,
  required ChatApiService apiService,
}) {
  return showModalBottomSheet<ForwardResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ForwardMessageSheet(
        message: message,
        allChats: allChats,
        apiService: apiService,
      ),
    ),
  );
}
