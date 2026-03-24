class Group {
  String? uid;
  String? chatType;
  dynamic participant1;
  dynamic participant2;
  dynamic batch;
  dynamic batchName;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic lastMessageAt;
  dynamic lastMessagePreview;
  int? unreadCount;
  dynamic otherParticipant;
  bool? isActive;
  bool? isArchived;
  String? groupName;
  String? groupDescription;
  dynamic groupIcon;

  Group({
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

  factory Group.fromJson(Map<String, dynamic> json) => Group(
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
    lastMessageAt: json["last_message_at"],
    lastMessagePreview: json["last_message_preview"],
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
    "last_message_at": lastMessageAt,
    "last_message_preview": lastMessagePreview,
    "unread_count": unreadCount,
    "other_participant": otherParticipant,
    "is_active": isActive,
    "is_archived": isArchived,
    "group_name": groupName,
    "group_description": groupDescription,
    "group_icon": groupIcon,
  };
}
