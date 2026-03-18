// lib/repository/payment_screen/model.dart

import 'dart:convert';

EnrollmentDetailResponse enrollmentDetailResponseFromJson(String str) =>
    EnrollmentDetailResponse.fromJson(json.decode(str));

String enrollmentDetailResponseToJson(EnrollmentDetailResponse data) =>
    json.encode(data.toJson());

class EnrollmentDetailResponse {
  String? uid;
  String? enrollmentNumber;
  num? status; // Changed from int? to num?
  StatusObject? statusObject;
  String? statusName;
  String? statusValue;
  String? statusColor;
  String? statusDescription;
  String? statusDisplay;
  String? source;
  String? sourceDisplay;
  DateTime? enrollmentDate;
  DateTime? demoStartDate;
  DateTime? demoEndDate;
  dynamic demoConversionDate;
  bool? demoFollowUpRequired;
  num? student; // Changed from int? to num?
  String? studentName;
  String? studentId;
  String? studentEmail;
  String? studentPhone;
  String? studentStatus;
  Batch? batch;
  AttendanceMode? attendanceMode;
  String? paymentType;
  String? paymentTypeDisplay;
  String? originalCourseFees;
  String? originalCourseFeesDiscount;
  String? originalAdmissionFees;
  String? otherFees;
  String? totalDiscountAmount;
  String? totalAmountPaid;
  String? totalPendingAmount;
  num? netFees; // Changed from int? to num?
  num? paymentCompletionPercentage; // Changed from double? to num?
  String? emiPlan;
  String? emiPlanName;
  num? emiInstallmentCount; // Changed from int? to num?
  DateTime? nextEmiDueDate;
  num? enrolledBy; // Changed from int? to num?
  String? enrolledByName;
  dynamic academicCounselor;
  num? admissionCounselor; // Changed from int? to num?
  String? admissionCounselorName;
  dynamic paymentDeadline;
  bool? crmAccessEnabled;
  bool? paymentGraceExpired;
  bool? isFamilyEnrollment;
  String? attendancePercentage;
  String? completionPercentage;
  String? finalGrade;
  bool? certificateIssued;
  dynamic certificateIssueDate;
  bool? certificateDataCollected;
  num? daysSinceEnrollment; // Changed from int? to num?
  dynamic demoDaysRemaining;
  bool? isPaymentOverdue;
  List<dynamic>? appliedDiscountsSummary;
  String? specialNotes;
  List<dynamic>? tags;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastActivityDate;
  String? admissionCounselorUid;
  List<PaymentTransaction>? paymentTransactions;
  List<EmiInstallment>? emiInstallments;
  List<dynamic>? appliedDiscounts;

  EnrollmentDetailResponse({
    this.uid,
    this.enrollmentNumber,
    this.status,
    this.statusObject,
    this.statusName,
    this.statusValue,
    this.statusColor,
    this.statusDescription,
    this.statusDisplay,
    this.source,
    this.sourceDisplay,
    this.enrollmentDate,
    this.demoStartDate,
    this.demoEndDate,
    this.demoConversionDate,
    this.demoFollowUpRequired,
    this.student,
    this.studentName,
    this.studentId,
    this.studentEmail,
    this.studentPhone,
    this.studentStatus,
    this.batch,
    this.attendanceMode,
    this.paymentType,
    this.paymentTypeDisplay,
    this.originalCourseFees,
    this.originalCourseFeesDiscount,
    this.originalAdmissionFees,
    this.otherFees,
    this.totalDiscountAmount,
    this.totalAmountPaid,
    this.totalPendingAmount,
    this.netFees,
    this.paymentCompletionPercentage,
    this.emiPlan,
    this.emiPlanName,
    this.emiInstallmentCount,
    this.nextEmiDueDate,
    this.enrolledBy,
    this.enrolledByName,
    this.academicCounselor,
    this.admissionCounselor,
    this.admissionCounselorName,
    this.paymentDeadline,
    this.crmAccessEnabled,
    this.paymentGraceExpired,
    this.isFamilyEnrollment,
    this.attendancePercentage,
    this.completionPercentage,
    this.finalGrade,
    this.certificateIssued,
    this.certificateIssueDate,
    this.certificateDataCollected,
    this.daysSinceEnrollment,
    this.demoDaysRemaining,
    this.isPaymentOverdue,
    this.appliedDiscountsSummary,
    this.specialNotes,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.lastActivityDate,
    this.admissionCounselorUid,
    this.paymentTransactions,
    this.emiInstallments,
    this.appliedDiscounts,
  });

