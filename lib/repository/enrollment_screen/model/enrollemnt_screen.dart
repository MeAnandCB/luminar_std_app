class EntrolmentModel {
  String? status;
  List<Enrollment>? enrollments;
  Summary? summary;

  EntrolmentModel({this.status, this.enrollments, this.summary});

  factory EntrolmentModel.fromJson(Map<String, dynamic> json) =>
      EntrolmentModel(
        status: json["status"],
        enrollments: json["enrollments"] == null
            ? []
            : List<Enrollment>.from(
                json["enrollments"]!.map((x) => Enrollment.fromJson(x)),
              ),
        summary: json["summary"] == null
            ? null
            : Summary.fromJson(json["summary"]),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "enrollments": enrollments == null
        ? []
        : List<dynamic>.from(enrollments!.map((x) => x.toJson())),
    "summary": summary?.toJson(),
  };
}

class Enrollment {
  String? uid;
  String? enrollmentNumber;
  DateTime? enrollmentDate;
  int? originalCourseFeesDiscount;
  String? source;
  Status? status;
  Batch? batch;
  Course? course;
  AttendanceMode? attendanceMode;
  PaymentInfo? paymentInfo;
  Progress? progress;
  String? specialNotes;
  List<dynamic>? tags;

  Enrollment({
    this.uid,
    this.enrollmentNumber,
    this.enrollmentDate,
    this.originalCourseFeesDiscount,
    this.source,
    this.status,
    this.batch,
    this.course,
    this.attendanceMode,
    this.paymentInfo,
    this.progress,
    this.specialNotes,
    this.tags,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
    uid: json["uid"],
    enrollmentNumber: json["enrollment_number"],
    enrollmentDate: json["enrollment_date"] == null
        ? null
        : DateTime.parse(json["enrollment_date"]),
    originalCourseFeesDiscount: json["original_course_fees_discount"],
    source: json["source"],
    status: json["status"] == null ? null : Status.fromJson(json["status"]),
    batch: json["batch"] == null ? null : Batch.fromJson(json["batch"]),
    course: json["course"] == null ? null : Course.fromJson(json["course"]),
    attendanceMode: json["attendance_mode"] == null
        ? null
        : AttendanceMode.fromJson(json["attendance_mode"]),
    paymentInfo: json["payment_info"] == null
        ? null
        : PaymentInfo.fromJson(json["payment_info"]),
    progress: json["progress"] == null
        ? null
        : Progress.fromJson(json["progress"]),
    specialNotes: json["special_notes"],
    tags: json["tags"] == null
        ? []
        : List<dynamic>.from(json["tags"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "enrollment_number": enrollmentNumber,
    "enrollment_date": enrollmentDate?.toIso8601String(),
    "original_course_fees_discount": originalCourseFeesDiscount,
    "source": source,
    "status": status?.toJson(),
    "batch": batch?.toJson(),
    "course": course?.toJson(),
    "attendance_mode": attendanceMode?.toJson(),
    "payment_info": paymentInfo?.toJson(),
    "progress": progress?.toJson(),
    "special_notes": specialNotes,
    "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
  };
}

class AttendanceMode {
  String? name;
  String? value;

  AttendanceMode({this.name, this.value});

  factory AttendanceMode.fromJson(Map<String, dynamic> json) =>
      AttendanceMode(name: json["name"], value: json["value"]);

  Map<String, dynamic> toJson() => {"name": name, "value": value};
}

class Batch {
  String? uid;
  String? batchName;
  DateTime? startDate;
  DateTime? endDate;
  dynamic joinUrl;
  String? time;
  String? status;

  Batch({
    this.uid,
    this.batchName,
    this.startDate,
    this.endDate,
    this.joinUrl,
    this.time,
    this.status,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    uid: json["uid"],
    batchName: json["batch_name"],
    startDate: json["start_date"] == null
        ? null
        : DateTime.parse(json["start_date"]),
    endDate: json["end_date"] == null ? null : DateTime.parse(json["end_date"]),
    joinUrl: json["join_url"],
    time: json["time"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "batch_name": batchName,
    "start_date":
        "${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}",
    "end_date":
        "${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}",
    "join_url": joinUrl,
    "time": time,
    "status": status,
  };
}

class Course {
  String? courseName;
  dynamic duration;

  Course({this.courseName, this.duration});

  factory Course.fromJson(Map<String, dynamic> json) =>
      Course(courseName: json["course_name"], duration: json["duration"]);

  Map<String, dynamic> toJson() => {
    "course_name": courseName,
    "duration": duration,
  };
}

class PaymentInfo {
  int? grossAmount;
  int? totalDiscount;
  int? netAmount;
  int? amountPaid;
  int? pendingAmount;
  double? paymentCompletionPercentage;
  bool? isFullyPaid;
  bool? hasOverpayment;

  PaymentInfo({
    this.grossAmount,
    this.totalDiscount,
    this.netAmount,
    this.amountPaid,
    this.pendingAmount,
    this.paymentCompletionPercentage,
    this.isFullyPaid,
    this.hasOverpayment,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
    grossAmount: json["gross_amount"],
    totalDiscount: json["total_discount"],
    netAmount: json["net_amount"],
    amountPaid: json["amount_paid"],
    pendingAmount: json["pending_amount"],
    paymentCompletionPercentage: json["payment_completion_percentage"]
        ?.toDouble(),
    isFullyPaid: json["is_fully_paid"],
    hasOverpayment: json["has_overpayment"],
  );

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

class Progress {
  int? attendancePercentage;
  int? completionPercentage;
  String? finalGrade;
  bool? certificateIssued;
  dynamic certificateIssueDate;

  Progress({
    this.attendancePercentage,
    this.completionPercentage,
    this.finalGrade,
    this.certificateIssued,
    this.certificateIssueDate,
  });

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
    attendancePercentage: json["attendance_percentage"],
    completionPercentage: json["completion_percentage"],
    finalGrade: json["final_grade"],
    certificateIssued: json["certificate_issued"],
    certificateIssueDate: json["certificate_issue_date"],
  );

  Map<String, dynamic> toJson() => {
    "attendance_percentage": attendancePercentage,
    "completion_percentage": completionPercentage,
    "final_grade": finalGrade,
    "certificate_issued": certificateIssued,
    "certificate_issue_date": certificateIssueDate,
  };
}

class Status {
  String? name;
  String? value;
  String? color;

  Status({this.name, this.value, this.color});

  factory Status.fromJson(Map<String, dynamic> json) =>
      Status(name: json["name"], value: json["value"], color: json["color"]);

  Map<String, dynamic> toJson() => {
    "name": name,
    "value": value,
    "color": color,
  };
}

class Summary {
  int? totalEnrollments;
  int? activeEnrollments;
  int? completedEnrollments;
  int? demoEnrollments;
  int? totalFeesPaid;
  int? totalFeesPending;

  Summary({
    this.totalEnrollments,
    this.activeEnrollments,
    this.completedEnrollments,
    this.demoEnrollments,
    this.totalFeesPaid,
    this.totalFeesPending,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    totalEnrollments: json["total_enrollments"],
    activeEnrollments: json["active_enrollments"],
    completedEnrollments: json["completed_enrollments"],
    demoEnrollments: json["demo_enrollments"],
    totalFeesPaid: json["total_fees_paid"],
    totalFeesPending: json["total_fees_pending"],
  );

  Map<String, dynamic> toJson() => {
    "total_enrollments": totalEnrollments,
    "active_enrollments": activeEnrollments,
    "completed_enrollments": completedEnrollments,
    "demo_enrollments": demoEnrollments,
    "total_fees_paid": totalFeesPaid,
    "total_fees_pending": totalFeesPending,
  };
}
