class AttendanceRecord {
  final int id;
  final String studentId;
  final String studentName;
  final String date;
  final String status;
  final String statusDisplay;
  final String reason;
  final String timestamp;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    required this.statusDisplay,
    required this.reason,
    required this.timestamp,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      reason: json['reason'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class AttendanceSummary {
  final int totalDays;
  final int online;
  final int offline;
  final int recording;
  final int absent;
  final double onlinePercentage;
  final double offlinePercentage;
  final double recordingPercentage;
  final double absentPercentage;

  AttendanceSummary({
    required this.totalDays,
    required this.online,
    required this.offline,
    required this.recording,
    required this.absent,
    required this.onlinePercentage,
    required this.offlinePercentage,
    required this.recordingPercentage,
    required this.absentPercentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: json['total_days'] ?? 0,
      online: json['online'] ?? 0,
      offline: json['offline'] ?? 0,
      recording: json['recording'] ?? 0,
      absent: json['absent'] ?? 0,
      onlinePercentage: (json['online_percentage'] ?? 0.0).toDouble(),
      offlinePercentage: (json['offline_percentage'] ?? 0.0).toDouble(),
      recordingPercentage: (json['recording_percentage'] ?? 0.0).toDouble(),
      absentPercentage: (json['absent_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class AttendanceResponse {
  final String status;
  final int count;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final String? next;
  final String? previous;
  final List<AttendanceRecord> results;
  final String batchId;
  final String studentId;
  final AttendanceSummary summary;

  AttendanceResponse({
    required this.status,
    required this.count,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    this.next,
    this.previous,
    required this.results,
    required this.batchId,
    required this.studentId,
    required this.summary,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
      currentPage: json['current_page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      batchId: json['batch_id'] ?? '',
      studentId: json['student_id'] ?? '',
      summary: AttendanceSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

// Dashboard models
class BatchSession {
  final String uid;
  final String name;
  final String description;

  BatchSession({
    required this.uid,
    required this.name,
    required this.description,
  });

  factory BatchSession.fromJson(Map<String, dynamic> json) {
    return BatchSession(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class EnrollmentBatch {
  final String uid;
  final String batchName;
  final String startDate;
  final String endDate;
  final String courseName;
  final List<BatchSession> sessions;

  EnrollmentBatch({
    required this.uid,
    required this.batchName,
    required this.startDate,
    required this.endDate,
    required this.courseName,
    required this.sessions,
  });

  factory EnrollmentBatch.fromJson(Map<String, dynamic> enrollment) {
    final batchInfo = enrollment['batch_info'] as Map<String, dynamic>? ?? {};
    final courseInfo = enrollment['course_info'] as Map<String, dynamic>? ?? {};
    final sessionsData = batchInfo['sessions'] as Map<String, dynamic>? ?? {};
    final topicsList = sessionsData['topics'] as List<dynamic>? ?? [];

    return EnrollmentBatch(
      uid: batchInfo['uid'] ?? '',
      batchName: batchInfo['batch_name'] ?? '',
      startDate: batchInfo['start_date'] ?? '',
      endDate: batchInfo['end_date'] ?? '',
      courseName: courseInfo['course_name'] ?? '',
      sessions: topicsList
          .map((t) => BatchSession.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
