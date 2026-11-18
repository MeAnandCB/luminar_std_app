import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';
import 'package:luminar_std/repository/certificate/certificate_report.dart';
import 'package:luminar_std/repository/certificate/certificate_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CertificateHomeCard — self-contained home-screen entry for course
// certificates. It fetches the student's completed batches and renders
// nothing at all (header included) until at least one batch is completed.
// Tapping opens a sheet where each completed enrollment shows either the
// request form or the status of the request already made.
// ─────────────────────────────────────────────────────────────────────────────

const Color _gold = Color(0xFFFFC24B);
const Color _goldDeep = Color(0xFFB45309);
const Color _pendingColor = Color(0xFFF59E0B);
const Color _issuedColor = Color(0xFF10B981);
const Color _rejectedColor = Color(0xFFEF4444);

String _fmtYmd(String raw) {
  final d = DateTime.tryParse(raw);
  return d == null ? raw : DateFormat('d MMM yyyy').format(d);
}

String _fmtDate(DateTime? d) =>
    d == null ? '' : DateFormat('d MMM yyyy').format(d);

class CertificateHomeCard extends StatefulWidget {
  /// Section heading shown above the card — only rendered together with it,
  /// so a student with no completed batch never sees an empty section.
  final Widget? header;

  /// Space above the header/card, also only applied when the card shows.
  final double topSpacing;

  /// Injectable for tests; defaults to the real API-backed service.
  final CertificateService? service;

  /// Every non-dropped enrollment the dashboard knows about, with its batch
  /// status and fee data. Used to (a) show the card when the certificate list
  /// call fails/is empty but a batch is completed, (b) add the fee check to
  /// server entries, and (c) list still-running batches as locked.
  final List<CertificateEnrollment> dashboardEnrollments;

  /// Logged-in student's name — only used to describe an application in the
  /// debug console.
  final String studentName;

  const CertificateHomeCard({
    super.key,
    this.header,
    this.topSpacing = 0,
    this.service,
    this.dashboardEnrollments = const [],
    this.studentName = '',
  });

  @override
  State<CertificateHomeCard> createState() => _CertificateHomeCardState();
}

