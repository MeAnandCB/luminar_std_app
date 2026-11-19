import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminar_std/presentation/certificate/certificate_controller.dart';
import 'package:luminar_std/presentation/certificate/certificate_screen.dart';
import 'package:luminar_std/presentation/home_screen/widget/certificate_card.dart';

import 'certificate_test_helpers.dart';

CertificateController _controller(
  FakeCertificateService service, {
  List<String>? opened,
}) {
  final c = CertificateController(
    service: service,
    fileOpener: (path) async {
      opened?.add(path);
      return true;
    },
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _pumpScreen(WidgetTester tester, CertificateController c) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: CertificateScreen(controller: c)));
  await settle(tester);
}

void main() {
  // ── Controller ────────────────────────────────────────────────────────────

  group('CertificateController', () {
    test('is loading until the first answer, then holds the list', () async {
      final service = FakeCertificateService(listOf([enrollmentJson('E1')]))
        ..gate = Completer<void>();
      final c = _controller(service);

      expect(c.isLoading, isTrue);
      expect(c.data, isNull);

      final loading = c.load();
      service.gate!.complete();
      await loading;

      expect(c.isLoading, isFalse);
      expect(c.error, isNull);
      expect(c.data!.enrollments.single.enrollmentNumber, 'E1');
    });

    test('load() fetches once; refresh() fetches again', () async {
      final service = FakeCertificateService(listOf([enrollmentJson('E1')]));
      final c = _controller(service);

      await c.load();
      await c.load();
      expect(service.listCalls, 1);

      await c.refresh();
      expect(service.listCalls, 2);
    });

    test('overlapping refreshes share one request', () async {
      final service = FakeCertificateService(listOf([enrollmentJson('E1')]))
        ..gate = Completer<void>();
      final c = _controller(service);

      final a = c.refresh();
      final b = c.refresh();
      final d = c.load();
      service.gate!.complete();
      await Future.wait([a, b, d]);

      expect(service.listCalls, 1);
    });

    test('a failed first load reports an error and can be retried', () async {
      final service = FakeCertificateService(null);
      final c = _controller(service);

      await c.load();
      expect(c.isLoading, isFalse);
      expect(c.data, isNull);
      expect(c.error, isNotNull);

      service.list = listOf([enrollmentJson('E1')]);
      await c.refresh();
      expect(c.error, isNull);
      expect(c.data!.enrollments, hasLength(1));
    });

    test('retrying after a failure never notifies synchronously', () async {
      // refresh() runs from initState, i.e. mid-build; a listener (like the
      // Home card) must not be told until that build is over.
      final service = FakeCertificateService(null);
      final c = _controller(service);
      await c.load();
      expect(c.error, isNotNull);

      var notified = 0;
      c.addListener(() => notified++);
      service.list = listOf([enrollmentJson('E1')]);
      final retry = c.refresh();

      expect(c.isLoading, isTrue, reason: 'state is updated immediately');
      expect(notified, 0, reason: 'but nobody is notified mid-build');
      await retry;
      expect(notified, greaterThan(0));
      expect(c.data!.enrollments, hasLength(1));
    });

    test('a failed refresh keeps the list that is already on screen', () async {
      final service = FakeCertificateService(listOf([enrollmentJson('E1')]));
      final c = _controller(service);
      await c.load();

      service.list = null; // server goes away
      await c.refresh();

      expect(c.error, isNull);
      expect(c.data!.enrollments.single.enrollmentNumber, 'E1');
    });

    test('an empty list is "answered", not loading, and has no data', () async {
      final c = _controller(FakeCertificateService(listOf([])));
      await c.load();
      expect(c.isLoading, isFalse);
      expect(c.error, isNull);
      expect(c.data, isNull);
    });

    test('submit flips the enrollment to pending for every listener', () async {
      final service = FakeCertificateService(
        listOf([enrollmentJson('E1'), enrollmentJson('E2')]),
      );
      final c = _controller(service);
      await c.load();
      var notified = 0;
      c.addListener(() => notified++);

      final error = await c.submit('E1', ' for a job ');

      expect(error, isNull);
      expect(notified, greaterThan(0));
      expect(service.posted, [
        {'enrollment_number': 'E1', 'student_note': ' for a job '},
      ]);
      final byNumber = {
        for (final e in c.data!.enrollments) e.enrollmentNumber: e,
      };
      expect(byNumber['E1']!.request!.isPending, isTrue);
      expect(byNumber['E2']!.request, isNull);
    });

    test('submit still shows pending if the follow-up refresh fails', () async {
      final service = FakeCertificateService(listOf([enrollmentJson('E1')]))
        ..failReloadAfterPost = true;
      final c = _controller(service);
      await c.load();

      expect(await c.submit('E1', ''), isNull);
      expect(c.data!.enrollments.single.request!.isPending, isTrue);
    });

    test('submit returns the server message on failure', () async {
      final service = FakeCertificateService(listOf([enrollmentJson('E1')]))
        ..failWith = 'Request already exists';
      final c = _controller(service);
      await c.load();

      expect(await c.submit('E1', ''), 'Request already exists');
      // The real state is pulled so the stale form goes away.
      expect(service.listCalls, 2);
    });

    test('download fetches by request uid and opens the file', () async {
      final service = FakeCertificateService(
        listOf([
          enrollmentJson(
            'E1',
            request: requestJson('issued', download: true),
          ),
        ]),
      );
      final opened = <String>[];
      final c = _controller(service, opened: opened);
      await c.load();

      expect(await c.download(c.data!.enrollments.single), isNull);
      expect(service.downloads, [
        {'uid': 'u-issued', 'enrollment_number': 'E1'},
      ]);
      expect(opened, ['/tmp/Certificate-E1.pdf']);
    });

    test('technical failures reach the student as plain language', () async {
      final service = FakeCertificateService(
        listOf([
          enrollmentJson(
            'E1',
            request: requestJson('issued', download: true),
          ),
        ]),
      );
      final c = _controller(service);
      await c.load();

      service.downloadFailWith =
          'SocketException: Failed host lookup: api.example.com (OS Error)';
      final error = await c.download(c.data!.enrollments.single);
      expect(error, contains('No internet connection'));
      expect(error, isNot(contains('SocketException')));

      service.failWith = 'Exception: Null check operator used on a null value';
      final submitError = await c.submit('E1', '');
      expect(submitError, 'Something went wrong. Please try again.');
    });

    test('notifying after dispose does not throw', () async {
      final service = FakeCertificateService(listOf([enrollmentJson('E1')]))
        ..gate = Completer<void>();
      final c = CertificateController(service: service);

      final pending = c.load();
      c.dispose();
      service.gate!.complete();
      await pending; // would throw if it notified a disposed notifier
    });
  });

  // ── More → Certificates page ──────────────────────────────────────────────

  testWidgets('shows a spinner, then a tile per enrollment', (tester) async {
    final service = FakeCertificateService(
      listOf([enrollmentJson('ENR1'), enrollmentJson('ENR2')]),
    )..gate = Completer<void>();
    final c = _controller(service);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: CertificateScreen(controller: c)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Certificates'), findsOneWidget);

    service.gate!.complete();
    await settle(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('ENR1'), findsOneWidget);
    expect(find.text('ENR2'), findsOneWidget);
    expect(find.text('Request Certificate'), findsNWidgets(2));
  });

  testWidgets('requesting from the page flips that tile to pending', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]));
    await _pumpScreen(tester, _controller(service));

    await tester.enterText(find.byType(TextField), 'for a job');
    await tester.pump();
    await tester.tap(find.text('Request Certificate'));
    await settle(tester);

    expect(service.posted, [
      {'enrollment_number': 'ENR1', 'student_note': 'for a job'},
    ]);
    expect(find.text('Request Certificate'), findsNothing);
    expect(find.textContaining('Requested on'), findsOneWidget);
  });

  testWidgets('an issued certificate can be downloaded from the page', (
    tester,
  ) async {
    final service = FakeCertificateService(
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
    );
    final opened = <String>[];
    await _pumpScreen(tester, _controller(service, opened: opened));

    expect(find.text('LUM / KOC / 42782'), findsOneWidget);
    await tester.tap(find.text('Download Certificate'));
    await settle(tester);

    expect(opened, ['/tmp/Certificate-ENR1.pdf']);
  });

  testWidgets('Serial / Register values line up in one column', (tester) async {
    await _pumpScreen(
      tester,
      _controller(
        FakeCertificateService(
          listOf([
            enrollmentJson(
              'ENR1',
              request: requestJson(
                'issued',
                download: true,
                serial: 1003,
                // Labels of different lengths must not shift the values.
                register: 'LUM / KOC / 42783',
              ),
            ),
          ]),
        ),
      ),
    );

    final serial = tester.getTopLeft(find.text('1003')).dx;
    final register = tester.getTopLeft(find.text('LUM / KOC / 42783')).dx;
    expect(serial, register);
    // And both sit to the right of their (left-aligned) labels.
    expect(
      serial,
      greaterThan(tester.getTopRight(find.text('Register No.')).dx),
    );
    expect(
      tester.getTopLeft(find.text('Serial No.')).dx,
      tester.getTopLeft(find.text('Register No.')).dx,
    );
  });

  testWidgets('the title stays left-aligned under the app\'s centred theme', (
    tester,
  ) async {
    final c = _controller(
      FakeCertificateService(listOf([enrollmentJson('ENR1')])),
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // AppTheme centres every AppBar title; this page must opt out.
        theme: ThemeData(appBarTheme: const AppBarTheme(centerTitle: true)),
        home: CertificateScreen(controller: c),
      ),
    );
    await settle(tester);

    final title = tester.getTopLeft(find.text('Certificates'));
    final screenWidth = tester.view.physicalSize.width / 3;
    expect(title.dx, lessThan(screenWidth / 4));
  });

  testWidgets('opening the page re-reads the list even if one is cached', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]));
    final c = _controller(service);
    await c.load(); // e.g. the home card already fetched it
    expect(service.listCalls, 1);

    // Staff issued it in the meantime.
    service.list = listOf([
      enrollmentJson('ENR1', request: requestJson('issued', download: true)),
    ]);
    await _pumpScreen(tester, c);

    expect(service.listCalls, 2);
    expect(find.text('Download Certificate'), findsOneWidget);
    expect(find.text('Request Certificate'), findsNothing);
  });

  testWidgets('a failed load shows the error and Try again recovers', (
    tester,
  ) async {
    final service = FakeCertificateService(null);
    await _pumpScreen(tester, _controller(service));

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Request Certificate'), findsNothing);

    service.list = listOf([enrollmentJson('ENR1')]);
    await tester.tap(find.text('Try again'));
    await settle(tester);

    expect(find.text('Try again'), findsNothing);
    expect(find.text('Request Certificate'), findsOneWidget);
  });

  testWidgets('no completed batch shows the guide\'s empty message', (
    tester,
  ) async {
    await _pumpScreen(tester, _controller(FakeCertificateService(listOf([]))));
    expect(
      find.text('Certificates can be requested after your batch is completed.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('a completed course the server has nothing for is explained', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([]));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CertificateScreen(
          controller: _controller(service),
          courseName: 'Python Full Stack',
        ),
      ),
    );
    await settle(tester);

    // Must not tell someone whose course IS completed to wait for completion.
    expect(
      find.textContaining('after your batch is completed'),
      findsNothing,
    );
    expect(
      find.textContaining('couldn\'t find a certificate for Python Full Stack'),
      findsOneWidget,
    );
    expect(find.textContaining('academic counselor'), findsOneWidget);

    // Refresh asks the server again.
    expect(service.listCalls, 1);
    await tester.tap(find.text('Refresh'));
    await settle(tester);
    expect(service.listCalls, 2);
  });

  testWidgets('not eligible: message, no form, no button', (tester) async {
    await _pumpScreen(
      tester,
      _controller(
        FakeCertificateService(listOf([enrollmentJson('E', eligible: false)])),
      ),
    );
    expect(
      find.text('Not eligible for a certificate for this enrollment.'),
      findsOneWidget,
    );
    expect(find.text('Request Certificate'), findsNothing);
  });

  // ── Shared with the home card ─────────────────────────────────────────────

  testWidgets('a request made on the page shows up on the home card', (
    tester,
  ) async {
    final service = FakeCertificateService(listOf([enrollmentJson('ENR1')]));
    final c = _controller(service);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  CertificateHomeCard(controller: c, topSpacing: 8),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CertificateScreen(controller: c),
                      ),
                    ),
                    child: const Text('open page'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Claim your certificate!'), findsOneWidget);

    await tester.tap(find.text('open page'));
    await settle(tester);
    await tester.tap(find.text('Request Certificate'));
    await settle(tester);

    // Back on Home, with no reload of its own, it already knows.
    Navigator.of(tester.element(find.byType(CertificateScreen))).pop();
    await settle(tester);
    expect(find.text('Claim your certificate!'), findsNothing);
    expect(find.text('Certificate requested'), findsOneWidget);
  });
}
