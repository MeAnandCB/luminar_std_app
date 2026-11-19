import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';
import 'package:luminar_std/repository/certificate/certificate_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Opens a saved certificate file. Returns false when no app could open it.
typedef CertificateFileOpener = Future<bool> Function(String path);

Future<bool> openCertificatePdf(String path) async {
  try {
    final result = await OpenFilex.open(path, type: 'application/pdf');
    return result.type == ResultType.done;
  } catch (_) {
    return false;
  }
}

/// The student's certificates, shared by every place that shows them (the home
/// card and the More → Certificates page) so a request made in one is seen in
/// the other straight away.
///
/// The server is the source of truth: it lists only completed batches and
/// decides eligibility. This class only fetches, remembers the answer, and
/// performs the two actions a student can take — request and download.
class CertificateController extends ChangeNotifier {
  CertificateController({
    CertificateService? service,
    CertificateFileOpener? fileOpener,
  }) : _service = service ?? CertificateService(),
       _openFile = fileOpener ?? openCertificatePdf;

  final CertificateService _service;
  final CertificateFileOpener _openFile;

  /// Last good answer from the server (null until one arrives).
  CertificateListResponse? _api;

  /// Why the first fetch failed. Only kept while there is nothing to show;
  /// once a list is on screen a failed refresh just leaves it as it was.
  String? _error;

  Future<void>? _inFlight;
  bool _disposed = false;

  /// Requests just created by this student that the server list has not
  /// confirmed yet (e.g. the follow-up refresh failed), keyed by enrollment.
  final Map<String, CertificateRequestInfo> _patches = {};

  /// No answer yet — neither a list nor an error.
  bool get isLoading => _api == null && _error == null;

  /// A readable reason the list could not be loaded (null when it could, or
  /// while a list is already on screen).
  String? get error => _error;

  /// The server's enrollments with any just-submitted request laid over them.
  /// Null when there is nothing to show (not loaded, failed, or empty), which
  /// is what hides the home card.
  CertificateListResponse? get data {
    final api = _api?.enrollments ?? const <CertificateEnrollment>[];
    if (api.isEmpty) return null;
    return CertificateListResponse(
      enrollments: [
        for (final e in api)
          _patches[e.enrollmentNumber] == null
              ? e
              : e.copyWith(request: _patches[e.enrollmentNumber]),
      ],
    );
  }

  /// Fetches once; does nothing if a list has already been loaded.
  Future<void> load() => _api != null ? Future.value() : refresh();

  /// Re-reads the list from the server. Overlapping calls share one request.
  /// A failure keeps whatever is already on screen.
  Future<void> refresh() {
    final running = _inFlight;
    if (running != null) return running;

    // Retrying after a failed first load: show the spinner again. The state
    // changes now, but listeners are told a moment later — refresh() is also
    // called from initState (while widgets are being built), and marking a
    // listening widget dirty mid-build throws.
    if (_error != null) {
      _error = null;
      scheduleMicrotask(() {
        if (!_disposed) notifyListeners();
      });
    }
    return _inFlight = _fetch();
  }

  Future<void> _fetch() async {
    final res = await _service.getRequests();
    _inFlight = null;
    if (_disposed) return;

    if (res.success && res.data != null) {
      _api = res.data;
      _error = null;
      // The server now knows these — its answer beats any local patch.
      _patches.removeWhere(
        (number, _) =>
            res.data!.enrollments.any((e) => e.enrollmentNumber == number),
      );
    } else {
      LoggerUtils.warning(
        'Certificate list failed [${res.statusCode}] ${res.message} | '
        'token ${_service.lastTokenNote}',
        tag: 'Certificate',
      );
      if (_api == null) {
        _error = AppUtils.friendlyError(res.message ?? '');
      }
    }
    notifyListeners();
  }

  /// Requests ONE enrollment's certificate. Each enrollment is submitted on
  /// its own; the others are untouched. Returns an error message, or null.
  Future<String?> submit(String enrollmentNumber, String note) async {
    final res = await _service.requestCertificate(
      enrollmentNumber: enrollmentNumber,
      studentNote: note,
    );
    LoggerUtils.info(
      'Request for $enrollmentNumber: '
      '${res.success ? 'SUCCESS' : 'FAILED'} [${res.statusCode}] '
      '${res.success ? 'status=${res.data?.status}' : res.message}',
      tag: 'Certificate',
    );
    if (res.success && res.data != null) {
      HapticFeedback.mediumImpact();
      if (!_disposed) {
        // Flip that enrollment to "pending" right away, then confirm with the
        // server (the API guide's recommended way to stay in sync).
        _patches[enrollmentNumber] = res.data!;
        notifyListeners();
        await refresh();
      }
      return null;
    }
    // e.g. a double tap already created it — pull the real state.
    if (res.message == 'Request already exists') await refresh();
    return AppUtils.friendlyError(
      res.message ?? 'Could not submit your request. Please try again.',
    );
  }

  /// Downloads the issued PDF and opens it. Returns an error message, or null.
  /// If no PDF viewer can open the file, it is offered through the share
  /// sheet instead so the student still gets it.
  Future<String?> download(CertificateEnrollment e) async {
    final res = await _service.downloadCertificate(
      requestUid: e.request?.uid ?? '',
      enrollmentNumber: e.enrollmentNumber,
    );
    LoggerUtils.info(
      'Download for ${e.enrollmentNumber}: '
      '${res.success ? 'SUCCESS' : 'FAILED'} [${res.statusCode}] '
      '${res.success ? res.data : res.message}',
      tag: 'Certificate',
    );
    if (!res.success || res.data == null) {
      return AppUtils.friendlyError(
        res.message ?? 'Could not download the certificate.',
      );
    }

    HapticFeedback.mediumImpact();
    if (await _openFile(res.data!)) return null;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(res.data!, mimeType: 'application/pdf')],
          text: 'My ${e.certificateTypeLabel} certificate',
        ),
      );
      return null;
    } catch (_) {
      return 'Downloaded, but no app could open the PDF.';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
