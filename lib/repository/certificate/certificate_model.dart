/// One certificate request, as returned inside an enrollment (GET) or on its
/// own (POST). Fields that only exist once issued (`download_available`,
/// serial/register numbers) default to "not available" so the shorter POST
/// answer parses too.
class CertificateRequestInfo {
  final String uid;
  final String certificateType;
  final String certificateTypeLabel;
  final String status; // pending | issued | rejected
  final String remark; // only populated by the server when rejected
  final String studentNote;
  final DateTime? requestedAt;
  final String? issuedDate; // YYYY-MM-DD

  /// True when the PDF can be downloaded right now.
  final bool downloadAvailable;

  /// Set by staff when the certificate is issued.
  final int? serialNo;
  final String? registerNo; // e.g. "LUM / KOC / 42782"

  const CertificateRequestInfo({
    required this.uid,
    required this.certificateType,
    required this.certificateTypeLabel,
    required this.status,
    required this.remark,
    required this.studentNote,
    this.requestedAt,
    this.issuedDate,
    this.downloadAvailable = false,
    this.serialNo,
    this.registerNo,
  });

  bool get isPending => status == 'pending';
  bool get isIssued => status == 'issued';
  bool get isRejected => status == 'rejected';

  factory CertificateRequestInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString())?.toLocal();
    }

    String? nonEmpty(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    return CertificateRequestInfo(
      uid: json['uid']?.toString() ?? '',
      certificateType: json['certificate_type']?.toString() ?? '',
      certificateTypeLabel: json['certificate_type_label']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      remark: json['remark']?.toString() ?? '',
      studentNote: json['student_note']?.toString() ?? '',
      requestedAt: parseDate(json['requested_at']),
      issuedDate: nonEmpty(json['issued_date']),
      downloadAvailable: json['download_available'] == true,
      serialNo: json['serial_no'] == null
          ? null
          : int.tryParse(json['serial_no'].toString()),
      registerNo: nonEmpty(json['register_no']),
    );
  }
}

/// A completed batch the student could get a certificate for.
///
/// The server decides everything here: it only lists completed batches,
/// `eligible` is false for dropped/removed enrollments, and which certificate
/// the batch gives (`certificateTypeLabel`) is fixed by the batch — the app
/// never asks the student to choose.
class CertificateEnrollment {
  final String enrollmentNumber;
  final String courseName;
  final String batchName;
  final String batchEndDate; // YYYY-MM-DD ('' when unknown)
  final bool eligible;
  final String certificateType;
  final String certificateTypeLabel;
  final CertificateRequestInfo? request;

  const CertificateEnrollment({
    required this.enrollmentNumber,
    required this.courseName,
    required this.batchName,
    required this.batchEndDate,
    required this.eligible,
    this.certificateType = '',
    this.certificateTypeLabel = '',
    this.request,
  });

  /// A request can be (re)submitted: the enrollment is eligible and the
  /// student has either never requested or was rejected. Pending/issued
  /// requests never go again.
  bool get canRequest => eligible && (request == null || request!.isRejected);

  CertificateEnrollment copyWith({CertificateRequestInfo? request}) =>
      CertificateEnrollment(
        enrollmentNumber: enrollmentNumber,
        courseName: courseName,
        batchName: batchName,
        batchEndDate: batchEndDate,
        eligible: eligible,
        certificateType: certificateType,
        certificateTypeLabel: certificateTypeLabel,
        request: request ?? this.request,
      );

  factory CertificateEnrollment.fromJson(Map<String, dynamic> json) {
    final req = json['request'];
    return CertificateEnrollment(
      enrollmentNumber: json['enrollment_number']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      batchName: json['batch_name']?.toString() ?? '',
      batchEndDate: json['batch_end_date']?.toString() ?? '',
      eligible: json['eligible'] == true,
      certificateType: json['certificate_type']?.toString() ?? '',
      certificateTypeLabel: json['certificate_type_label']?.toString() ?? '',
      request: req is Map<String, dynamic>
          ? CertificateRequestInfo.fromJson(req)
          : null,
    );
  }
}

class CertificateListResponse {
  final List<CertificateEnrollment> enrollments;

  const CertificateListResponse({required this.enrollments});

  factory CertificateListResponse.fromJson(Map<String, dynamic> json) {
    final enrollments = json['enrollments'] as List? ?? const [];
    return CertificateListResponse(
      enrollments: enrollments
          .whereType<Map<String, dynamic>>()
          .map(CertificateEnrollment.fromJson)
          .toList(),
    );
  }
}
