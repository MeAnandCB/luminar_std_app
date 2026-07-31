class StudentTasksResponse {
  final String status;
  final List<StudentAssignment> assignments;

  StudentTasksResponse({
    required this.status,
    required this.assignments,
  });

  factory StudentTasksResponse.fromJson(Map<String, dynamic> json) {
    var list = json['assignments'] as List? ?? [];
    List<StudentAssignment> assignmentsList =
        list.map((i) => StudentAssignment.fromJson(i as Map<String, dynamic>)).toList();
    return StudentTasksResponse(
      status: json['status']?.toString() ?? '',
      assignments: assignmentsList,
    );
  }
}

class StudentAssignment {
  final String uid;
  final String status;
  final String? lastSubmissionAt;
  final String? lastVerificationResult;
  final String? lastVerifiedAt;
  final StudentTaskInfo task;
  final int maxAttempts;
  final int attemptsUsed;
  final bool canResubmit;
  final TaskSubmissionInfo? latestSubmission;

  StudentAssignment({
    required this.uid,
    required this.status,
    this.lastSubmissionAt,
    this.lastVerificationResult,
    this.lastVerifiedAt,
    required this.task,
    required this.maxAttempts,
    required this.attemptsUsed,
    required this.canResubmit,
    this.latestSubmission,
  });

  factory StudentAssignment.fromJson(Map<String, dynamic> json) {
    return StudentAssignment(
      uid: json['uid']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NOT_SUBMITTED',
      lastSubmissionAt: json['last_submission_at']?.toString(),
      lastVerificationResult: json['last_verification_result']?.toString(),
      lastVerifiedAt: json['last_verified_at']?.toString(),
      task: StudentTaskInfo.fromJson(json['task'] as Map<String, dynamic>? ?? {}),
      maxAttempts: (json['max_attempts'] as num?)?.toInt() ?? 1,
      attemptsUsed: (json['attempts_used'] as num?)?.toInt() ?? 0,
      canResubmit: json['can_resubmit'] as bool? ?? false,
      latestSubmission: json['latest_submission'] != null
          ? TaskSubmissionInfo.fromJson(json['latest_submission'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StudentTaskInfo {
  final String taskUid;
  final String title;
  final String description;
  final String? dueAt;
  final int maxAttempts;

  StudentTaskInfo({
    required this.taskUid,
    required this.title,
    required this.description,
    this.dueAt,
    required this.maxAttempts,
  });

  factory StudentTaskInfo.fromJson(Map<String, dynamic> json) {
    return StudentTaskInfo(
      taskUid: json['task_uid']?.toString() ?? json['uid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Task',
      description: json['description']?.toString() ?? '',
      dueAt: json['due_at']?.toString(),
      maxAttempts: (json['max_attempts'] as num?)?.toInt() ?? 1,
    );
  }
}

class TaskSubmissionInfo {
  final String uid;
  final int attemptNumber;
  final String? message;
  final String? attachmentUrl;
  final List<TaskAttachmentInfo> attachments;
  final String? submittedAt;
  final String? verificationStatus;
  final String? feedback;
  final String? submittedByUid;

  TaskSubmissionInfo({
    required this.uid,
    required this.attemptNumber,
    this.message,
    this.attachmentUrl,
    required this.attachments,
    this.submittedAt,
    this.verificationStatus,
    this.feedback,
    this.submittedByUid,
  });

  factory TaskSubmissionInfo.fromJson(Map<String, dynamic> json) {
    var attList = json['attachments'] as List? ?? [];
    List<TaskAttachmentInfo> attachments =
        attList.map((i) => TaskAttachmentInfo.fromJson(i as Map<String, dynamic>)).toList();

    return TaskSubmissionInfo(
      uid: json['uid']?.toString() ?? '',
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
      message: json['message']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
      attachments: attachments,
      submittedAt: json['submitted_at']?.toString(),
      verificationStatus: json['verification_status']?.toString(),
      feedback: json['feedback']?.toString(),
      submittedByUid: json['submitted_by_uid']?.toString(),
    );
  }
}

class TaskAttachmentInfo {
  final String uid;
  final String url;
  final String originalName;
  final int fileSize;
  final String contentType;
  final int sortOrder;

  TaskAttachmentInfo({
    required this.uid,
    required this.url,
    required this.originalName,
    required this.fileSize,
    required this.contentType,
    required this.sortOrder,
  });

  factory TaskAttachmentInfo.fromJson(Map<String, dynamic> json) {
    return TaskAttachmentInfo(
      uid: json['uid']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      originalName: json['original_name']?.toString() ?? 'attachment',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      contentType: json['content_type']?.toString() ?? 'application/octet-stream',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubmissionCreateResponse {
  final String status;
  final String? submissionUid;
  final int? attemptNumber;
  final String? assignmentStatus;
  final int? filesCount;
  final String? message;
  final int? maxAttempts;
  final int? maxFiles;

  SubmissionCreateResponse({
    required this.status,
    this.submissionUid,
    this.attemptNumber,
    this.assignmentStatus,
    this.filesCount,
    this.message,
    this.maxAttempts,
    this.maxFiles,
  });

  factory SubmissionCreateResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionCreateResponse(
      status: json['status']?.toString() ?? 'error',
      submissionUid: json['submission_uid']?.toString(),
      attemptNumber: (json['attempt_number'] as num?)?.toInt(),
      assignmentStatus: json['assignment_status']?.toString(),
      filesCount: (json['files_count'] as num?)?.toInt(),
      message: json['message']?.toString(),
      maxAttempts: (json['max_attempts'] as num?)?.toInt(),
      maxFiles: (json['max_files'] as num?)?.toInt(),
    );
  }
}
