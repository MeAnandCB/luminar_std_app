class EnrollmentResponse {
  final String status;
  final List<Enrollment> enrollments;
  final Summary summary;

  EnrollmentResponse({
    required this.status,
    required this.enrollments,
    required this.summary,
  });

  factory EnrollmentResponse.fromJson(Map<String, dynamic> json) {
    return EnrollmentResponse(
      status: json['status'],
      enrollments: (json['enrollments'] as List)
          .map((e) => Enrollment.fromJson(e))
          .toList(),
      summary: Summary.fromJson(json['summary']),
    );
  }
}

class Enrollment {
  final String uid;
  final String enrollmentNumber;
  final DateTime enrollmentDate;
  final double originalCourseFeesDiscount;
  final String source;
  final Status status;
  final Batch batch;
  final Course course;
  final AttendanceMode attendanceMode;
  final PaymentInfo paymentInfo;
  final Progress progress;
  final String specialNotes;
  final List<String> tags;

  Enrollment({
    required this.uid,
    required this.enrollmentNumber,
    required this.enrollmentDate,
    required this.originalCourseFeesDiscount,
    required this.source,
    required this.status,
    required this.batch,
    required this.course,
    required this.attendanceMode,
    required this.paymentInfo,
    required this.progress,
    required this.specialNotes,
    required this.tags,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      uid: json['uid'] ?? '', // Handle null
      enrollmentNumber: json['enrollment_number'] ?? '', // Handle null
      enrollmentDate: json['enrollment_date'] != null
          ? DateTime.parse(json['enrollment_date'])
          : DateTime.now(), // Handle null with default
      originalCourseFeesDiscount: (json['original_course_fees_discount'] ?? 0)
          .toDouble(),
      source: json['source'] ?? '', // Handle null
      status: Status.fromJson(
        json['status'] ?? {},
      ), // Handle null with empty map
      batch: Batch.fromJson(json['batch'] ?? {}), // Handle null with empty map
      course: Course.fromJson(
        json['course'] ?? {},
      ), // Handle null with empty map
      attendanceMode: AttendanceMode.fromJson(
        json['attendance_mode'] ?? {},
      ), // Handle null
      paymentInfo: PaymentInfo.fromJson(
        json['payment_info'] ?? {},
      ), // Handle null
      progress: Progress.fromJson(json['progress'] ?? {}), // Handle null
      specialNotes: json['special_notes'] ?? '', // Handle null
      tags: List<String>.from(json['tags'] ?? []), // Handle null
    );
  }
}

class Status {
  final String name;
  final String value;
  final String color;

  Status({required this.name, required this.value, required this.color});

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      name: json['name'] ?? '', // Handle null
      value: json['value'] ?? '', // Handle null
      color: json['color'] ?? '#000000', // Handle null with default color
    );
  }
}

class Batch {
  final String uid;
  final String batchName;
  final DateTime startDate;
  final DateTime endDate;
  final String joinUrl;
  final String time;
  final String status;

  Batch({
    required this.uid,
    required this.batchName,
    required this.startDate,
    required this.endDate,
    required this.joinUrl,
    required this.time,
    required this.status,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      uid: json['uid'] ?? '', // Handle null
      batchName: json['batch_name'] ?? '', // Handle null
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(), // Handle null
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 30)), // Handle null
      joinUrl: json['join_url'] ?? '', // Handle null
      time: json['time'] ?? '', // Handle null
      status: json['status'] ?? '', // Handle null
    );
  }
}

class Course {
  final String courseName;
  final String? duration; // Made nullable since it can be null

  Course({required this.courseName, this.duration});

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseName: json['course_name'] ?? '', // Handle null with empty string
      duration: json['duration'] as String?, // Keep as nullable
    );
  }
}

class AttendanceMode {
  final String name;
  final String value;

  AttendanceMode({required this.name, required this.value});

  factory AttendanceMode.fromJson(Map<String, dynamic> json) {
    return AttendanceMode(
      name: json['name'] ?? '', // Handle null
      value: json['value'] ?? '', // Handle null
    );
  }
}

class PaymentInfo {
  final double grossAmount;
  final double totalDiscount;
  final double netAmount;
  final double amountPaid;
  final double pendingAmount;
  final double paymentCompletionPercentage;
  final bool isFullyPaid;
  final bool hasOverpayment;

  PaymentInfo({
    required this.grossAmount,
    required this.totalDiscount,
    required this.netAmount,
    required this.amountPaid,
    required this.pendingAmount,
    required this.paymentCompletionPercentage,
    required this.isFullyPaid,
    required this.hasOverpayment,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      grossAmount: (json['gross_amount'] ?? 0).toDouble(),
      totalDiscount: (json['total_discount'] ?? 0).toDouble(),
      netAmount: (json['net_amount'] ?? 0).toDouble(),
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      paymentCompletionPercentage: (json['payment_completion_percentage'] ?? 0)
          .toDouble(),
      isFullyPaid: json['is_fully_paid'] ?? false, // Handle null
      hasOverpayment: json['has_overpayment'] ?? false, // Handle null
    );
  }
}

class Progress {
  final double attendancePercentage;
  final double completionPercentage;
  final String finalGrade;
  final bool certificateIssued;
  final dynamic
  certificateIssueDate; // Keep as dynamic since it can be null or date string

  Progress({
    required this.attendancePercentage,
    required this.completionPercentage,
    required this.finalGrade,
    required this.certificateIssued,
    this.certificateIssueDate,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      attendancePercentage: (json['attendance_percentage'] ?? 0).toDouble(),
      completionPercentage: (json['completion_percentage'] ?? 0).toDouble(),
      finalGrade: json['final_grade'] ?? '', // Handle null with empty string
      certificateIssued: json['certificate_issued'] ?? false, // Handle null
      certificateIssueDate: json['certificate_issue_date'], // Can be null
    );
  }
}

class Summary {
  final int totalEnrollments;
  final int activeEnrollments;
  final int completedEnrollments;
  final int demoEnrollments;
  final double totalFeesPaid;
  final double totalFeesPending;

  Summary({
    required this.totalEnrollments,
    required this.activeEnrollments,
    required this.completedEnrollments,
    required this.demoEnrollments,
    required this.totalFeesPaid,
    required this.totalFeesPending,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalEnrollments: json['total_enrollments'] ?? 0, // Handle null
      activeEnrollments: json['active_enrollments'] ?? 0, // Handle null
      completedEnrollments: json['completed_enrollments'] ?? 0, // Handle null
      demoEnrollments: json['demo_enrollments'] ?? 0, // Handle null
      totalFeesPaid: (json['total_fees_paid'] ?? 0).toDouble(),
      totalFeesPending: (json['total_fees_pending'] ?? 0).toDouble(),
    );
  }
}
