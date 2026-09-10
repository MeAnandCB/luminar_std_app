class ConcernType {
  final String value;
  final String label;

  ConcernType({required this.value, required this.label});

  factory ConcernType.fromJson(Map<String, dynamic> json) => ConcernType(
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

class FeedbackOptions {
  final int ratingMin;
  final int ratingMax;
  final List<ConcernType> concernTypes;

  FeedbackOptions({
    required this.ratingMin,
    required this.ratingMax,
    required this.concernTypes,
  });

  factory FeedbackOptions.fromJson(Map<String, dynamic> json) {
    final list = json['concern_types'] as List? ?? [];
    return FeedbackOptions(
      ratingMin: (json['rating_min'] as num?)?.toInt() ?? 1,
      ratingMax: (json['rating_max'] as num?)?.toInt() ?? 10,
      concernTypes: list
          .map((e) => ConcernType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BatchFeedbackEntry {
  final String uid;
  final String batchUid;
  final String batchName;
  final String enrollmentUid;
  final int rating;
  final String message;
  final String concernType;
  final String concernLabel;
  final String concernDetail;
  final String studentName;
  final String studentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BatchFeedbackEntry({
    required this.uid,
    required this.batchUid,
    required this.batchName,
    required this.enrollmentUid,
    required this.rating,
    required this.message,
    required this.concernType,
    required this.concernLabel,
    required this.concernDetail,
    required this.studentName,
    required this.studentId,
    this.createdAt,
    this.updatedAt,
  });

  factory BatchFeedbackEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return BatchFeedbackEntry(
      uid: json['uid']?.toString() ?? '',
      batchUid: json['batch_uid']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      enrollmentUid: json['enrollment_uid']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      concernType: json['concern_type']?.toString() ?? '',
      concernLabel: json['concern_label']?.toString() ?? '',
      concernDetail: json['concern_detail']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class BatchFeedbackSummary {
  final String enrollmentUid;
  final String batchUid;
  final String batchName;
  final bool hasFeedback;
  final int feedbackCount;
  final BatchFeedbackEntry? latestFeedback;
  final List<BatchFeedbackEntry> feedbacks;

  BatchFeedbackSummary({
    required this.enrollmentUid,
    required this.batchUid,
    required this.batchName,
    required this.hasFeedback,
    required this.feedbackCount,
    this.latestFeedback,
    required this.feedbacks,
  });

  factory BatchFeedbackSummary.fromJson(Map<String, dynamic> json) {
    final list = json['feedbacks'] as List? ?? [];
    return BatchFeedbackSummary(
      enrollmentUid: json['enrollment_uid']?.toString() ?? '',
      batchUid: json['batch_uid']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      hasFeedback: json['has_feedback'] == true,
      feedbackCount: (json['feedback_count'] as num?)?.toInt() ?? 0,
      latestFeedback: json['feedback'] == null
          ? null
          : BatchFeedbackEntry.fromJson(json['feedback'] as Map<String, dynamic>),
      feedbacks: list
          .map((e) => BatchFeedbackEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MyBatchFeedbackResponse {
  final int count;
  final List<BatchFeedbackSummary> batches;

  MyBatchFeedbackResponse({required this.count, required this.batches});

  factory MyBatchFeedbackResponse.fromJson(Map<String, dynamic> json) {
    final list = json['batches'] as List? ?? [];
    return MyBatchFeedbackResponse(
      count: (json['count'] as num?)?.toInt() ?? list.length,
      batches: list
          .map((e) => BatchFeedbackSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
