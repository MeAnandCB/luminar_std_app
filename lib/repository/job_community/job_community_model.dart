import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// Community
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPerson {
  final int id;
  final String fullName;
  final String email;

  CommunityPerson({required this.id, required this.fullName, required this.email});

  factory CommunityPerson.fromJson(Map<String, dynamic> json) => CommunityPerson(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fullName: json['full_name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
      );
}

class CommunityBatch {
  final String uid;
  final String batchName;
  final String batchCode;

  CommunityBatch({
    required this.uid,
    required this.batchName,
    required this.batchCode,
  });

  factory CommunityBatch.fromJson(Map<String, dynamic> json) => CommunityBatch(
        uid: json['uid']?.toString() ?? '',
        batchName: json['batch_name']?.toString() ?? '',
        batchCode: json['batch_code']?.toString() ?? '',
      );
}

class JobCommunity {
  final String uid;
  final String name;
  final bool isActive;
  final int? courseId;
  final String courseName;
  final String chatUid;
  final int memberCount;
  final CommunityPerson? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CommunityBatch> activeBatches;

  JobCommunity({
    required this.uid,
    required this.name,
    required this.isActive,
    this.courseId,
    required this.courseName,
    required this.chatUid,
    required this.memberCount,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    required this.activeBatches,
  });

  factory JobCommunity.fromJson(Map<String, dynamic> json) {
    final batches = json['active_batches'] as List? ?? [];
    return JobCommunity(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] == true,
      courseId: (json['course_id'] as num?)?.toInt(),
      courseName: json['course_name']?.toString() ?? '',
      chatUid: json['chat_uid']?.toString() ?? '',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by'] == null
          ? null
          : CommunityPerson.fromJson(json['created_by'] as Map<String, dynamic>),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      activeBatches: batches
          .map((b) => CommunityBatch.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

class JobCommunityListResponse {
  final int count;
  final int page;
  final int pageSize;
  final List<JobCommunity> results;

  JobCommunityListResponse({
    required this.count,
    required this.page,
    required this.pageSize,
    required this.results,
  });

  factory JobCommunityListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List? ?? [];
    return JobCommunityListResponse(
      count: (json['count'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      results:
          list.map((e) => JobCommunity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared jobs
// ─────────────────────────────────────────────────────────────────────────────

class CommunityCompany {
  final String uid;
  final String name;

  CommunityCompany({required this.uid, required this.name});

  factory CommunityCompany.fromJson(Map<String, dynamic> json) => CommunityCompany(
        uid: json['uid']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class CommunityJobShare {
  final String uid; // share uid
  final String jobUid;
  final String title;
  final CommunityCompany company;
  final String location;
  final bool isPublished;
  final bool isActive;
  final CommunityPerson? sharedBy;
  final DateTime? sharedAt;
  final String? chatMessageUid;
  final DateTime? unsharedAt;

  CommunityJobShare({
    required this.uid,
    required this.jobUid,
    required this.title,
    required this.company,
    required this.location,
    required this.isPublished,
    required this.isActive,
    this.sharedBy,
    this.sharedAt,
    this.chatMessageUid,
    this.unsharedAt,
  });

  factory CommunityJobShare.fromJson(Map<String, dynamic> json) {
    return CommunityJobShare(
      uid: json['uid']?.toString() ?? '',
      jobUid: json['job_uid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      company: CommunityCompany.fromJson(
        json['company'] as Map<String, dynamic>? ?? {},
      ),
      location: json['location']?.toString() ?? '',
      isPublished: json['is_published'] == true,
      isActive: json['is_active'] == true,
      sharedBy: json['shared_by'] == null
          ? null
          : CommunityPerson.fromJson(json['shared_by'] as Map<String, dynamic>),
      sharedAt: DateTime.tryParse(json['shared_at']?.toString() ?? ''),
      chatMessageUid: json['chat_message_uid']?.toString(),
      unsharedAt: json['unshared_at'] == null
          ? null
          : DateTime.tryParse(json['unshared_at'].toString()),
    );
  }
}

class CommunityJobsResponse {
  final int count;
  final List<CommunityJobShare> results;

  CommunityJobsResponse({required this.count, required this.results});

  factory CommunityJobsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List? ?? [];
    return CommunityJobsResponse(
      count: (json['count'] as num?)?.toInt() ?? list.length,
      results: list
          .map((e) => CommunityJobShare.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job detail (apply form)
// ─────────────────────────────────────────────────────────────────────────────

/// `field_type`: text | select | multi_select | date | number | url | file
class CommunityCustomField {
  final String uid;
  final String label;
  final String fieldType;
  final bool isRequired;
  final List<String> options;

  CommunityCustomField({
    required this.uid,
    required this.label,
    required this.fieldType,
    required this.isRequired,
    required this.options,
  });

  factory CommunityCustomField.fromJson(Map<String, dynamic> json) {
    return CommunityCustomField(
      uid: json['uid']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? 'text',
      isRequired: json['is_required'] == true,
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  bool get isSelect => fieldType == 'select' || fieldType == 'multi_select';
  bool get isMulti => fieldType == 'multi_select';
}

class CommunityJobDetail {
  final String uid;
  final String title;
  final String location;
  final CommunityCompany company;
  final List<CommunityCustomField> customFields;

  CommunityJobDetail({
    required this.uid,
    required this.title,
    required this.location,
    required this.company,
    required this.customFields,
  });

  factory CommunityJobDetail.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>? ?? json;
    final fields = job['custom_fields'] as List? ?? [];
    return CommunityJobDetail(
      uid: job['uid']?.toString() ?? '',
      title: job['title']?.toString() ?? '',
      location: job['location']?.toString() ?? '',
      company: CommunityCompany.fromJson(
        job['company'] as Map<String, dynamic>? ?? {},
      ),
      customFields: fields
          .map((f) => CommunityCustomField.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat (read-only)
// ─────────────────────────────────────────────────────────────────────────────

class CommunityMessageSender {
  final int id;
  final String fullName;

  CommunityMessageSender({required this.id, required this.fullName});

  factory CommunityMessageSender.fromJson(Map<String, dynamic> json) =>
      CommunityMessageSender(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fullName: json['full_name']?.toString() ?? '',
      );
}

/// Parsed from a `job_share` message's JSON-string `content`.
class JobShareContent {
  final String jobUid;
  final String title;
  final String company;
  final String location;
  final String communityUid;
  final String communityName;

  JobShareContent({
    required this.jobUid,
    required this.title,
    required this.company,
    required this.location,
    required this.communityUid,
    required this.communityName,
  });

  static JobShareContent? tryParse(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['type'] != 'job_share') return null;
      return JobShareContent(
        jobUid: decoded['job_uid']?.toString() ?? '',
        title: decoded['title']?.toString() ?? '',
        company: decoded['company']?.toString() ?? '',
        location: decoded['location']?.toString() ?? '',
        communityUid: decoded['community_uid']?.toString() ?? '',
        communityName: decoded['community_name']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

class CommunityMessage {
  final String uid;
  final String messageType;
  final String content;
  final DateTime createdAt;
  final CommunityMessageSender? sender;

  CommunityMessage({
    required this.uid,
    required this.messageType,
    required this.content,
    required this.createdAt,
    this.sender,
  });

  bool get isJobShare => messageType == 'job_share';

  JobShareContent? get jobShare => isJobShare ? JobShareContent.tryParse(content) : null;

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    return CommunityMessage(
      uid: json['uid']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      sender: json['sender'] == null
          ? null
          : CommunityMessageSender.fromJson(json['sender'] as Map<String, dynamic>),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Apply
// ─────────────────────────────────────────────────────────────────────────────

class CommunityApplyResult {
  final bool success;
  final String message;
  final String? applicationUid;
  final String? currentStageName;

  CommunityApplyResult({
    required this.success,
    required this.message,
    this.applicationUid,
    this.currentStageName,
  });

  factory CommunityApplyResult.fromJson(Map<String, dynamic> json) {
    return CommunityApplyResult(
      success: json['status'] == 'success',
      message: json['message']?.toString() ?? '',
      applicationUid: json['application_uid']?.toString(),
      currentStageName:
          (json['current_stage'] as Map<String, dynamic>?)?['name']?.toString(),
    );
  }
}
