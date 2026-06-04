class JobNotificationResponse {
  final String status;
  final int page;
  final int pageSize;
  final int totalPages;
  final int count;
  final List<JobNotification> results;

  JobNotificationResponse({
    required this.status,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.count,
    required this.results,
  });

  factory JobNotificationResponse.fromJson(Map<String, dynamic> json) {
    return JobNotificationResponse(
      status: json['status'] ?? '',
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
      count: json['count'] ?? 0,
      results: (json['results'] as List? ?? [])
          .map((e) => JobNotification.fromJson(e))
          .toList(),
    );
  }
}

class JobNotification {
  final String uid;
  final String jobUid;
  final String jobTitle;
  final String companyName;
  final String companyUid;
  final String? companyLogo;
  final String batchName;
  final bool isViewed;
  final DateTime? viewedAt;
  final DateTime createdAt;
  final int timesShared;
  final JobApplication application;

  JobNotification({
    required this.uid,
    required this.jobUid,
    required this.jobTitle,
    required this.companyName,
    required this.companyUid,
    this.companyLogo,
    required this.batchName,
    required this.isViewed,
    this.viewedAt,
    required this.createdAt,
    required this.timesShared,
    required this.application,
  });

  static String _str(dynamic v) => v?.toString() ?? '';
  static DateTime? _date(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;
  static int _int(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  factory JobNotification.fromJson(Map<String, dynamic> json) {
    return JobNotification(
      uid: _str(json['uid']),
      jobUid: _str(json['job_uid']),
      jobTitle: _str(json['job_title']),
      companyName: _str(json['company_name']),
      companyUid: _str(json['company_uid']),
      companyLogo: json['company_logo']?.toString(),
      batchName: _str(json['batch_name']),
      isViewed: json['is_viewed'] == true,
      viewedAt: _date(json['viewed_at']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      timesShared: _int(json['times_shared']),
      application: json['application'] is Map<String, dynamic>
          ? JobApplication.fromJson(json['application'] as Map<String, dynamic>)
          : JobApplication(hasApplication: false),
    );
  }
}

class JobApplication {
  final bool hasApplication;
  final String? applicationUid;
  final String? applicationStatus;
  final String? currentStage;
  final String? rejectionReason;

  JobApplication({
    required this.hasApplication,
    this.applicationUid,
    this.applicationStatus,
    this.currentStage,
    this.rejectionReason,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    // current_stage can be a Map {"uid":..,"name":"Applied"} or null
    final stage = json['current_stage'];
    return JobApplication(
      hasApplication: json['has_application'] == true,
      applicationUid: json['application_uid']?.toString(),
      applicationStatus: json['application_status']?.toString(),
      currentStage: stage is Map<String, dynamic>
          ? stage['name']?.toString()
          : stage?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}

// ─── Job Detail ───────────────────────────────────────────────────────────────

class JobDetailResponse {
  final String status;
  final JobDetail job;
  final JobDetailNotification notification;
  final JobApplication application;

  JobDetailResponse({
    required this.status,
    required this.job,
    required this.notification,
    required this.application,
  });

  factory JobDetailResponse.fromJson(Map<String, dynamic> json) {
    return JobDetailResponse(
      status: json['status'] ?? '',
      job: JobDetail.fromJson(json['job'] as Map<String, dynamic>? ?? {}),
      notification: JobDetailNotification.fromJson(
        json['notification'] as Map<String, dynamic>? ?? {},
      ),
      application: JobApplication.fromJson(
        json['application'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class JobDetail {
  final String uid;
  final String title;
  final String description;
  final String location;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool isExpired;
  final JobCompany company;
  final String? customFieldTemplateUid;
  final List<JobCustomField> customFields;

  JobDetail({
    required this.uid,
    required this.title,
    required this.description,
    required this.location,
    this.publishedAt,
    this.expiresAt,
    required this.isExpired,
    required this.company,
    this.customFieldTemplateUid,
    required this.customFields,
  });

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      uid: json['uid'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      isExpired: json['is_expired'] ?? false,
      company: JobCompany.fromJson(
        json['company'] as Map<String, dynamic>? ?? {},
      ),
      customFieldTemplateUid: json['custom_field_template_uid'],
      customFields: (json['custom_fields'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(JobCustomField.fromJson)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }
}

class JobCompany {
  final String name;
  final String? logo;

  JobCompany({required this.name, this.logo});

  factory JobCompany.fromJson(Map<String, dynamic> json) {
    return JobCompany(
      name: json['name'] ?? '',
      logo: json['logo'],
    );
  }
}

class JobCustomField {
  final String uid;
  final String label;
  final String key;
  final String fieldType;
  final bool isRequired;
  final List<String> options;
  final int sortOrder;

  JobCustomField({
    required this.uid,
    required this.label,
    required this.key,
    required this.fieldType,
    required this.isRequired,
    required this.options,
    required this.sortOrder,
  });

  factory JobCustomField.fromJson(Map<String, dynamic> json) {
    return JobCustomField(
      uid: json['uid'] ?? '',
      label: json['label'] ?? '',
      key: json['key'] ?? '',
      fieldType: json['field_type'] ?? 'text',
      isRequired: json['is_required'] ?? false,
      options: List<String>.from(json['options'] as List? ?? []),
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

class JobDetailNotification {
  final String recipientUid;
  final String broadcastUid;
  final String jobUid;
  final bool isViewed;
  final DateTime? viewedAt;
  final String batchUid;
  final String batchName;
  final DateTime? sentAt;

  JobDetailNotification({
    required this.recipientUid,
    required this.broadcastUid,
    required this.jobUid,
    required this.isViewed,
    this.viewedAt,
    required this.batchUid,
    required this.batchName,
    this.sentAt,
  });

  static DateTime? _date(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  factory JobDetailNotification.fromJson(Map<String, dynamic> json) {
    return JobDetailNotification(
      recipientUid: json['recipient_uid']?.toString() ?? '',
      broadcastUid: json['broadcast_uid']?.toString() ?? '',
      jobUid: json['job_uid']?.toString() ?? '',
      isViewed: json['is_viewed'] == true,
      viewedAt: _date(json['viewed_at']),
      batchUid: json['batch_uid']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      sentAt: _date(json['sent_at']),
    );
  }
}

// ─── Application Detail ───────────────────────────────────────────────────────

class JobApplicationDetailResponse {
  final String status;
  final JobApplicationDetail application;

  JobApplicationDetailResponse({required this.status, required this.application});

  factory JobApplicationDetailResponse.fromJson(Map<String, dynamic> json) {
    return JobApplicationDetailResponse(
      status: json['status']?.toString() ?? '',
      application: JobApplicationDetail.fromJson(
        json['application'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class JobInterview {
  final String uid;
  final String stageUid;
  final String stageName;
  final DateTime? scheduledAt;
  final String mode;
  final String? meetingLink;
  final String? location;
  final String attendance;
  final String? feedback;
  final String? score; // API returns as string e.g. "5.00"
  final DateTime? createdAt;

  JobInterview({
    required this.uid,
    required this.stageUid,
    required this.stageName,
    this.scheduledAt,
    required this.mode,
    this.meetingLink,
    this.location,
    required this.attendance,
    this.feedback,
    this.score,
    this.createdAt,
  });

  bool get isOnline => mode.toLowerCase() == 'online';

  static DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  factory JobInterview.fromJson(Map<String, dynamic> json) {
    return JobInterview(
      uid: json['uid']?.toString() ?? '',
      stageUid: json['stage_uid']?.toString() ?? '',
      stageName: json['stage_name']?.toString() ?? '',
      scheduledAt: _date(json['scheduled_at']),
      mode: json['mode']?.toString() ?? 'offline',
      meetingLink: json['meeting_link']?.toString(),
      location: json['location']?.toString(),
      attendance: json['attendance']?.toString() ?? 'scheduled',
      feedback: json['feedback']?.toString(),
      score: json['score']?.toString(),
      createdAt: _date(json['created_at']),
    );
  }
}

class JobApplicationDetail {
  final String applicationUid;
  final String jobUid;
  final String status;
  final DateTime? appliedAt;
  final PipelineStage? currentStage;
  final List<PipelineStage> pipelineStages;
  final List<StageHistory> stageHistory;
  final List<JobInterview> interviews;
  final List<ApplicationAnswer> answers;
  final String? resumeUrl;
  final String? resumeFile;

  JobApplicationDetail({
    required this.applicationUid,
    required this.jobUid,
    required this.status,
    this.appliedAt,
    this.currentStage,
    required this.pipelineStages,
    required this.stageHistory,
    required this.interviews,
    required this.answers,
    this.resumeUrl,
    this.resumeFile,
  });

  static DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  factory JobApplicationDetail.fromJson(Map<String, dynamic> json) {
    final currentStageJson = json['current_stage'];
    return JobApplicationDetail(
      applicationUid: json['application_uid']?.toString() ?? '',
      jobUid: json['job_uid']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      appliedAt: _date(json['applied_at']),
      currentStage: currentStageJson is Map<String, dynamic>
          ? PipelineStage.fromJson(currentStageJson, isCurrent: true)
          : null,
      pipelineStages: (json['pipeline_stages'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PipelineStage.fromJson)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      stageHistory: (json['stage_history'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StageHistory.fromJson)
          .toList(),
      interviews: (json['interviews'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(JobInterview.fromJson)
          .toList(),
      answers: (json['answers'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ApplicationAnswer.fromJson)
          .toList(),
      resumeUrl: json['resume_url']?.toString(),
      resumeFile: json['resume_file']?.toString(),
    );
  }

  // Rejection reason extracted from stage history note
  String? get rejectionNote {
    for (final h in stageHistory) {
      final code = h.toStage?.code ?? '';
      if (code.contains('reject') && h.note != null) {
        return h.cleanedNote;
      }
    }
    return null;
  }
}

class PipelineStage {
  final String uid;
  final String name;
  final String code;
  final int sortOrder;
  final bool isTerminal;
  final bool isActive;
  final bool isCurrent;
  final DateTime? createdAt;

  PipelineStage({
    required this.uid,
    required this.name,
    required this.code,
    required this.sortOrder,
    required this.isTerminal,
    required this.isActive,
    required this.isCurrent,
    this.createdAt,
  });

  static DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  factory PipelineStage.fromJson(
    Map<String, dynamic> json, {
    bool isCurrent = false,
  }) {
    return PipelineStage(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
      isTerminal: json['is_terminal'] == true,
      isActive: json['is_active'] == true,
      isCurrent: json['is_current'] == true || isCurrent,
      createdAt: _date(json['created_at']),
    );
  }
}

class StageHistory {
  final String uid;
  final StageRef? fromStage;
  final StageRef? toStage;
  final String? note;
  final String? changedBy;
  final DateTime? changedAt;

  StageHistory({
    required this.uid,
    this.fromStage,
    this.toStage,
    this.note,
    this.changedBy,
    this.changedAt,
  });

  static DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  // Strip "[CRM: name]" prefix from admin notes
  String? get cleanedNote {
    if (note == null) return null;
    return note!.replaceAll(RegExp(r'^\[CRM:[^\]]*\]\s*'), '').trim();
  }

  factory StageHistory.fromJson(Map<String, dynamic> json) {
    return StageHistory(
      uid: json['uid']?.toString() ?? '',
      fromStage: json['from_stage'] is Map<String, dynamic>
          ? StageRef.fromJson(json['from_stage'] as Map<String, dynamic>)
          : null,
      toStage: json['to_stage'] is Map<String, dynamic>
          ? StageRef.fromJson(json['to_stage'] as Map<String, dynamic>)
          : null,
      note: json['note']?.toString(),
      changedBy: json['changed_by']?.toString(),
      changedAt: _date(json['changed_at']),
    );
  }
}

class StageRef {
  final String uid;
  final String name;
  final String code;

  StageRef({required this.uid, required this.name, required this.code});

  factory StageRef.fromJson(Map<String, dynamic> json) {
    return StageRef(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class ApplicationAnswer {
  final String uid;
  final String fieldUid;
  final String label;
  final String key;
  final String fieldType;
  final String? valueText;
  final List<String> valueJson;

  ApplicationAnswer({
    required this.uid,
    required this.fieldUid,
    required this.label,
    required this.key,
    required this.fieldType,
    this.valueText,
    this.valueJson = const [],
  });

  /// Human-readable display: joins multi-select list or returns text value.
  String get displayValue {
    if (valueJson.isNotEmpty) return valueJson.join(', ');
    return valueText ?? '';
  }

  factory ApplicationAnswer.fromJson(Map<String, dynamic> json) {
    final rawJson = json['value_json'];
    return ApplicationAnswer(
      uid: json['uid']?.toString() ?? '',
      fieldUid: json['field_uid']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? 'text',
      valueText: json['value_text']?.toString(),
      valueJson: rawJson is List
          ? rawJson.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
