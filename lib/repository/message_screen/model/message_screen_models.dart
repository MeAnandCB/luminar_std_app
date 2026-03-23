class ChatModel {
  final String uid;
  final int id;
  final String chatType;
  final int participant1;
  final int participant2;
  final dynamic batch;
  final String? batchName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final LastMessagePreview? lastMessagePreview;
  final int unreadCount;
  final OtherParticipant otherParticipant;
  final bool isActive;
  final bool isArchived;
  final String? groupName;
  final String? groupDescription;
  final String? groupIcon;

  ChatModel({
    required this.uid,
    required this.id,
    required this.chatType,
    required this.participant1,
    required this.participant2,
    this.batch,
    this.batchName,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadCount,
    required this.otherParticipant,
    required this.isActive,
    required this.isArchived,
    this.groupName,
    this.groupDescription,
    this.groupIcon,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Try to get ID from various possible fields
    int chatId = 0;
    if (json['id'] != null) {
      chatId = json['id'];
    } else if (json['chat_id'] != null) {
      chatId = json['chat_id'];
    }

    return ChatModel(
      uid: json['uid'] ?? '',
      id: chatId,
      chatType: json['chat_type'] ?? 'individual',
      participant1: json['participant_1'] ?? 0,
      participant2: json['participant_2'] ?? 0,
      batch: json['batch'],
      batchName: json['batch_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
      lastMessagePreview: json['last_message_preview'] != null
          ? LastMessagePreview.fromJson(json['last_message_preview'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      otherParticipant: json['other_participant'] != null
          ? OtherParticipant.fromJson(json['other_participant'])
          : OtherParticipant(
              id: 0,
              fullName: 'Unknown',
              email: '',
              profilePic: null,
            ),
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      groupName: json['group_name'],
      groupDescription: json['group_description'],
      groupIcon: json['group_icon'],
    );
  }
}

// Add this class - LastMessagePreview
class LastMessagePreview {
  final String content;
  final String sender;
  final String messageType;
  final bool isDeleted;
  final DateTime createdAt;

  LastMessagePreview({
    required this.content,
    required this.sender,
    required this.messageType,
    required this.isDeleted,
    required this.createdAt,
  });

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) {
    return LastMessagePreview(
      content: json['content'] ?? '',
      sender: json['sender'] ?? '',
      messageType: json['message_type'] ?? 'text',
      isDeleted: json['is_deleted'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'sender': sender,
      'message_type': messageType,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// OtherParticipant class
class OtherParticipant {
  final int id;
  final String fullName;
  final String email;
  final String? profilePic;

  OtherParticipant({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePic,
  });

  factory OtherParticipant.fromJson(Map<String, dynamic> json) {
    return OtherParticipant(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? 'Unknown',
      email: json['email'] ?? '',
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_pic': profilePic,
    };
  }
}

class MessageModel {
  final String uid;
  final int chat; // This is the chat ID (integer)
  final Sender sender;
  final String messageType;
  final String content;
  final dynamic file;
  final String? fileName;
  final dynamic fileSize;
  final String? fileUrl;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final dynamic replyTo;
  final dynamic replyToContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic> readBy;
  bool isSending;
  MessageStatus status;

  MessageModel({
    required this.uid,
    required this.chat,
    required this.sender,
    required this.messageType,
    required this.content,
    this.file,
    this.fileName,
    this.fileSize,
    this.fileUrl,
    required this.isEdited,
    this.editedAt,
    required this.isDeleted,
    this.deletedAt,
    this.replyTo,
    this.replyToContent,
    required this.createdAt,
    required this.updatedAt,
    required this.readBy,
    this.isSending = false,
    this.status = MessageStatus.sent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      uid: json['uid'] ?? '',
      chat: json['chat'] is int
          ? json['chat']
          : int.tryParse(json['chat'].toString()) ?? 0,
      sender: json['sender'] != null
          ? Sender.fromJson(json['sender'])
          : Sender(id: 0, fullName: 'Unknown', email: '', profilePic: null),
      messageType: json['message_type'] ?? 'text',
      content: json['content'] ?? '',
      file: json['file'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      fileUrl: json['file_url'],
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'])
          : null,
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
      replyTo: json['reply_to'],
      replyToContent: json['reply_to_content'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      readBy: json['read_by'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'chat': chat,
      'sender': sender.toJson(),
      'message_type': messageType,
      'content': content,
      'file': file,
      'file_name': fileName,
      'file_size': fileSize,
      'file_url': fileUrl,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'reply_to': replyTo,
      'reply_to_content': replyToContent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'read_by': readBy,
    };
  }

  Map<String, dynamic> toWebSocketJson() {
    return {
      'chat_uid': chat, // Use chat ID (integer) not the string UID
      'content': content,
      'message_type': messageType,
      'reply_to': replyTo,
    };
  }
}

// Sender class - Add this right after MessageModel
class Sender {
  final int id;
  final String fullName;
  final String email;
  final String? profilePic;

  Sender({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePic,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? 'Unknown',
      email: json['email'] ?? '',
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_pic': profilePic,
    };
  }
}

// MessageStatus enum
enum MessageStatus { sending, sent, delivered, read, failed }
