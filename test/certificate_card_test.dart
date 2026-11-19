import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminar_std/presentation/certificate/certificate_controller.dart';
import 'package:luminar_std/presentation/certificate/certificate_screen.dart';
import 'package:luminar_std/presentation/home_screen/widget/certificate_card.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';
import 'certificate_test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeCertificateService service, {
  List<String>? opened,
  bool canOpen = true,
  List<String> completedCourses = const [],
}) async {
  final controller = CertificateController(
    service: service,
    fileOpener: (path) async {
      opened?.add(path);
      return canOpen;
    },
  );
  addTearDown(controller.dispose);

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
            controller: controller,
            completedCourses: completedCourses,
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
  // ── Model ─────────────────────────────────────────────────────────────────

  test('parses the guide\'s GET example', () {
    final list = CertificateListResponse.fromJson({
      'status': 'success',
      'enrollments': [
        {
          'enrollment_number': 'ENR2026118595',
          'course_name': 'Python Full Stack',
          'batch_name': 'PY-1',
          'batch_end_date': '2026-11-07',
          'eligible': true,
          'certificate_type': 'completion',
          'certificate_type_label': 'Course Completion',
          'request': null,
        },
        {
          'enrollment_number': 'ENR2026117097',
          'course_name': 'Data Science',
          'batch_name': 'DS-4',
          'batch_end_date': '2026-10-30',
          'eligible': true,
          'certificate_type': 'internship',
          'certificate_type_label': 'Internship',
          'request': {
            'uid': '2a7ca5b1',
            'certificate_type': 'internship',
            'certificate_type_label': 'Internship',
            'status': 'issued',
            'remark': '',
            'student_note': 'for job',
            'requested_at': '2026-11-17T10:21:43.512Z',
            'issued_date': '2026-11-20',
            'download_available': true,
            'serial_no': 17,
            'register_no': 'LUM / KOC / 42782',
          },
        },
      ],
    });

    final first = list.enrollments[0];
    expect(first.certificateTypeLabel, 'Course Completion');
    expect(first.request, isNull);
    expect(first.canRequest, isTrue);

    final req = list.enrollments[1].request!;
    expect(req.isIssued, isTrue);
    expect(req.downloadAvailable, isTrue);
    expect(req.serialNo, 17);
    expect(req.registerNo, 'LUM / KOC / 42782');
    expect(req.issuedDate, '2026-11-20');
    expect(list.enrollments[1].canRequest, isFalse);
  });

  test('POST answer without the issued-only fields still parses', () {
    final req = CertificateRequestInfo.fromJson({
      'uid': 'u1',
      'certificate_type': 'completion',
      'certificate_type_label': 'Course Completion',
      'status': 'pending',
      'remark': '',
      'student_note': 'x',
      'requested_at': '2026-11-17T10:30:00Z',
      'issued_date': null,
    });
    expect(req.downloadAvailable, isFalse);
    expect(req.serialNo, isNull);
    expect(req.registerNo, isNull);
  });

  test('only eligible, never-requested or rejected enrollments can request', () {
    CertificateEnrollment e(String? status, {bool eligible = true}) =>
        CertificateEnrollment.fromJson(
          enrollmentJson(
            'E',
            eligible: eligible,
            request: status == null ? null : requestJson(status),
          ),
        );
    expect(e(null).canRequest, isTrue);
    expect(e('rejected').canRequest, isTrue);
    expect(e('pending').canRequest, isFalse);
    expect(e('issued').canRequest, isFalse);
    expect(e(null, eligible: false).canRequest, isFalse);
    expect(e('rejected', eligible: false).canRequest, isFalse);
  });

  // ── Home card ─────────────────────────────────────────────────────────────

  testWidgets('hidden (heading too) when there is no completed batch', (
    tester,
  ) async {
    await _pump(tester, FakeCertificateService(listOf([])));
    expect(find.text('Certificate heading'), findsNothing);
    expect(find.text('Apply Now'), findsNothing);
  });

  testWidgets('hidden when the request fails', (tester) async {
    await _pump(tester, FakeCertificateService(null));
    expect(find.text('Certificate heading'), findsNothing);
  });

  testWidgets('completed batch with no request shows Apply Now', (
    tester,
  ) async {
    await _pump(tester, FakeCertificateService(listOf([enrollmentJson('ENR1')])));
    expect(find.text('Certificate heading'), findsOneWidget);
    expect(find.text('Claim your certificate!'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
  });

  // ── When the Home card shows ──────────────────────────────────────────────

  testWidgets('tapping the card opens the Certificates page', (tester) async {
    await _pump(tester, FakeCertificateService(listOf([enrollmentJson('E1')])));
    expect(find.byType(CertificateScreen), findsNothing);

    await tester.tap(find.text('Apply Now'));
    await settle(tester);

    expect(find.byType(CertificateScreen), findsOneWidget);
    expect(find.text('Request Certificate'), findsOneWidget);
  });

  testWidgets('hidden when no course is completed and the server has none', (
    tester,
  ) async {
    // Dashboard: nothing completed. Server: nothing listed.
    await _pump(tester, FakeCertificateService(listOf([])));
    expect(find.text('Certificate heading'), findsNothing);
    expect(find.text('View Certificate'), findsNothing);
  });

  testWidgets('shown when the dashboard says a course is completed', (
    tester,
  ) async {
    // The server has nothing for it (yet), but the course is completed.
    await _pump(
      tester,
      FakeCertificateService(listOf([])),
      completedCourses: ['Python Full Stack'],
    );
    expect(find.text('Certificate heading'), findsOneWidget);
    // Neutral: never claims "apply" or "issued" it cannot confirm.
    expect(find.text('Your certificate'), findsOneWidget);
    expect(
      find.textContaining('Congratulations on completing Python Full Stack'),
      findsOneWidget,
    );
    expect(find.text('View Certificate'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);
    expect(find.text('Certificate issued!'), findsNothing);
  });

  testWidgets('shown when the dashboard says completed but the server fails', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(null),
      completedCourses: ['Python Full Stack'],
    );
    expect(find.text('View Certificate'), findsOneWidget);

    // The page explains what is going on instead of an empty sheet.
    await tester.tap(find.text('View Certificate'));
    await settle(tester);
    expect(find.byType(CertificateScreen), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('completed with nothing on the server: the page explains why', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(listOf([])),
      completedCourses: ['Python Full Stack'],
    );
    await tester.tap(find.text('View Certificate'));
    await settle(tester);
    expect(
      find.textContaining('couldn\'t find a certificate for Python Full Stack'),
      findsOneWidget,
    );
  });

  testWidgets('neutral while loading, then the real state once it arrives', (
    tester,
  ) async {
    final gate = Completer<void>();
    final service = FakeCertificateService(
      listOf([enrollmentJson('E1', request: requestJson('issued'))]),
    )..gate = gate;
    await _pump(tester, service, completedCourses: ['Python Full Stack']);

    // No flash of "Claim your certificate!" for someone already issued.
    expect(find.text('Your certificate'), findsOneWidget);
    expect(find.text('Claim your certificate!'), findsNothing);

    gate.complete();
    await settle(tester);
    expect(find.text('Certificate issued!'), findsOneWidget);
    expect(find.text('Your certificate'), findsNothing);
  });

  testWidgets('the server\'s state wins once it is known', (tester) async {
    await _pump(
      tester,
      FakeCertificateService(
        listOf([enrollmentJson('E1', request: requestJson('pending'))]),
      ),
      completedCourses: ['Python Full Stack'],
    );
    expect(find.text('Certificate requested'), findsOneWidget);
    expect(find.text('View Certificate'), findsNothing);
  });

  testWidgets('appears when the dashboard finishes loading later', (
    tester,
  ) async {
    final completed = ValueNotifier<List<String>>(const []);
    final controller = CertificateController(
      service: FakeCertificateService(listOf([])),
    );
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<List<String>>(
            valueListenable: completed,
            builder: (_, names, __) => CertificateHomeCard(
              controller: controller,
              completedCourses: names,
              header: const Text('Certificate heading'),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Certificate heading'), findsNothing);

    // The dashboard arrives and reports a completed course.
    completed.value = ['Python Full Stack'];
    await settle(tester);
    expect(find.text('Certificate heading'), findsOneWidget);
    expect(find.text('View Certificate'), findsOneWidget);

    // ...and it goes away again if that stops being true.
    completed.value = const [];
    await settle(tester);
    expect(find.text('Certificate heading'), findsNothing);
  });

  testWidgets('pending / issued / rejected / ineligible summaries', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(listOf([enrollmentJson('E', request: requestJson('pending'))])),
    );
    expect(find.text('Certificate requested'), findsOneWidget);

    await _pump(
      tester,
      FakeCertificateService(listOf([enrollmentJson('E', request: requestJson('issued'))])),
    );
    expect(find.text('Certificate issued!'), findsOneWidget);

    await _pump(
      tester,
      FakeCertificateService(
        listOf([
          enrollmentJson(
            'E',
            request: requestJson('rejected', remark: 'Attendance below 75%'),
          ),
        ]),
      ),
    );
    expect(find.text('Certificate request rejected'), findsOneWidget);
    expect(find.text('Reason: Attendance below 75%'), findsOneWidget);

    await _pump(
      tester,
      FakeCertificateService(listOf([enrollmentJson('E', eligible: false)])),
    );
    expect(
      find.text('Not eligible for a certificate for this enrollment.'),
      findsOneWidget,
    );
  });

  testWidgets('issued summary offers Download only when it is available', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(
        listOf([
          enrollmentJson('E', request: requestJson('issued', download: true)),
        ]),
      ),
    );
    expect(find.text('Download'), findsOneWidget);

    await _pump(
      tester,
      FakeCertificateService(listOf([enrollmentJson('E', request: requestJson('issued'))])),
    );
    expect(find.text('Download'), findsNothing);
    expect(find.text('View Details'), findsOneWidget);
  });

  testWidgets('actionable state wins and multiple batches show a count', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(
        listOf([
          enrollmentJson('A', request: requestJson('issued')),
          enrollmentJson('B'),
          enrollmentJson('C'),
        ]),
      ),
    );
    expect(find.text('Claim your certificate!'), findsOneWidget);
    expect(find.text('2 batches'), findsOneWidget);
  });

  // ── Requesting ────────────────────────────────────────────────────────────

  testWidgets('the batch decides the certificate: label shown, no chooser', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(
        listOf([
          enrollmentJson('ENR1', type: 'completion', typeLabel: 'Course Completion'),
        ]),
      ),
    );
    await tester.tap(find.text('Apply Now'));
    await settle(tester);

    // Shown once, as plain text — the old "Certificate type" picker and its
    // second option are gone.
    expect(find.text('Course Completion'), findsOneWidget);
    expect(find.text('Certificate type'), findsNothing);
    expect(find.text('Internship'), findsNothing);
  });

  testWidgets('applying posts enrollment + note only and flips to pending', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]));
    await _pump(tester, service);

    await tester.tap(find.text('Apply Now'));
    await settle(tester);

    expect(find.text('Request Certificate'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'for a job');
    await tester.pump();
    await tester.tap(find.text('Request Certificate'));
    await settle(tester);

    expect(service.posted, [
      {'enrollment_number': 'ENR1', 'student_note': 'for a job'},
    ]);
    // Form is gone, status badge shown.
    expect(find.text('Request Certificate'), findsNothing);
    expect(find.textContaining('Requested on'), findsWidgets);
  });

  testWidgets('server error message is shown inline and form stays', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]))
      ..failWith = 'Certificates can be requested after your batch is completed';
    await _pump(tester, service);

    await tester.tap(find.text('Apply Now'));
    await settle(tester);
    await tester.tap(find.text('Request Certificate'));
    await settle(tester);

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
      FakeCertificateService(
        listOf([
          enrollmentJson(
            'ENR1',
            request: requestJson('rejected', remark: 'Fee pending'),
          ),
        ]),
      ),
    );
    await tester.tap(find.text('Review & Re-apply'));
    await settle(tester);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Reason: Fee pending'), findsWidgets);
    expect(find.text('Request Certificate'), findsOneWidget);
  });

  testWidgets('a remark is only shown for a rejection', (tester) async {
    // The server blanks it otherwise, but never rely on that.
    await _pump(
      tester,
      FakeCertificateService(
        listOf([
          enrollmentJson(
            'ENR1',
            request: requestJson('pending', remark: 'internal note'),
          ),
        ]),
      ),
    );
    await tester.tap(find.text('View Status'));
    await settle(tester);
    expect(find.textContaining('internal note'), findsNothing);
  });

  testWidgets('not eligible with no request: message, no form', (tester) async {
    await _pump(
      tester,
      FakeCertificateService(listOf([enrollmentJson('ENR1', eligible: false)])),
    );
    await tester.tap(find.text('View Details'));
    await settle(tester);
    expect(
      find.text('Not eligible for a certificate for this enrollment.'),
      findsWidgets,
    );
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('applying still flips to pending if the reload fails', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR9')]))
      ..failReloadAfterPost = true;
    await _pump(tester, service);

    await tester.tap(find.text('Apply Now'));
    await settle(tester);
    await tester.tap(find.text('Request Certificate'));
    await settle(tester);

    expect(service.posted.single['enrollment_number'], 'ENR9');
    expect(find.text('Request Certificate'), findsNothing);
    expect(find.textContaining('Requested on'), findsWidgets);
  });

  testWidgets('each enrollment is requested individually', (tester) async {
    final service = FakeCertificateService(
      listOf([enrollmentJson('A'), enrollmentJson('B')]),
    );
    await _pump(tester, service);
    expect(find.text('2 batches'), findsOneWidget);

    await tester.tap(find.text('Apply Now'));
    await settle(tester);
    expect(find.text('Request Certificate'), findsNWidgets(2));

    // Apply for the first tile only.
    await tester.tap(find.text('Request Certificate').first);
    await settle(tester);

    expect(service.posted.map((p) => p['enrollment_number']), ['A']);
    // B is untouched and still offers its own form.
    expect(find.text('Request Certificate'), findsOneWidget);
    expect(find.textContaining('Requested on'), findsWidgets);
  });

  // ── Issued: numbers + download ────────────────────────────────────────────

  testWidgets('issued shows serial / register numbers and Download', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(
        listOf([
          enrollmentJson(
            'ENR1',
            request: requestJson(
              'issued',
              download: true,
              serial: 17,
              register: 'LUM / KOC / 42782',
            ),
          ),
        ]),
      ),
    );
    await tester.tap(find.text('Download'));
    await settle(tester);

    expect(find.textContaining('Issued on 20 Nov 2026'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('LUM / KOC / 42782'), findsOneWidget);
    expect(find.text('Download Certificate'), findsOneWidget);
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('issued without download_available has no Download button', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCertificateService(
        listOf([
          enrollmentJson('ENR1', request: requestJson('issued', serial: 5)),
        ]),
      ),
    );
    await tester.tap(find.text('View Details'));
    await settle(tester);
    expect(find.text('Download Certificate'), findsNothing);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('Download fetches by request uid and opens the saved PDF', (
    tester,
  ) async {
    final service = FakeCertificateService(
      listOf([
        enrollmentJson('ENR1', request: requestJson('issued', download: true)),
      ]),
    );
    final opened = <String>[];
    await _pump(tester, service, opened: opened);

    await tester.tap(find.text('Download'));
    await settle(tester);
    await tester.tap(find.text('Download Certificate'));
    await settle(tester);

    expect(service.downloads, [
      {'uid': 'u-issued', 'enrollment_number': 'ENR1'},
    ]);
    expect(opened, ['/tmp/Certificate-ENR1.pdf']);
    // Button is back to its idle label, no error shown.
    expect(find.text('Download Certificate'), findsOneWidget);
    expect(find.text('Downloading…'), findsNothing);
  });

  testWidgets('a download error shows the server message and can be retried', (
    tester,
  ) async {
    final service = FakeCertificateService(
      listOf([
        enrollmentJson('ENR1', request: requestJson('issued', download: true)),
      ]),
    )..downloadFailWith = 'Certificate template image is missing';
    final opened = <String>[];
    await _pump(tester, service, opened: opened);

    await tester.tap(find.text('Download'));
    await settle(tester);
    await tester.tap(find.text('Download Certificate'));
    await settle(tester);

    expect(find.text('Certificate template image is missing'), findsOneWidget);
    expect(opened, isEmpty);

    // Retry works once the server recovers, and clears the error.
    service.downloadFailWith = null;
    await tester.tap(find.text('Download Certificate'));
    await settle(tester);
    expect(find.text('Certificate template image is missing'), findsNothing);
    expect(opened, hasLength(1));
    expect(service.downloads, hasLength(2));
  });
}
