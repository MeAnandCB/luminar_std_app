import 'package:flutter_test/flutter_test.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';
import 'package:luminar_std/repository/certificate/certificate_report.dart';
import 'package:luminar_std/repository/certificate/certificate_service.dart';

void main() {
  test('POST body carries the enrollment number from the list response', () {
    // Shape taken from the API guide's GET example.
    final list = CertificateListResponse.fromJson({
      'status': 'success',
      'certificate_types': [
        {'value': 'completion', 'label': 'Course Completion'},
      ],
      'enrollments': [
        {
          'enrollment_number': 'ENR2026118595',
          'course_name': 'Python Full Stack',
          'batch_name': 'PY-1',
          'batch_end_date': '2026-11-07',
          'eligible': true,
          'request': null,
        },
      ],
    });
    final enrollment = list.enrollments.single;
    expect(enrollment.enrollmentNumber, 'ENR2026118595');

    final body = CertificateService.requestBody(
      enrollmentNumber: enrollment.enrollmentNumber,
      certificateType: list.certificateTypes.first.value,
      studentNote: '  Need it for a job application  ',
    );

    expect(body, {
      'enrollment_number': 'ENR2026118595',
      'certificate_type': 'completion',
      'student_note': 'Need it for a job application',
    });
  });

  test('blank note is omitted, number is trimmed', () {
    final body = CertificateService.requestBody(
      enrollmentNumber: ' ENR1 ',
      certificateType: 'internship',
      studentNote: '   ',
    );
    expect(body, {
      'enrollment_number': 'ENR1',
      'certificate_type': 'internship',
    });
  });

  test('an empty enrollment number is never sent', () async {
    final res = await CertificateService().requestCertificate(
      enrollmentNumber: '  ',
      certificateType: 'completion',
    );
    expect(res.success, isFalse);
    expect(res.message, 'Enrollment not found');
  });

  _reportTests();
  _emiReportTest();
}

// ── Application report (printed to the debug console on apply) ─────────────

void _reportTests() {
  test('report names the student, enrollment, course, batch and payment', () {
    final report = certificateApplicationReport(
      enrollment: const CertificateEnrollment(
        enrollmentNumber: 'ENR2026118595',
        courseName: 'Python Full Stack',
        batchName: 'PY-1',
        batchEndDate: '2026-11-07',
        eligible: true,
        batchCompleted: true,
        pendingAmount: 0,
        details: {
          'Enrollment': 'Fully Paid (paid)',
          'Batch status': 'status=completed, isCompleted=true, isActive=false',
          'Fees': 'net ₹50,000 · paid ₹50,000 · pending ₹0 · 100%',
        },
      ),
      studentName: 'Anu Raj',
      typeValue: 'internship',
      typeLabel: 'Internship',
      note: ' for a job ',
      dataSource: 'server list',
    );

    expect(report, contains('Student'));
    expect(report, contains('Anu Raj'));
    expect(report, contains('ENR2026118595'));
    expect(report, contains('Python Full Stack'));
    expect(report, contains('PY-1 · ends 2026-11-07'));
    expect(report, contains('status=completed, isCompleted=true'));
    expect(report, contains('net ₹50,000'));
    expect(report, contains('Pending fees'));
    expect(report, contains('batch completed ✔'));
    expect(report, contains('course fees cleared ✔'));
    expect(report, contains('Overdue EMI'));
    expect(report, contains('Internship (internship)'));
    expect(report, contains('"for a job"'));
    expect(report, contains('Earlier request : none'));
    expect(report, contains('server list'));
  });

  test('report flags a failing check and shows a rejected earlier request', () {
    final report = certificateApplicationReport(
      enrollment: CertificateEnrollment(
        enrollmentNumber: 'ENR7',
        courseName: 'Data Science',
        batchName: 'DS-4',
        batchEndDate: '',
        eligible: true,
        pendingAmount: 12500,
        request: CertificateRequestInfo.fromJson({
          'uid': 'u',
          'certificate_type': 'completion',
          'certificate_type_label': 'Course Completion',
          'status': 'rejected',
          'remark': 'Attendance below 75%',
        }),
      ),
      studentName: '',
      typeValue: 'completion',
      typeLabel: 'Course Completion',
      note: '',
      dataSource: 'dashboard',
    );
    expect(report, contains('course fees cleared ✘'));
    expect(report, contains('no overdue EMI ✔'));
    expect(report, contains('₹12,500'));
    expect(report, contains('rejected — "Attendance below 75%"'));
    expect(report, contains('Note'));
  });
}

void _emiReportTest() {
  test('report shows overdue EMI and whether it is on this enrollment', () {
    final report = certificateApplicationReport(
      enrollment: const CertificateEnrollment(
        enrollmentNumber: 'ENR2026076877',
        courseName: 'Flutter',
        batchName: 'FL-2',
        batchEndDate: '',
        eligible: true,
        pendingAmount: 0,
        emiOverdueCount: 2,
        emiOverdueAmount: 8000,
        emiOverdueHere: false,
      ),
      studentName: 'Anu',
      typeValue: 'completion',
      typeLabel: 'Course Completion',
      note: '',
      dataSource: 'server list',
    );
    expect(report, contains('course fees cleared ✔'));
    expect(report, contains('no overdue EMI ✘'));
    expect(report, contains('2 instalment(s) · ₹8,000'));
    expect(report, contains('no — on another enrollment'));
  });
}
