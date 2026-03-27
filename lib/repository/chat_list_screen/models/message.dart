import 'package:luminar_std/core/utils/app_utils.dart';
import 'user.dart';

class Message {
  final String uid;
  final int chatId;
  final User sender;
  final String messageType; // 'text' | 'image' | 'video' | 'file' | 'audio'
  final String content;
  final String? file;
  final String? fileName;
  final int? fileSize;
  final String? fileUrl;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? replyTo;
  final String? replyToContent;
  final ReplyToInfo? replyToInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> readBy;
  final List<Reaction>? reactions;

  const Message({
    required this.uid,
    required this.chatId,
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
    this.replyToInfo,
    required this.createdAt,
    required this.updatedAt,
    required this.readBy,
    this.reactions,
  });

  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isAudio => messageType == 'audio';
  bool get isFile => messageType == 'file';
  bool get isText => messageType == 'text';
  bool get hasMedia => file != null || fileUrl != null;
  bool get hasReply => replyTo != null && replyTo!.isNotEmpty;
  bool get hasReactions => reactions != null && reactions!.isNotEmpty;

  String? get mediaUrl => fileUrl ?? file;

  String? get fileSizeLabel {
    if (fileSize == null) return null;
    const kb = 1024;
    const mb = kb * 1024;
    if (fileSize! >= mb) {
      return '${(fileSize! / mb).toStringAsFixed(1)} MB';
    } else if (fileSize! >= kb) {
      return '${(fileSize! / kb).toStringAsFixed(0)} KB';
    }
    return '$fileSize B';
  }

  int getReactionCount(String emoji) {
    if (reactions == null) return 0;
    return reactions!.where((r) => r.emoji == emoji).length;
  }

  bool userReacted(String emoji, int userId) {
    if (reactions == null) return false;
    return reactions!.any((r) => r.emoji == emoji && r.userId == userId);
  }

  List<String> get uniqueReactions {
    if (reactions == null) return [];
    return reactions!.map((r) => r.emoji).toSet().toList();
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    ReplyToInfo? replyToInfo;
    String? replyToContent;

    final rawReplyContent = json['reply_to_content'];
    if (rawReplyContent is Map<String, dynamic>) {
      replyToInfo = ReplyToInfo.fromJson(rawReplyContent);
      replyToContent = replyToInfo.content;
    } else if (rawReplyContent is String) {
      replyToContent = rawReplyContent;
    }

    List<Reaction>? reactions;
    if (json['reactions'] != null) {
      reactions = (json['reactions'] as List)
          .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return Message(
      uid: json['uid']?.toString() ?? '',
      chatId: _parseInt(json['chat']) ?? 0,
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      messageType: json['message_type']?.toString() ?? 'text',
      content: json['content']?.toString() ?? '',
      file: AppUtils.getAbsoluteUrl(json['file']?.toString()),
      fileName: json['file_name']?.toString(),
      fileSize: _parseInt(json['file_size']),
      fileUrl: AppUtils.getAbsoluteUrl(json['file_url']?.toString()),
      isEdited: json['is_edited'] == true,
      editedAt: _parseDate(json['edited_at']),
      isDeleted: json['is_deleted'] == true,
      deletedAt: _parseDate(json['deleted_at']),
      replyTo: json['reply_to']?.toString(),
      replyToContent: replyToContent,
      replyToInfo: replyToInfo,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      readBy: _parseIntList(json['read_by']),
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'chat': chatId,
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
    'reply_to_content': replyToInfo?.toJson() ?? replyToContent,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'read_by': readBy,
    if (reactions != null)
      'reactions': reactions!.map((r) => r.toJson()).toList(),
  };

  Message copyWith({
    String? uid,
    int? chatId,
    User? sender,
    String? messageType,
    String? content,
    String? file,
    String? fileName,
    int? fileSize,
    String? fileUrl,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? replyTo,
    String? replyToContent,
    ReplyToInfo? replyToInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? readBy,
    List<Reaction>? reactions,
  }) => Message(
    uid: uid ?? this.uid,
    chatId: chatId ?? this.chatId,
    sender: sender ?? this.sender,
    messageType: messageType ?? this.messageType,
    content: content ?? this.content,
    file: file ?? this.file,
    fileName: fileName ?? this.fileName,
    fileSize: fileSize ?? this.fileSize,
    fileUrl: fileUrl ?? this.fileUrl,
    isEdited: isEdited ?? this.isEdited,
    editedAt: editedAt ?? this.editedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt ?? this.deletedAt,
    replyTo: replyTo ?? this.replyTo,
    replyToContent: replyToContent ?? this.replyToContent,
    replyToInfo: replyToInfo ?? this.replyToInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    readBy: readBy ?? this.readBy,
    reactions: reactions ?? this.reactions,
  );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static List<int> _parseIntList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v.map((e) => _parseInt(e) ?? 0).where((e) => e != 0).toList();
    }
    return [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Message && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'Message(uid: $uid, type: $messageType, sender: ${sender.fullName})';
}

class ReplyToInfo {
  final String uid;
  final String content;
  final String senderName;

  const ReplyToInfo({
    required this.uid,
    required this.content,
    required this.senderName,
  });

  factory ReplyToInfo.fromJson(Map<String, dynamic> json) => ReplyToInfo(
    uid: json['uid']?.toString() ?? '',
    content: json['content']?.toString() ?? '',
    senderName: json['sender']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'content': content,
    'sender': senderName,
  };
}

class Reaction {
  final String emoji;
  final int userId;
  final String userName;
  final DateTime createdAt;

  const Reaction({
    required this.emoji,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
    emoji: json['emoji']?.toString() ?? '',
    userId: json['user_id'] as int? ?? 0,
    userName: json['user_name']?.toString() ?? '',
    createdAt: DateTime.parse(
      json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    ),
  );

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'user_id': userId,
    'user_name': userName,
    'created_at': createdAt.toIso8601String(),
  };
}
