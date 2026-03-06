class DashBoardModel {
  String? status;
  String? message;
  Dashboard? dashboard;
  DateTime? timestamp;

  DashBoardModel({this.status, this.message, this.dashboard, this.timestamp});

  factory DashBoardModel.fromJson(Map<String, dynamic> json) => DashBoardModel(
    status: json["status"],
    message: json["message"],
    dashboard: json["dashboard"] == null
        ? null
        : Dashboard.fromJson(json["dashboard"]),
    timestamp: json["timestamp"] == null
        ? null
        : DateTime.parse(json["timestamp"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "dashboard": dashboard?.toJson(),
    "timestamp": timestamp?.toIso8601String(),
  };
}

class Dashboard {
  StudentDetails? studentDetails;
  EnrollmentDetails? enrollmentDetails;
  BatchDetails? batchDetails;
  dynamic courseDetails;
  FinancialSummary? financialSummary;
  DashboardAcademicProgress? academicProgress;
  UpcomingActivities? upcomingActivities;
  QuickStats? quickStats;
  RecentActivities? recentActivities;
  NotificationsSummary? notificationsSummary;

  Dashboard({
    this.studentDetails,
    this.enrollmentDetails,
    this.batchDetails,
    this.courseDetails,
    this.financialSummary,
    this.academicProgress,
    this.upcomingActivities,
    this.quickStats,
    this.recentActivities,
    this.notificationsSummary,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    studentDetails: json["student_details"] == null
        ? null
        : StudentDetails.fromJson(json["student_details"]),
    enrollmentDetails: json["enrollment_details"] == null
        ? null
        : EnrollmentDetails.fromJson(json["enrollment_details"]),
    batchDetails: json["batch_details"] == null
        ? null
        : BatchDetails.fromJson(json["batch_details"]),
    courseDetails: json["course_details"],
    financialSummary: json["financial_summary"] == null
        ? null
        : FinancialSummary.fromJson(json["financial_summary"]),
    academicProgress: json["academic_progress"] == null
        ? null
        : DashboardAcademicProgress.fromJson(json["academic_progress"]),
    upcomingActivities: json["upcoming_activities"] == null
        ? null
        : UpcomingActivities.fromJson(json["upcoming_activities"]),
    quickStats: json["quick_stats"] == null
        ? null
        : QuickStats.fromJson(json["quick_stats"]),
    recentActivities: json["recent_activities"] == null
        ? null
        : RecentActivities.fromJson(json["recent_activities"]),
    notificationsSummary: json["notifications_summary"] == null
        ? null
        : NotificationsSummary.fromJson(json["notifications_summary"]),
  );

  Map<String, dynamic> toJson() => {
    "student_details": studentDetails?.toJson(),
    "enrollment_details": enrollmentDetails?.toJson(),
    "batch_details": batchDetails?.toJson(),
    "course_details": courseDetails,
    "financial_summary": financialSummary?.toJson(),
    "academic_progress": academicProgress?.toJson(),
    "upcoming_activities": upcomingActivities?.toJson(),
    "quick_stats": quickStats?.toJson(),
    "recent_activities": recentActivities?.toJson(),
    "notifications_summary": notificationsSummary?.toJson(),
  };
}

class DashboardAcademicProgress {
  OverallMetrics? overallMetrics;
  Certificates? certificates;
  List<PerformanceByCourse>? performanceByCourse;
  Achievements? achievements;

  DashboardAcademicProgress({
    this.overallMetrics,
    this.certificates,
    this.performanceByCourse,
    this.achievements,
  });

  factory DashboardAcademicProgress.fromJson(Map<String, dynamic> json) =>
      DashboardAcademicProgress(
        overallMetrics: json["overall_metrics"] == null
            ? null
            : OverallMetrics.fromJson(json["overall_metrics"]),
        certificates: json["certificates"] == null
            ? null
            : Certificates.fromJson(json["certificates"]),
        performanceByCourse: json["performance_by_course"] == null
            ? []
            : List<PerformanceByCourse>.from(
                json["performance_by_course"]!.map(
                  (x) => PerformanceByCourse.fromJson(x),
                ),
              ),
        achievements: json["achievements"] == null
            ? null
            : Achievements.fromJson(json["achievements"]),
      );

  Map<String, dynamic> toJson() => {
    "overall_metrics": overallMetrics?.toJson(),
    "certificates": certificates?.toJson(),
    "performance_by_course": performanceByCourse == null
        ? []
        : List<dynamic>.from(performanceByCourse!.map((x) => x.toJson())),
    "achievements": achievements?.toJson(),
  };
}

class Achievements {
  int? perfectAttendance;
  int? highPerformers;
  int? coursesWithGrades;

  Achievements({
    this.perfectAttendance,
    this.highPerformers,
    this.coursesWithGrades,
  });

  factory Achievements.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Achievements(
      perfectAttendance: toInt(json["perfect_attendance"]),
      highPerformers: toInt(json["high_performers"]),
      coursesWithGrades: toInt(json["courses_with_grades"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "perfect_attendance": perfectAttendance,
    "high_performers": highPerformers,
    "courses_with_grades": coursesWithGrades,
  };
}

class Certificates {
  int? totalCertificates;
  List<dynamic>? certificateList;

  Certificates({this.totalCertificates, this.certificateList});

  factory Certificates.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Certificates(
      totalCertificates: toInt(json["total_certificates"]),
      certificateList: json["certificate_list"] == null
          ? []
          : List<dynamic>.from(json["certificate_list"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_certificates": totalCertificates,
    "certificate_list": certificateList == null
        ? []
        : List<dynamic>.from(certificateList!.map((x) => x)),
  };
}

class OverallMetrics {
  int? totalCoursesEnrolled;
  int? completedCourses;
  int? activeCourses;
  int? completionRate;
  int? averageAttendancePercentage;
  int? averageCompletionPercentage;

  OverallMetrics({
    this.totalCoursesEnrolled,
    this.completedCourses,
    this.activeCourses,
    this.completionRate,
    this.averageAttendancePercentage,
    this.averageCompletionPercentage,
  });

  factory OverallMetrics.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return OverallMetrics(
      totalCoursesEnrolled: toInt(json["total_courses_enrolled"]),
      completedCourses: toInt(json["completed_courses"]),
      activeCourses: toInt(json["active_courses"]),
      completionRate: toInt(json["completion_rate"]),
      averageAttendancePercentage: toInt(json["average_attendance_percentage"]),
      averageCompletionPercentage: toInt(json["average_completion_percentage"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_courses_enrolled": totalCoursesEnrolled,
    "completed_courses": completedCourses,
    "active_courses": activeCourses,
    "completion_rate": completionRate,
    "average_attendance_percentage": averageAttendancePercentage,
    "average_completion_percentage": averageCompletionPercentage,
  };
}

class PerformanceByCourse {
  EnrollmentNumber? enrollmentNumber;
  String? courseName;
  BatchName? batchName;
  int? attendancePercentage;
  int? completionPercentage;
  String? finalGrade;
  String? status;
  bool? certificateIssued;

  PerformanceByCourse({
    this.enrollmentNumber,
    this.courseName,
    this.batchName,
    this.attendancePercentage,
    this.completionPercentage,
    this.finalGrade,
    this.status,
    this.certificateIssued,
  });

  factory PerformanceByCourse.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return PerformanceByCourse(
      enrollmentNumber: json["enrollment_number"] != null
          ? enrollmentNumberValues.map[json["enrollment_number"]]
          : null,
      courseName: json["course_name"],
      batchName: json["batch_name"] != null
          ? batchNameValues.map[json["batch_name"]]
          : null,
      attendancePercentage: toInt(json["attendance_percentage"]),
      completionPercentage: toInt(json["completion_percentage"]),
      finalGrade: json["final_grade"],
      status: json["status"],
      certificateIssued: json["certificate_issued"],
    );
  }

  Map<String, dynamic> toJson() => {
    "enrollment_number": enrollmentNumber != null
        ? enrollmentNumberValues.reverse[enrollmentNumber]
        : null,
    "course_name": courseName,
    "batch_name": batchName != null ? batchNameValues.reverse[batchName] : null,
    "attendance_percentage": attendancePercentage,
    "completion_percentage": completionPercentage,
    "final_grade": finalGrade,
    "status": status,
    "certificate_issued": certificateIssued,
  };
}

enum BatchName { GGF }

final batchNameValues = EnumValues({"ggf": BatchName.GGF});

enum EnrollmentNumber { ENR2026033570 }

final enrollmentNumberValues = EnumValues({
  "ENR2026033570": EnrollmentNumber.ENR2026033570,
});

class BatchDetails {
  List<dynamic>? currentBatches;
  int? totalCurrentBatches;
  bool? hasActiveBatches;
  List<dynamic>? upcomingBatches;
  int? completedBatchesCount;

  BatchDetails({
    this.currentBatches,
    this.totalCurrentBatches,
    this.hasActiveBatches,
    this.upcomingBatches,
    this.completedBatchesCount,
  });

  factory BatchDetails.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return BatchDetails(
      currentBatches: json["current_batches"] == null
          ? []
          : List<dynamic>.from(json["current_batches"]!.map((x) => x)),
      totalCurrentBatches: toInt(json["total_current_batches"]),
      hasActiveBatches: json["has_active_batches"],
      upcomingBatches: json["upcoming_batches"] == null
          ? []
          : List<dynamic>.from(json["upcoming_batches"]!.map((x) => x)),
      completedBatchesCount: toInt(json["completed_batches_count"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "current_batches": currentBatches == null
        ? []
        : List<dynamic>.from(currentBatches!.map((x) => x)),
    "total_current_batches": totalCurrentBatches,
    "has_active_batches": hasActiveBatches,
    "upcoming_batches": upcomingBatches == null
        ? []
        : List<dynamic>.from(upcomingBatches!.map((x) => x)),
    "completed_batches_count": completedBatchesCount,
  };
}

class EnrollmentDetails {
  List<Enrollment>? enrollments;
  EnrollmentDetailsSummary? summary;
  dynamic currentActiveEnrollment;

  EnrollmentDetails({
    this.enrollments,
    this.summary,
    this.currentActiveEnrollment,
  });

  factory EnrollmentDetails.fromJson(Map<String, dynamic> json) =>
      EnrollmentDetails(
        enrollments: json["enrollments"] == null
            ? []
            : List<Enrollment>.from(
                json["enrollments"]!.map((x) => Enrollment.fromJson(x)),
              ),
        summary: json["summary"] == null
            ? null
            : EnrollmentDetailsSummary.fromJson(json["summary"]),
        currentActiveEnrollment: json["current_active_enrollment"],
      );

  Map<String, dynamic> toJson() => {
    "enrollments": enrollments == null
        ? []
        : List<dynamic>.from(enrollments!.map((x) => x.toJson())),
    "summary": summary?.toJson(),
    "current_active_enrollment": currentActiveEnrollment,
  };
}

class Enrollment {
  EnrollmentBasicInfo? basicInfo;
  CurrentStatus? status;
  BatchInfo? batchInfo;
  CourseInfo? courseInfo;
  CurrentStatus? attendanceMode;
  PaymentDetails? paymentDetails;
  EnrollmentAcademicProgress? academicProgress;
  DemoInfo? demoInfo;
  Counselors? counselors;
  AdditionalInfo? additionalInfo;

  Enrollment({
    this.basicInfo,
    this.status,
    this.batchInfo,
    this.courseInfo,
    this.attendanceMode,
    this.paymentDetails,
    this.academicProgress,
    this.demoInfo,
    this.counselors,
    this.additionalInfo,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
    basicInfo: json["basic_info"] == null
        ? null
        : EnrollmentBasicInfo.fromJson(json["basic_info"]),
    status: json["status"] == null
        ? null
        : CurrentStatus.fromJson(json["status"]),
    batchInfo: json["batch_info"] == null
        ? null
        : BatchInfo.fromJson(json["batch_info"]),
    courseInfo: json["course_info"] == null
        ? null
        : CourseInfo.fromJson(json["course_info"]),
    attendanceMode: json["attendance_mode"] == null
        ? null
        : CurrentStatus.fromJson(json["attendance_mode"]),
    paymentDetails: json["payment_details"] == null
        ? null
        : PaymentDetails.fromJson(json["payment_details"]),
    academicProgress: json["academic_progress"] == null
        ? null
        : EnrollmentAcademicProgress.fromJson(json["academic_progress"]),
    demoInfo: json["demo_info"] == null
        ? null
        : DemoInfo.fromJson(json["demo_info"]),
    counselors: json["counselors"] == null
        ? null
        : Counselors.fromJson(json["counselors"]),
    additionalInfo: json["additional_info"] == null
        ? null
        : AdditionalInfo.fromJson(json["additional_info"]),
  );

  Map<String, dynamic> toJson() => {
    "basic_info": basicInfo?.toJson(),
    "status": status?.toJson(),
    "batch_info": batchInfo?.toJson(),
    "course_info": courseInfo?.toJson(),
    "attendance_mode": attendanceMode?.toJson(),
    "payment_details": paymentDetails?.toJson(),
    "academic_progress": academicProgress?.toJson(),
    "demo_info": demoInfo?.toJson(),
    "counselors": counselors?.toJson(),
    "additional_info": additionalInfo?.toJson(),
  };
}

class EnrollmentAcademicProgress {
  int? attendancePercentage;
  int? completionPercentage;
  String? finalGrade;
  bool? certificateIssued;
  dynamic certificateIssueDate;

  EnrollmentAcademicProgress({
    this.attendancePercentage,
    this.completionPercentage,
    this.finalGrade,
    this.certificateIssued,
    this.certificateIssueDate,
  });

  factory EnrollmentAcademicProgress.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return EnrollmentAcademicProgress(
      attendancePercentage: toInt(json["attendance_percentage"]),
      completionPercentage: toInt(json["completion_percentage"]),
      finalGrade: json["final_grade"],
      certificateIssued: json["certificate_issued"],
      certificateIssueDate: json["certificate_issue_date"],
    );
  }

  Map<String, dynamic> toJson() => {
    "attendance_percentage": attendancePercentage,
    "completion_percentage": completionPercentage,
    "final_grade": finalGrade,
    "certificate_issued": certificateIssued,
    "certificate_issue_date": certificateIssueDate,
  };
}

class AdditionalInfo {
  String? specialNotes;
  List<dynamic>? tags;
  bool? isFamilyEnrollment;
  DateTime? lastActivityDate;

  AdditionalInfo({
    this.specialNotes,
    this.tags,
    this.isFamilyEnrollment,
    this.lastActivityDate,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) => AdditionalInfo(
    specialNotes: json["special_notes"],
    tags: json["tags"] == null
        ? []
        : List<dynamic>.from(json["tags"]!.map((x) => x)),
    isFamilyEnrollment: json["is_family_enrollment"],
    lastActivityDate: json["last_activity_date"] == null
        ? null
        : DateTime.parse(json["last_activity_date"]),
  );

  Map<String, dynamic> toJson() => {
    "special_notes": specialNotes,
    "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
    "is_family_enrollment": isFamilyEnrollment,
    "last_activity_date": lastActivityDate?.toIso8601String(),
  };
}

class CurrentStatus {
  String? name;
  String? value;
  String? description;
  String? color;

  CurrentStatus({this.name, this.value, this.description, this.color});

  factory CurrentStatus.fromJson(Map<String, dynamic> json) => CurrentStatus(
    name: json["name"],
    value: json["value"],
    description: json["description"],
    color: json["color"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "value": value,
    "description": description,
    "color": color,
  };
}

class EnrollmentBasicInfo {
  String? uid;
  EnrollmentNumber? enrollmentNumber;
  DateTime? enrollmentDate;
  String? source;
  bool? crmAccess;
  int? daysSinceEnrollment;

  EnrollmentBasicInfo({
    this.uid,
    this.enrollmentNumber,
    this.enrollmentDate,
    this.source,
    this.crmAccess,
    this.daysSinceEnrollment,
  });

  factory EnrollmentBasicInfo.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return EnrollmentBasicInfo(
      uid: json["uid"],
      enrollmentNumber: json["enrollment_number"] != null
          ? enrollmentNumberValues.map[json["enrollment_number"]]
          : null,
      enrollmentDate: json["enrollment_date"] == null
          ? null
          : DateTime.parse(json["enrollment_date"]),
      source: json["source"],
      crmAccess: json["crm_access"],
      daysSinceEnrollment: toInt(json["days_since_enrollment"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "enrollment_number": enrollmentNumber != null
        ? enrollmentNumberValues.reverse[enrollmentNumber]
        : null,
    "enrollment_date": enrollmentDate?.toIso8601String(),
    "source": source,
    "crm_access": crmAccess,
    "days_since_enrollment": daysSinceEnrollment,
  };
}

class BatchInfo {
  String? uid;
  BatchName? batchName;
  DateTime? startDate;
  DateTime? endDate;
  String? time;
  String? status;
  dynamic batchType;
  dynamic maxStudents;
  dynamic currentStudents;
  int? durationInDays;
  bool? isActive;
  bool? isCompleted;
  int? admissionFees;
  Sessions? sessions;

  BatchInfo({
    this.uid,
    this.batchName,
    this.startDate,
    this.endDate,
    this.time,
    this.status,
    this.batchType,
    this.maxStudents,
    this.currentStudents,
    this.durationInDays,
    this.isActive,
    this.isCompleted,
    this.admissionFees,
    this.sessions,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return BatchInfo(
      uid: json["uid"],
      batchName: json["batch_name"] != null
          ? batchNameValues.map[json["batch_name"]]
          : null,
      startDate: json["start_date"] == null
          ? null
          : DateTime.parse(json["start_date"]),
      endDate: json["end_date"] == null
          ? null
          : DateTime.parse(json["end_date"]),
      time: json["time"],
      status: json["status"],
      batchType: json["batch_type"],
      maxStudents: json["max_students"],
      currentStudents: json["current_students"],
      durationInDays: toInt(json["duration_in_days"]),
      isActive: json["is_active"],
      isCompleted: json["is_completed"],
      admissionFees: toInt(json["admission_fees"]),
      sessions: json["sessions"] == null
          ? null
          : Sessions.fromJson(json["sessions"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "batch_name": batchName != null ? batchNameValues.reverse[batchName] : null,
    "start_date": startDate != null
        ? "${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}"
        : null,
    "end_date": endDate != null
        ? "${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}"
        : null,
    "time": time,
    "status": status,
    "batch_type": batchType,
    "max_students": maxStudents,
    "current_students": currentStudents,
    "duration_in_days": durationInDays,
    "is_active": isActive,
    "is_completed": isCompleted,
    "admission_fees": admissionFees,
    "sessions": sessions?.toJson(),
  };
}

class Sessions {
  int? count;
  List<dynamic>? topics;

  Sessions({this.count, this.topics});

  factory Sessions.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Sessions(
      count: toInt(json["count"]),
      topics: json["topics"] == null
          ? []
          : List<dynamic>.from(json["topics"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "count": count,
    "topics": topics == null ? [] : List<dynamic>.from(topics!.map((x) => x)),
  };
}

class Counselors {
  FullName? enrollmentCounselor;
  dynamic academicCounselor;
  String? admissionCounselor;

  Counselors({
    this.enrollmentCounselor,
    this.academicCounselor,
    this.admissionCounselor,
  });

  factory Counselors.fromJson(Map<String, dynamic> json) => Counselors(
    enrollmentCounselor: json["enrollment_counselor"] != null
        ? fullNameValues.map[json["enrollment_counselor"]]
        : null,
    academicCounselor: json["academic_counselor"],
    admissionCounselor: json["admission_counselor"],
  );

  Map<String, dynamic> toJson() => {
    "enrollment_counselor": enrollmentCounselor != null
        ? fullNameValues.reverse[enrollmentCounselor]
        : null,
    "academic_counselor": academicCounselor,
    "admission_counselor": admissionCounselor,
  };
}

enum FullName { AMNANABEEL, M_BTEST, SYSTEM }

final fullNameValues = EnumValues({
  "amnanabeel": FullName.AMNANABEEL,
  "MBtest": FullName.M_BTEST,
  "System": FullName.SYSTEM,
});

class CourseInfo {
  String? courseName;
  dynamic courseCode;
  dynamic durationMonths;
  dynamic description;

  CourseInfo({
    this.courseName,
    this.courseCode,
    this.durationMonths,
    this.description,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) => CourseInfo(
    courseName: json["course_name"],
    courseCode: json["course_code"],
    durationMonths: json["duration_months"],
    description: json["description"],
  );

  Map<String, dynamic> toJson() => {
    "course_name": courseName,
    "course_code": courseCode,
    "duration_months": durationMonths,
    "description": description,
  };
}

class DemoInfo {
  DateTime? demoStartDate;
  DateTime? demoEndDate;
  DateTime? demoConversionDate;
  bool? demoFollowUpRequired;
  bool? isDemoPeriod;
  int? demoDaysRemaining;

  DemoInfo({
    this.demoStartDate,
    this.demoEndDate,
    this.demoConversionDate,
    this.demoFollowUpRequired,
    this.isDemoPeriod,
    this.demoDaysRemaining,
  });

  factory DemoInfo.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return DemoInfo(
      demoStartDate: json["demo_start_date"] == null
          ? null
          : DateTime.parse(json["demo_start_date"]),
      demoEndDate: json["demo_end_date"] == null
          ? null
          : DateTime.parse(json["demo_end_date"]),
      demoConversionDate: json["demo_conversion_date"] == null
          ? null
          : DateTime.parse(json["demo_conversion_date"]),
      demoFollowUpRequired: json["demo_follow_up_required"],
      isDemoPeriod: json["is_demo_period"],
      demoDaysRemaining: toInt(json["demo_days_remaining"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "demo_start_date": demoStartDate?.toIso8601String(),
    "demo_end_date": demoEndDate?.toIso8601String(),
    "demo_conversion_date": demoConversionDate?.toIso8601String(),
    "demo_follow_up_required": demoFollowUpRequired,
    "is_demo_period": isDemoPeriod,
    "demo_days_remaining": demoDaysRemaining,
  };
}

class PaymentDetails {
  String? paymentType;
  Breakdown? financialBreakdown;
  dynamic emiPlan;

  PaymentDetails({this.paymentType, this.financialBreakdown, this.emiPlan});

  factory PaymentDetails.fromJson(Map<String, dynamic> json) => PaymentDetails(
    paymentType: json["payment_type"],
    financialBreakdown: json["financial_breakdown"] == null
        ? null
        : Breakdown.fromJson(json["financial_breakdown"]),
    emiPlan: json["emi_plan"],
  );

  Map<String, dynamic> toJson() => {
    "payment_type": paymentType,
    "financial_breakdown": financialBreakdown?.toJson(),
    "emi_plan": emiPlan,
  };
}

class Breakdown {
  int? grossAmount;
  int? totalDiscount;
  int? netAmount;
  int? amountPaid;
  int? pendingAmount;
  int? paymentCompletionPercentage;
  bool? isFullyPaid;
  bool? hasOverpayment;

  Breakdown({
    this.grossAmount,
    this.totalDiscount,
    this.netAmount,
    this.amountPaid,
    this.pendingAmount,
    this.paymentCompletionPercentage,
    this.isFullyPaid,
    this.hasOverpayment,
  });

  factory Breakdown.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Breakdown(
      grossAmount: toInt(json["gross_amount"]),
      totalDiscount: toInt(json["total_discount"]),
      netAmount: toInt(json["net_amount"]),
      amountPaid: toInt(json["amount_paid"]),
      pendingAmount: toInt(json["pending_amount"]),
      paymentCompletionPercentage: toInt(json["payment_completion_percentage"]),
      isFullyPaid: json["is_fully_paid"],
      hasOverpayment: json["has_overpayment"],
    );
  }

  Map<String, dynamic> toJson() => {
    "gross_amount": grossAmount,
    "total_discount": totalDiscount,
    "net_amount": netAmount,
    "amount_paid": amountPaid,
    "pending_amount": pendingAmount,
    "payment_completion_percentage": paymentCompletionPercentage,
    "is_fully_paid": isFullyPaid,
    "has_overpayment": hasOverpayment,
  };
}

class EnrollmentDetailsSummary {
  int? totalEnrollments;
  int? activeEnrollments;
  int? completedEnrollments;
  int? demoEnrollments;
  int? onHoldEnrollments;
  int? droppedEnrollments;

  EnrollmentDetailsSummary({
    this.totalEnrollments,
    this.activeEnrollments,
    this.completedEnrollments,
    this.demoEnrollments,
    this.onHoldEnrollments,
    this.droppedEnrollments,
  });

  factory EnrollmentDetailsSummary.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return EnrollmentDetailsSummary(
      totalEnrollments: toInt(json["total_enrollments"]),
      activeEnrollments: toInt(json["active_enrollments"]),
      completedEnrollments: toInt(json["completed_enrollments"]),
      demoEnrollments: toInt(json["demo_enrollments"]),
      onHoldEnrollments: toInt(json["on_hold_enrollments"]),
      droppedEnrollments: toInt(json["dropped_enrollments"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_enrollments": totalEnrollments,
    "active_enrollments": activeEnrollments,
    "completed_enrollments": completedEnrollments,
    "demo_enrollments": demoEnrollments,
    "on_hold_enrollments": onHoldEnrollments,
    "dropped_enrollments": droppedEnrollments,
  };
}

class FinancialSummary {
  Overview? overview;
  PaymentSummary? paymentSummary;
  EmiInformation? emiInformation;
  List<EnrollmentWiseBreakdown>? enrollmentWiseBreakdown;

  FinancialSummary({
    this.overview,
    this.paymentSummary,
    this.emiInformation,
    this.enrollmentWiseBreakdown,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) =>
      FinancialSummary(
        overview: json["overview"] == null
            ? null
            : Overview.fromJson(json["overview"]),
        paymentSummary: json["payment_summary"] == null
            ? null
            : PaymentSummary.fromJson(json["payment_summary"]),
        emiInformation: json["emi_information"] == null
            ? null
            : EmiInformation.fromJson(json["emi_information"]),
        enrollmentWiseBreakdown: json["enrollment_wise_breakdown"] == null
            ? []
            : List<EnrollmentWiseBreakdown>.from(
                json["enrollment_wise_breakdown"]!.map(
                  (x) => EnrollmentWiseBreakdown.fromJson(x),
                ),
              ),
      );

  Map<String, dynamic> toJson() => {
    "overview": overview?.toJson(),
    "payment_summary": paymentSummary?.toJson(),
    "emi_information": emiInformation?.toJson(),
    "enrollment_wise_breakdown": enrollmentWiseBreakdown == null
        ? []
        : List<dynamic>.from(enrollmentWiseBreakdown!.map((x) => x.toJson())),
  };
}

class EmiInformation {
  List<dynamic>? hasEmiEnrollments;
  int? totalPendingEmis;
  int? totalOverdueEmis;
  dynamic nextEmiDueDate;
  dynamic nextEmiAmount;
  int? totalPendingEmiAmount;
  int? totalOverdueAmount;
  List<dynamic>? upcomingEmis;
  List<dynamic>? overdueEmis;

  EmiInformation({
    this.hasEmiEnrollments,
    this.totalPendingEmis,
    this.totalOverdueEmis,
    this.nextEmiDueDate,
    this.nextEmiAmount,
    this.totalPendingEmiAmount,
    this.totalOverdueAmount,
    this.upcomingEmis,
    this.overdueEmis,
  });

  factory EmiInformation.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return EmiInformation(
      hasEmiEnrollments: json["has_emi_enrollments"] == null
          ? []
          : List<dynamic>.from(json["has_emi_enrollments"]!.map((x) => x)),
      totalPendingEmis: toInt(json["total_pending_emis"]),
      totalOverdueEmis: toInt(json["total_overdue_emis"]),
      nextEmiDueDate: json["next_emi_due_date"],
      nextEmiAmount: json["next_emi_amount"],
      totalPendingEmiAmount: toInt(json["total_pending_emi_amount"]),
      totalOverdueAmount: toInt(json["total_overdue_amount"]),
      upcomingEmis: json["upcoming_emis"] == null
          ? []
          : List<dynamic>.from(json["upcoming_emis"]!.map((x) => x)),
      overdueEmis: json["overdue_emis"] == null
          ? []
          : List<dynamic>.from(json["overdue_emis"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "has_emi_enrollments": hasEmiEnrollments == null
        ? []
        : List<dynamic>.from(hasEmiEnrollments!.map((x) => x)),
    "total_pending_emis": totalPendingEmis,
    "total_overdue_emis": totalOverdueEmis,
    "next_emi_due_date": nextEmiDueDate,
    "next_emi_amount": nextEmiAmount,
    "total_pending_emi_amount": totalPendingEmiAmount,
    "total_overdue_amount": totalOverdueAmount,
    "upcoming_emis": upcomingEmis == null
        ? []
        : List<dynamic>.from(upcomingEmis!.map((x) => x)),
    "overdue_emis": overdueEmis == null
        ? []
        : List<dynamic>.from(overdueEmis!.map((x) => x)),
  };
}

class EnrollmentWiseBreakdown {
  EnrollmentNumber? enrollmentNumber;
  BatchName? batchName;
  Breakdown? paymentBreakdown;
  String? paymentType;

  EnrollmentWiseBreakdown({
    this.enrollmentNumber,
    this.batchName,
    this.paymentBreakdown,
    this.paymentType,
  });

  factory EnrollmentWiseBreakdown.fromJson(Map<String, dynamic> json) =>
      EnrollmentWiseBreakdown(
        enrollmentNumber: json["enrollment_number"] != null
            ? enrollmentNumberValues.map[json["enrollment_number"]]
            : null,
        batchName: json["batch_name"] != null
            ? batchNameValues.map[json["batch_name"]]
            : null,
        paymentBreakdown: json["payment_breakdown"] == null
            ? null
            : Breakdown.fromJson(json["payment_breakdown"]),
        paymentType: json["payment_type"],
      );

  Map<String, dynamic> toJson() => {
    "enrollment_number": enrollmentNumber != null
        ? enrollmentNumberValues.reverse[enrollmentNumber]
        : null,
    "batch_name": batchName != null ? batchNameValues.reverse[batchName] : null,
    "payment_breakdown": paymentBreakdown?.toJson(),
    "payment_type": paymentType,
  };
}

class Overview {
  int? totalFeesPaid;
  int? totalFeesPending;
  int? totalFeesAmount;
  int? paymentCompletionPercentage;
  String? paymentStatus;

  Overview({
    this.totalFeesPaid,
    this.totalFeesPending,
    this.totalFeesAmount,
    this.paymentCompletionPercentage,
    this.paymentStatus,
  });

  factory Overview.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Overview(
      totalFeesPaid: toInt(json["total_fees_paid"]),
      totalFeesPending: toInt(json["total_fees_pending"]),
      totalFeesAmount: toInt(json["total_fees_amount"]),
      paymentCompletionPercentage: toInt(json["payment_completion_percentage"]),
      paymentStatus: json["payment_status"],
    );
  }

  Map<String, dynamic> toJson() => {
    "total_fees_paid": totalFeesPaid,
    "total_fees_pending": totalFeesPending,
    "total_fees_amount": totalFeesAmount,
    "payment_completion_percentage": paymentCompletionPercentage,
    "payment_status": paymentStatus,
  };
}

class PaymentSummary {
  int? totalTransactions;
  int? totalAmountPaidViaTransactions;
  int? averagePaymentAmount;
  DateTime? lastPaymentDate;
  int? lastPaymentAmount;

  PaymentSummary({
    this.totalTransactions,
    this.totalAmountPaidViaTransactions,
    this.averagePaymentAmount,
    this.lastPaymentDate,
    this.lastPaymentAmount,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return PaymentSummary(
      totalTransactions: toInt(json["total_transactions"]),
      totalAmountPaidViaTransactions: toInt(
        json["total_amount_paid_via_transactions"],
      ),
      averagePaymentAmount: toInt(json["average_payment_amount"]),
      lastPaymentDate: json["last_payment_date"] == null
          ? null
          : DateTime.parse(json["last_payment_date"]),
      lastPaymentAmount: toInt(json["last_payment_amount"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_transactions": totalTransactions,
    "total_amount_paid_via_transactions": totalAmountPaidViaTransactions,
    "average_payment_amount": averagePaymentAmount,
    "last_payment_date": lastPaymentDate?.toIso8601String(),
    "last_payment_amount": lastPaymentAmount,
  };
}

class NotificationsSummary {
  NotificationsSummarySummary? summary;
  List<dynamic>? recentNotifications;
  List<dynamic>? urgentNotifications;

  NotificationsSummary({
    this.summary,
    this.recentNotifications,
    this.urgentNotifications,
  });

  factory NotificationsSummary.fromJson(Map<String, dynamic> json) =>
      NotificationsSummary(
        summary: json["summary"] == null
            ? null
            : NotificationsSummarySummary.fromJson(json["summary"]),
        recentNotifications: json["recent_notifications"] == null
            ? []
            : List<dynamic>.from(json["recent_notifications"]!.map((x) => x)),
        urgentNotifications: json["urgent_notifications"] == null
            ? []
            : List<dynamic>.from(json["urgent_notifications"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
    "summary": summary?.toJson(),
    "recent_notifications": recentNotifications == null
        ? []
        : List<dynamic>.from(recentNotifications!.map((x) => x)),
    "urgent_notifications": urgentNotifications == null
        ? []
        : List<dynamic>.from(urgentNotifications!.map((x) => x)),
  };
}

class NotificationsSummarySummary {
  int? totalNotifications;
  int? unreadCount;
  int? urgentCount;
  int? notificationsToday;

  NotificationsSummarySummary({
    this.totalNotifications,
    this.unreadCount,
    this.urgentCount,
    this.notificationsToday,
  });

  factory NotificationsSummarySummary.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return NotificationsSummarySummary(
      totalNotifications: toInt(json["total_notifications"]),
      unreadCount: toInt(json["unread_count"]),
      urgentCount: toInt(json["urgent_count"]),
      notificationsToday: toInt(json["notifications_today"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_notifications": totalNotifications,
    "unread_count": unreadCount,
    "urgent_count": urgentCount,
    "notifications_today": notificationsToday,
  };
}

class QuickStats {
  Academic? academic;
  Financial? financial;
  Engagement? engagement;
  Alerts? alerts;

  QuickStats({this.academic, this.financial, this.engagement, this.alerts});

  factory QuickStats.fromJson(Map<String, dynamic> json) => QuickStats(
    academic: json["academic"] == null
        ? null
        : Academic.fromJson(json["academic"]),
    financial: json["financial"] == null
        ? null
        : Financial.fromJson(json["financial"]),
    engagement: json["engagement"] == null
        ? null
        : Engagement.fromJson(json["engagement"]),
    alerts: json["alerts"] == null ? null : Alerts.fromJson(json["alerts"]),
  );

  Map<String, dynamic> toJson() => {
    "academic": academic?.toJson(),
    "financial": financial?.toJson(),
    "engagement": engagement?.toJson(),
    "alerts": alerts?.toJson(),
  };
}

class Academic {
  int? totalCourses;
  int? activeCourses;
  int? completedCourses;
  int? certificatesEarned;
  int? completionRate;

  Academic({
    this.totalCourses,
    this.activeCourses,
    this.completedCourses,
    this.certificatesEarned,
    this.completionRate,
  });

  factory Academic.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Academic(
      totalCourses: toInt(json["total_courses"]),
      activeCourses: toInt(json["active_courses"]),
      completedCourses: toInt(json["completed_courses"]),
      certificatesEarned: toInt(json["certificates_earned"]),
      completionRate: toInt(json["completion_rate"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_courses": totalCourses,
    "active_courses": activeCourses,
    "completed_courses": completedCourses,
    "certificates_earned": certificatesEarned,
    "completion_rate": completionRate,
  };
}

class Alerts {
  bool? hasPendingPayments;
  bool? hasOverdueEmis;
  bool? demoExpiringSoon;
  bool? paymentGraceExpired;

  Alerts({
    this.hasPendingPayments,
    this.hasOverdueEmis,
    this.demoExpiringSoon,
    this.paymentGraceExpired,
  });

  factory Alerts.fromJson(Map<String, dynamic> json) => Alerts(
    hasPendingPayments: json["has_pending_payments"],
    hasOverdueEmis: json["has_overdue_emis"],
    demoExpiringSoon: json["demo_expiring_soon"],
    paymentGraceExpired: json["payment_grace_expired"],
  );

  Map<String, dynamic> toJson() => {
    "has_pending_payments": hasPendingPayments,
    "has_overdue_emis": hasOverdueEmis,
    "demo_expiring_soon": demoExpiringSoon,
    "payment_grace_expired": paymentGraceExpired,
  };
}

class Engagement {
  int? daysSinceAdmission;
  int? referralsMade;
  bool? isAlumni;
  bool? isPlaced;

  Engagement({
    this.daysSinceAdmission,
    this.referralsMade,
    this.isAlumni,
    this.isPlaced,
  });

  factory Engagement.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Engagement(
      daysSinceAdmission: toInt(json["days_since_admission"]),
      referralsMade: toInt(json["referrals_made"]),
      isAlumni: json["is_alumni"],
      isPlaced: json["is_placed"],
    );
  }

  Map<String, dynamic> toJson() => {
    "days_since_admission": daysSinceAdmission,
    "referrals_made": referralsMade,
    "is_alumni": isAlumni,
    "is_placed": isPlaced,
  };
}

class Financial {
  int? totalPaid;
  int? totalPending;
  int? paymentCompletion;
  int? pendingEmis;
  int? overdueEmis;

  Financial({
    this.totalPaid,
    this.totalPending,
    this.paymentCompletion,
    this.pendingEmis,
    this.overdueEmis,
  });

  factory Financial.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Financial(
      totalPaid: toInt(json["total_paid"]),
      totalPending: toInt(json["total_pending"]),
      paymentCompletion: toInt(json["payment_completion"]),
      pendingEmis: toInt(json["pending_emis"]),
      overdueEmis: toInt(json["overdue_emis"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_paid": totalPaid,
    "total_pending": totalPending,
    "payment_completion": paymentCompletion,
    "pending_emis": pendingEmis,
    "overdue_emis": overdueEmis,
  };
}

class RecentActivities {
  List<EntActivity>? recentActivities;
  Categorized? categorized;
  RecentActivitiesSummary? summary;

  RecentActivities({this.recentActivities, this.categorized, this.summary});

  factory RecentActivities.fromJson(Map<String, dynamic> json) =>
      RecentActivities(
        recentActivities: json["recent_activities"] == null
            ? []
            : List<EntActivity>.from(
                json["recent_activities"]!.map((x) => EntActivity.fromJson(x)),
              ),
        categorized: json["categorized"] == null
            ? null
            : Categorized.fromJson(json["categorized"]),
        summary: json["summary"] == null
            ? null
            : RecentActivitiesSummary.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "recent_activities": recentActivities == null
        ? []
        : List<dynamic>.from(recentActivities!.map((x) => x.toJson())),
    "categorized": categorized?.toJson(),
    "summary": summary?.toJson(),
  };
}

class Categorized {
  List<EntActivity>? paymentActivities;
  List<dynamic>? enrollmentActivities;
  List<dynamic>? academicActivities;

  Categorized({
    this.paymentActivities,
    this.enrollmentActivities,
    this.academicActivities,
  });

  factory Categorized.fromJson(Map<String, dynamic> json) {
    return Categorized(
      paymentActivities: json["payment_activities"] == null
          ? []
          : List<EntActivity>.from(
              json["payment_activities"]!.map((x) => EntActivity.fromJson(x)),
            ),
      enrollmentActivities: json["enrollment_activities"] == null
          ? []
          : List<dynamic>.from(json["enrollment_activities"]!.map((x) => x)),
      academicActivities: json["academic_activities"] == null
          ? []
          : List<dynamic>.from(json["academic_activities"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "payment_activities": paymentActivities == null
        ? []
        : List<dynamic>.from(paymentActivities!.map((x) => x.toJson())),
    "enrollment_activities": enrollmentActivities == null
        ? []
        : List<dynamic>.from(enrollmentActivities!.map((x) => x)),
    "academic_activities": academicActivities == null
        ? []
        : List<dynamic>.from(academicActivities!.map((x) => x)),
  };
}

class EntActivity {
  String? uid;
  String? type;
  String? title;
  String? description;
  int? amount;
  DateTime? date;
  FullName? performedBy;
  Priority? priority;
  EnrollmentInfo? enrollmentInfo;
  bool? requiresFollowUp;
  List<dynamic>? tags;

  EntActivity({
    this.uid,
    this.type,
    this.title,
    this.description,
    this.amount,
    this.date,
    this.performedBy,
    this.priority,
    this.enrollmentInfo,
    this.requiresFollowUp,
    this.tags,
  });

  factory EntActivity.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return EntActivity(
      uid: json["uid"],
      type: json["type"],
      title: json["title"],
      description: json["description"],
      amount: toInt(json["amount"]),
      date: json["date"] == null ? null : DateTime.parse(json["date"]),
      performedBy: json["performed_by"] != null
          ? fullNameValues.map[json["performed_by"]]
          : null,
      priority: json["priority"] != null
          ? priorityValues.map[json["priority"]]
          : null,
      enrollmentInfo: json["enrollment_info"] == null
          ? null
          : EnrollmentInfo.fromJson(json["enrollment_info"]),
      requiresFollowUp: json["requires_follow_up"],
      tags: json["tags"] == null
          ? []
          : List<dynamic>.from(json["tags"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "type": type,
    "title": title,
    "description": description,
    "amount": amount,
    "date": date?.toIso8601String(),
    "performed_by": performedBy != null
        ? fullNameValues.reverse[performedBy]
        : null,
    "priority": priority != null ? priorityValues.reverse[priority] : null,
    "enrollment_info": enrollmentInfo?.toJson(),
    "requires_follow_up": requiresFollowUp,
    "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
  };
}

class EnrollmentInfo {
  EnrollmentNumber? enrollmentNumber;
  BatchName? batchName;

  EnrollmentInfo({this.enrollmentNumber, this.batchName});

  factory EnrollmentInfo.fromJson(Map<String, dynamic> json) => EnrollmentInfo(
    enrollmentNumber: json["enrollment_number"] != null
        ? enrollmentNumberValues.map[json["enrollment_number"]]
        : null,
    batchName: json["batch_name"] != null
        ? batchNameValues.map[json["batch_name"]]
        : null,
  );

  Map<String, dynamic> toJson() => {
    "enrollment_number": enrollmentNumber != null
        ? enrollmentNumberValues.reverse[enrollmentNumber]
        : null,
    "batch_name": batchName != null ? batchNameValues.reverse[batchName] : null,
  };
}

enum Priority { MEDIUM }

final priorityValues = EnumValues({"medium": Priority.MEDIUM});

class RecentActivitiesSummary {
  int? totalActivities;
  int? activitiesToday;
  int? activitiesThisWeek;
  int? pendingFollowUps;

  RecentActivitiesSummary({
    this.totalActivities,
    this.activitiesToday,
    this.activitiesThisWeek,
    this.pendingFollowUps,
  });

  factory RecentActivitiesSummary.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return RecentActivitiesSummary(
      totalActivities: toInt(json["total_activities"]),
      activitiesToday: toInt(json["activities_today"]),
      activitiesThisWeek: toInt(json["activities_this_week"]),
      pendingFollowUps: toInt(json["pending_follow_ups"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total_activities": totalActivities,
    "activities_today": activitiesToday,
    "activities_this_week": activitiesThisWeek,
    "pending_follow_ups": pendingFollowUps,
  };
}

class StudentDetails {
  StudentDetailsBasicInfo? basicInfo;
  PersonalInfo? personalInfo;
  AcademicBackground? academicBackground;
  AddressInfo? addressInfo;
  ProfessionalInfo? professionalInfo;
  FamilyInfo? familyInfo;
  StatusInfo? statusInfo;
  CounselorInfo? counselorInfo;
  dynamic placementInfo;
  ReferralInfo? referralInfo;

  StudentDetails({
    this.basicInfo,
    this.personalInfo,
    this.academicBackground,
    this.addressInfo,
    this.professionalInfo,
    this.familyInfo,
    this.statusInfo,
    this.counselorInfo,
    this.placementInfo,
    this.referralInfo,
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) => StudentDetails(
    basicInfo: json["basic_info"] == null
        ? null
        : StudentDetailsBasicInfo.fromJson(json["basic_info"]),
    personalInfo: json["personal_info"] == null
        ? null
        : PersonalInfo.fromJson(json["personal_info"]),
    academicBackground: json["academic_background"] == null
        ? null
        : AcademicBackground.fromJson(json["academic_background"]),
    addressInfo: json["address_info"] == null
        ? null
        : AddressInfo.fromJson(json["address_info"]),
    professionalInfo: json["professional_info"] == null
        ? null
        : ProfessionalInfo.fromJson(json["professional_info"]),
    familyInfo: json["family_info"] == null
        ? null
        : FamilyInfo.fromJson(json["family_info"]),
    statusInfo: json["status_info"] == null
        ? null
        : StatusInfo.fromJson(json["status_info"]),
    counselorInfo: json["counselor_info"] == null
        ? null
        : CounselorInfo.fromJson(json["counselor_info"]),
    placementInfo: json["placement_info"],
    referralInfo: json["referral_info"] == null
        ? null
        : ReferralInfo.fromJson(json["referral_info"]),
  );

  Map<String, dynamic> toJson() => {
    "basic_info": basicInfo?.toJson(),
    "personal_info": personalInfo?.toJson(),
    "academic_background": academicBackground?.toJson(),
    "address_info": addressInfo?.toJson(),
    "professional_info": professionalInfo?.toJson(),
    "family_info": familyInfo?.toJson(),
    "status_info": statusInfo?.toJson(),
    "counselor_info": counselorInfo?.toJson(),
    "placement_info": placementInfo,
    "referral_info": referralInfo?.toJson(),
  };
}

class AcademicBackground {
  Qualification? qualification;
  String? college;
  String? specialization;
  int? passOutYear;
  bool? isCurrentStudent;
  int? cgpa;
  bool? anyArrears;

  AcademicBackground({
    this.qualification,
    this.college,
    this.specialization,
    this.passOutYear,
    this.isCurrentStudent,
    this.cgpa,
    this.anyArrears,
  });

  factory AcademicBackground.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return AcademicBackground(
      qualification: json["qualification"] == null
          ? null
          : Qualification.fromJson(json["qualification"]),
      college: json["college"],
      specialization: json["specialization"],
      passOutYear: toInt(json["pass_out_year"]),
      isCurrentStudent: json["is_current_student"],
      cgpa: toInt(json["cgpa"]),
      anyArrears: json["any_arrears"],
    );
  }

  Map<String, dynamic> toJson() => {
    "qualification": qualification?.toJson(),
    "college": college,
    "specialization": specialization,
    "pass_out_year": passOutYear,
    "is_current_student": isCurrentStudent,
    "cgpa": cgpa,
    "any_arrears": anyArrears,
  };
}

class Qualification {
  String? name;
  dynamic description;

  Qualification({this.name, this.description});

  factory Qualification.fromJson(Map<String, dynamic> json) =>
      Qualification(name: json["name"], description: json["description"]);

  Map<String, dynamic> toJson() => {"name": name, "description": description};
}

class AddressInfo {
  String? address;
  String? pincode;
  String? district;

  AddressInfo({this.address, this.pincode, this.district});

  factory AddressInfo.fromJson(Map<String, dynamic> json) => AddressInfo(
    address: json["address"],
    pincode: json["pincode"],
    district: json["district"],
  );

  Map<String, dynamic> toJson() => {
    "address": address,
    "pincode": pincode,
    "district": district,
  };
}

class StudentDetailsBasicInfo {
  String? studentId;
  FullName? fullName;
  String? email;
  String? phone;
  String? whatsappNumber;
  String? profilePicture;
  DateTime? admissionDate;
  int? daysSinceAdmission;

  StudentDetailsBasicInfo({
    this.studentId,
    this.fullName,
    this.email,
    this.phone,
    this.whatsappNumber,
    this.profilePicture,
    this.admissionDate,
    this.daysSinceAdmission,
  });

  factory StudentDetailsBasicInfo.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return StudentDetailsBasicInfo(
      studentId: json["student_id"],
      fullName: json["full_name"] != null
          ? fullNameValues.map[json["full_name"]]
          : null,
      email: json["email"],
      phone: json["phone"],
      whatsappNumber: json["whatsapp_number"],
      profilePicture: json["profile_picture"],
      admissionDate: json["admission_date"] == null
          ? null
          : DateTime.parse(json["admission_date"]),
      daysSinceAdmission: toInt(json["days_since_admission"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "student_id": studentId,
    "full_name": fullName != null ? fullNameValues.reverse[fullName] : null,
    "email": email,
    "phone": phone,
    "whatsapp_number": whatsappNumber,
    "profile_picture": profilePicture,
    "admission_date": admissionDate != null
        ? "${admissionDate!.year.toString().padLeft(4, '0')}-${admissionDate!.month.toString().padLeft(2, '0')}-${admissionDate!.day.toString().padLeft(2, '0')}"
        : null,
    "days_since_admission": daysSinceAdmission,
  };
}

class CounselorInfo {
  String? name;
  String? email;
  String? phone;
  String? whatsapp;

  CounselorInfo({this.name, this.email, this.phone, this.whatsapp});

  factory CounselorInfo.fromJson(Map<String, dynamic> json) => CounselorInfo(
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
    whatsapp: json["whatsapp"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "phone": phone,
    "whatsapp": whatsapp,
  };
}

class FamilyInfo {
  String? parentName;
  String? parentPhone;

  FamilyInfo({this.parentName, this.parentPhone});

  factory FamilyInfo.fromJson(Map<String, dynamic> json) => FamilyInfo(
    parentName: json["parent_name"],
    parentPhone: json["parent_phone"],
  );

  Map<String, dynamic> toJson() => {
    "parent_name": parentName,
    "parent_phone": parentPhone,
  };
}

class PersonalInfo {
  DateTime? dateOfBirth;
  int? age;
  PreferredLocation? preferredLocation;
  String? howDidYouHear;

  PersonalInfo({
    this.dateOfBirth,
    this.age,
    this.preferredLocation,
    this.howDidYouHear,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return PersonalInfo(
      dateOfBirth: json["date_of_birth"] == null
          ? null
          : DateTime.parse(json["date_of_birth"]),
      age: toInt(json["age"]),
      preferredLocation: json["preferred_location"] == null
          ? null
          : PreferredLocation.fromJson(json["preferred_location"]),
      howDidYouHear: json["how_did_you_hear"],
    );
  }

  Map<String, dynamic> toJson() => {
    "date_of_birth": dateOfBirth != null
        ? "${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}"
        : null,
    "age": age,
    "preferred_location": preferredLocation?.toJson(),
    "how_did_you_hear": howDidYouHear,
  };
}

class PreferredLocation {
  String? name;
  dynamic address;

  PreferredLocation({this.name, this.address});

  factory PreferredLocation.fromJson(Map<String, dynamic> json) =>
      PreferredLocation(name: json["name"], address: json["address"]);

  Map<String, dynamic> toJson() => {"name": name, "address": address};
}

class ProfessionalInfo {
  String? studentOrWorkingProfessional;
  bool? placementAssistance;
  String? preferredJobLocation;

  ProfessionalInfo({
    this.studentOrWorkingProfessional,
    this.placementAssistance,
    this.preferredJobLocation,
  });

  factory ProfessionalInfo.fromJson(Map<String, dynamic> json) =>
      ProfessionalInfo(
        studentOrWorkingProfessional: json["student_or_working_professional"],
        placementAssistance: json["placement_assistance"],
        preferredJobLocation: json["preferred_job_location"],
      );

  Map<String, dynamic> toJson() => {
    "student_or_working_professional": studentOrWorkingProfessional,
    "placement_assistance": placementAssistance,
    "preferred_job_location": preferredJobLocation,
  };
}

class ReferralInfo {
  dynamic referredBy;
  int? totalReferralsMade;

  ReferralInfo({this.referredBy, this.totalReferralsMade});

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ReferralInfo(
      referredBy: json["referred_by"],
      totalReferralsMade: toInt(json["total_referrals_made"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "referred_by": referredBy,
    "total_referrals_made": totalReferralsMade,
  };
}

class StatusInfo {
  CurrentStatus? currentStatus;
  bool? isAlumni;
  bool? isPlaced;
  bool? portalAccessEnabled;

  StatusInfo({
    this.currentStatus,
    this.isAlumni,
    this.isPlaced,
    this.portalAccessEnabled,
  });

  factory StatusInfo.fromJson(Map<String, dynamic> json) => StatusInfo(
    currentStatus: json["current_status"] == null
        ? null
        : CurrentStatus.fromJson(json["current_status"]),
    isAlumni: json["is_alumni"],
    isPlaced: json["is_placed"],
    portalAccessEnabled: json["portal_access_enabled"],
  );

  Map<String, dynamic> toJson() => {
    "current_status": currentStatus?.toJson(),
    "is_alumni": isAlumni,
    "is_placed": isPlaced,
    "portal_access_enabled": portalAccessEnabled,
  };
}

class UpcomingActivities {
  List<dynamic>? activities;
  UpcomingActivitiesSummary? summary;

  UpcomingActivities({this.activities, this.summary});

  factory UpcomingActivities.fromJson(Map<String, dynamic> json) =>
      UpcomingActivities(
        activities: json["activities"] == null
            ? []
            : List<dynamic>.from(json["activities"]!.map((x) => x)),
        summary: json["summary"] == null
            ? null
            : UpcomingActivitiesSummary.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "activities": activities == null
        ? []
        : List<dynamic>.from(activities!.map((x) => x)),
    "summary": summary?.toJson(),
  };
}

class UpcomingActivitiesSummary {
  int? totalUpcoming;
  int? highPriority;
  int? emiPayments;
  int? courseCompletions;
  int? demoExpiries;
  dynamic nextActivityDate;

  UpcomingActivitiesSummary({
    this.totalUpcoming,
    this.highPriority,
    this.emiPayments,
    this.courseCompletions,
    this.demoExpiries,
    this.nextActivityDate,
  });

  factory UpcomingActivitiesSummary.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return UpcomingActivitiesSummary(
      totalUpcoming: toInt(json["total_upcoming"]),
      highPriority: toInt(json["high_priority"]),
      emiPayments: toInt(json["emi_payments"]),
      courseCompletions: toInt(json["course_completions"]),
      demoExpiries: toInt(json["demo_expiries"]),
      nextActivityDate: json["next_activity_date"],
    );
  }

  Map<String, dynamic> toJson() => {
    "total_upcoming": totalUpcoming,
    "high_priority": highPriority,
    "emi_payments": emiPayments,
    "course_completions": courseCompletions,
    "demo_expiries": demoExpiries,
    "next_activity_date": nextActivityDate,
  };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
