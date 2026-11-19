import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:luminar_std/repository/certificate/certificate_service.dart';

// A minimal but real-looking PDF body: the service only trusts `%PDF`.
final Uint8List _pdf = Uint8List.fromList(
  utf8.encode('%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF'),
);

http.Response _json(int status, Map<String, dynamic> body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('POST body', () {
    test('carries the enrollment number and note, never a certificate type', () {
      final body = CertificateService.requestBody(
        enrollmentNumber: 'ENR2026118595',
        studentNote: '  Need it for a job application  ',
      );
      // The server sets the type from the batch; sending one is pointless.
      expect(body, {
        'enrollment_number': 'ENR2026118595',
        'student_note': 'Need it for a job application',
      });
      expect(body.containsKey('certificate_type'), isFalse);
    });

    test('blank note is omitted, number is trimmed', () {
      final body = CertificateService.requestBody(
        enrollmentNumber: ' ENR1 ',
        studentNote: '   ',
      );
      expect(body, {'enrollment_number': 'ENR1'});
    });

    test('an empty enrollment number is never sent', () async {
      final res = await CertificateService().requestCertificate(
        enrollmentNumber: '  ',
      );
      expect(res.success, isFalse);
      expect(res.message, 'Enrollment not found');
    });
  });

  test('file name follows the guide and is filesystem-safe', () {
    expect(
      CertificateService.fileNameFor('ENR2026118595'),
      'Certificate-ENR2026118595.pdf',
    );
    expect(
      CertificateService.fileNameFor('../ENR 1/2'),
      'Certificate-.._ENR_1_2.pdf',
    );
    expect(CertificateService.fileNameFor('  '), 'Certificate-download.pdf');
  });

  group('downloadCertificate', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('cert_test_'));
    tearDown(() => dir.deleteSync(recursive: true));

    CertificateService service({String? token = 'tok'}) => CertificateService(
      tokenReader: () async => token,
      saveDirectory: () async => dir,
    );

    /// Runs [body] with every `package:http` call answered by [handler].
    Future<T> withServer<T>(
      http.Response Function(http.Request) handler,
      Future<T> Function() body,
    ) => http.runWithClient(
      body,
      () => MockClient((request) async => handler(request)),
    );

    test('saves the PDF as Certificate-<enrollment>.pdf and returns the path',
        () async {
      http.Request? seen;
      final res = await withServer((req) {
        seen = req;
        return http.Response.bytes(
          _pdf,
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition':
                'attachment; filename="Certificate-ENR2026118595.pdf"',
          },
        );
      }, () => service().downloadCertificate(
        requestUid: '2a7ca5b1-10da',
        enrollmentNumber: 'ENR2026118595',
      ));

      expect(res.success, isTrue, reason: res.message);
      expect(res.data, '${dir.path}/Certificate-ENR2026118595.pdf');
      expect(File(res.data!).readAsBytesSync(), _pdf);

      expect(
        seen!.url.path,
        '/api/student_portal/certificate-requests/2a7ca5b1-10da/download/',
      );
      expect(seen!.method, 'GET');
      expect(seen!.headers['Authorization'], 'Bearer tok');
    });

    test('downloading again overwrites the same file', () async {
      Future<String> once(Uint8List bytes) async {
        final res = await withServer(
          (_) => http.Response.bytes(bytes, 200),
          () => service().downloadCertificate(
            requestUid: 'u1',
            enrollmentNumber: 'ENR1',
          ),
        );
        expect(res.success, isTrue, reason: res.message);
        return res.data!;
      }

      final newer = Uint8List.fromList([..._pdf, 0x0A, 0x0A]);
      final first = await once(_pdf);
      final second = await once(newer);
      expect(second, first);
      expect(File(second).readAsBytesSync(), newer);
      expect(dir.listSync(), hasLength(1));
    });

    test('404 surfaces the server message and writes nothing', () async {
      final res = await withServer(
        (_) => _json(404, {'status': 'error', 'message': 'Certificate not found'}),
        () => service().downloadCertificate(
          requestUid: 'u1',
          enrollmentNumber: 'ENR1',
        ),
      );
      expect(res.success, isFalse);
      expect(res.message, 'Certificate not found');
      expect(res.statusCode, 404);
      expect(dir.listSync(), isEmpty);
    });

    test('500 template error is passed through to be shown', () async {
      final res = await withServer(
        (_) => _json(500, {
          'status': 'error',
          'message': 'Certificate template image is missing',
        }),
        () => service().downloadCertificate(
          requestUid: 'u1',
          enrollmentNumber: 'ENR1',
        ),
      );
      expect(res.success, isFalse);
      expect(res.message, 'Certificate template image is missing');
      expect(dir.listSync(), isEmpty);
    });

    test('a 200 that is not a PDF is rejected, not saved', () async {
      final res = await withServer(
        (_) => http.Response(
          '<html>Bad gateway</html>',
          200,
          headers: {'content-type': 'text/html'},
        ),
        () => service().downloadCertificate(
          requestUid: 'u1',
          enrollmentNumber: 'ENR1',
        ),
      );
      expect(res.success, isFalse);
      expect(res.message, isNotEmpty);
      expect(dir.listSync(), isEmpty);
    });

    test('no stored token never reaches the network', () async {
      var called = false;
      final res = await withServer((_) {
        called = true;
        return http.Response.bytes(_pdf, 200);
      }, () => service(token: null).downloadCertificate(
        requestUid: 'u1',
        enrollmentNumber: 'ENR1',
      ));
      expect(called, isFalse);
      expect(res.success, isFalse);
      expect(res.statusCode, 401);
    });

    test('a blank request uid is rejected before any call', () async {
      var called = false;
      final res = await withServer((_) {
        called = true;
        return http.Response.bytes(_pdf, 200);
      }, () => service().downloadCertificate(
        requestUid: '  ',
        enrollmentNumber: 'ENR1',
      ));
      expect(called, isFalse);
      expect(res.success, isFalse);
      expect(res.message, 'Certificate not found');
    });
  });
}
