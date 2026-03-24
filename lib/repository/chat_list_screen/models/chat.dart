import 'user.dart';

enum ChatType { individual, group, batch }

class Chat {
  final String uid;
  final ChatType chatType;
  final int? participant1;
  final int? participant2;
  final String? batch;
  final String? batchName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final Map<String, dynamic>? lastMessagePreview;
  final int unreadCount;
  final User? otherParticipant;
  final bool isActive;
  final bool isArchived;
  final String? groupName;
  final String? groupDescription;
  final String? groupIcon;

  Chat({
    required this.uid,
    required this.chatType,
    this.participant1,
    this.participant2,
    this.batch,
    this.batchName,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadCount,
    this.otherParticipant,
    required this.isActive,
    required this.isArchived,
    this.groupName,
    this.groupDescription,
    this.groupIcon,
  });

  String get name {
    switch (chatType) {
      case ChatType.individual:
        return otherParticipant?.fullName ?? 'Unknown';
      case ChatType.batch:
        return batchName ?? 'Batch Chat';
      case ChatType.group:
        return groupName ?? 'Group Chat';
    }
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    ChatType type;
    switch (json['chat_type']) {
      case 'individual':
        type = ChatType.individual;
        break;
      case 'batch':
        type = ChatType.batch;
        break;
      default:
        type = ChatType.group;
    }

    return Chat(
      uid: json['uid']?.toString() ?? '',
      chatType: type,
      participant1: json['participant_1'],
      participant2: json['participant_2'],
      batch: json['batch']?.toString(),
      batchName: json['batch_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      lastMessagePreview: json['last_message_preview'],
      unreadCount: json['unread_count'] ?? 0,
      otherParticipant: json['other_participant'] != null
          ? User.fromJson(json['other_participant'])
          : null,
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      groupName: json['group_name'],
      groupDescription: json['group_description'],
      groupIcon: json['group_icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'chat_type': chatType == ChatType.individual
          ? 'individual'
          : chatType == ChatType.batch
          ? 'batch'
          : 'group',
      'participant_1': participant1,
      'participant_2': participant2,
      'batch': batch,
      'batch_name': batchName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_preview': lastMessagePreview,
      'unread_count': unreadCount,
      'other_participant': otherParticipant?.toJson(),
      'is_active': isActive,
      'is_archived': isArchived,
      'group_name': groupName,
      'group_description': groupDescription,
      'group_icon': groupIcon,
    };
  }
}
