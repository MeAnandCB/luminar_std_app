import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/presentation/home_screen/widget/certificate_card.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';
import 'package:luminar_std/repository/certificate/certificate_service.dart';

Map<String, dynamic> _enrollment(
  String number, {
  Map<String, dynamic>? request,
  bool eligible = true,
}) => {
  'enrollment_number': number,
  'course_name': 'Python Full Stack',
  'batch_name': 'PY-1',
  'batch_end_date': '2026-11-07',
  'eligible': eligible,
  'request': request,
};

Map<String, dynamic> _request(String status, {String remark = ''}) => {
  'uid': 'u-$status',
  'certificate_type': 'internship',
  'certificate_type_label': 'Internship',
  'status': status,
  'remark': remark,
  'student_note': '',
  'requested_at': '2026-11-17T10:21:43.512Z',
  'issued_date': status == 'issued' ? '2026-11-20' : null,
};

CertificateListResponse _list(List<Map<String, dynamic>> enrollments) =>
    CertificateListResponse.fromJson({
      'certificate_types': [
        {'value': 'completion', 'label': 'Course Completion'},
        {'value': 'internship', 'label': 'Internship'},
      ],
      'enrollments': enrollments,
    });

class _FakeService extends CertificateService {
  CertificateListResponse? list;
  String? failWith;
  bool failReloadAfterPost = false;
  final List<Map<String, String>> posted = [];

  _FakeService(this.list);

  @override
  Future<ApiResponse<CertificateListResponse>> getRequests() async => list == null
      ? ApiResponse.error('boom', 500)
      : ApiResponse.success(list!, 200);

  @override
  Future<ApiResponse<CertificateRequestInfo>> requestCertificate({
    required String enrollmentNumber,
    required String certificateType,
    String? studentNote,
  }) async {
    if (failWith != null) return ApiResponse.error(failWith!, 400);
    posted.add({
      'enrollment_number': enrollmentNumber,
      'certificate_type': certificateType,
      'student_note': studentNote ?? '',
    });
    // Server now has a pending request for it (or the reload breaks).
    final info = CertificateRequestInfo.fromJson(_request('pending'));
    if (failReloadAfterPost) {
      list = null;
    } else if (list != null) {
      list = CertificateListResponse(
        certificateTypes: list!.certificateTypes,
        enrollments: [
          for (final e in list!.enrollments)
            e.enrollmentNumber == enrollmentNumber
                ? e.copyWith(request: info)
                : e,
        ],
      );
    }
    return ApiResponse.success(
      CertificateRequestInfo.fromJson(_request('pending')),
      201,
    );
  }
}

// The card loops its pulse/sheen animations forever, so pumpAndSettle would
// never return — advance time explicitly instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

CertificateEnrollment _dash(
  String number, {
  bool completed = true,
  int? pending,
  bool issued = false,
  int emiCount = 0,
  int? emiAmount,
  bool? emiHere,
  String course = 'Python Full Stack',
}) => CertificateEnrollment(
  enrollmentNumber: number,
  courseName: course,
  batchName: 'PY-1',
  batchEndDate: '2026-11-07',
  eligible: true,
  batchCompleted: completed,
  pendingAmount: pending,
  certificateAlreadyIssued: issued,
  emiOverdueCount: emiCount,
  emiOverdueAmount: emiAmount,
  emiOverdueHere: emiHere,
);

