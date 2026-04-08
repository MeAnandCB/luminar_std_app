class ExamSessionsResponse {
  final String status;
  final List<ExamSession> data;
  final ExamMeta meta;

  ExamSessionsResponse({
    required this.status,
    required this.data,
    required this.meta,
  });

  factory ExamSessionsResponse.fromJson(Map<String, dynamic> json) =>
      ExamSessionsResponse(
        status: json['status'] ?? '',
        data: (json['data'] as List<dynamic>? ?? [])
            .map((e) => ExamSession.fromJson(e as Map<String, dynamic>))
            .toList(),
        meta: json['meta'] != null
            ? ExamMeta.fromJson(json['meta'])
            : ExamMeta(enrollmentCount: 0, batchCount: 0, sessionCount: 0),
      );
}

class ExamSession {
  final String uid;
  final String examName;
  final DateTime? scheduledDate;
  final String status;
  final String instructions;
  final String? attemptUid;
  final bool isVisibleToStudent;
  final bool canOpenResult;
  final ExamBatch? batch;
  final String? templateUid;
  final ExamModule? module;
  final ExamType? examType;

  ExamSession({
    required this.uid,
    required this.examName,
    this.scheduledDate,
    required this.status,
    required this.instructions,
    this.attemptUid,
    required this.isVisibleToStudent,
    required this.canOpenResult,
    this.batch,
    this.templateUid,
    this.module,
    this.examType,
  });

  factory ExamSession.fromJson(Map<String, dynamic> json) => ExamSession(
        uid: json['uid'] ?? '',
        examName: json['exam_name'] ?? '',
        scheduledDate: json['scheduled_date'] != null
            ? DateTime.tryParse(json['scheduled_date'])
            : null,
        status: json['status'] ?? '',
        instructions: json['instructions'] ?? '',
        attemptUid: json['attempt_uid'],
        isVisibleToStudent: json['is_visible_to_student'] ?? false,
        canOpenResult: json['can_open_result'] ?? false,
        batch: json['batch'] != null ? ExamBatch.fromJson(json['batch']) : null,
        templateUid: json['template_uid'],
        module:
            json['module'] != null ? ExamModule.fromJson(json['module']) : null,
        examType: json['exam_type'] != null
            ? ExamType.fromJson(json['exam_type'])
            : null,
      );
}

class ExamBatch {
  final String uid;
  final String batchName;
  final String courseName;

  ExamBatch({
    required this.uid,
    required this.batchName,
    required this.courseName,
  });

  factory ExamBatch.fromJson(Map<String, dynamic> json) => ExamBatch(
        uid: json['uid'] ?? '',
        batchName: json['batch_name'] ?? '',
        courseName: json['course_name'] ?? '',
      );
}

class ExamModule {
  final String uid;
  final String name;
  final String code;

  ExamModule({required this.uid, required this.name, required this.code});

  factory ExamModule.fromJson(Map<String, dynamic> json) => ExamModule(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
      );
}

class ExamType {
  final int id;
  final String name;
  final String code;

  ExamType({required this.id, required this.name, required this.code});

  factory ExamType.fromJson(Map<String, dynamic> json) => ExamType(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        code: json['code'] ?? '',
      );
}

class ExamMeta {
  final int enrollmentCount;
  final int batchCount;
  final int sessionCount;

  ExamMeta({
    required this.enrollmentCount,
    required this.batchCount,
    required this.sessionCount,
  });

  factory ExamMeta.fromJson(Map<String, dynamic> json) => ExamMeta(
        enrollmentCount: json['enrollment_count'] ?? 0,
        batchCount: json['batch_count'] ?? 0,
        sessionCount: json['session_count'] ?? 0,
      );
}