class _CertificateHomeCardState extends State<CertificateHomeCard>
    with TickerProviderStateMixin {
  late final CertificateService _service =
      widget.service ?? CertificateService();

  bool _loading = true;

  /// Last answer from the server (null if the call failed).
  CertificateListResponse? _api;

  /// Requests just created by this student that the server list has not
  /// confirmed yet (e.g. the follow-up reload failed), keyed by enrollment.
  final Map<String, CertificateRequestInfo> _patches = {};

  /// What the open sheet renders; kept in sync with the card.
  final ValueNotifier<CertificateListResponse?> _view = ValueNotifier(null);

  /// What is shown. The server's completed batches win; when the list call
  /// failed or is empty, the dashboard's completed batches stand in. Fee and
  /// issued data always come from the dashboard. Still-running batches are
  /// appended as locked entries, but never make the card appear on their own.
  CertificateListResponse? get _data {
    final api = _api?.enrollments ?? const <CertificateEnrollment>[];
    final dash = widget.dashboardEnrollments;
    final dashBy = {for (final d in dash) d.enrollmentNumber: d};

    final Iterable<CertificateEnrollment> base = api.isNotEmpty
        ? api
        : dash.where((d) => d.batchCompleted);

    final completed = <CertificateEnrollment>[
      for (final e in base)
        () {
          final merged = e.mergeDashboard(dashBy[e.enrollmentNumber]);
          final patch = _patches[e.enrollmentNumber];
          return patch == null ? merged : merged.copyWith(request: patch);
        }(),
    ];
    if (completed.isEmpty) return null;

    final shown = {for (final e in completed) e.enrollmentNumber};
    final inProgress = dash.where(
      (d) => !d.batchCompleted && !shown.contains(d.enrollmentNumber),
    );

    final types = _api?.certificateTypes ?? const <CertificateType>[];
    return CertificateListResponse(
      certificateTypes: types.isNotEmpty ? types : CertificateType.fallback,
      enrollments: [...completed, ...inProgress],
    );
  }

  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _entryFade =
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  late final Animation<double> _entryScale = CurvedAnimation(
    parent: _entryCtrl,
    curve: Curves.easeOutBack,
  ).drive(Tween(begin: 0.92, end: 1.0));

  // Pulse for the seal on the certificate icon.
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  // Slow sheen sweeping across the card.
  late final AnimationController _sheenCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _sheenCtrl.dispose();
    _view.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CertificateHomeCard old) {
    super.didUpdateWidget(old);
    if (_loading) return;
    _syncAnimations();
    // Don't touch the open sheet's listeners while the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _view.value = _data;
    });
  }

  Future<void> _load() async {
    final res = await _service.getRequests();
    if (!mounted) return;

    // Console only (debug builds): why the list was unusable, if it was.
    if (!res.success) {
      LoggerUtils.warning(
        'Certificate list failed [${res.statusCode}] ${res.message} | '
        'token ${_service.lastTokenNote}',
        tag: 'Certificate',
      );
    }
    _apply(res.success ? res.data : null);
  }

  void _apply(CertificateListResponse? api) {
    setState(() {
      _api = api;
      _loading = false;
    });
    _view.value = _data;
    _syncAnimations();
  }

  /// Re-reads the server list (the API guide's recommended way to stay in
  /// sync after a request). A failed/empty answer keeps what is on screen.
  Future<void> _reload() async {
    final res = await _service.getRequests();
    if (!mounted || !res.success || res.data == null) return;
    if (res.data!.enrollments.isEmpty) return;
    // The server now knows these — its answer beats any local patch.
    _patches.removeWhere(
      (number, _) =>
          res.data!.enrollments.any((e) => e.enrollmentNumber == number),
    );
    _apply(res.data);
  }

  /// Prints which enrollment is applying, with its batch/payment details.
  void _logApplication(String enrollmentNumber, String type, String note) {
    final data = _data;
    if (data == null) return;
    final enrollment = data.enrollments.firstWhere(
      (e) => e.enrollmentNumber == enrollmentNumber,
      orElse: () => CertificateEnrollment(
        enrollmentNumber: enrollmentNumber,
        courseName: '',
        batchName: '',
        batchEndDate: '',
        eligible: true,
      ),
    );
    final label = data.certificateTypes
        .where((t) => t.value == type)
        .map((t) => t.label)
        .firstOrNull;
    LoggerUtils.info(
      certificateApplicationReport(
        enrollment: enrollment,
        studentName: widget.studentName,
        typeValue: type,
        typeLabel: label ?? type,
        note: note,
        dataSource: (_api?.enrollments.isNotEmpty ?? false)
            ? 'server list'
            : 'dashboard (server list unavailable or empty)',
      ),
      tag: 'Certificate',
    );
  }

  /// Requests ONE enrollment's certificate. Each enrollment is submitted on
  /// its own; the others are untouched. Returns an error message, or null.
  Future<String?> _submit(
    String enrollmentNumber,
    String type,
    String note,
  ) async {
    _logApplication(enrollmentNumber, type, note);

    final res = await _service.requestCertificate(
      enrollmentNumber: enrollmentNumber,
      certificateType: type,
      studentNote: note,
    );
    LoggerUtils.info(
      'Result for $enrollmentNumber: '
      '${res.success ? 'SUCCESS' : 'FAILED'} [${res.statusCode}] '
      '${res.success ? 'status=${res.data?.status}' : res.message}',
      tag: 'Certificate',
    );
    if (res.success && res.data != null) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        // Flip that enrollment to "pending" right away, then confirm.
        setState(() => _patches[enrollmentNumber] = res.data!);
        _view.value = _data;
        await _reload();
      }
      return null;
    }
    // e.g. a double tap already created it — pull the real state.
    if (res.message == 'Request already exists') await _reload();
    return res.message ?? 'Could not submit your request. Please try again.';
  }

  /// Only burn frames on the looping animations while the card is visible.
  void _syncAnimations() {
    if (_data != null) {
      if (!_entryCtrl.isCompleted && !_entryCtrl.isAnimating) {
        _entryCtrl.forward();
      }
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      if (!_sheenCtrl.isAnimating) _sheenCtrl.repeat();
    } else {
      _pulseCtrl.stop();
      _sheenCtrl.stop();
    }
  }

  Future<void> _openSheet() async {
    final data = _data;
    if (data == null) return;
    HapticFeedback.selectionClick();
    _view.value = data;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CertificateSheet(view: _view, onSubmit: _submit),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final data = _data;
    if (data == null || data.enrollments.isEmpty) {
      return const SizedBox.shrink();
    }

    final summary = _CardSummary.from(data.enrollments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: widget.topSpacing),
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 14),
        ],
        FadeTransition(
          opacity: _entryFade,
          child: ScaleTransition(
            scale: _entryScale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openSheet,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _sheenCtrl,
                              builder: (_, __) => CustomPaint(
                                painter: _BackdropPainter(
                                  sheen: _sheenCtrl.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: _buildContent(summary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(_CardSummary s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 62,
              height: 62,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _CertificateIconPainter(pulse: _pulseCtrl.value),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.tagIcon, size: 12, color: _gold),
                        const SizedBox(width: 4),
                        Text(
                          s.tag,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        s.cta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Spacer(),
            if (s.actionCount > 1)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s.actionCount} batches',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B2A00),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// What the home card says, derived from the completed enrollments (locked,
// still-running batches never drive it). The most actionable state wins:
// ready to apply > rejected > fees pending > pending > issued > not eligible.
// ─────────────────────────────────────────────────────────────────────────────

String _money(int amount) => '₹${NumberFormat('#,##,###').format(amount)}';

class _CardSummary {
  final String tag;
  final IconData tagIcon;
  final String title;
  final String subtitle;
  final String cta;

  /// How many enrollments are in the winning state (shown as a chip if > 1).
  final int actionCount;

  const _CardSummary({
    required this.tag,
    required this.tagIcon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.actionCount,
  });

  factory _CardSummary.from(List<CertificateEnrollment> all) {
    final done = all.where((e) => e.batchCompleted).toList();

    final ready = done.where((e) => e.request == null && e.block == null);
    final rejected = done.where((e) => e.request?.isRejected == true).toList();
    final unpaid = done
        .where(
          (e) =>
              e.request == null &&
              (e.block == CertificateBlock.paymentPending ||
                  e.block == CertificateBlock.emiOverdue),
        )
        .toList();
    final pending = done.where((e) => e.request?.isPending == true).toList();
    final issued = done
        .where(
          (e) =>
              e.request?.isIssued == true ||
              (e.request == null && e.certificateAlreadyIssued),
        )
        .toList();

    if (ready.isNotEmpty) {
      final list = ready.toList();
      return _CardSummary(
        tag: 'BATCH COMPLETED',
        tagIcon: Icons.celebration_rounded,
        title: 'Claim your certificate!',
        subtitle: list.length == 1
            ? 'Congratulations on completing ${list.first.courseName}. '
                  'Apply in under a minute.'
            : '${list.length} completed batches are ready for a certificate.',
        cta: 'Apply Now',
        actionCount: list.length,
      );
    }
    if (rejected.isNotEmpty) {
      final only = rejected.length == 1 ? rejected.first.request! : null;
      return _CardSummary(
        tag: 'ACTION NEEDED',
        tagIcon: Icons.error_outline_rounded,
        title: 'Certificate request rejected',
        subtitle: only != null && only.remark.isNotEmpty
            ? 'Reason: ${only.remark}'
            : 'Tap to see the reason and apply again.',
        cta: rejected.any((e) => e.canRequest)
            ? 'Review & Re-apply'
            : 'View Details',
        actionCount: rejected.length,
      );
    }
    if (unpaid.isNotEmpty) {
      final first = unpaid.first;
      final emi = first.block == CertificateBlock.emiOverdue;
      final amount = emi ? first.emiOverdueAmount : first.pendingAmount;
      final money = amount == null || amount <= 0 ? '' : ' (${_money(amount)})';
      return _CardSummary(
        tag: 'PAYMENT PENDING',
        tagIcon: Icons.account_balance_wallet_rounded,
        title: emi ? 'EMI payment overdue' : 'Complete your payment',
        subtitle: unpaid.length == 1
            ? (emi
                  ? 'Clear your overdue EMI$money to apply for your '
                        'certificate.'
                  : 'Clear ${_money(first.pendingAmount ?? 0)} of pending '
                        'fees to apply for your certificate.')
            : '${unpaid.length} completed batches are waiting on payment. '
                  'Clear it to apply.',
        cta: 'View Details',
        actionCount: unpaid.length,
      );
    }
    if (pending.isNotEmpty) {
      final only = pending.length == 1 ? pending.first.request! : null;
      return _CardSummary(
        tag: 'IN REVIEW',
        tagIcon: Icons.hourglass_top_rounded,
        title: 'Certificate requested',
        subtitle: only != null
            ? '${only.certificateTypeLabel} · requested on '
                  '${_fmtDate(only.requestedAt)}'
            : '${pending.length} requests are being reviewed.',
        cta: 'View Status',
        actionCount: pending.length,
      );
    }
    if (issued.isNotEmpty) {
      final one = issued.length == 1 ? issued.first : null;
      final req = one?.request;
      return _CardSummary(
        tag: 'ISSUED',
        tagIcon: Icons.verified_rounded,
        title: 'Certificate issued!',
        subtitle: one == null
            ? '${issued.length} certificates have been issued.'
            : req == null
            ? 'Your certificate has already been issued.'
            : '${req.certificateTypeLabel}'
                  '${req.issuedDate != null ? ' · issued on ${_fmtYmd(req.issuedDate!)}' : ''}',
        cta: 'View Details',
        actionCount: issued.length,
      );
    }
    return const _CardSummary(
      tag: 'BATCH COMPLETED',
      tagIcon: Icons.school_rounded,
      title: 'Certificates',
      subtitle: 'Not eligible for a certificate for this enrollment.',
      cta: 'View Details',
      actionCount: 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

/// Faint decorative circles + gold sparkles, with a slow diagonal sheen.
class _BackdropPainter extends CustomPainter {
  final double sheen; // 0..1, looping

  _BackdropPainter({required this.sheen});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final soft = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(w * 0.92, h * 0.05), h * 0.55, soft);
    canvas.drawCircle(Offset(w * 0.78, h * 1.0), h * 0.45, soft);

    final sparkle = Paint()..color = _gold.withValues(alpha: 0.55);
    _sparkle(canvas, Offset(w * 0.90, h * 0.22), 7, sparkle);
    _sparkle(canvas, Offset(w * 0.80, h * 0.62), 4.5, sparkle);
    _sparkle(canvas, Offset(w * 0.95, h * 0.78), 5.5, sparkle);

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.86, h * 0.40), 1.8, dot);
    canvas.drawCircle(Offset(w * 0.70, h * 0.12), 1.5, dot);

    // Sheen band.
    final band = w * 0.26;
    final skew = h * 0.6;
    final travel = w + band * 2;
    final cx = -band + sheen * travel;
    final path = Path()
      ..moveTo(cx - band / 2, 0)
      ..lineTo(cx + band / 2, 0)
      ..lineTo(cx + band / 2 - skew, h)
      ..lineTo(cx - band / 2 - skew, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(cx - band, 0, band * 2, h)),
    );
  }

  void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.sheen != sheen;
}

/// A certificate sheet with a gold rosette + ribbon tails, drawn by hand
/// instead of a stock Material icon. The rosette glows with [pulse].
class _CertificateIconPainter extends CustomPainter {
  final double pulse; // 0..1

  _CertificateIconPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.30),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Paper.
    final paper = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.17, w * 0.62, h * 0.58),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(paper, Paint()..color = Colors.white);
    canvas.drawRRect(
      paper.deflate(w * 0.045),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = _gold.withValues(alpha: 0.9),
    );

    // Text lines — the first (title) is darker and shorter.
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.045;
    line.color = const Color(0xFF94A3B8);
    canvas.drawLine(
      Offset(w * 0.30, h * 0.31),
      Offset(w * 0.60, h * 0.31),
      line,
    );
    line.color = const Color(0xFFCBD5E1);
    canvas.drawLine(
      Offset(w * 0.25, h * 0.42),
      Offset(w * 0.65, h * 0.42),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.25, h * 0.52),
      Offset(w * 0.52, h * 0.52),
      line,
    );

    // Rosette: soft halo, ribbon tails, seal, star.
    final center = Offset(w * 0.68, h * 0.70);
    final r = w * 0.17 * (1.0 + 0.07 * pulse);

    canvas.drawCircle(
      center,
      r * 1.5,
      Paint()
        ..color = _gold.withValues(alpha: 0.28 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final tailL = Path()
      ..moveTo(center.dx - r * 0.55, center.dy + r * 0.4)
      ..lineTo(center.dx - r * 0.95, center.dy + r * 1.75)
      ..lineTo(center.dx - r * 0.35, center.dy + r * 1.35)
      ..lineTo(center.dx - r * 0.05, center.dy + r * 1.8)
      ..close();
    final tailR = Path()
      ..moveTo(center.dx + r * 0.55, center.dy + r * 0.4)
      ..lineTo(center.dx + r * 0.95, center.dy + r * 1.75)
      ..lineTo(center.dx + r * 0.35, center.dy + r * 1.35)
      ..lineTo(center.dx + r * 0.05, center.dy + r * 1.8)
      ..close();
    canvas.drawPath(tailL, Paint()..color = const Color(0xFFE08A00));
    canvas.drawPath(tailR, Paint()..color = const Color(0xFFF2A816));

    canvas.drawCircle(center, r, Paint()..color = _gold);
    canvas.drawCircle(
      center,
      r * 0.74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _goldDeep.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      _star(center, r * 0.5, r * 0.22),
      Paint()..color = _goldDeep,
    );
  }

  Path _star(Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _CertificateIconPainter old) =>
      old.pulse != pulse;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — one tile per completed enrollment.
// ─────────────────────────────────────────────────────────────────────────────

class _CertificateSheet extends StatelessWidget {
  final ValueListenable<CertificateListResponse?> view;
  final Future<String?> Function(String enrollmentNumber, String type, String note)
  onSubmit;

  const _CertificateSheet({required this.view, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ValueListenableBuilder<CertificateListResponse?>(
            valueListenable: view,
            builder: (context, data, _) {
              final enrollments = data?.enrollments ?? const [];
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: _gold,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Certificates',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Each course is requested separately',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (enrollments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Certificates can be requested after your batch is '
                        'completed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    for (final e in enrollments)
                      _EnrollmentTile(
                        key: ValueKey(e.enrollmentNumber),
                        enrollment: e,
                        types: data!.certificateTypes,
                        onSubmit: onSubmit,
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EnrollmentTile extends StatefulWidget {
  final CertificateEnrollment enrollment;
  final List<CertificateType> types;
  final Future<String?> Function(String enrollmentNumber, String type, String note)
  onSubmit;

  const _EnrollmentTile({
    super.key,
    required this.enrollment,
    required this.types,
    required this.onSubmit,
  });

  @override
  State<_EnrollmentTile> createState() => _EnrollmentTileState();
}

class _EnrollmentTileState extends State<_EnrollmentTile> {
  String? _type;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.types.isNotEmpty) _type = widget.types.first.value;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final type = _type;
    if (type == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await widget.onSubmit(
      widget.enrollment.enrollmentNumber,
      type,
      _noteCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enrollment;
    final req = e.request;
    final block = e.block;
    // A pending/issued request is the whole story; otherwise show what (if
    // anything) stops a new request.
    final showBlock = block != null && (req == null || req.isRejected);

    final subtitle = e.batchCompleted
        ? (e.batchEndDate.isEmpty
              ? 'Batch ${e.batchName} · Completed'
              : 'Batch ${e.batchName} · Completed ${_fmtYmd(e.batchEndDate)}')
        : (e.batchEndDate.isEmpty
              ? 'Batch ${e.batchName} · In progress'
              : 'Batch ${e.batchName} · Ends ${_fmtYmd(e.batchEndDate)}');

    return Opacity(
      opacity: e.batchCompleted ? 1 : 0.8,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.courseName.isEmpty ? 'Course' : e.courseName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              e.enrollmentNumber,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            if (req != null) _statusBlock(req),
            if (showBlock) ...[
              if (req != null) const SizedBox(height: 10),
              _blockNotice(e, block),
            ],
            if (e.canRequest) ...[
              if (req != null) const SizedBox(height: 14),
              _form(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _blockNotice(CertificateEnrollment e, CertificateBlock block) {
    switch (block) {
      case CertificateBlock.batchInProgress:
        return _InfoBox(
          icon: Icons.lock_clock_rounded,
          color: AppColors.textSecondary,
          text:
              'Your batch is still in progress. You can apply for the '
              'certificate once it is completed.',
        );
      case CertificateBlock.notEligible:
        return _InfoBox(
          icon: Icons.info_outline_rounded,
          color: AppColors.textSecondary,
          text: 'Not eligible for a certificate for this enrollment.',
        );
      case CertificateBlock.alreadyIssued:
        return _InfoBox(
          icon: Icons.verified_rounded,
          color: _issuedColor,
          text: 'Your certificate for this enrollment has already been issued.',
        );
      case CertificateBlock.emiOverdue:
        final money = (e.emiOverdueAmount ?? 0) > 0
            ? ' (${_money(e.emiOverdueAmount!)})'
            : '';
        final where = switch (e.emiOverdueHere) {
          true => 'Your EMI for this enrollment is overdue$money.',
          false =>
            'Your account has an overdue EMI$money on another enrollment.',
          null => 'Your EMI payment is overdue$money.',
        };
        return _InfoBox(
          icon: Icons.event_busy_rounded,
          color: _pendingColor,
          text: '$where Clear the overdue EMI to apply for the certificate.',
        );
      case CertificateBlock.paymentPending:
        return _InfoBox(
          icon: Icons.account_balance_wallet_rounded,
          color: _pendingColor,
          text:
              'Payment pending: ${_money(e.pendingAmount ?? 0)}. Clear your '
              'pending fees to apply for the certificate.',
        );
    }
  }

  Widget _statusBlock(CertificateRequestInfo req) {
    final (color, icon, label) = switch (req.status) {
      'issued' => (
        _issuedColor,
        Icons.verified_rounded,
        'Issued on ${req.issuedDate != null ? _fmtYmd(req.issuedDate!) : '—'}',
      ),
      'rejected' => (_rejectedColor, Icons.cancel_rounded, 'Rejected'),
      _ => (
        _pendingColor,
        Icons.hourglass_top_rounded,
        'Requested on ${_fmtDate(req.requestedAt)}',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          req.certificateTypeLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (req.isRejected && req.remark.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InfoBox(
            icon: Icons.chat_bubble_outline_rounded,
            color: _rejectedColor,
            text: 'Reason: ${req.remark}',
          ),
        ],
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Certificate type',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in widget.types)
              _TypeChip(
                label: t.label,
                selected: t.value == _type,
                onTap: _submitting ? null : () => setState(() => _type = t.value),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteCtrl,
          enabled: !_submitting,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Add a note (optional) — e.g. needed for a job application',
            hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _InfoBox(
            icon: Icons.error_outline_rounded,
            color: _rejectedColor,
            text: _error!,
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_submitting || _type == null) ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.workspace_premium_rounded, size: 18),
            label: Text(
              _submitting ? 'Submitting…' : 'Request Certificate',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBox({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, height: 1.35, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
