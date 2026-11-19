import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/certificate/certificate_controller.dart';
import 'package:luminar_std/presentation/certificate/certificate_not_ready_dialog.dart';
import 'package:luminar_std/presentation/certificate/certificate_screen.dart';
import 'package:luminar_std/presentation/home_screen/controller.dart';
import 'package:luminar_std/presentation/more_enrollment_screen_bottom/more_entrollment_bottom.dart';
import 'package:luminar_std/repository/enrollment_screen/model/enrollemnt_screen.dart'
    as enroll_model;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'certificate_test_helpers.dart';

/// A dashboard that already has one enrollment, with no network involved.
class _FakeDashboard extends DashboardController {
  _FakeDashboard(this.batchStatus);

  /// The batch's status as the dashboard reports it ('completed', 'ongoing').
  final String batchStatus;

  @override
  bool get isLoading => false;

  @override
  List<enroll_model.Enrollment> get enrollmentsFromDashboard => [
    enroll_model.Enrollment.fromJson({
      'uid': 'enr-uid-1',
      'enrollment_number': 'ENR1',
      'batch': {
        'uid': 'batch-1',
        'batch_name': 'PY-1',
        'status': batchStatus,
      },
      'course': {'course_name': 'Python Full Stack'},
      'status': {'name': 'Active', 'value': 'active'},
    }),
  ];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<CertificateController> pumpMore(
    WidgetTester tester,
    FakeCertificateService service, {
    String batchStatus = 'completed',
  }) async {
    final certificates = CertificateController(service: service);
    addTearDown(certificates.dispose);

    // Tall enough that the first few cards are all on screen, and wide enough
    // for the test environment's (much wider than real) square-glyph font.
    tester.view.physicalSize = const Size(1500, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<DashboardController>(
            create: (_) => _FakeDashboard(batchStatus),
          ),
          ChangeNotifierProvider<CertificateController>.value(
            value: certificates,
          ),
        ],
        child: const MaterialApp(home: MoreEnrollmentScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return certificates;
  }

  testWidgets('Certificates sits directly below Attendance in More', (
    tester,
  ) async {
    await pumpMore(
      tester,
      FakeCertificateService(listOf([enrollmentJson('ENR1')])),
    );

    final attendance = tester.getTopLeft(find.text('Attendance')).dy;
    final certificates = tester.getTopLeft(find.text('Certificates')).dy;
    final videos = tester.getTopLeft(find.text('Recorded Videos')).dy;

    expect(attendance, lessThan(certificates));
    expect(certificates, lessThan(videos));
    expect(
      find.text('Request and download your course certificates'),
      findsOneWidget,
    );
  });

  testWidgets('tapping Certificates opens the page and requests work there', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]));
    final shared = await pumpMore(tester, service);

    await tester.tap(find.text('Certificates'));
    await settle(tester);

    expect(find.byType(CertificateScreen), findsOneWidget);
    expect(find.text('Each course is requested separately'), findsOneWidget);
    expect(find.text('ENR1'), findsOneWidget);

    await tester.tap(find.text('Request Certificate'));
    await settle(tester);

    expect(service.posted.single['enrollment_number'], 'ENR1');
    // The page used the shared controller, so Home sees it too.
    expect(shared.data!.enrollments.single.request!.isPending, isTrue);
  });

  // ── Course not completed yet ──────────────────────────────────────────────

  testWidgets('a running course keeps the card and says when it unlocks', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]));
    await pumpMore(tester, service, batchStatus: 'ongoing');

    // Never hidden: still right below Attendance.
    expect(find.text('Certificates'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Attendance')).dy,
      lessThan(tester.getTopLeft(find.text('Certificates')).dy),
    );
    expect(find.text('Available after you complete the course'), findsOneWidget);
    expect(
      find.text('Request and download your course certificates'),
      findsNothing,
    );
  });

  testWidgets('tapping it on a running course explains, and opens nothing', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]));
    await pumpMore(tester, service, batchStatus: 'ongoing');

    await tester.tap(find.text('Certificates'));
    await settle(tester);

    expect(find.text('Certificate not ready yet'), findsOneWidget);
    expect(
      find.text(
        'Your certificate will be generated after you complete the course.',
      ),
      findsOneWidget,
    );
    // The course is named inside the dialog (the course card behind it also
    // shows the name, so look only within the dialog).
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Python Full Stack'),
      ),
      findsOneWidget,
    );
    expect(find.byType(CertificateScreen), findsNothing);
    // Nothing is fetched for a course that cannot have a certificate.
    expect(service.listCalls, 0);

    await tester.tap(find.text('Got it'));
    await settle(tester);
    expect(find.text('Certificate not ready yet'), findsNothing);
  });

  testWidgets('upcoming batches are treated the same as running ones', (
    tester,
  ) async {
    await pumpMore(
      tester,
      FakeCertificateService(listOf([enrollmentJson('ENR1')])),
      batchStatus: 'upcoming',
    );
    await tester.tap(find.text('Certificates'));
    await settle(tester);
    expect(find.text('Certificate not ready yet'), findsOneWidget);
  });

  testWidgets('a completed course shows the normal subtitle', (tester) async {
    await pumpMore(
      tester,
      FakeCertificateService(listOf([enrollmentJson('ENR1')])),
    );
    expect(
      find.text('Request and download your course certificates'),
      findsOneWidget,
    );
    expect(find.text('Available after you complete the course'), findsNothing);
  });

  group('not-ready dialog', () {
    Future<void> open(
      WidgetTester tester, {
      DateTime? expectedEnd,
      String course = 'Python Full Stack',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCertificateNotReadyDialog(
                context,
                courseName: course,
                batchName: 'PY-1',
                expectedEnd: expectedEnd,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
    }

    testWidgets('names the course and batch and the future finish date', (
      tester,
    ) async {
      await open(
        tester,
        expectedEnd: DateTime.now().add(const Duration(days: 20)),
      );
      expect(find.text('Python Full Stack · Batch PY-1'), findsOneWidget);
      expect(find.textContaining('Expected to finish on'), findsOneWidget);
    });

    testWidgets('a past or missing end date is not mentioned', (tester) async {
      await open(
        tester,
        expectedEnd: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(find.textContaining('Expected to finish on'), findsNothing);
      await tester.tap(find.text('Got it'));
      await settle(tester);

      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.textContaining('Expected to finish on'), findsNothing);
    });
  });
}
