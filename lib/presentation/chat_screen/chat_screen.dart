import 'package:flutter/material.dart';

// ---------- Contact List Screen (First Screen) ----------
class ContactListScreen extends StatelessWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Creative header with gradient and search
            Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C5CE7),
                    Color(0xFF8B7BF2),
                    Color(0xFFA29BFE),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
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
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.edit_square,
                            color: Colors.white,
                            size: 26,
                          ),
                          SizedBox(width: 16),
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
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
                  SizedBox(height: 24),
                  // Search bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search contacts...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: Colors.white),
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
                padding: EdgeInsets.all(16),
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
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C5CE7).withOpacity(0.05),
                            blurRadius: 15,
                            offset: Offset(0, 5),
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
                                      color: Color(0xFF00B894),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(width: 16),
                          // Name and last message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  contact.lastMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              if (contact.unreadCount > 0)
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF6C5CE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    contact.unreadCount.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
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
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      // Simulate reply after 1 second
      Future.delayed(Duration(seconds: 1), () {
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
            duration: Duration(milliseconds: 300),
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Chat header with contact info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C5CE7).withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: 8),
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
                              color: Color(0xFF00B894),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.contact.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        Text(
                          widget.contact.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.contact.isOnline
                                ? Color(0xFF00B894)
                                : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 26,
                  ),
                ],
              ),
            ),
            // Messages list - NOW WITH CORRECT ORDER (latest at bottom)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 26,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F3FA),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF8B7BF2)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
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
      margin: EdgeInsets.only(bottom: 12),
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
          if (!message.isMe) SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe ? Color(0xFF6C5CE7) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: message.isMe
                      ? Radius.circular(20)
                      : Radius.circular(4),
                  bottomRight: message.isMe
                      ? Radius.circular(4)
                      : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (message.isMe ? Color(0xFF6C5CE7) : Colors.black)
                        .withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : Color(0xFF2D3436),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message.time,
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
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

// ---------- Dummy Data ----------
final List<Contact> contacts = [
  Contact(
    name: 'Alice Johnson',
    avatar: 'https://i.pravatar.cc/150?img=1',
    lastMessage: 'See you at the meeting!',
    time: '10:35 AM',
    unreadCount: 2,
    isOnline: true,
  ),
  Contact(
    name: 'Bob Smith',
    avatar: 'https://i.pravatar.cc/150?img=2',
    lastMessage: 'Can you send the files?',
    time: '09:20 AM',
    unreadCount: 0,
    isOnline: false,
  ),
  Contact(
    name: 'Carol Davis',
    avatar: 'https://i.pravatar.cc/150?img=3',
    lastMessage: 'Thanks for your help!',
    time: 'Yesterday',
    unreadCount: 5,
    isOnline: true,
  ),
  Contact(
    name: 'David Wilson',
    avatar: 'https://i.pravatar.cc/150?img=4',
    lastMessage: 'Let\'s catch up later',
    time: 'Yesterday',
    unreadCount: 1,
    isOnline: false,
  ),
  Contact(
    name: 'Emma Brown',
    avatar: 'https://i.pravatar.cc/150?img=5',
    lastMessage: 'I love the design!',
    time: 'Monday',
    unreadCount: 0,
    isOnline: true,
  ),
  Contact(
    name: 'Frank Miller',
    avatar: 'https://i.pravatar.cc/150?img=6',
    lastMessage: 'Check this out 🔥',
    time: 'Monday',
    unreadCount: 3,
    isOnline: false,
  ),
  Contact(
    name: 'Grace Lee',
    avatar: 'https://i.pravatar.cc/150?img=8',
    lastMessage: 'Are we still on for today?',
    time: 'Sunday',
    unreadCount: 0,
    isOnline: true,
  ),
  Contact(
    name: 'Henry Garcia',
    avatar: 'https://i.pravatar.cc/150?img=9',
    lastMessage: 'Great work!',
    time: 'Sunday',
    unreadCount: 1,
    isOnline: false,
  ),
];