Future<void> _pump(
  WidgetTester tester,
  _FakeService service, {
  List<CertificateEnrollment> dashboard = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: CertificateHomeCard(
            key: UniqueKey(),
            service: service,
            dashboardEnrollments: dashboard,
            topSpacing: 28,
            header: const Text('Certificate heading'),
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // load future
  await tester.pump(const Duration(milliseconds: 800)); // entry animation
}

void main() {
  testWidgets('hidden (heading too) when there is no completed batch', (
    tester,
  ) async {
    await _pump(tester, _FakeService(_list([])));
    expect(find.text('Certificate heading'), findsNothing);
    expect(find.text('Apply Now'), findsNothing);
  });

  testWidgets('hidden when the request fails', (tester) async {
    await _pump(tester, _FakeService(null));
    expect(find.text('Certificate heading'), findsNothing);
  });

  testWidgets('completed batch with no request shows Apply Now', (
    tester,
  ) async {
    await _pump(tester, _FakeService(_list([_enrollment('ENR1')])));
    expect(find.text('Certificate heading'), findsOneWidget);
    expect(find.text('Claim your certificate!'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
  });

  testWidgets('pending / issued / rejected / ineligible summaries', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('E', request: _request('pending'))])),
    );
    expect(find.text('Certificate requested'), findsOneWidget);

    await _pump(
      tester,
      _FakeService(_list([_enrollment('E', request: _request('issued'))])),
    );
    expect(find.text('Certificate issued!'), findsOneWidget);

    await _pump(
      tester,
      _FakeService(
        _list([
          _enrollment(
            'E',
            request: _request('rejected', remark: 'Attendance below 75%'),
          ),
        ]),
      ),
    );
    expect(find.text('Certificate request rejected'), findsOneWidget);
    expect(find.text('Reason: Attendance below 75%'), findsOneWidget);

    await _pump(
      tester,
      _FakeService(_list([_enrollment('E', eligible: false)])),
    );
    expect(
      find.text('Not eligible for a certificate for this enrollment.'),
      findsOneWidget,
    );
  });

  testWidgets('actionable state wins and multiple batches show a count', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(
        _list([
          _enrollment('A', request: _request('issued')),
          _enrollment('B'),
          _enrollment('C'),
        ]),
      ),
    );
    expect(find.text('Claim your certificate!'), findsOneWidget);
    expect(find.text('2 batches'), findsOneWidget);
  });

  testWidgets('applying posts the request and the tile flips to pending', (
    tester,
  ) async {
    final service = _FakeService(_list([_enrollment('ENR1')]));
    await _pump(tester, service);

    await tester.tap(find.text('Apply Now'));
    await _settle(tester);

    expect(find.text('Request Certificate'), findsOneWidget);
    await tester.tap(find.text('Internship'));
    await tester.enterText(find.byType(TextField), 'for a job');
    await tester.pump();
    await tester.tap(find.text('Request Certificate'));
    await _settle(tester);

    expect(service.posted, [
      {
        'enrollment_number': 'ENR1',
        'certificate_type': 'internship',
        'student_note': 'for a job',
      },
    ]);
    // Form is gone, status badge shown.
    expect(find.text('Request Certificate'), findsNothing);
    expect(find.textContaining('Requested on'), findsWidgets);
  });

  testWidgets('server error message is shown inline and form stays', (
    tester,
  ) async {
    final service = _FakeService(_list([_enrollment('ENR1')]))
      ..failWith = 'Certificates can be requested after your batch is completed';
    await _pump(tester, service);

    await tester.tap(find.text('Apply Now'));
    await _settle(tester);
    await tester.tap(find.text('Request Certificate'));
    await _settle(tester);

    expect(
      find.text('Certificates can be requested after your batch is completed'),
      findsOneWidget,
    );
    expect(find.text('Request Certificate'), findsOneWidget);
  });

  testWidgets('rejected enrollment shows reason and the form again', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(
        _list([
          _enrollment(
            'ENR1',
            request: _request('rejected', remark: 'Fee pending'),
          ),
        ]),
      ),
    );
    await tester.tap(find.text('Review & Re-apply'));
    await _settle(tester);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Reason: Fee pending'), findsWidgets);
    expect(find.text('Request Certificate'), findsOneWidget);
  });

  testWidgets('list call fails but dashboard says completed -> card shows', (
    tester,
  ) async {
    await _pump(tester, _FakeService(null), dashboard: [_dash('ENR9')]);
    expect(find.text('Certificate heading'), findsOneWidget);
    expect(find.text('Claim your certificate!'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
  });

  testWidgets('list empty but dashboard says completed -> card shows', (
    tester,
  ) async {
    await _pump(tester, _FakeService(_list([])), dashboard: [_dash('ENR9')]);
    expect(find.text('Apply Now'), findsOneWidget);
  });

  testWidgets('server list wins over the dashboard when it has data', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('S1', request: _request('issued'))])),
      dashboard: [_dash('D1')],
    );
    expect(find.text('Certificate issued!'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);
  });

  testWidgets('applying from dashboard data works even if reload fails', (
    tester,
  ) async {
    final service = _FakeService(null)..failReloadAfterPost = true;
    await _pump(tester, service, dashboard: [_dash('ENR9')]);

    await tester.tap(find.text('Apply Now'));
    await _settle(tester);
    // Fallback types are offered because the list call never answered.
    expect(find.text('Course Completion'), findsOneWidget);
    await tester.tap(find.text('Request Certificate'));
    await _settle(tester);

    expect(service.posted.single['enrollment_number'], 'ENR9');
    expect(service.posted.single['certificate_type'], 'completion');
    expect(find.text('Request Certificate'), findsNothing);
    expect(find.textContaining('Requested on'), findsWidgets);
  });

  // ── Eligibility rules, judged per enrollment ──────────────────────────────

  testWidgets('fees pending blocks applying and shows the amount', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('E1')])),
      dashboard: [_dash('E1', pending: 12500)],
    );
    expect(find.text('Complete your payment'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);

    await tester.tap(find.text('View Details'));
    await _settle(tester);
    expect(find.textContaining('Payment pending: ₹12,500'), findsOneWidget);
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('fees fully paid can apply', (tester) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('E1')])),
      dashboard: [_dash('E1', pending: 0)],
    );
    expect(find.text('Apply Now'), findsOneWidget);
  });

  testWidgets('unknown fee data does not block (server decides)', (
    tester,
  ) async {
    await _pump(tester, _FakeService(_list([_enrollment('E1')])));
    expect(find.text('Apply Now'), findsOneWidget);
  });

  testWidgets('batch still running: card hidden when nothing is completed', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([])),
      dashboard: [_dash('E1', completed: false)],
    );
    expect(find.text('Certificate heading'), findsNothing);
    expect(find.text('Apply Now'), findsNothing);
  });

  testWidgets('running batch is listed locked next to a completed one', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('DONE')])),
      dashboard: [
        _dash('DONE'),
        _dash('LIVE', completed: false, course: 'Data Science'),
      ],
    );
    expect(find.text('Apply Now'), findsOneWidget);

    await tester.tap(find.text('Apply Now'));
    await _settle(tester);
    expect(find.text('Data Science'), findsOneWidget);
    expect(
      find.textContaining('Your batch is still in progress'),
      findsOneWidget,
    );
    // Only the completed enrollment has a form.
    expect(find.text('Request Certificate'), findsOneWidget);
  });

  testWidgets('certificate already issued (no request) cannot be requested', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('E1')])),
      dashboard: [_dash('E1', issued: true)],
    );
    expect(find.text('Certificate issued!'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);

    await tester.tap(find.text('View Details'));
    await _settle(tester);
    expect(find.textContaining('has already been issued'), findsWidgets);
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('rejected + fees pending: reason and payment notice, no form', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(
        _list([
          _enrollment(
            'E1',
            request: _request('rejected', remark: 'Fee pending'),
          ),
        ]),
      ),
      dashboard: [_dash('E1', pending: 5000)],
    );
    expect(find.text('Certificate request rejected'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await _settle(tester);
    expect(find.text('Reason: Fee pending'), findsWidgets);
    expect(find.textContaining('Payment pending: ₹5,000'), findsOneWidget);
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('pending request is shown as-is even if fees are owed', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('E1', request: _request('pending'))])),
      dashboard: [_dash('E1', pending: 5000)],
    );
    await tester.tap(find.text('View Status'));
    await _settle(tester);
    expect(find.textContaining('Requested on'), findsWidgets);
    expect(find.textContaining('Payment pending'), findsNothing);
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('each enrollment is requested individually', (tester) async {
    final service = _FakeService(
      _list([_enrollment('A'), _enrollment('B')]),
    );
    await _pump(tester, service);
    expect(find.text('2 batches'), findsOneWidget);

    await tester.tap(find.text('Apply Now'));
    await _settle(tester);
    expect(find.text('Request Certificate'), findsNWidgets(2));

    // Apply for the first tile only.
    await tester.tap(find.text('Request Certificate').first);
    await _settle(tester);

    expect(service.posted.map((p) => p['enrollment_number']), ['A']);
    // B is untouched and still offers its own form.
    expect(find.text('Request Certificate'), findsOneWidget);
    expect(find.textContaining('Requested on'), findsWidgets);
  });

  // ── EMI overdue: the server blocks the whole student portal ───────────────

  testWidgets('overdue EMI blocks even when course fees look cleared', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('E1')])),
      dashboard: [
        _dash('E1', pending: 0, emiCount: 1, emiAmount: 5000, emiHere: true),
      ],
    );
    expect(find.text('EMI payment overdue'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);

    await tester.tap(find.text('View Details'));
    await _settle(tester);
    expect(
      find.textContaining('Your EMI for this enrollment is overdue (₹5,000)'),
      findsOneWidget,
    );
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('EMI overdue on another enrollment blocks this one too', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('PAID')])),
      dashboard: [
        _dash('PAID', pending: 0, emiCount: 1, emiAmount: 3000, emiHere: false),
      ],
    );
    expect(find.text('Apply Now'), findsNothing);
    await tester.tap(find.text('View Details'));
    await _settle(tester);
    expect(find.textContaining('on another enrollment'), findsOneWidget);
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('no overdue EMI and fees cleared can apply', (tester) async {
    await _pump(
      tester,
      _FakeService(_list([_enrollment('E1')])),
      dashboard: [_dash('E1', pending: 0, emiCount: 0)],
    );
    expect(find.text('Apply Now'), findsOneWidget);
  });
}
