import 'package:intl/intl.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';

/// A readable, multi-line description of ONE certificate application — who is
/// applying, for which enrollment/course/batch, the batch and payment state,
/// and which eligibility checks passed. Printed to the debug console when the
/// student taps "Request Certificate" so it is clear exactly what is sent.
String certificateApplicationReport({
  required CertificateEnrollment enrollment,
  required String studentName,
  required String typeValue,
  required String typeLabel,
  required String note,
  required String dataSource,
}) {
  String mark(bool? ok) => ok == null ? '?' : (ok ? '✔' : '✘');
  String money(int n) => '₹${NumberFormat('#,##,###').format(n)}';

  final e = enrollment;
  final req = e.request;

  final rows = <MapEntry<String, String>>[
    MapEntry('Student', studentName.isEmpty ? '—' : studentName),
    MapEntry('Enrollment No.', e.enrollmentNumber),
    MapEntry('Course', e.courseName.isEmpty ? '—' : e.courseName),
    MapEntry(
      'Batch',
      '${e.batchName.isEmpty ? '—' : e.batchName}'
          '${e.batchEndDate.isEmpty ? '' : ' · ends ${e.batchEndDate}'}',
    ),
    ...e.details.entries,
    MapEntry(
      'Overdue EMI',
      e.emiOverdueCount == 0
          ? 'none'
          : '${e.emiOverdueCount} instalment(s)'
                '${e.emiOverdueAmount == null ? '' : ' · ${money(e.emiOverdueAmount!)}'}'
                ' · this enrollment: '
                '${e.emiOverdueHere == null ? 'unknown' : (e.emiOverdueHere! ? 'yes' : 'no — on another enrollment')}',
    ),
    MapEntry(
      'Pending fees',
      e.pendingAmount == null ? 'unknown' : money(e.pendingAmount!),
    ),
    MapEntry(
      'Checks',
      'batch completed ${mark(e.batchCompleted)} · '
          'enrollment active ${mark(e.eligible)} · '
          'course fees cleared ${mark(e.pendingAmount == null ? null : !e.paymentPending)} · '
          'no overdue EMI ${mark(e.emiOverdueCount == 0)} · '
          'not already issued ${mark(!e.certificateAlreadyIssued)}',
    ),
    MapEntry('Applying for', '$typeLabel ($typeValue)'),
    MapEntry('Note', note.trim().isEmpty ? '—' : '"${note.trim()}"'),
    MapEntry(
      'Earlier request',
      req == null
          ? 'none'
          : '${req.status}${req.remark.isEmpty ? '' : ' — "${req.remark}"'}',
    ),
    MapEntry('Data source', dataSource),
  ];

  final width = rows.map((r) => r.key.length).reduce((a, b) => a > b ? a : b);
  final body = rows.map((r) => '${r.key.padRight(width)} : ${r.value}').join('\n');
  return '══════ CERTIFICATE APPLICATION ══════\n$body\n'
      '═════════════════════════════════════';
}
