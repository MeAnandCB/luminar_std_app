class Batch {
  String? uid;
  String? chatType;
  dynamic participant1;
  dynamic participant2;
  String? batch;
  String? batchName;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastMessageAt;
  LastMessagePreview? lastMessagePreview;
  int? unreadCount;
  dynamic otherParticipant;
  bool? isActive;
  bool? isArchived;
  dynamic groupName;
  dynamic groupDescription;
  dynamic groupIcon;

  Batch({
    this.uid,
    this.chatType,
    this.participant1,
    this.participant2,
    this.batch,
    this.batchName,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount,
    this.otherParticipant,
    this.isActive,
    this.isArchived,
    this.groupName,
    this.groupDescription,
    this.groupIcon,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    uid: json["uid"],
    chatType: json["chat_type"],
    participant1: json["participant_1"],
    participant2: json["participant_2"],
    batch: json["batch"],
    batchName: json["batch_name"],
    createdAt: json["created_at"] == null
        ? null
        : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.parse(json["updated_at"]),
    lastMessageAt: json["last_message_at"] == null
        ? null
        : DateTime.parse(json["last_message_at"]),
    lastMessagePreview: json["last_message_preview"] == null
        ? null
        : LastMessagePreview.fromJson(json["last_message_preview"]),
    unreadCount: json["unread_count"],
    otherParticipant: json["other_participant"],
    isActive: json["is_active"],
    isArchived: json["is_archived"],
    groupName: json["group_name"],
    groupDescription: json["group_description"],
    groupIcon: json["group_icon"],
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "chat_type": chatType,
    "participant_1": participant1,
    "participant_2": participant2,
    "batch": batch,
    "batch_name": batchName,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "last_message_at": lastMessageAt?.toIso8601String(),
    "last_message_preview": lastMessagePreview?.toJson(),
    "unread_count": unreadCount,
    "other_participant": otherParticipant,
    "is_active": isActive,
    "is_archived": isArchived,
    "group_name": groupName,
    "group_description": groupDescription,
    "group_icon": groupIcon,
  };
}

class LastMessagePreview {
  String? content;
  String? sender;
  String? messageType;
  bool? isDeleted;
  DateTime? createdAt;

  LastMessagePreview({
    this.content,
    this.sender,
    this.messageType,
    this.isDeleted,
    this.createdAt,
  });

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) =>
      LastMessagePreview(
        content: json["content"],
        sender: json["sender"],
        messageType: json["message_type"],
        isDeleted: json["is_deleted"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
    "content": content,
    "sender": sender,
    "message_type": messageType,
    "is_deleted": isDeleted,
    "created_at": createdAt?.toIso8601String(),
  };
}
