import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luminar_std/core/services/response.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';
import 'package:luminar_std/repository/certificate/certificate_service.dart';

/// One enrollment as the list endpoint returns it.
Map<String, dynamic> enrollmentJson(
  String number, {
  Map<String, dynamic>? request,
  bool eligible = true,
  String type = 'internship',
  String typeLabel = 'Internship',
}) => {
  'enrollment_number': number,
  'course_name': 'Python Full Stack',
  'batch_name': 'PY-1',
  'batch_end_date': '2026-11-07',
  'eligible': eligible,
  'certificate_type': type,
  'certificate_type_label': typeLabel,
  'request': request,
};

/// One certificate request as the API returns it.
Map<String, dynamic> requestJson(
  String status, {
  String remark = '',
  bool download = false,
  int? serial,
  String? register,
}) => {
  'uid': 'u-$status',
  'certificate_type': 'internship',
  'certificate_type_label': 'Internship',
  'status': status,
  'remark': remark,
  'student_note': '',
  'requested_at': '2026-11-17T10:21:43.512Z',
  'issued_date': status == 'issued' ? '2026-11-20' : null,
  'download_available': download,
  'serial_no': serial,
  'register_no': register,
};

CertificateListResponse listOf(List<Map<String, dynamic>> enrollments) =>
    CertificateListResponse.fromJson({
      'status': 'success',
      // Kept by the server for old apps; the app must ignore it.
      'certificate_types': [
        {'value': 'completion', 'label': 'Course Completion'},
        {'value': 'internship', 'label': 'Internship'},
      ],
      'enrollments': enrollments,
    });

/// A [CertificateService] that never touches the network.
class FakeCertificateService extends CertificateService {
  CertificateListResponse? list;
  String? failWith;
  String? downloadFailWith;
  bool failReloadAfterPost = false;
  final List<Map<String, String>> posted = [];
  final List<Map<String, String>> downloads = [];

  /// How many times the list was fetched.
  int listCalls = 0;

  /// While set, `getRequests` waits on it — lets a test observe "loading".
  Completer<void>? gate;

  FakeCertificateService(this.list);

  @override
  Future<ApiResponse<CertificateListResponse>> getRequests() async {
    listCalls++;
    if (gate != null) await gate!.future;
    return list == null
        ? ApiResponse.error('boom', 500)
        : ApiResponse.success(list!, 200);
  }

  @override
  Future<ApiResponse<CertificateRequestInfo>> requestCertificate({
    required String enrollmentNumber,
    String? studentNote,
  }) async {
    if (failWith != null) return ApiResponse.error(failWith!, 400);
    posted.add({
      'enrollment_number': enrollmentNumber,
      'student_note': studentNote ?? '',
    });
    // Server now has a pending request for it (or the reload breaks).
    final info = CertificateRequestInfo.fromJson(requestJson('pending'));
    if (failReloadAfterPost) {
      list = null;
    } else if (list != null) {
      list = CertificateListResponse(
        enrollments: [
          for (final e in list!.enrollments)
            e.enrollmentNumber == enrollmentNumber
                ? e.copyWith(request: info)
                : e,
        ],
      );
    }
    return ApiResponse.success(info, 201);
  }

  @override
  Future<ApiResponse<String>> downloadCertificate({
    required String requestUid,
    required String enrollmentNumber,
  }) async {
    downloads.add({'uid': requestUid, 'enrollment_number': enrollmentNumber});
    if (downloadFailWith != null) {
      return ApiResponse.error(downloadFailWith!, 404);
    }
    return ApiResponse.success('/tmp/Certificate-$enrollmentNumber.pdf', 200);
  }
}

/// The card loops its pulse/sheen animations forever, so `pumpAndSettle` would
/// never return — advance time explicitly instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}
