class CertificateType {
  final String value;
  final String label;

  const CertificateType({required this.value, required this.label});

  factory CertificateType.fromJson(Map<String, dynamic> json) =>
      CertificateType(
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );

  /// Only used when the list endpoint did not answer, so the form can still
  /// be offered. The server list is authoritative whenever it is available.
  static const List<CertificateType> fallback = [
    CertificateType(value: 'completion', label: 'Course Completion'),
    CertificateType(value: 'internship', label: 'Internship'),
  ];
}

class CertificateRequestInfo {
  final String uid;
  final String certificateType;
  final String certificateTypeLabel;
  final String status; // pending | issued | rejected
  final String remark; // only populated by the server when rejected
  final String studentNote;
  final DateTime? requestedAt;
  final String? issuedDate; // YYYY-MM-DD

  const CertificateRequestInfo({
    required this.uid,
    required this.certificateType,
    required this.certificateTypeLabel,
    required this.status,
    required this.remark,
    required this.studentNote,
    this.requestedAt,
    this.issuedDate,
  });

  bool get isPending => status == 'pending';
  bool get isIssued => status == 'issued';
  bool get isRejected => status == 'rejected';

  factory CertificateRequestInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString())?.toLocal();
    }

    return CertificateRequestInfo(
      uid: json['uid']?.toString() ?? '',
      certificateType: json['certificate_type']?.toString() ?? '',
      certificateTypeLabel: json['certificate_type_label']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      remark: json['remark']?.toString() ?? '',
      studentNote: json['student_note']?.toString() ?? '',
      requestedAt: parseDate(json['requested_at']),
      issuedDate: json['issued_date']?.toString(),
    );
  }
}

/// Why a student cannot request a certificate for an enrollment right now.
enum CertificateBlock {
  /// The batch has not been completed yet (running or upcoming).
  batchInProgress,

  /// Dropped / removed enrollment, or the server says it is not eligible.
  notEligible,

  /// A certificate was already issued for this enrollment.
  alreadyIssued,

  /// An EMI instalment is overdue. The server restricts the whole student
  /// portal while any is overdue (403 `emi_payment_overdue`).
  emiOverdue,

  /// Course fees are not fully paid.
  paymentPending,
}

class CertificateEnrollment {
  final String enrollmentNumber;
  final String courseName;
  final String batchName;
  final String batchEndDate; // YYYY-MM-DD ('' when unknown)
  final bool eligible;
  final CertificateRequestInfo? request;

  /// False for an enrollment whose batch is still running; such enrollments
  /// are shown locked and can never be requested.
  final bool batchCompleted;

  /// Outstanding course fees. null = unknown, which never blocks a request
  /// (the server stays the final judge).
  final int? pendingAmount;

  /// The dashboard already marks a certificate as issued for this enrollment.
  final bool certificateAlreadyIssued;

  /// Overdue EMI instalments across the whole student, per the dashboard.
  final int emiOverdueCount;
  final int? emiOverdueAmount;

  /// Whether the overdue EMI belongs to THIS enrollment (null = can't tell).
  final bool? emiOverdueHere;

  /// Extra dashboard facts (enrollment status, batch status, fees, …) kept
  /// only so an application can be described in the debug console. They never
  /// influence eligibility and are never sent to the server.
  final Map<String, String> details;

  const CertificateEnrollment({
    required this.enrollmentNumber,
    required this.courseName,
    required this.batchName,
    required this.batchEndDate,
    required this.eligible,
    this.request,
    this.batchCompleted = true,
    this.pendingAmount,
    this.certificateAlreadyIssued = false,
    this.emiOverdueCount = 0,
    this.emiOverdueAmount,
    this.emiOverdueHere,
    this.details = const {},
  });

  bool get paymentPending => (pendingAmount ?? 0) > 0;

  /// The first rule that stops a (new) request, in priority order; null when
  /// nothing stands in the way. Existing requests are judged separately.
  CertificateBlock? get block {
    if (!batchCompleted) return CertificateBlock.batchInProgress;
    if (!eligible) return CertificateBlock.notEligible;
    if (request == null && certificateAlreadyIssued) {
      return CertificateBlock.alreadyIssued;
    }
    if (emiOverdueCount > 0) return CertificateBlock.emiOverdue;
    if (paymentPending) return CertificateBlock.paymentPending;
    return null;
  }

  /// A request can be (re)submitted: nothing blocks it, and the student has
  /// either never requested or was rejected. Pending/issued never re-request.
  bool get canRequest =>
      block == null && (request == null || request!.isRejected);

  CertificateEnrollment copyWith({
    CertificateRequestInfo? request,
    int? pendingAmount,
    bool? certificateAlreadyIssued,
    int? emiOverdueCount,
    int? emiOverdueAmount,
    bool? emiOverdueHere,
    Map<String, String>? details,
  }) => CertificateEnrollment(
    enrollmentNumber: enrollmentNumber,
    courseName: courseName,
    batchName: batchName,
    batchEndDate: batchEndDate,
    eligible: eligible,
    request: request ?? this.request,
    batchCompleted: batchCompleted,
    pendingAmount: pendingAmount ?? this.pendingAmount,
    certificateAlreadyIssued:
        certificateAlreadyIssued ?? this.certificateAlreadyIssued,
    emiOverdueCount: emiOverdueCount ?? this.emiOverdueCount,
    emiOverdueAmount: emiOverdueAmount ?? this.emiOverdueAmount,
    emiOverdueHere: emiOverdueHere ?? this.emiOverdueHere,
    details: details ?? this.details,
  );

  /// Fills in what only the dashboard knows (fees, issued flag) on top of a
  /// server entry. The server's batch/eligibility/request data is kept.
  CertificateEnrollment mergeDashboard(CertificateEnrollment? d) {
    if (d == null) return this;
    return copyWith(
      pendingAmount: d.pendingAmount,
      certificateAlreadyIssued: d.certificateAlreadyIssued,
      emiOverdueCount: d.emiOverdueCount,
      emiOverdueAmount: d.emiOverdueAmount,
      emiOverdueHere: d.emiOverdueHere,
      details: d.details,
    );
  }

  factory CertificateEnrollment.fromJson(Map<String, dynamic> json) {
    final req = json['request'];
    return CertificateEnrollment(
      enrollmentNumber: json['enrollment_number']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      batchEndDate: json['batch_end_date']?.toString() ?? '',
      eligible: json['eligible'] == true,
      request: req is Map<String, dynamic>
          ? CertificateRequestInfo.fromJson(req)
          : null,
    );
  }
}

class CertificateListResponse {
  final List<CertificateType> certificateTypes;
  final List<CertificateEnrollment> enrollments;

  const CertificateListResponse({
    required this.certificateTypes,
    required this.enrollments,
  });

  factory CertificateListResponse.fromJson(Map<String, dynamic> json) {
    final types = json['certificate_types'] as List? ?? const [];
    final enrollments = json['enrollments'] as List? ?? const [];
    return CertificateListResponse(
      certificateTypes: types
          .whereType<Map<String, dynamic>>()
          .map(CertificateType.fromJson)
          .toList(),
      enrollments: enrollments
          .whereType<Map<String, dynamic>>()
          .map(CertificateEnrollment.fromJson)
          .toList(),
    );
  }
}
