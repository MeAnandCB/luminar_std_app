import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/certificate/certificate_controller.dart';
import 'package:luminar_std/presentation/certificate/certificate_screen.dart';
import 'package:luminar_std/presentation/certificate/certificate_tile.dart';
import 'package:luminar_std/repository/certificate/certificate_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CertificateHomeCard — home-screen entry for course certificates.
//
// WHEN IT SHOWS (otherwise it renders nothing, heading included):
//   • the dashboard says at least one of the student's courses is completed
//     (`completedCourses`, see batch_completion.dart), OR
//   • the server's certificate list already has a course in it.
//
// WHAT IT SAYS: once the server's list is in, the state of the most
// actionable course (ready to apply > rejected > pending > issued). Until
// then — or if the server can't confirm — a neutral "view your certificate"
// card, so it never claims "apply" or "issued" before it knows.
//
// Tapping opens the full Certificates page, which has the request form, the
// request status, the certificate's numbers and the Download button — and
// explains loading, errors and "nothing found yet".
// ─────────────────────────────────────────────────────────────────────────────

const Color _gold = Color(0xFFFFC24B);
const Color _goldDeep = Color(0xFFB45309);

class CertificateHomeCard extends StatefulWidget {
  /// Shared with the More → Certificates page, so a request made in either
  /// place shows up in both.
  final CertificateController controller;

  /// Names of the courses the dashboard says are completed (one entry per
  /// course; a missing name is ''). Non-empty makes the card show even before
  /// the server's list arrives.
  final List<String> completedCourses;

  /// Section heading shown above the card — only rendered together with it,
  /// so a student with no completed course never sees an empty section.
  final Widget? header;

  /// Space above the header/card, also only applied when the card shows.
  final double topSpacing;

  const CertificateHomeCard({
    super.key,
    required this.controller,
    this.completedCourses = const [],
    this.header,
    this.topSpacing = 0,
  });

  @override
  State<CertificateHomeCard> createState() => _CertificateHomeCardState();
}

class _CertificateHomeCardState extends State<CertificateHomeCard>
    with TickerProviderStateMixin {
  CertificateController get _c => widget.controller;

  /// The card shows if the dashboard says a course is completed, or the
  /// server already lists one.
  bool get _visible => widget.completedCourses.isNotEmpty || _c.data != null;

  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _entryFade = CurvedAnimation(
    parent: _entryCtrl,
    curve: Curves.easeOut,
  );
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
    _c.addListener(_onChanged);
    _c.load();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant CertificateHomeCard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      widget.controller.load();
    }
    // The dashboard usually finishes loading after this card is first built,
    // so `completedCourses` can change under us.
    _syncAnimations();
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _syncAnimations();
  }

  /// Only burn frames on the looping animations while the card is visible.
  void _syncAnimations() {
    if (_visible) {
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

  Future<void> _openPage() async {
    HapticFeedback.selectionClick();
    final names = widget.completedCourses.where((n) => n.trim().isNotEmpty);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CertificateScreen(
          controller: _c,
          // Only used to word the "nothing found yet" message.
          courseName: names.isEmpty ? '' : names.first,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final data = _c.data;
    final summary = data == null
        ? _CardSummary.checking(widget.completedCourses)
        : _CardSummary.from(data.enrollments);

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
                    onTap: _openPage,
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
// What the home card says, derived from the server's enrollments. The most
// actionable state wins: ready to apply > rejected > pending > issued > not
// eligible.
// ─────────────────────────────────────────────────────────────────────────────

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

  /// The dashboard says a course is completed, but the server's list has not
  /// arrived (or cannot confirm it). Says nothing about applying or issuing.
  factory _CardSummary.checking(List<String> courses) {
    final named = courses.where((n) => n.trim().isNotEmpty).toList();
    return _CardSummary(
      tag: 'COURSE COMPLETED',
      tagIcon: Icons.school_rounded,
      title: 'Your certificate',
      subtitle: courses.length == 1
          ? 'Congratulations on completing '
                '${named.isEmpty ? 'your course' : named.first}. '
                'Tap to view your certificate.'
          : '${courses.length} completed courses. Tap to view your '
                'certificates.',
      cta: 'View Certificate',
      actionCount: courses.length,
    );
  }

  factory _CardSummary.from(List<CertificateEnrollment> all) {
    final ready = all.where((e) => e.request == null && e.canRequest).toList();
    final rejected = all.where((e) => e.request?.isRejected == true).toList();
    final pending = all.where((e) => e.request?.isPending == true).toList();
    final issued = all.where((e) => e.request?.isIssued == true).toList();

    if (ready.isNotEmpty) {
      return _CardSummary(
        tag: 'BATCH COMPLETED',
        tagIcon: Icons.celebration_rounded,
        title: 'Claim your certificate!',
        subtitle: ready.length == 1
            ? 'Congratulations on completing ${ready.first.courseName}. '
                  'Apply in under a minute.'
            : '${ready.length} completed batches are ready for a certificate.',
        cta: 'Apply Now',
        actionCount: ready.length,
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
    if (pending.isNotEmpty) {
      final only = pending.length == 1 ? pending.first.request! : null;
      return _CardSummary(
        tag: 'IN REVIEW',
        tagIcon: Icons.hourglass_top_rounded,
        title: 'Certificate requested',
        subtitle: only != null
            ? '${only.certificateTypeLabel} · requested on '
                  '${formatCertificateDate(only.requestedAt)}'
            : '${pending.length} requests are being reviewed.',
        cta: 'View Status',
        actionCount: pending.length,
      );
    }
    if (issued.isNotEmpty) {
      final one = issued.length == 1 ? issued.first.request! : null;
      final canDownload = issued.any((e) => e.request!.downloadAvailable);
      return _CardSummary(
        tag: 'ISSUED',
        tagIcon: Icons.verified_rounded,
        title: 'Certificate issued!',
        subtitle: one == null
            ? '${issued.length} certificates have been issued.'
            : '${one.certificateTypeLabel}'
                  '${one.issuedDate != null ? ' · issued on ${formatCertificateYmd(one.issuedDate!)}' : ''}',
        cta: canDownload ? 'Download' : 'View Details',
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
