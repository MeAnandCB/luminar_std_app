class NactetCheckDisplayResponse {
  final String status;
  final bool displayForm;
  final String? reason;
  final List<NactetCheckDisplayEnrollment> enrollments;
  final int totalEligibleEnrollments;
  final int enrollmentsWithCertificateData;
  final int certificateFormDisplayDays;

  NactetCheckDisplayResponse({
    required this.status,
    required this.displayForm,
    this.reason,
    required this.enrollments,
    required this.totalEligibleEnrollments,
    required this.enrollmentsWithCertificateData,
    required this.certificateFormDisplayDays,
  });

  factory NactetCheckDisplayResponse.fromJson(Map<String, dynamic> json) {
    return NactetCheckDisplayResponse(
      status: json['status'] ?? '',
      displayForm: json['display_form'] ?? false,
      reason: json['reason'],
      enrollments: (json['enrollments'] as List? ?? [])
          .map((e) => NactetCheckDisplayEnrollment.fromJson(e))
          .toList(),
      totalEligibleEnrollments: json['total_eligible_enrollments'] ?? 0,
      enrollmentsWithCertificateData: json['enrollments_with_certificate_data'] ?? 0,
      certificateFormDisplayDays: json['certificate_form_display_days'] ?? 0,
    );
  }
}

class NactetCheckDisplayEnrollment {
  final String enrollmentUid;
  final String enrollmentNumber;
  final String enrollmentTitle;
  final String courseName;
  final int courseId;
  final String batchName;
  final String batchUid;
  final String batchStartDate;
  final String displayDate;
  final int? daysRemaining;
  final bool hasCertificateData;
  final bool hasCertificateDataFromModel;
  final bool hasCertificateDataFromFlag;
  final bool canDisplayFormDate;
  final bool shouldDisplayForm;
  final bool isFromBatchChange;
  final dynamic oldEnrollmentHasData;
  final String? reason;
  final String status;
  final String statusDisplay;

  NactetCheckDisplayEnrollment({
    required this.enrollmentUid,
    required this.enrollmentNumber,
    required this.enrollmentTitle,
    required this.courseName,
    required this.courseId,
    required this.batchName,
    required this.batchUid,
    required this.batchStartDate,
    required this.displayDate,
    this.daysRemaining,
    required this.hasCertificateData,
    required this.hasCertificateDataFromModel,
    required this.hasCertificateDataFromFlag,
    required this.canDisplayFormDate,
    required this.shouldDisplayForm,
    required this.isFromBatchChange,
    this.oldEnrollmentHasData,
    this.reason,
    required this.status,
    required this.statusDisplay,
  });

  factory NactetCheckDisplayEnrollment.fromJson(Map<String, dynamic> json) {
    return NactetCheckDisplayEnrollment(
      enrollmentUid: json['enrollment_uid'] ?? '',
      enrollmentNumber: json['enrollment_number'] ?? '',
      enrollmentTitle: json['enrollment_title'] ?? '',
      courseName: json['course_name'] ?? '',
      courseId: json['course_id'] ?? 0,
      batchName: json['batch_name'] ?? '',
      batchUid: json['batch_uid'] ?? '',
      batchStartDate: json['batch_start_date'] ?? '',
      displayDate: json['display_date'] ?? '',
      daysRemaining: json['days_remaining'],
      hasCertificateData: json['has_certificate_data'] ?? false,
      hasCertificateDataFromModel: json['has_certificate_data_from_model'] ?? false,
      hasCertificateDataFromFlag: json['has_certificate_data_from_flag'] ?? false,
      canDisplayFormDate: json['can_display_form_date'] ?? false,
      shouldDisplayForm: json['should_display_form'] ?? false,
      isFromBatchChange: json['is_from_batch_change'] ?? false,
      oldEnrollmentHasData: json['old_enrollment_has_data'],
      reason: json['reason'],
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
    );
  }
}