  factory EnrollmentDetailResponse.fromJson(Map<String, dynamic> json) {
    return EnrollmentDetailResponse(
      uid: json["uid"],
      enrollmentNumber: json["enrollment_number"],
      status: json["status"], // Can be int or double
      statusObject: json["status_object"] == null
          ? null
          : StatusObject.fromJson(json["status_object"]),
      statusName: json["status_name"],
      statusValue: json["status_value"],
      statusColor: json["status_color"],
      statusDescription: json["status_description"],
      statusDisplay: json["status_display"],
      source: json["source"],
      sourceDisplay: json["source_display"],
      enrollmentDate: json["enrollment_date"] == null
          ? null
          : DateTime.parse(json["enrollment_date"]),
      demoStartDate: json["demo_start_date"] == null
          ? null
          : DateTime.parse(json["demo_start_date"]),
      demoEndDate: json["demo_end_date"] == null
          ? null
          : DateTime.parse(json["demo_end_date"]),
      demoConversionDate: json["demo_conversion_date"],
      demoFollowUpRequired: json["demo_follow_up_required"],
      student: json["student"],
      studentName: json["student_name"],
      studentId: json["student_id"],
      studentEmail: json["student_email"],
      studentPhone: json["student_phone"],
      studentStatus: json["student_status"],
      batch: json["batch"] == null ? null : Batch.fromJson(json["batch"]),
      attendanceMode: json["attendance_mode"] == null
          ? null
          : AttendanceMode.fromJson(json["attendance_mode"]),
      paymentType: json["payment_type"],
      paymentTypeDisplay: json["payment_type_display"],
      originalCourseFees: json["original_course_fees"],
      originalCourseFeesDiscount: json["original_course_fees_discount"],
      originalAdmissionFees: json["original_admission_fees"],
      otherFees: json["other_fees"],
      totalDiscountAmount: json["total_discount_amount"],
      totalAmountPaid: json["total_amount_paid"],
      totalPendingAmount: json["total_pending_amount"],
      netFees: json["net_fees"],
      paymentCompletionPercentage:
          json["payment_completion_percentage"], // Removed .toDouble()
      emiPlan: json["emi_plan"],
      emiPlanName: json["emi_plan_name"],
      emiInstallmentCount: json["emi_installment_count"],
      nextEmiDueDate: json["next_emi_due_date"] == null
          ? null
          : DateTime.parse(json["next_emi_due_date"]),
      enrolledBy: json["enrolled_by"],
      enrolledByName: json["enrolled_by_name"],
      academicCounselor: json["academic_counselor"],
      admissionCounselor: json["admission_counselor"],
      admissionCounselorName: json["admission_counselor_name"],
      paymentDeadline: json["payment_deadline"],
      crmAccessEnabled: json["crm_access_enabled"],
      paymentGraceExpired: json["payment_grace_expired"],
      isFamilyEnrollment: json["is_family_enrollment"],
      attendancePercentage: json["attendance_percentage"],
      completionPercentage: json["completion_percentage"],
      finalGrade: json["final_grade"],
      certificateIssued: json["certificate_issued"],
      certificateIssueDate: json["certificate_issue_date"],
      certificateDataCollected: json["certificate_data_collected"],
      daysSinceEnrollment: json["days_since_enrollment"],
      demoDaysRemaining: json["demo_days_remaining"],
      isPaymentOverdue: json["is_payment_overdue"],
      appliedDiscountsSummary: json["applied_discounts_summary"] == null
          ? []
          : List<dynamic>.from(
              json["applied_discounts_summary"]!.map((x) => x),
            ),
      specialNotes: json["special_notes"],
      tags: json["tags"] == null
          ? []
          : List<dynamic>.from(json["tags"]!.map((x) => x)),
      createdAt: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
      updatedAt: json["updated_at"] == null
          ? null
          : DateTime.parse(json["updated_at"]),
      lastActivityDate: json["last_activity_date"] == null
          ? null
          : DateTime.parse(json["last_activity_date"]),
      admissionCounselorUid: json["admission_counselor_uid"],
      paymentTransactions: json["payment_transactions"] == null
          ? []
          : List<PaymentTransaction>.from(
              json["payment_transactions"]!.map(
                (x) => PaymentTransaction.fromJson(x),
              ),
            ),
      emiInstallments: json["emi_installments"] == null
          ? []
          : List<EmiInstallment>.from(
              json["emi_installments"]!.map((x) => EmiInstallment.fromJson(x)),
            ),
      appliedDiscounts: json["applied_discounts"] == null
          ? []
          : List<dynamic>.from(json["applied_discounts"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "enrollment_number": enrollmentNumber,
    "status": status,
    "status_object": statusObject?.toJson(),
    "status_name": statusName,
    "status_value": statusValue,
    "status_color": statusColor,
    "status_description": statusDescription,
    "status_display": statusDisplay,
    "source": source,
    "source_display": sourceDisplay,
    "enrollment_date": enrollmentDate?.toIso8601String(),
    "demo_start_date": demoStartDate?.toIso8601String(),
    "demo_end_date": demoEndDate?.toIso8601String(),
    "demo_conversion_date": demoConversionDate,
    "demo_follow_up_required": demoFollowUpRequired,
    "student": student,
    "student_name": studentName,
    "student_id": studentId,
    "student_email": studentEmail,
    "student_phone": studentPhone,
    "student_status": studentStatus,
    "batch": batch?.toJson(),
    "attendance_mode": attendanceMode?.toJson(),
    "payment_type": paymentType,
    "payment_type_display": paymentTypeDisplay,
    "original_course_fees": originalCourseFees,
    "original_course_fees_discount": originalCourseFeesDiscount,
    "original_admission_fees": originalAdmissionFees,
    "other_fees": otherFees,
    "total_discount_amount": totalDiscountAmount,
    "total_amount_paid": totalAmountPaid,
    "total_pending_amount": totalPendingAmount,
    "net_fees": netFees,
    "payment_completion_percentage": paymentCompletionPercentage,
    "emi_plan": emiPlan,
    "emi_plan_name": emiPlanName,
    "emi_installment_count": emiInstallmentCount,
    "next_emi_due_date": nextEmiDueDate == null
        ? null
        : "${nextEmiDueDate!.year.toString().padLeft(4, '0')}-${nextEmiDueDate!.month.toString().padLeft(2, '0')}-${nextEmiDueDate!.day.toString().padLeft(2, '0')}",
    "enrolled_by": enrolledBy,
    "enrolled_by_name": enrolledByName,
    "academic_counselor": academicCounselor,
    "admission_counselor": admissionCounselor,
    "admission_counselor_name": admissionCounselorName,
    "payment_deadline": paymentDeadline,
    "crm_access_enabled": crmAccessEnabled,
    "payment_grace_expired": paymentGraceExpired,
    "is_family_enrollment": isFamilyEnrollment,
    "attendance_percentage": attendancePercentage,
    "completion_percentage": completionPercentage,
    "final_grade": finalGrade,
    "certificate_issued": certificateIssued,
    "certificate_issue_date": certificateIssueDate,
    "certificate_data_collected": certificateDataCollected,
    "days_since_enrollment": daysSinceEnrollment,
    "demo_days_remaining": demoDaysRemaining,
    "is_payment_overdue": isPaymentOverdue,
    "applied_discounts_summary": appliedDiscountsSummary == null
        ? []
        : List<dynamic>.from(appliedDiscountsSummary!.map((x) => x)),
    "special_notes": specialNotes,
    "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "last_activity_date": lastActivityDate?.toIso8601String(),
    "admission_counselor_uid": admissionCounselorUid,
    "payment_transactions": paymentTransactions == null
        ? []
        : List<dynamic>.from(paymentTransactions!.map((x) => x.toJson())),
    "emi_installments": emiInstallments == null
        ? []
        : List<dynamic>.from(emiInstallments!.map((x) => x.toJson())),
    "applied_discounts": appliedDiscounts == null
        ? []
        : List<dynamic>.from(appliedDiscounts!.map((x) => x)),
  };
}

class AttendanceMode {
  num? id; // Changed from int? to num?
  String? name;
  String? value;
  bool? deletable;
  bool? editable;
  bool? active;

  AttendanceMode({
    this.id,
    this.name,
    this.value,
    this.deletable,
    this.editable,
    this.active,
  });

  factory AttendanceMode.fromJson(Map<String, dynamic> json) => AttendanceMode(
    id: json["id"],
    name: json["name"],
    value: json["value"],
    deletable: json["deletable"],
    editable: json["editable"],
    active: json["active"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "value": value,
    "deletable": deletable,
    "editable": editable,
    "active": active,
  };
}

class Batch {
  String? uid;
  String? batchName;
  String? courseName;
  DateTime? startDate;
  DateTime? endDate;
  String? time;
  String? status;
  List<String>? counselorNames;
  List<String>? trainerNames;

  Batch({
    this.uid,
    this.batchName,
    this.courseName,
    this.startDate,
    this.endDate,
    this.time,
    this.status,
    this.counselorNames,
    this.trainerNames,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    uid: json["uid"],
    batchName: json["batch_name"],
    courseName: json["course_name"],
    startDate: json["start_date"] == null
        ? null
        : DateTime.parse(json["start_date"]),
    endDate: json["end_date"] == null ? null : DateTime.parse(json["end_date"]),
    time: json["time"],
    status: json["status"],
    counselorNames: json["counselor_names"] == null
        ? []
        : List<String>.from(json["counselor_names"]!.map((x) => x)),
    trainerNames: json["trainer_names"] == null
        ? []
        : List<String>.from(json["trainer_names"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "batch_name": batchName,
    "course_name": courseName,
    "start_date": startDate == null
        ? null
        : "${startDate!.year.toString().padLeft(4, '0')}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}",
    "end_date": endDate == null
        ? null
        : "${endDate!.year.toString().padLeft(4, '0')}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}",
    "time": time,
    "status": status,
    "counselor_names": counselorNames == null
        ? []
        : List<dynamic>.from(counselorNames!.map((x) => x)),
    "trainer_names": trainerNames == null
        ? []
        : List<dynamic>.from(trainerNames!.map((x) => x)),
  };
}

class EmiInstallment {
  String? uid;
  num? installmentNumber; // Changed from int? to num?
  num? totalAmount; // Changed from double? to num?
  num? paidAmount; // Changed from double? to num?
  num? pendingAmount; // Changed from double? to num?
  DateTime? dueDate;
  String? status;
  dynamic paidDate;
  bool? isOverdue;
  num? daysOverdue; // Changed from int? to num?
  DateTime? createdAt;
  DateTime? updatedAt;

  EmiInstallment({
    this.uid,
    this.installmentNumber,
    this.totalAmount,
    this.paidAmount,
    this.pendingAmount,
    this.dueDate,
    this.status,
    this.paidDate,
    this.isOverdue,
    this.daysOverdue,
    this.createdAt,
    this.updatedAt,
  });

  factory EmiInstallment.fromJson(Map<String, dynamic> json) {
    return EmiInstallment(
      uid: json["uid"],
      installmentNumber: json["installment_number"],
      totalAmount: json["total_amount"],
      paidAmount: json["paid_amount"],
      pendingAmount: json["pending_amount"],
      dueDate: json["due_date"] == null
          ? null
          : DateTime.parse(json["due_date"]),
      status: json["status"],
      paidDate: json["paid_date"],
      isOverdue: json["is_overdue"],
      daysOverdue: json["days_overdue"],
      createdAt: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
      updatedAt: json["updated_at"] == null
          ? null
          : DateTime.parse(json["updated_at"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "installment_number": installmentNumber,
    "total_amount": totalAmount,
    "paid_amount": paidAmount,
    "pending_amount": pendingAmount,
    "due_date": dueDate == null
        ? null
        : "${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}",
    "status": status,
    "paid_date": paidDate,
    "is_overdue": isOverdue,
    "days_overdue": daysOverdue,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class PaymentTransaction {
  String? uid;
  String? transactionId;
  String? studentName;
  String? courseName;
  String? batchName;
  String? amount;
  String? paymentMethod;
  String? paymentMethodDisplay;
  String? status;
  String? statusDisplay;
  DateTime? paymentDate;
  DateTime? createdAt;
  Metadata? metadata;
  String? studentId;
  String? counselor;
  dynamic pdfFile;

  PaymentTransaction({
    this.uid,
    this.transactionId,
    this.studentName,
    this.courseName,
    this.batchName,
    this.amount,
    this.paymentMethod,
    this.paymentMethodDisplay,
    this.status,
    this.statusDisplay,
    this.paymentDate,
    this.createdAt,
    this.metadata,
    this.studentId,
    this.counselor,
    this.pdfFile,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      PaymentTransaction(
        uid: json["uid"],
        transactionId: json["transaction_id"],
        studentName: json["student_name"],
        courseName: json["course_name"],
        batchName: json["batch_name"],
        amount: json["amount"],
        paymentMethod: json["payment_method"],
        paymentMethodDisplay: json["payment_method_display"],
        status: json["status"],
        statusDisplay: json["status_display"],
        paymentDate: json["payment_date"] == null
            ? null
            : DateTime.parse(json["payment_date"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        metadata: json["metadata"] == null
            ? null
            : Metadata.fromJson(json["metadata"]),
        studentId: json["student_id"],
        counselor: json["counselor"],
        pdfFile: json["pdf_file"],
      );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "transaction_id": transactionId,
    "student_name": studentName,
    "course_name": courseName,
    "batch_name": batchName,
    "amount": amount,
    "payment_method": paymentMethod,
    "payment_method_display": paymentMethodDisplay,
    "status": status,
    "status_display": statusDisplay,
    "payment_date": paymentDate?.toIso8601String(),
    "created_at": createdAt?.toIso8601String(),
    "metadata": metadata?.toJson(),
    "student_id": studentId,
    "counselor": counselor,
    "pdf_file": pdfFile,
  };
}

class Metadata {
  dynamic name;

  Metadata({this.name});

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      Metadata(name: json["name"]);

  Map<String, dynamic> toJson() => {"name": name};
}

class StatusObject {
  num? id; // Changed from int? to num?
  String? name;
  String? value;
  String? color;
  String? description;
  bool? isActive;

  StatusObject({
    this.id,
    this.name,
    this.value,
    this.color,
    this.description,
    this.isActive,
  });

  factory StatusObject.fromJson(Map<String, dynamic> json) => StatusObject(
    id: json["id"],
    name: json["name"],
    value: json["value"],
    color: json["color"],
    description: json["description"],
    isActive: json["is_active"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "value": value,
    "color": color,
    "description": description,
    "is_active": isActive,
  };
}
