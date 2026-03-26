// lib/repository/attandance_screen/model.dart

class AttendanceResponse {
  final String status;
  final int count;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final dynamic next;
  final dynamic previous;
  final List<AttendanceRecord> results;
  final String batchId;
  final String studentId;
  final Summary summary;
  final FiltersApplied filtersApplied;

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
    required this.filtersApplied,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    var resultsList = json['results'] as List? ?? [];

    return AttendanceResponse(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      next: json['next'],
      previous: json['previous'],
      batchId: json['batch_id'] ?? '',
      studentId: json['student_id'] ?? '',
      summary: Summary.fromJson(json['summary'] ?? {}),
      filtersApplied: FiltersApplied.fromJson(json['filters_applied'] ?? {}),
      results: resultsList
          .map((item) => AttendanceRecord.fromJson(item))
          .toList(),
    );
  }
}

class AttendanceRecord {
  final int id;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String status;
  final String statusDisplay;
  final String reason;
  final DateTime timestamp;

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
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      reason: json['reason'] ?? 'No Remark',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class Summary {
  final int totalDays;
  final int online;
  final int offline;
  final int recording;
  final int absent;
  final double onlinePercentage;
  final double offlinePercentage;
  final double recordingPercentage;
  final double absentPercentage;

  Summary({
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

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalDays: json['total_days'] ?? 0,
      online: json['online'] ?? 0,
      offline: json['offline'] ?? 0,
      recording: json['recording'] ?? 0,
      absent: json['absent'] ?? 0,
      onlinePercentage: (json['online_percentage'] as num?)?.toDouble() ?? 0.0,
      offlinePercentage:
          (json['offline_percentage'] as num?)?.toDouble() ?? 0.0,
      recordingPercentage:
          (json['recording_percentage'] as num?)?.toDouble() ?? 0.0,
      absentPercentage: (json['absent_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FiltersApplied {
  final String? sessionId;
  final String? startDate;
  final String? endDate;

  FiltersApplied({this.sessionId, this.startDate, this.endDate});

  factory FiltersApplied.fromJson(Map<String, dynamic> json) {
    return FiltersApplied(
      sessionId: json['session_id'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}
