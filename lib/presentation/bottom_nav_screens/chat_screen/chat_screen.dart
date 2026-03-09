import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/app_text_styles.dart';

// ---------- Contact List Screen (First Screen) ----------
class ContactListScreen extends StatelessWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Creative header with gradient and search
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.splashGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Messages',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 34,
                          color: AppColors.white,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_square,
                            color: AppColors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?img=7',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.whiteWithOpacity20,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: AppColors.whiteWithOpacity80,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search contacts...',
                              hintStyle: TextStyle(
                                color: AppColors.whiteWithOpacity80,
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contact list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(contact: contact),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar with online indicator
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(contact.avatar),
                              ),
                              if (contact.isOnline)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.statsGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Name and last message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: AppTextStyles.headerName,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contact.lastMessage,
                                  style: AppTextStyles.activitySubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Time and unread badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                contact.time,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (contact.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    contact.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Chat Screen (Second Screen) ----------
class ChatScreen extends StatefulWidget {
  final Contact contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(text: 'Hey! How are you?', isMe: false, time: '10:30 AM'),
    ChatMessage(
      text: 'I\'m good! Thanks for asking. How about you?',
      isMe: true,
      time: '10:32 AM',
    ),
    ChatMessage(
      text: 'Doing great! Ready for the meeting later?',
      isMe: false,
      time: '10:33 AM',
    ),
    ChatMessage(
      text: 'Absolutely! I\'ve prepared everything.',
      isMe: true,
      time: '10:34 AM',
    ),
    ChatMessage(
      text: 'Perfect! See you then 👋',
      isMe: false,
      time: '10:35 AM',
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(text: _messageController.text, isMe: true, time: 'Now'),
        );
        _messageController.clear();
      });

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      // Simulate reply after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Thanks for your message!',
              isMe: false,
              time: 'Now',
            ),
          );
        });
        // Scroll to bottom for reply
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Chat header with contact info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(widget.contact.avatar),
                      ),
                      if (widget.contact.isOnline)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.statsGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
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
                          widget.contact.name,
                          style: AppTextStyles.headerName,
                        ),
                        Text(
                          widget.contact.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.contact.isOnline
                                ? AppColors.statsGreen
                                : AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ],
              ),
            ),
            // Messages list - NOW WITH CORRECT ORDER (latest at bottom)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                // No reverse, just normal order - index 0 at top, last at bottom
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            // Message input bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3FA),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: AppColors.textHint),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.contact.avatar),
            ),
          if (!message.isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isMe
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (message.isMe ? AppColors.primary : Colors.black)
                        .withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe
                          ? AppColors.white
                          : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: TextStyle(
                      color: message.isMe
                          ? AppColors.whiteWithOpacity70
                          : AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Data Models ----------
class Contact {
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  Contact({
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

// ---------- Dummy Data with Malayali Names and Actor Photos ----------
final List<Contact> contacts = [
  Contact(
    name: 'Mohanlal',
    avatar:
        'https://i.pinimg.com/1200x/e3/5a/0c/e35a0cfa1b0589435cf6f9f11a94adec.jpg',
    lastMessage: 'See you at the meeting!',
    time: '10:35 AM',
    unreadCount: 2,
    isOnline: true,
  ),
  Contact(
    name: 'Mammootty',
    avatar:
        'https://i.pinimg.com/736x/08/8c/8d/088c8dd53c224f9be9b8fbe0242be9b9.jpg',
    lastMessage: 'Can you send the files?',
    time: '09:20 AM',
    unreadCount: 0,
    isOnline: false,
  ),
  Contact(
    name: 'Prithviraj Sukumaran',
    avatar:
        'https://i.pinimg.com/736x/db/39/82/db39829124de844351f27564a9082c9e.jpg',
    lastMessage: 'Thanks for your help!',
    time: 'Yesterday',
    unreadCount: 5,
    isOnline: true,
  ),
  Contact(
    name: 'Dulquer Salmaan',
    avatar:
        'https://i.pinimg.com/736x/ef/12/cf/ef12cf0805412a6be140bf8fbac71525.jpg',
    lastMessage: 'Let\'s catch up later',
    time: 'Yesterday',
    unreadCount: 1,
    isOnline: false,
  ),
  Contact(
    name: 'Fahadh Faasil',
    avatar:
        'https://i.pinimg.com/736x/12/83/9e/12839e3cc64a06ac851ba5b5f6aa2618.jpg',
    lastMessage: 'I love the design!',
    time: 'Monday',
    unreadCount: 0,
    isOnline: true,
  ),
  Contact(
    name: 'Nivin Pauly',
    avatar:
        'https://i.pinimg.com/736x/96/c5/69/96c5699942db9322fee68eea8b53ec82.jpg',
    lastMessage: 'Check this out 🔥',
    time: 'Monday',
    unreadCount: 3,
    isOnline: false,
  ),
  Contact(
    name: 'Manju Warrier',
    avatar:
        'https://i.pinimg.com/736x/2c/a2/c9/2ca2c9f77bd42eea91f0e66120ffa33f.jpg',
    lastMessage: 'Are we still on for today?',
    time: 'Sunday',
    unreadCount: 0,
    isOnline: true,
  ),
  Contact(
    name: 'Nazriya Nazim',
    avatar:
        'https://i.pinimg.com/1200x/09/da/bf/09dabf991fb2d07b6d377d74728d3e95.jpg',
    lastMessage: 'Great work!',
    time: 'Sunday',
    unreadCount: 1,
    isOnline: false,
  ),
];
